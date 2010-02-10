package Hoya;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use base qw/Class::Accessor::Fast/;
use Hoya::Util;
#use base qw/Hoya::Class::Base/;
#use Hoya::Class::Base qw/:base :debug/;
use Hoya::Controller;


our $FINISH_ACTION = '__FINISH_ACTION__';


sub run {
    my ($self, $req, $app_name) = @_;

    my $script_name = (caller 0)[1];
    $req->{env}{SCRIPT_NAME} = $script_name;

    my $c = Hoya::Controller->new({
        req      => $req,
        app_name => $app_name,
    });
    $c->init;
    $c->go;
}

sub auth {
    my $self = shift;
    my ($username, $passwd) = @_;

    $username eq 'iwata';
}





#sub _run {
#  my ( $self, $param ) = self_param( @_ );
#  my $urlmap_key = $param->{urlmap_key};
#  my $request    = $param->{r}  ||  $param->{request};
#  $DEBUG = $ENV{SABAE_DEBUG}  ||  $param->{debug}  ||  0;
#
#  if( $DEBUG ) {
#    #eval q{
#    #  use CGI::Carp qw( fatalsToBrowser );
#    #};
#  }
#
#  unless( defined $request ) {
#    # mod_perl
#    if( exists $ENV{MOD_PERL} ) {
#    }
#    # CGI
#    else {
#      $request = CGI->new;
#    }
#  }
#
#  my $c = Sabae::Controller->new({
#    request    => $request,
#    urlmap_key => $urlmap_key
#  })->init;
#  $c->go;
#  $c->finish;
#  1;
#}







1;
__END__

=head1 NAME

Hoya -

=head1 SYNOPSIS

  use Hoya;

=head1 DESCRIPTION

Hoya is

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
