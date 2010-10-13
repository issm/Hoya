use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../../extlib";
use Test::More;
use Test::These;
use Hoya::Config::Core;
use Hoya::Util;
use Hoya::MetaModel;
use Hoya::Action;
use Plack::Request;
use Hash::MultiValue;


BEGIN {
    use_ok 'Hoya::Action';
}


$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/../project";


my $conf = Hoya::Config::Core->new->as_hashref;
my $req  = Plack::Request->new(\%ENV);
my $q    = Hash::MultiValue->new({});
my $qq   = Hash::MultiValue->new({});
my $mm   = Hoya::MetaModel->new({ env => \%ENV, conf => $conf });




#--------------------------------------------------------------------------------
#
# ->new
#
#--------------------------------------------------------------------------------

#
# failure cases
#
test_these {
    case [
        {},
    ];

    code { Hoya::Action->new(shift); };

    success {
        fail 'should fail';
    };

    error {
        ok shift;
    };


};

#
# success cases
#
test_these {
    case [

        {
            name          => 'test',
            req           => $req,
            conf          => $conf,
            q             => $q,
            qq            => $qq,
            up            => $req->uploads,
            mm            => $mm,
            cookies       => {},
            vars          => {},
            # base_name     => $self->base_name || $self->name,
            # sub_name      => $self->sub_name,
            # backward_name => $self->backward_name,
        },
    ];

    code { Hoya::Action->new(shift); };

    success {
        my ($a, $i) = @_;

        #
        if ($i == 0) {
            isa_ok $a, 'Hoya::Action';
        }
    };

    error {
        fail 'should pass: ' . shift;
    };
};



done_testing;
