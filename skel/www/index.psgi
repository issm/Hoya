use strict;
use warnings;
use utf8;
use FindBin;
use Plack::Request;
use Plack::Builder;
use Hoya;

my ($app_admin, $app_main);

my $RE_STATIC_COMMON = qr{(?: ^/ | \.(?:pdf)$ )}x;
my $RE_STATIC_SKIN   = qr{(?: ^/(js|img|css) | \.(ico)$ )}x;

$app_main = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    Hoya->run($req, 'main');
};

$app_admin = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    Hoya->run($req, 'admin');
};

builder {
    enable 'Static', path => $RE_STATIC_SKIN, root => 'skin/default';

    mount '/admin' => builder {
        enable 'Auth::Basic', authenticator => sub {
            my ($username, $passwd) = @_;
            #Hoya->auth($username, $passwd);
            1;
        };
        $app_admin;
    };

    mount '/' => builder {
        $app_main;
    };
};
