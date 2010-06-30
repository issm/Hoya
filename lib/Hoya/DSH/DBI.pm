package Hoya::DSH::DBI;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use DBI;
use YAML::Syck;
use Digest::SHA1 qw/sha1_hex/;
use Carp;
use Try::Tiny;

use Hoya::Util;

our $CACHE_EXPIRES = 10;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/name env conf cache
                            _sql_cache
                            _sth _dbh
                           /;

    return $self->_init;
}


sub _init {
    my $self = shift;

    $self->_sql_cache({});
    $self->connect;
    $self;
}


#
#  DBに接続する
#
sub connect {
    my $self = shift;
    my $conf = $self->conf;
    my $db_conf =
        $self->name ? $conf->{DSH}{$self->name} : $conf->{DB}; # 前者は新設定，後者は旧設定

    my $db_type = lc ($db_conf->{DB}{TYPE} || 'mysql');

    if($self->_dbh  &&  $self->_sth) {
        #carp sprintf '[%s] Already connected to %s', __PACKAGE__, $db_type;
        return;
    }

    # MySQL
    if($db_type eq 'mysql') {
        my $data_source = sprintf(
            'dbi:mysql:%s:%s:%s',
            $db_conf->{NAME},
            $db_conf->{HOST},
            ($db_conf->{PORT} || 3306),
        );
        $self->_dbh(
            DBI->connect(
                $data_source,
                $db_conf->{USER},
                $db_conf->{PASSWD},
                {
                    AutoCommit => 1
                },
            ) or (
                carp(
                    sprintf(
                        '[%s] Could not connect to database: %s',
                        __PACKAGE__, DBI->errstr,
                    )
                ) && return
            )
        );
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
    $self->_sth->finish;
    $self->_dbh->disconnect;
}

#  ステートメントハンドルを準備する
sub prepare {
    my $self = shift;
    $self->_sth(
        $self->_dbh->prepare(shift || '')
    );
    return $self->_sth;
}



#
#  ステートメントを実行する
#
sub execute {
    my $self = shift;
    $self->_sth->execute(defined @_ ? @_ : undef);
}




# q($sql, \@bind, []);
# q($sql, \@bind, {}, $key);
sub q { shift->query(@_); }
sub query {
    my $self = shift;
    my ($sql, $bind, $ref_type, $key) = @_;
    my $conf = $self->conf;
    my $cache = 0;
    my $db_type = $conf->{DB}{TYPE};

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

    my $sth = $self->prepare($sql);

    #
    # INSERT, REPLACE, UPDATE, DELETE, CREATE TABLE, DROP TABLE, ALTER TABLE
    #
    if ($sql =~ qr/^\s*
                   (?:
                       INSERT|REPLACE|UPDATE|DELETE|
                       CREATE\s+TABLE|DROP\s+TABLE|ALTER\s+TABLE
                   )\s
                  /ix) {
        my $rows_affected = 0;
        # $bindが指定されている
        if (defined $bind) {
            for my $b (@$bind) {
                # $bind == [\@arr1, \@arr2, ...]
                if (ref $b eq 'ARRAY') {
                    $rows_affected += $sth->execute(@$b) || 0;
                    next;
                }
                # $bind == \@arr
                else {
                    $rows_affected += $sth->execute(@$bind) || 0;
                    last;
                }
            }
        }
        # $bindが指定されていない
        else {
            $rows_affected = $sth->execute();
        }

        return $rows_affected;
    }
    #
    # SELECT, SHOW, DESCRIBE(== DESC), EXPLAIN
    # 今のところscalarを要素に持つarrayrefのみbindを許可
    #
    elsif ($sql =~ qr/^\s*
                      (?:
                          SELECT|SHOW|DESCRIBE|DESC|EXPLAIN
                      )\s
                     /ix) {
        # キャッシュ
        my $cache_key = sha1_hex($sql . Dump($bind || []));

        if ($cache) {
            my $data_cached = $self->cache->get($cache_key);
            #carp d 'get cache.'  if defined $data_cached;
            return $data_cached  if defined $data_cached;
        }



        defined $bind
            ?  $self->execute(@$bind)
            :  $self->execute()
        ;
        use Hash::MultiValue;
        my $fetch = $ref_type eq 'hash'
            ? sub {
                my $_key = shift;
                try {
                    # see: http://blog.iwa-ya.net/2010/02/18/192601
                    my $ret = $sth->fetchall_hmv($_key);
                    die  unless is_def $ret;
                    return $ret;
                }
                catch {
                    carp 'DBI::st::fetchall_hmv is not defined, call DBI::st::fetchall_hashref, instead';
                    return ($sth->fetchall_hashref($_key) || {});
                };
            }->($key)
            :  ($sth->fetchall_arrayref() || [])
        ;
        $fetch = de $fetch;

        # データをキャッシュする
        if ($cache) {
            $self->cache->set($cache_key, $fetch, $CACHE_EXPIRES);
            #carp d 'set cache.';
        }

        return $fetch;
    }
    #
    # CREATE TABLE, DROP TABLE, CREATE DATABASE
    #
    elsif ($sql =~ qr/^\s*
                      (?:
                          CREATE\s+TABLE|DROP\s+TABLE|
                          CREATE\s+DATABASE
                      )\s
                     /ix) {
        return $sth->execute();
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

    my $conf = $self->conf;

    unless (exists $self->_sql_cache->{$name}) {
        my $data = {};
        my $yamlfile = sprintf(
            '%s/sql/%s.yml',
            $conf->{PATH}{DATA},
            name2path($name),
        );

        try {
            $data = LoadFile($yamlfile);
            $self->_sql_cache->{$name} = $data;
        }
        catch {
            carp shift;
            #carp sprintf '[%s] YAML file does not exist: %s.', __PACKAGE__, $yamlfile;
            return undef;
        };
    }
    my $sql = $self->_sql_cache->{$name}{$key};
    unless (defined $sql) {
        croak "SQL with specified key does not exist: ${name}::${key}";
        $sql = 'SELECT 1';
    }

    my $table_prefix = $self->conf->{DB}{TABLE_PREFIX}  ||  '';
    $sql =~ s/%(?:PRE)?%/$table_prefix/g;
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
    $sql =~ s/%(?:LIMIT|L|LIM)%/$LIMIT/;
    $sql;
}



1;
__END__

=head1 NAME

Hoya::DSH::DBI - Data source handler wrapping DBI.

=head1 SYNOPSIS

  use Hoya::DSH::DBI;

=head1 DESCRIPTION

Hoya::DSH::DBI is

=head1 METHODS

=over 4

=item init

initialize.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
