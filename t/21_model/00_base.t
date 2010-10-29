use strict;
use warnings;
use Test::More;
use FindBin;
use lib "${FindBin::Bin}/../_proj/lib";
use Hoya::Config::Core;
use Hoya::MetaModel;
use Hoya::Util;

$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/../_proj";


my $conf = Hoya::Config::Core->new->as_hashref;
my $mm = Hoya::MetaModel->new({
    conf => $conf,
    env  => \%ENV,
});


#--------------------------------------------------------------------------------
#
# 従来方式
#
#--------------------------------------------------------------------------------
my $m1 = $mm->get_model('test1');

isa_ok $m1, 'Hoya::Model::test1';
#is $m1->_dsh_type, 'skinny';
isa_ok $m1->h, 'Hoya::DSH::DBIx::Skinny';
is $m1->return_10, 10;



#--------------------------------------------------------------------------------
#
# 0.0003 で採用の方式
#
#--------------------------------------------------------------------------------
my $m2 = $mm->get_model('test2');  # 0.0003 からの方式

isa_ok $m2, sprintf( '%s::Model::Test2', name2class($conf->{PROJECT_NAME}) );
is $m2->_dsh_name, 'skinny';
isa_ok $m2->h, 'Hoya::DSH::DBIx::Skinny';
is $m2->return_10, 10;




done_testing;
