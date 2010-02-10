package Hoya::Config;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use YAML::Syck;
use File::Basename;
use File::Spec;
use Error qw/:try/;

use Hoya::Util;

__PACKAGE__->mk_accessors(qw/env/);

my $_env;
my $_conf;



sub init {
    my $self = shift;
    $_env  = $self->env;
    $_conf = {};

    # PATH
    my $PATH = {};
    my $script_dir = dirname(File::Spec->rel2abs($_env->{SCRIPT_NAME}));
    (my $project_root = $script_dir) =~ s{/www$}{};

    $PATH->{ROOT}     = $project_root;
    $PATH->{CONF}     = "$PATH->{ROOT}/conf";
    $PATH->{PL}       = "$PATH->{ROOT}/pl";
    $PATH->{TEMPLATE} = "$PATH->{ROOT}/template";
    $PATH->{STATIC}   = "$PATH->{ROOT}/static";
    $PATH->{ACTION}   = "$PATH->{PL}/action";
    $PATH->{MODEL}    = "$PATH->{PL}/model";

    # base.yml, additional.yml
    for my $f (qw/base additional/) {
        my $file = "$PATH->{CONF}/$f.yml";
        $self->_add_from_yaml($file);
    }
    # _local.yml
    if ($_conf->{LOCAL}) {
        my $file = "$PATH->{CONF}/_local.yml";
        $self->_add_from_yaml($file);
    }

    # merge
    $self->_add({
        PATH => $PATH,
    });

    return $self;
}


# _add(\%added);
sub _add {
    my ($self, $added) = @_;
    $added = {}  unless defined $added;
    return 0  unless ref $added eq 'HASH';
    $_conf = merge_hash($_conf, de $added);
}

# _add_from_yaml($file)
sub _add_from_yaml {
    my ($self, $file) = @_;
    my $added = {};
    try {
        $added = de LoadFile($file);
        $_conf = merge_hash($_conf, $added)
    }
    catch Error with {
    };
    return $_conf;
}


# get();
sub get {
    my $self = shift;
    return $_conf;
}


1;
