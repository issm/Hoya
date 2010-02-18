# skel/t/model.t
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../extlib";

use Test::More qw/no_plan/;
#plan tests => 1;

use Try::Tiny;
use Hoya::Util;
use Hoya::Config;
use Hoya::MetaModel;

my $conf = Hoya::Config->new->init->get;
my $mm   = Hoya::MetaModel->new({conf => $conf, env => \%ENV})->init;
my $m    = $mm->get_model('<modelname>');


ok 1;

