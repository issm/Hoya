use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../../extlib";

use Test::More;
use Hoya::X::Params::Validate::Spec;


if ($ENV{HOYA_USE_X}) {
    #plan tests => 1;
    plan 'no_plan';
}
else {
    plan skip_all => 'HOYA_USE_X is not set.';
}


# toriaez
my $vspec = Hoya::X::Params::Validate::Spec->new({ hoge => 1 });
isa_ok $vspec, 'Hoya::X::Params::Validate::Spec';
