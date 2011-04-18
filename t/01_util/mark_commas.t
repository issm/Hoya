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

        p21 => 1.1,
        p22 => 22.22,
        p23 => 333.333,
        p24 => 4444.4444,
        p25 => 55555.55555,
        p26 => 666666.666666,
        p27 => 7777777.7777777,
        # p28 => 88888888.88888888,
        # p29 => 999999999.999999999,
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

        p21 => sub { is shift, '1.1'; },
        p22 => sub { is shift, '22.22'; },
        p23 => sub { is shift, '333.333'; },
        p24 => sub { is shift, '4,444.4444'; },
        p25 => sub { is shift, '55,555.55555'; },
        p26 => sub { is shift, '666,666.666666'; },
        p27 => sub { is shift, '7,777,777.7777777'; },
        # p28 => sub { is shift, '88,888,888.88888888'; },
        # p29 => sub { is shift, '999,999,999.999999999'; },
    };
};


done_testing;
