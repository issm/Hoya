# t/00_load.t
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../extlib";
use Test::More;
plan tests => 1;


use_ok('Hoya');
