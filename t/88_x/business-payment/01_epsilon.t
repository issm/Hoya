use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../../lib", "$FindBin::Bin/../../../extlib";
use Test::More;
use Hoya::X::Business::Payment;
use Hoya::Util;

if ($ENV{HOYA_USE_X}) {
    #plan tests => 1;
    plan 'no_plan';
}
else {
    plan skip_all => 'HOYA_USE_X is not set.';
}


my $contract_code = $ENV{HOYA_X_EPSILON_CONTRACT_CODE} || '00000000';
my $passwd        = $ENV{HOYA_X_EPSILON_PASSWD}        || 'passwd';

my $epsilon_classname = 'Hoya::X::Business::Payment::Epsilon';

my $epsilon_t = Hoya::X::Business::Payment->new({
    test          => 1,
    type          => 'epsilon',
    contract_code => $contract_code,
    passwd        => $passwd,
});

isa_ok $epsilon_t, $epsilon_classname;
is $epsilon_t->is_test, 1;




my $epsilon = Hoya::X::Business::Payment->new({
    type          => 'epsilon',
    contract_code => $contract_code,
    passwd        => $passwd,
});

isa_ok $epsilon, $epsilon_classname;
is $epsilon->is_test, 0;



# type: 'E'psilon
undef $epsilon;
$epsilon = Hoya::X::Business::Payment->new({
    type          => 'Epsilon',
    contract_code => $contract_code,
    passwd        => $passwd,
});
isa_ok $epsilon, $epsilon_classname;



#done_testing;
