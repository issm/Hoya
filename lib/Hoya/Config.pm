package Hoya::Config;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use YAML::Syck;
use File::Basename;
use File::Spec;
use Try::Tiny;
use Carp;

use Hoya::Util;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/req conf/;

    return $self->_init;
}

sub _init {
    my $self = shift;
    my $req  = $self->req;
    my $env  = $req ? $req->env : \%ENV;
    my $conf = {};

    # PATH
    # 環境変数"HOYA_SCRIPT_PATH"にpsgiスクリプトのパスが入っている必要がある
    my $PATH = {};
    my $script_dir = dirname(
        File::Spec->rel2abs($env->{HOYA_SCRIPT_PATH})
    );
    (my $ROOT = $script_dir) =~ s{/www$}{};
    $ROOT = $env->{PROJECT_ROOT}  if exists $env->{PROJECT_ROOT};

    $PATH->{ROOT}      = $ROOT;
    $PATH->{CONF}      = "$ROOT/conf";
    $PATH->{PL}        = "$ROOT/pl";
    $PATH->{DATA}      = "$ROOT/data";
    $PATH->{SITE}      = "$ROOT/site/$env->{HOYA_SITE}";
    $PATH->{SKIN}      = "$ROOT/site/$env->{HOYA_SITE}/$env->{HOYA_SKIN}";
    $PATH->{UPLOAD}    = "$ROOT/upload/$env->{HOYA_SITE}";
    $PATH->{BIN}       = "$ROOT/bin";
    $PATH->{TMP}       = "$ROOT/tmp";
    $PATH->{LOG}       = "$ROOT/log";

    $PATH->{ACTION}    = "$PATH->{PL}/action";
    $PATH->{MODEL}     = "$PATH->{PL}/model";
    $PATH->{FILECACHE} = "$PATH->{TMP}/FileCache";

    # グローバル
    # base.yml, additional.yml, _local.yml
    {
        for my $f (qw/base additional/) {
            my $file = "$PATH->{CONF}/$f.yml";
            $self->_add_from_yaml($file);
        }
        if ($self->conf->{LOCAL}) {
            my $file = "$PATH->{CONF}/_local.yml";
            $self->_add_from_yaml($file);
        }

        $conf = $self->conf;
    }
    # サイト特化
    # <site>/conf.yml が存在する場合，
    # これを読み込んで，グローバル設定に上書きする
    {
        for my $f (qw/conf/) {
            my $file = "$PATH->{SITE}/$f.yml";
            $self->_add_from_yaml($file);
        }
    }
    # スキン特化
    # <site>/<skin>/conf.yml が存在する場合，
    # これを読み込んで，グローバル設定に上書きする
    {
        for my $f (qw/conf/) {
            my $file = "$PATH->{SKIN}/$f.yml";
            $self->_add_from_yaml($file);
        }
    }


    my $LOCATION = {};
    my $URL_BASE = '';

    if (defined $self->req) {
        # LOCATION
        (my $_PROTOCOL = lc $req->protocol) =~ s{/.*$}{};
        $LOCATION->{PROTOCOL} = $conf->{LOCATION}{PROTOCOL} || $_PROTOCOL;
        $LOCATION->{URL}      = '' . $req->uri;  # as string
        $LOCATION->{HOST}     = $req->env->{HTTP_HOST};

        # URL_BASE
        $URL_BASE = $req->base . '/';  # as string
        $URL_BASE =~ s{/+$}{/};

        ($conf->{COOKIE}{DOMAIN} = $LOCATION->{HOST}) =~ s/:\d+//;
    }

    # CACHE
    my $CACHE = {};
    {
        my $project_name = $self->conf->{PROJECT_NAME} || 'hoya';
        my $a = substr($project_name, 0, 1);
        my $z = substr($project_name, -1);
        $CACHE->{NAMESPACE} = sprintf(
            '%s%s',
            random_key(1, $self->conf->{PROJECT_NAME}),
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
    return $self->conf(
        merge_hash($self->conf, de $added)
    );
}

# _add_from_yaml($file)
sub _add_from_yaml {
    my ($self, $file) = @_;
    my $added = {};
    return $self->conf  unless -f $file; # not exists
    return $self->conf  unless ((stat $file)[7]); # zero-sized
    try {
        $added = de LoadFile($file);
        if (ref $added eq 'HASH') {
            $self->conf(
                merge_hash($self->conf, $added),
            );
        }
    }
    catch {
        die shift;
    };
    return $self->conf;
}


# get();
sub get {
    my $self = shift;
    return $self->conf;
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
