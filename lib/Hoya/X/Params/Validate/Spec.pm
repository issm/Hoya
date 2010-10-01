package Hoya::X::Params::Validate::Spec;
use strict;
use warnings;
use base qw/Class::Accessor::Faster/;

use Params::Validate qw/:all/;
use Clone qw/clone/;
use Hoya::Re;
use Hoya::Util;

my @properties = qw/_spec/;


sub new {
    my ($class, $param) = @_;
    my $self = bless( $class->SUPER::new($param), $class );
    $class->mk_accessors(@properties);
    return $self->_init($param);
}


sub _init {
    my ($self, $all_spec) = @_;
    $self->_setup($all_spec || {});
    return $self;
}


sub _setup {
    my ($self, $all_spec) = @_;

    while (my ($k, $v) = each %$all_spec) {
        if (ref $v eq '') {
            $all_spec->{$k} = $self->_parse($v);
        }
    }

    $self->_spec($all_spec);
    return $all_spec;
}


sub _parse {
    my ($self, $v) = @_;
    return $v  if ref $v;

    my $parsed = {};

    return $parsed;
}


sub fetch {
    my ($self, @fields) = @_;
    my $additional = do {
        ref $fields[-1] eq 'HASH'  ?  (pop @fields)  :  {};
    };

    my $spec_all = $self->_spec;
    my $spec = {};

    for (@fields) {
        my ($field, $alias) = split ':';
        next  unless defined $spec_all->{$field};
        $spec->{defined $alias ? $alias : $field} = clone $spec_all->{$field};
    }

    while (my ($f, $a) = each %$additional) {
        # フィールドが $spec に存在している
        if (defined $spec->{$f}) {
            while (my ($k, $v) = each %$a) {
                if (defined $v) { $spec->{$f}{$k} = $v; }
                else            { delete $spec->{$f}{$k}; }
            }
        }
        # フィールドが $spec に存在しない場合，
        # そのフィールド自身を $spec に追加する
        else {
            while (my ($k, $v) = each %$a) {
                # 値が undef な項目を削除する
                delete $a->{$k}  unless defined $v;
            }
            $spec->{$f} = $a;
        }

    }

    return $spec;
}




1;
__END__

=head1 NAME

Hoya::X::Params::Validate::Spec - Manages "spec" hashref parameter of Params::Validate.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item $vspec = Hoya::X::Params::Validate::Spec->new(\%all_spec);

=item $vspec->_setup(\%all_spec);

=item \%parsed = $vspec->_parse($a_spec);

not implemented.

=item \%spec = $vspec->fetch(@fields, [\%additional]);

fetches "spec" hashref which constructs of specified fields from all spec definition.

    $spec = $vspec->fetch('foo', 'bar', 'baz');

    $spec = $vspec->fetch('hoge:foo', 'hoge:bar', 'hoge:baz');

    $spec = $vspec->fetch('foo', 'bar', 'hoge:baz', {
        foo => { optional => 1 },
        baz => { type => ARRAYREF, optional => undef },
    });


=back
