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


my $payment_classname = 'Hoya::X::Business::Payment';


my $payment = Hoya::X::Business::Payment->new;
isa_ok $payment, $payment_classname;
is $payment->is_test, 0;


my $payment_t = Hoya::X::Business::Payment->new({
    test => 1,
});
isa_ok $payment_t, $payment_classname;
is $payment_t->is_test, 1;



# done_testing;
