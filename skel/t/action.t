# skel/t/action.t
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../extlib";

use Test::More qw/no_plan/;
#plan tests => 2;

use Try::Tiny;
use Hoya::Util;
use Hoya::Config;
use Hoya::MetaModel;
use Hoya::Action;


ok 1;
