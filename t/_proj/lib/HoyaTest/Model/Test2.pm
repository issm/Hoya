package HoyaTest::Model::Test2;
use strict;
use warnings;
use parent qw/Hoya::Model/;
use Hoya::Util;

our $dsh_name = 'skinny';


sub return_10 {
    my ($self, $params) = @_;
    return 10;
}


1;
__END__

