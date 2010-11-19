use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../extlib";

use Test::More;
use Test::These;
use Hoya::Util;


test_these {
    case +{
        p01 => 1,
        p02 => 20,
        p03 => 300,
        p04 => 4000,
        p05 => 50000,
        p06 => 600000,
        p07 => 7000000,
        p08 => 80000000,
        p09 => 900000000,
        p10 => 1000000000,
    };

    code { mark_commas(shift) };

    success_each +{
        p01 => sub { is shift, '1'; },
        p02 => sub { is shift, '20'; },
        p03 => sub { is shift, '300'; },
        p04 => sub { is shift, '4,000'; },
        p05 => sub { is shift, '50,000'; },
        p06 => sub { is shift, '600,000'; },
        p07 => sub { is shift, '7,000,000'; },
        p08 => sub { is shift, '80,000,000'; },
        p09 => sub { is shift, '900,000,000'; },
        p10 => sub { is shift, '1,000,000,000'; },
    };
};


done_testing;
