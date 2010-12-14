package Hoya::DSH::DBIx::Skinny;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use UNIVERSAL::require;
use Carp;
use Try::Tiny;
use Hoya::Util;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;
    $class->mk_accessors qw/name env conf cache
                            skinny
                           /;
    return $self->_init;
}

sub _init {
    my $self = shift;
    return $self->_setup;
    #return $self;
}


sub _setup {
    my $self = shift;
    my $db_conf = $self->conf->{DSH}{$self->name};

    my $skinny;
    try {
        my $module_name;
        if (
            ($module_name) = $db_conf->{MODULE} =~ /^\+(.*)$/
        ) {
            1;
        }
        else {
            $module_name = sprintf(
                '%s_DB_%s',
                $self->conf->{PROJECT_NAME},
                $db_conf->{MODULE},
            );
            $module_name = name2class $module_name;
        }

        $module_name->use;
        my $attr = ${module_name}->_attributes;

        # クラス定義時に接続情報が設定されている場合，それを利用する
        if (defined $attr->{dsn}) {
            $skinny = ${module_name}->new;
        }
        # そうでない場合，$db_conf から該当する設定を渡して接続する
        else {
            $skinny = ${module_name}->new(+{
                dsn      => "dbi:$db_conf->{TYPE}:$db_conf->{NAME}",
                username => $db_conf->{USER},
                password => $db_conf->{PASSWD},
            });
        }

        croak 'failed to initialize DSH::DBIx::Skinny handler for unknown reasons...'
            unless defined $skinny;
    }
    catch {
        my $msg = shift;

        if ($ENV{HOYA_PROJECT_TEST}) {
            warn $msg;
        }

        my $text = << "...";
**** Error in Hoya::DSH::DBIx::Skinny ****

$msg
...
        croak $text;
    };


    $self->skinny($skinny);
    return $self;
}


# $dsh->disconnect();
sub disconnect {
    my $self = shift;
    $self->skinny->disconnect;
}


# table('table');          # ${PREFIX}table
# table('-table');         # table
# table('table', 'tbl');   # ${PREFIX}table tbl
# table('-table', 'tbl');  # table tbl
sub table {
    my ($self, $table, $alias) = @_;
    my $db_conf = $self->conf->{DSH}{$self->name} || {};

    my $no_prefix = ($table =~ s/^-//) || 0;

    my $sql = $table;
    $sql = "$table $alias"
        if defined $alias;
    unless ($no_prefix) {
        $sql = "$db_conf->{TABLE_PREFIX}$sql"
            if defined $db_conf->{TABLE_PREFIX};
    }

    return $sql;
}

# column('col');                           # col
# column('col', 'table');                  # ${PREIFX}table.col
# column('col', 'table', '-');             # ${PREIFX}table.col
# column('col', 'table', 'colx');          # ${PREFIX}table.col colx
# column('col', '-tbl');                   # tbl.col
# column('col', '-tbl', 'colx');           # tbl.col colx
# column('col', '-tbl', 'c', sub {...});   # 
sub column {
    my ($self, $col, $table, $alias, $sub) = @_;
    my $db_conf = $self->conf->{DSH}{$self->name};
    my $col_name = $col;

    if (defined $table) {
        if (my ($table_alias) = $table =~ /^-(.*)$/) {
            $col_name = "${table_alias}.${col}"
                if $table_alias ne '';
        }
        else {
            $col_name = "${table}.${col}";
            $col_name = "$db_conf->{TABLE_PREFIX}${col_name}"
                if defined $db_conf->{TABLE_PREFIX};
        }
    }

    if (defined $sub  &&  ref $sub eq 'CODE') {
        $col_name = $sub->($self, $col_name)
    }

    return (defined $alias  &&  $alias ne '-')
        ? "$col_name $alias" : $col_name;
}

# join_cond('=' => [$col_L, $col_R], ...);
sub join_cond {
    my ($self, @param) = @_;
    my ($cond, @cond);
    while (@param) {
        my ($op, $l, $r) = (shift(@param), @{shift @param});
        push @cond, join(' ', $l, $op, $r);
    }
    $cond = join ' AND ', map "($_)", @cond;
    return $cond;
}



#
# wrappers of DBIx::Skinny
#

# $h->insert($name, \%columns);
sub insert {
    my ($self, $name, $columns) = @_;
    return $self->skinny->insert(
        $self->table($name),
        $columns,
    );
}
# create -> insert
sub create { return shift->insert(@_); }

# $true = $h->bulk_insert($name, \@data);
sub bulk_insert {
    my ($self, $name, $data) = @_;
    return $self->skinny->bulk_insert(
        $self->table($name),
        $data,
    );
}

# $row_count = $h->update($name, \%data, \%cond);
sub update {
    my ($self, $name, $data, $cond) = @_;
    return $self->skinny->update(
        $self->table($name),
        $data,
        $cond,
    );
}

# $row_count = $h->update_by_sql($sql, \@bind);
sub update_by_sql { return shift->skinny->update_by_sql(@_); }

# $row_count = $h->delete($name, \%cond);
sub delete {
    my ($self, $name, $cond) = @_;
    return $self->skinny->delete(
        $self->table($name),
        $cond,
    );
}

# $row_count = $h->delete_by_sql($sql, \@bind);
sub delete_by_sql { return shift->skinny->delete_by_sql(@_); }

# $row = $h->find_or_create($name, \%columns);
sub find_or_create {
    my ($self, $name, $columns) = @_;
    return $self->skinny->find_or_create(
        $self->table($name),
        $columns,
    );
}
# find_or_insert -> find_or_create
sub find_or_insert { return shift->find_or_create(@_); }

# $count = $h->count($name, $column, \%options);
sub count {
    my ($self, $name, $column, $options) = @_;
    return $self->skinny->count(
        $self->table($name),
        $column,
        $options,
    );
}

# $itr = $h->search($name, \%columns, \%options);
sub search {
    my ($self, $name, $columns, $options) = @_;
    return $self->skinny->search(
        $self->table($name),
        $columns,
        $options,
    );
}

# $row = $h->single($name, \%columns);
sub single {
    my ($self, $name, $columns) = @_;
    return $self->skinny->single(
        $self->table($name),
        $columns,
    );
}

# $itr = $h->search_named($sql, \%bind);
sub search_named { return shift->skinny->search_named(@_); }

# $itr = $h->search_by_sql($sql, \@bind);
sub search_by_sql { return shift->skinny->search_by_sql(@_); }

# $row = $h->find_or_new($name, \%columns);
sub find_or_new {
    my ($self, $name, $columns) = @_;
    return $self->skinny->find_or_new(
        $self->table($name),
        $columns,
    );
}


# $rs = $h->resultset({select => \@columns, from => \@tables, });
# $rs = $h->resultset({select => \@columns, from => \@tables, where => \@where });
sub resultset {
    my ($self, $param) = @_;
    my $select = $param->{select} || [];
    my $from   = $param->{from} || [];

    $select = [
        map {
            $self->column(@$_);
        } @$select,
    ];
    $from = [
        map {
            $self->table(@$_);
        } @$from,
    ];

    my $rs = $self->skinny->resultset({
        select => $select,
        from   => $from,
    });

    # where
    if (defined (my $where = $param->{where})) {
        while (@$where) {
            my ($l, $r) = (shift @$where, shift @$where);
            last  unless is_def $l, $r;

            # l
            if (ref $l eq 'ARRAY') {
                $l = $self->column(@$l);
            }
            # r
            if (ref $r eq 'ARRAY') {
                $r = $self->column(@$r);
            }

            $rs->add_where($l => $r);
        }
    }

    return $rs;
}





1;
