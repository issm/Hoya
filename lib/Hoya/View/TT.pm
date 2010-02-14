package Hoya::View::TT;
use strict;
use warnings;
use utf8;

use base qw/Class::Accessor::Faster/;

use Template;
use Encode;
use HTML::Entities;

use Carp;
use Try::Tiny;

use Hoya::Page;

use Hoya::Util;



1;
__END__

=head1 NAME

Hoya::View::TT - View class using Template Toolkit.

=head1 SYNOPSIS

  use Hoya::View::TT;

=head1 DESCRIPTION

Hoya::View::TT is

=head1 METHODS

=over 4

=item init

initialize.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
