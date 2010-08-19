use strict;
use warnings;
use utf8;
use lib "$ENV{HOYA_ROOT}/lib", "$ENV{HOYA_ROOT}/extlib", "$ENV{HOYA_PROJECT_ROOT}/lib";

use Try::Tiny;
use Hoya::Config::Core;
use Hoya::MetaModel;
use Hoya::Util;

BEGIN {
    printlog '-------- Sciprt started. -------- ';
}

END {
    printlog '-------- Sciprt finished. -------- ';
    printlog '';
}

my $conf = Hoya::Config::Core->new({entry => __FILE__})->as_hashref;
my $mm   = Hoya::MetaModel->new({env => \%ENV, conf => $conf});

#my $h = $mm->_dsh->{dsh_name};

__END__
