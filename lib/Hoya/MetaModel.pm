package Hoya::MetaModel;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Try::Tiny;

use Hoya::DSH;
use Hoya::Factory::Model;
use Hoya::Util;

my $_env;
my $_conf;
my $_dsh   = {};
my $_model = {};


__PACKAGE__->mk_accessors(qw/env conf/);


sub init {
    my ($self) = self_param @_;
    $_env  = $self->env;
    $_conf = $self->conf;
    $self->_init_dsh;
    $self;
}


sub _init_dsh {
    my $self = shift;

    my @dsh = grep {
        $_conf->{DSH}{$_};  # 値が1のもののみ抜き出す
    } keys %{$_conf->{DSH} || {}};

    for my $dsh (@dsh) {
        unless (exists $_dsh->{$dsh}) {
            $_dsh->{$dsh} = Hoya::DSH->new({
                type => $dsh,
                env  => $_env,
                conf => $_conf,
            })->init;
        }
    }
}


# get_model($name);
sub get_model {
    my ($self, @names) = @_;
    return undef  unless @names;

    my @models;
    for my $name (@names) {
        if (exists $_model->{$name}) {
            push @models, $_model->{$name};
        }
        else {
            push @models, $self->_create_model($name);
        }
    }
    return wantarray ? @models : $models[0];
}

# get_dsh($type);
sub get_dsh {
    my ($self, $type) = @_;
    return undef  unless defined $type;
    return $_dsh->{$type};
}


# _create_model($name);
sub _create_model {
    my ($self, $name) = @_;
    return undef  unless defined $name;

    $_model->{$name} = Hoya::Factory::Model->new({
        name => $name,
        env  => $_env,
        conf => $_conf,
        dsh  => $_dsh,
    })->init;

    return $_model->{$name};
}



1;
__END__

=head1 NAME

Hoya::MetaModel - Model of "Model" classes.

=head1 SYNOPSIS

  use Hoya::MetaModel;

=head1 DESCRIPTION

Hoya::Controller is

=head1 METHODS

=over 4

=item init

initialize.

=item get_model($name)

returns Hoya::Model::* object.

=item get_dsh($type)

returns Hoya::DSH::$type object.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
