use strict;
use warnings;
use utf8;
use FindBin;
use lib "${FindBin::Bin}/../lib", "${FindBin::Bin}/../extlib";

use Test::More tests => 1;

BEGIN {
    use_ok 'Hoya';
}
