use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../../extlib";

use Test::More;
use Hoya::Config::Core;

#plan tests => 1;
plan 'no_plan';


my $conf;


$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/../_proj";

$conf = Hoya::Config::Core->new;
isa_ok $conf, 'Hoya::Config::Core';







ok 1;
