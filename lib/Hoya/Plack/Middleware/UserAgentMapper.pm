package Hoya::Plack::Middleware::UserAgentMapper;
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
    my $skin_name = 'default';
    my $conf = $self->conf;

    my ($ua_mapper, $ua_info);
    $ua_mapper = Hoya::Mapper::UserAgent->new({
        req  => Plack::Request->new($env),
        conf => $conf,
        #    PATH => { CONF => $conf_dir },
        #},
    });
    $ua_info = $ua_mapper->get_info;

    if (defined $ua_info) {
        $skin_name = $ua_info->{name};
        $conf->{SKIN_NAME}  = $skin_name;
        $conf->{PATH}{SKIN} = "$conf->{PATH}{SITE}/${skin_name}";
        $env->{HOYA_SKIN}   = $skin_name;
    }

    return;
}


1;
__END__
