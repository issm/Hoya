package Hoya::Config;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use YAML::Syck;
use File::Basename;
use File::Spec;
use Try::Tiny;

use Hoya::Util;

__PACKAGE__->mk_accessors(qw/req/);

my $_req;
my $_env;
my $_conf;



sub init {
    my $self = shift;
    $_req  = $self->req;
    $_env  = $_req->{env} || \%ENV;
    $_conf = {};

    # PATH
    my $PATH = {};
    my $script_dir = dirname(File::Spec->rel2abs($_env->{SCRIPT_PATH_FULL}));
    (my $ROOT = $script_dir) =~ s{/www$}{};

    $PATH->{ROOT}      = $ROOT;
    $PATH->{CONF}      = "$ROOT/conf";
    $PATH->{PL}        = "$ROOT/pl";
    $PATH->{DATA}      = "$ROOT/data";
    $PATH->{SKIN}      = "$ROOT/skin";
    $PATH->{STATIC}    = "$ROOT/static";
    $PATH->{BIN}       = "$ROOT/bin";
    $PATH->{TMP}       = "$ROOT/tmp";
    $PATH->{LOG}       = "$ROOT/log";

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

    my $LOCATION = {};
    my $URL_BASE = '';

    if (defined $self->req) {
        # LOCATION
        (my $_PROTOCOL = lc $_req->protocol) =~ s{/.*$}{};
        $LOCATION->{PROTOCOL} = $_conf->{LOCATION}{PROTOCOL} || $_PROTOCOL;
        $LOCATION->{URL} = $_req->uri;

        # URL_BASE
        my $URL_BASE = $_req->base;
    }

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
        # ^ PROJECT_NAME が 'project' の場合，
        # ^ 'project'，最初の'p'，最後の't' を順に連結した文字列を，
        # ^ random_key の引数に渡している
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
    catch {
    };
    return $_conf;
}


# get();
sub get {
    my $self = shift;
    return $_conf;
}


1;
__END__

=head1 NAME

Hoya::Config - Configuration loading class.

=head1 SYNOPSIS

  use Hoya;

=head1 DESCRIPTION

Hoya::Controller is

=head1 METHODS

=over 4

=item init

initialize.

=item get

Returns hashref of "configuration".

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
