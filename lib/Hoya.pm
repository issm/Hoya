package Hoya;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use base qw/Class::Accessor::Faster/;
use Hoya::Controller;
use Hoya::Util;


our $FINISH_ACTION = '__FINISH_ACTION__';

# 変数インポートに使用できない名前
our @NAMES_IMPORT_FORBIDDEN =
    qw/env conf q qq var
       URL
       VIEW_NAME ACTION_NAME
      /;


sub run {
    my ($self, $req, $app_name) = @_;

    my $script_name = (caller 0)[1];
    $req->env->{HOYA_SCRIPT_PATH} = $script_name;

    my $c = Hoya::Controller->new({
        req      => $req,
        app_name => $app_name,
    });

    return $c->go;
}

sub auth {
    my $self = shift;
    my ($username, $passwd) = @_;

    $username eq 'iwata';
}





1;
__END__

=head1 NAME

Hoya - A simple web application framework.

=head1 SYNOPSIS

  use Hoya;

=head1 DESCRIPTION

Hoya is

=head1 METHODS

=over 4

=item Hoya->run($req, $app_name)

hogehoge

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
