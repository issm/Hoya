use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../../extlib", "${FindBin::Bin}/../_proj/lib";
use Test::More;
use Test::These;
use Hoya::Config::Core;
use Hoya::Util;
use Hoya::MetaModel;
use Hoya::Action;
use Plack::Request;
use Hash::MultiValue;
use Clone qw/clone/;


BEGIN {
    use_ok 'Hoya::Action';
}


$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/../_proj";


my $conf = Hoya::Config::Core->new->as_hashref;
my $req  = Plack::Request->new(\%ENV);
my $q    = Hash::MultiValue->new(
    hoge => 1,
    fuga => 'b',
);
my $qq   = Hash::MultiValue->new(
    foo => 'x',
    bar => 2,
);
my $mm   = Hoya::MetaModel->new({ env => \%ENV, conf => $conf });


my $params_base = {
    name          => undef,
    req           => $req,
    conf          => $conf,
    q             => $q,
    qq            => $qq,
    up            => $req->uploads,
    mm            => $mm,
    cookies       => {},
    vars          => {},
    # base_name     => undef,
    # sub_name      => undef,
    # backward_name => undef,
};
my ($params, $action, $view_info);


#--------------------------------------------------------------------------------
#
# さて，どう書こうか
#
#--------------------------------------------------------------------------------
ok 1;



done_testing;
