package Hoya::Plack::Middleware::ConfigPlus;
use strict;
use warnings;
use utf8;
use parent qw/Plack::Middleware/;

use Plack::Util::Accessor qw/conf/;

use Plack::Request;
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
    my $req = Plack::Request->new($env);
    my $conf = $self->conf;
    my $site_name = $env->{HOYA_SITE} || 'default';

    $env->{SITE_NAME}     = $site_name;
    $conf->{SITE_NAME}    = $site_name;
    $conf->{PATH}{SITE}   = "$conf->{PATH}{ROOT}/${site_name}";
    $conf->{PATH}{UPLOAD} = "$conf->{PATH}{UPLOAD}/${site_name}";

    if (defined $req) {
        my ($LOCATION, $URL_BASE);

        # LOCATION
        ($LOCATION->{PROTOCOL} = lc $req->protocol) =~ s{/.*$}{};
        $LOCATION->{URL}       = '' . $req->uri;  # as string

        # URL_BASE
        $URL_BASE = $req->base . '/';  # as string
        $URL_BASE =~ s{/+$}{/};

        #($conf->{COOKIE}{DOMAIN} = $LOCATION->{HOST}) =~ s/:\d+//;

        $conf->{LOCATION} = $LOCATION;
        $conf->{URL_BASE} = $URL_BASE;
    }

    return;
}


1;
__END__
