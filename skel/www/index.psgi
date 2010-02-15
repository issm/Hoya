use strict;
use warnings;
use utf8;
use FindBin;
use Plack::Request;
use Plack::Builder;
use Log::Dispatch;
use Hoya;
use Hoya::Re;

my $logger = Log::Dispatch->new(
    outputs => [
        [
            'File',
            min_level => 'debug',
            max_level => 'notice',
            filename  => '/tmp/hoya-debug.log',
            mode      => '>>',
            newline   => 1,
        ],

        [
            'File',
            min_level => 'warning',
            filename  => '/tmp/hoya-error.log',
            mode      => '>>',
            newline   => 1,
        ],
    ],
);


my ($app_admin, $app_main);

$app_main = sub {
    Hoya->run(
        Plack::Request->new(shift),
        'main',
    );
};

$app_admin = sub {
    Hoya->run(
        Plack::Request->new(shift),
        'admin',
    );
};


builder {
    enable '+Hoya::PlackMiddleware::UserAgentMapper',
        site_name   => 'default',
        script_name => __FILE__,
    ;
    enable '+Hoya::PlackMiddleware::Static';

    #enable 'Static',
    #    path => $Hoya::Re::PATH_STATIC_SKIN,
    #    root => 'site/default',
    #;

    mount '/admin' => builder {
        enable 'LogDispatch', logger => $logger;
        enable 'Auth::Basic',
            authenticator => sub {
                my ($username, $passwd) = @_;
                #Hoya->auth($username, $passwd);
                1;
            },
        ;
        $app_admin;
    };

    mount '/' => builder {
        enable 'LogDispatch', logger => $logger;
        $app_main;
    };
};
