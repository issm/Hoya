package Hoya::MetaModel;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Error qw/:try/;

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
    my ($self, $name) = @_;
    return undef  unless defined $name;

    if (exists $_model->{$name}) {
        return $_model->{$name};
    }
    else {
        return $self->_create_model($name);
    }
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
}



1;
__END__
