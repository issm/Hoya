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

__PACKAGE__->mk_accessors(qw/req/);

my $_req;
my $_env;
my $_conf;



sub init {
    my $self = shift;
    $_req  = $self->req;
    $_env  = $_req->{env};
    $_conf = {};

    # PATH
    my $PATH = {};
    my $script_dir = dirname(File::Spec->rel2abs($_env->{SCRIPT_NAME}));
    (my $project_root = $script_dir) =~ s{/www$}{};

    $PATH->{ROOT}      = $project_root;
    $PATH->{CONF}      = "$PATH->{ROOT}/conf";
    $PATH->{PL}        = "$PATH->{ROOT}/pl";
    $PATH->{DATA}      = "$PATH->{ROOT}/data";
    $PATH->{SKIN}      = "$PATH->{ROOT}/skin";
    $PATH->{STATIC}    = "$PATH->{ROOT}/static";
    $PATH->{TMP}       = "$PATH->{ROOT}/tmp";
    $PATH->{ACTION}    = "$PATH->{PL}/action";
    $PATH->{MODEL}     = "$PATH->{PL}/model";
    $PATH->{FILECACHE} = "$PATH->{TMP}/FileCache";

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

    # LOCATION
    my $LOCATION = {};
    (my $_PROTOCOL = lc $_req->protocol) =~ s{/.*$}{};
    $LOCATION->{PROTOCOL} = $_conf->{LOCATION}{PROTOCOL} || $_PROTOCOL;

    # URL_BASE
    my $URL_BASE = '';
    $URL_BASE = sprintf(
        '%s://%s',
        $LOCATION->{PROTOCOL},
        $_env->{SERVER_NAME},
    );
    $URL_BASE .= ':' . $_env->{SERVER_PORT}  if $_env->{SERVER_PORT};
    $URL_BASE .= $_conf->{LOCATION}{PATH}  if $_conf->{LOCATION}{PATH};
    $URL_BASE .= '/';
    $URL_BASE =~ s{/+$}{/};

    # CACHE
    my $CACHE = {};
    {
        my $project_name = $_conf->{PROJECT_NAME};
        my $a = substr($project_name, 0, 1);
        my $z = substr($project_name, -1);
        $CACHE->{NAMESPACE} = sprintf(
            '%s%s',
            random_key(1, $_conf->{PROJECT_NAME}),
            random_key(1, "$a$z"),
        );
    }


    # merge
    $self->_add({
        PATH     => $PATH,
        LOCATION => $LOCATION,
        URL_BASE => $URL_BASE,
        CACHE    => $CACHE,
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
