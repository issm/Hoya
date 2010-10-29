use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../../extlib", "${FindBin::Bin}/../_proj/lib";
use Test::More;
use Test::These;
use Hoya::Config::Core;
use Hoya::Util;
use Hoya::MetaModel;
use Hoya::Factory::Action;
use Plack::Request;
use Hash::MultiValue;
use Clone qw/clone/;


BEGIN {
    use_ok 'Hoya::Action';
}


$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/../_proj";


my $conf = Hoya::Config::Core->new->as_hashref;
my $req  = Plack::Request->new(\%ENV);
my $q    = Hash::MultiValue->new(
    hoge => 1,
    fuga => 'b',
);
my $qq   = Hash::MultiValue->new(
    foo => 'x',
    bar => 2,
);
my $mm   = Hoya::MetaModel->new({ env => \%ENV, conf => $conf });


my $params_base = {
    name          => undef,
    req           => $req,
    conf          => $conf,
    q             => $q,
    qq            => $qq,
    up            => $req->uploads,
    mm            => $mm,
    cookies       => {},
    vars    => {
        __import__ => {},
    },
};
my ($params, $action, $view_info);




test_these {
    case [
        { name => 'action_not_exists' },
        { name => 'test_sample1' },
        { name => 'test_sample2' },
    ];


    code {
        my $case = shift;
        my $params = clone($params_base);
        $params->{$_} = $case->{$_}  for keys %$case;
        my $action = Hoya::Factory::Action->new($params);
        $action->go;
    };


    success {
        my ($v, $i) = @_;

        # 0
        if ($i == 0) {
            isnt $v->{name}, 'action_not_exists';
            isnt $v->{status}, 200;
            is $v->{name}, 'error_action-not-found';
            is $v->{status}, 500;
        }

        # 1
        elsif ($i == 1) {
            is $v->{name}, 'test_sample1';
            is $v->{status}, 200;
        }

        # 2
        elsif ($i == 2) {
            is $v->{name}, 'other_view';
            is $v->{status}, 200;
        }
    };


    error {
        fail 'should pass: ' . shift;
    };
};




done_testing;
