use strict;
use warnings;
use utf8;
use Plack::Request;
use Plack::Builder;
use Plack::Session::State::Cookie;
use Plack::Session::Store::Cache;

use FindBin;
use Cache::FileCache;
use Log::Dispatch;
use Encode;
use Data::Recursive::Encode;
use UUID::Tiny;
use YAML;
use JSON;
use Image::Magick;
use Data::Page;
use Text::MicroTemplate::Extended;
use Carp;
use Try::Tiny;
use File::Basename;
use File::Spec;
use Class::Accessor::Faster;
use Hash::Merge;
use Hash::MultiValue;
use Params::Validate;
use URI::Escape;
use HTML::Entities;
use Date::Calc;
use MIME::Lite;

use Hoya;
use Hoya::Util;
use Hoya::Re;
use Hoya::Config;
use Hoya::Controller;
use Hoya::Mapper::URL;
use Hoya::Mapper::UserAgent;
use Hoya::Factory::Action;
use Hoya::Action;
use Hoya::MetaModel;
use Hoya::Factory::Model;
use Hoya::View;
use Hoya::Form::Validator;

#================================ site settings ====================================
my $PROJECT_ROOT    = $ENV{HOYA_PROJECT_ROOT};
unless (defined $PROJECT_ROOT) {
    ($PROJECT_ROOT = dirname(__FILE__)) =~ s{/[^/]+$}{};
    $ENV{HOYA_PROJECT_ROOT} = $PROJECT_ROOT;
}
my $SITE_NAME       = $ENV{HOYA_SITE} || 'default';
my $SESSION_KEY     = "hoya_${SITE_NAME}_session";
my $SESSION_EXPIRES = 60 * 60 * 24 * 28;  # 28 days
my $CACHE_ROOT      = "${PROJECT_ROOT}/tmp/hoya_cache";
my $LOGDIR          = "${PROJECT_ROOT}/log";
my $ENABLE_LOGGER   = $ENV{HOYA_ENABLE_LOGGER} || 0;
#===================================================================================

my $logger;
if ($ENABLE_LOGGER) {
    $logger = Log::Dispatch->new(
        outputs => [
            [
                'File',
                min_level => 'debug',
                max_level => 'notice',
                filename  => "${LOGDIR}/hoya-debug.log",
                mode      => '>>',
                newline   => 1,
            ],

            [
                'File',
                min_level => 'warning',
                filename  => "${LOGDIR}/hoya-error.log",
                mode      => '>>',
                newline   => 1,
            ],
        ],
    );
}



sub build_common {
    my $site_name = $SITE_NAME;

    enable 'Session',
        state => Plack::Session::State::Cookie->new(
            session_key => $SESSION_KEY,
            expires     => $SESSION_EXPIRES,
        ),
        store => Plack::Session::Store::Cache->new(
            cache => Cache::FileCache->new({
                cache_root         => $CACHE_ROOT,
                namespace          => $site_name,
                default_expires_in => $SESSION_EXPIRES,
                cache_depth        => 5,
            }),
        ),
    ;

    enable '+Hoya::PlackMiddleware::UserAgentMapper',
        site_name   => $site_name,
        script_name => __FILE__,
    ;
    enable '+Hoya::PlackMiddleware::Static::Upload';
    #enable '+Hoya::PlackMiddleware::Static::Upload',
    #    path => qr{(?:^/(upload/) )}x,
    #;
    #enable '+Hoya::PlackMiddleware::Static::Skin';
    enable '+Hoya::PlackMiddleware::Static::Skin',
        site => $site_name,
    ;
}



sub build_app {
    my ($urlmap_name) = @_;
    $urlmap_name = 'main'  unless $urlmap_name;


    my $a = sub {
        Hoya->run(
            Plack::Request->new(shift),
            $urlmap_name,
        );
    };;

    my $app;
    # main
    if ($urlmap_name eq 'main') {
        $app = builder {
            if ($logger) {
                enable 'LogDispatch', logger => $logger;
            }
            $a;
        };
    }
    # admin
    elsif ($urlmap_name eq 'admin') {
        $app = builder {
            if ($logger) {
                enable 'LogDispatch', logger => $logger;
            }
            #enable 'Auth::Basic',
            #    authenticator => sub {
            #        my ($username, $passwd) = @_;
            #        #Hoya->auth($username, $passwd);
            #        1;
            #    },
            #;
            $a;
        };
    }

    build_common();
    $app;
}





builder {
    mount '/admin' => build_app('admin');
    mount '/' => build_app('main');
};
