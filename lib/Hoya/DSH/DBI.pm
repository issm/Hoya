package Hoya::DSH::DBI;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use DBI;
use YAML::Syck;
use Digest::SHA1 qw/sha1_hex/;
use Error qw/:try/;

use Hoya::Util;

our $CACHE_EXPIRES = 10;

my $_env;
my $_conf;

my $_cache;
my $_sql_cache;
my $_pre;
my $_sth;
my $_dbh;


__PACKAGE__->mk_accessors(qw/env conf cache/);


sub init {
    my $self = shift;
    $_env   = $self->env;
    $_conf  = $self->conf;
    $_cache = $self->cache;

    $_sql_cache = {};
    $_pre   = $_conf->{DB}{TABLE_PREFIX}  ||  '';
    $self->connect;
    $self;
}


#
#  DBに接続する
#
sub connect {
    my $self = shift;
    my $db_type = lc ($_conf->{DB}{TYPE} || 'mysql');

    if($_dbh  &&  $_sth) {
        warn sprintf 'Already connected to %s', $db_type;
        return;
    }

    # MySQL
    if($db_type eq 'mysql') {
        $_dbh = DBI->connect(
            sprintf(
                'DBI:mysql:%s:%s',
                $_conf->{DB}{NAME},
                $_conf->{DB}{HOST},
            ),
            $_conf->{DB}{USER},
            $_conf->{DB}{PASSWD},
            { AutoCommit => 1 },
        ) or
            (warn "Could not connect to database: " . DBI->errstr
             && return);
        $self->prepare;
    }
    # PostgreSQL
    elsif( $db_type eq 'pgsql' ) {
    }
    # SQLite
    elsif( $db_type eq 'sqlite' ) {
    }
}

#
#  DBから切断する
#
sub disconnect {
    my $self = shift;
    $_sth->finish;
    $_dbh->disconnect;
}

#  ステートメントハンドルを準備する
sub prepare {
    shift;
    $_sth = $_dbh->prepare( shift || '' );
}



#
#  ステートメントを実行する
#
sub execute {
    my $self = shift;
    $_sth->execute( defined @_ ? @_ : undef );
}




# q($sql, \@bind, []);
# q($sql, \@bind, {}, $key);
sub q { shift->query(@_); }
sub query {
    my $self = shift;
    my ($sql, $bind, $ref_type, $key) = @_;
    my $cache = 0;
    my $db_type = $_conf->{DB}{TYPE};

    if (!defined $ref_type || $ref_type eq '') { $ref_type = 'array'; }
    elsif (ref $ref_type eq 'ARRAY')           { $ref_type = 'array'; }
    elsif (ref $ref_type eq 'HASH')            { $ref_type = 'hash'; }

    $sql =~ s/^\s*//;

    # v $sql が次の書式の場合，load_sql メソッドを呼ぶ
    #   <name>::<key>[<limit>]
    #   +<name>::<key>[<limit>]  # 可能であればキャッシュする
    my ($cache_, $name_, $key_, $limit_) =
        $sql =~ qr/(\+)? (\w+) :: (\w+) (?:\[ (\d+ (?:, \d+)?) \])?/x;
    if ($name_  &&  $key_) {
        $sql = $self->load_sql(
            name  => $name_,
            key   => $key_,
            limit => $limit_,
        );
        $cache = $cache_ ? 1 : 0;
    }
    #
    # 通常のSQL文の先頭が「+」で始まっている場合
    #
    elsif ($sql =~ /^\s* \+/x) {
        $cache = 1;
        $sql = substr($sql, 1);  # 先頭の1文字（「+」）を削除
    }

    # v $ref_type がハッシュだが，$keyの指定がない場合
    return {}  if $ref_type eq 'hash'  &&  ! $key;

    my $ret;
    # mysql
    if ($db_type eq 'mysql') {
        $ret = $self->_q_mysql($sql, $bind, $ref_type, $key, $cache);
    }

    return $ret;
}


sub _q_mysql {
    my $self = shift;
    my ($sql, $bind, $ref_type, $key, $cache) = @_;

    $self->prepare($sql);

    #
    # INSERT, REPLACE, UPDATE, DELETE, CREATE TABLE, DROP TABLE
    #
    if ($sql =~ qr/
                      ^\s*(?:
                          INSERT|REPLACE|UPDATE|DELETE|
                          CREATE\s+TABLE|DROP\s+TABLE
                      )\s
                  /ix) {
        my $rows_affected = 0;
        # $bindが指定されている
        if (defined $bind) {
            for my $b (@$bind) {
                # $bind == [\@arr1, \@arr2, ...]
                if (ref $b eq 'ARRAY') {
                    $rows_affected += $_sth->execute(@$b) || 0;
                    next;
                }
                # $bind == \@arr
                else {
                    $rows_affected += $_sth->execute(@$bind) || 0;
                    last;
                }
            }
        }
        # $bindが指定されていない
        else {
            $rows_affected = $_sth->execute();
        }

        return $rows_affected;
    }
    #
    # SELECT, SHOW, DESCRIBE
    # 今のところscalarを要素に持つarrayrefのみbindを許可
    #
    elsif ($sql =~ qr/
                         ^\s*(?:
                             SELECT|SHOW|DESCRIBE
                         )\s
                     /ix) {
        # キャッシュ
        my $cache_key = sha1_hex($sql . Dump($bind || []));

        if ($cache) {
            my $data_cached = $_cache->get($cache_key);
            #warn d 'get cache.'  if defined $data_cached;
            return $data_cached  if defined $data_cached;
        }


        defined $bind
            ?  $self->execute(@$bind)
            :  $self->execute()
        ;
        my $fetch = $ref_type eq 'hash'
            ?  ($_sth->fetchall_hashref($key) || {})
            :  ($_sth->fetchall_arrayref() || [])
        ;
        $fetch = de $fetch;

        # データをキャッシュする
        if ($cache) {
            $_cache->set($cache_key, $fetch, $CACHE_EXPIRES);
            #warn d 'set cache.';
        }

        return $fetch;
    }
    #
    # CREATE TABLE, DROP TABLE, CREATE DATABASE
    #
    elsif ($sql =~ qr/
                         ^\s*(?:
                             CREATE\s+TABLE|DROP\s+TABLE|
                             CREATE\s+DATABASE
                         )\s
                     /ix) {
        return $_sth->execute();
    }
}



# load_sql( name => $name, key => $key );
# load_sql( name => $name, key => $key, limit => [ $start, $offset ] );
# load_sql( name => $name, key => $key, limit => $offset );
sub load_sql {
    my ($self, $param) = self_param @_;
    my $name  = $param->{name};
    my $key   = $param->{key};
    my $limit = $param->{limit};

    unless (exists $_sql_cache->{$name}) {
        my $data = {};
        my $yamlfile = sprintf(
            '%s/sql/%s.yml',
            $_conf->{PATH}{DATA},
            name2path($name),
        );

        try {
            $data = LoadFile($yamlfile);
            $_sql_cache->{$name} = $data;
        }
        catch Error with {
            warn shift->text;
            #warn sprintf '[%s] YAML file does not exist: %s.', __PACKAGE__, $yamlfile;
            return undef;
        }
    }
    my $sql;
    ($sql = $_sql_cache->{$name}->{$key}  ||  '')
        =~ s/%(?:PRE)?%/$_pre/g;
    # ^ %PRE% または %% を $_pre の値に置き換える

    my $LIMIT = '';
    # limit => [ $start, $offset ],
    if (
        defined $limit  &&
        ref $limit eq 'ARRAY'  &&
        scalar @$limit >= 2
    ) {
        $LIMIT = sprintf 'LIMIT %d, %d', @$limit;
    }
    # limiit => $offset
    elsif (
        defined $limit  &&
        ref $limit eq ''
    ) {
        $LIMIT = sprintf 'LIMIT %s', $limit;
    }
    else {
    }
    $sql =~ s{%LIMIT%}{$LIMIT};
    $sql;
}



1;
__END__
