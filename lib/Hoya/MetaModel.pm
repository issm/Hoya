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


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors(qw/
        env conf
        _dsh _model
    /);

    return $self->_init;
}

sub _init {
    my ($self) = self_param @_;
    $self->_dsh({});
    $self->_model({});

    $self->_init_dsh;
    $self;
}


sub _init_dsh {
    my $self = shift;
    $self->_dsh({});
    my $DSH_CONF = $self->conf->{DSH} || {};

    # 新設定
    my @dsh_names = grep {
        # クラスに「真の」値が設定されているものを抜き出す
        ref $DSH_CONF->{$_} eq 'HASH'  &&  $DSH_CONF->{$_}{CLASS};
    } keys %$DSH_CONF;
    for my $name (@dsh_names) {
        unless (exists $self->_dsh->{$name}) {
            $self->_dsh->{$name} = Hoya::DSH->new({
                name => $name,
                type => $DSH_CONF->{$name}{CLASS},
                env  => $self->env,
                conf => $self->conf,
            });
        }
    }

    # 旧設定: deprecated
    my @_dsh = grep {
        ( $self->conf->{DSH}{$_} || 0 ) == 1;  # 値が1のもののみ抜き出す
    } keys %{$self->conf->{DSH} || {}};
    for my $dsh (@_dsh) {
        unless (exists $self->_dsh->{$dsh}) {
            $self->_dsh->{$dsh} = Hoya::DSH->new({
                type => $dsh,
                env  => $self->env,
                conf => $self->conf,
            });
        }
    }
}


sub finish_dsh {
    my $self = shift;
    my $dsh = $self->_dsh;
    for my $k (keys %$dsh) {
        try {
            $dsh->{$k}->disconnect  if ref($dsh->{$k}) =~ /(?:::)?DBIx?(?:::)?/;
        }
        catch {
            carp shift;
        };
    }
}


# get_model($name);
sub get_model {
    my ($self, @names) = @_;
    return  unless @names;

    my @models;
    for my $name (@names) {
        if (exists $self->_model->{$name}) {
            push @models, $self->_model->{$name};
        }
        else {
            push @models, $self->_create_model($name);
        }
    }
    return wantarray ? @models : $models[0];
}

# get_dsh($name);
sub get_dsh {
    my ($self, $name) = @_;
    return  unless defined $name;
    return $self->_dsh->{$name};
}


# _create_model($name);
sub _create_model {
    my ($self, $name) = @_;
    return  unless defined $name;

    $self->_model->{$name} = Hoya::Factory::Model->new({
        name => $name,
        env  => $self->env,
        conf => $self->conf,
        dsh  => $self->_dsh,
    });

    return $self->_model->{$name};
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

=item get_dsh($name)

returns Hoya::DSH::$type object.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
