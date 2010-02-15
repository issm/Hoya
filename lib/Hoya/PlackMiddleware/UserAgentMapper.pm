package Hoya::PlackMiddleware::UserAgentMapper;
use strict;
use warnings;
use utf8;
use parent qw/Plack::Middleware/;

use Plack::Util::Accessor qw/site_name script_name/;

use Plack::Request;
use Hoya::Config;
use Hoya::Mapper::UserAgent;
use Hoya::Util;

sub call {
    my ($self, $env) = @_;

    my $res = $self->_handle($env);
    return $res  if $res;

    return $self->app->($env);
}

sub _handle {
    my ($self, $env) = @_;

    $env->{HOYA_SITE} = $self->site_name;

    (my $script_dir = $self->script_name) =~ s{/[^/]+$}{};
    my $conf_dir = "$script_dir/../conf";

    my ($ua_mapper, $ua_info);
    $ua_mapper = Hoya::Mapper::UserAgent->new({
        req  => Plack::Request->new($env),
        conf => {
            PATH => { CONF => $conf_dir },
        },
    })->init;
    $ua_info = $ua_mapper->get_info;

    $env->{HOYA_SKIN} = $ua_info->{name};

    return;
}


1;
__END__
