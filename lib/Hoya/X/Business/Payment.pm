package Hoya::X::Business::Payment;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use UNIVERSAL::require;
use Try::Tiny;
use LWP::UserAgent;
use Hoya::Util;


__PACKAGE__->mk_accessors(qw/
   type ua status result
   test
/);


sub new {
    my ($class, $param) = @_;
    #$class->mk_accessors(qw/type ua status result/);

    $param->{type} = ucfirst ($param->{type} || '');

    my $self;
    my $subclass = __PACKAGE__ . "::" . $param->{type};
    my $ua = LWP::UserAgent->new;
    try {
        die 'Payment type is not specified'  if $subclass =~ /::$/;

        $subclass->use;
        $self = bless $class->SUPER::new($param), $subclass;
        $ua->agent($subclass);
    }
    catch {
        local $Hoya::Util::DUMP_PREFIX = "[31m";
        #warn Dc shift;
        $self = bless $class->SUPER::new($param), $class;
        $ua->agent($class);
    };
    $self->ua($ua);

    try {
        $self = $self->_init($param);
    }
    catch {
        local $Hoya::Util::DUMP_PREFIX = "[31m";
        #warn Dc shift;
    };

    return $self;
}


sub is_test {
    my ($self) = @_;
    return $self->test ? 1 : 0;
}





1;
__END__

=head1 NAME

Hoya::X::Business::Payment - hoge.

=head1 SYNOPSIS

  use Hoya::X::Business::Payment;

=head1 DESCRIPTION

Hoya::X::Business::Payment is hoge.

=head1 CONSTRUCTOR

  $payment = Hoya::X::Business::Payment->new(\%params);

=head1 METHODS

=over 4

=item $bool = $payment->is_test

In "test" env?

=back

=cut
