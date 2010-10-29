package Hoya;
use strict;
use warnings;
use utf8;
use 5.008_001;
our $VERSION = '0.0003_02';

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
    my ($self, $req, $conf, $app_name) = @_;
#================================ per-request settings ====================================
    my $SITE_NAME       = $ENV{HOYA_SITE} || 'default';
    my $SESSION_KEY     = "hoya_${SITE_NAME}_session";
    my $SESSION_EXPIRES = 60 * 60 * 24 * 28;  # 28 days
#===================================================================================

    # 環境変数 HOYA_ROOT
    ($req->env->{HOYA_ROOT} = __FILE__) =~ s{/lib/Hoya\.pm$}{};

    # 環境変数 HOYA_PROJECT_ROOT
    $req->env->{HOYA_PROJECT_ROOT} =
        $ENV{HOYA_PROJECT_ROOT} || $ENV{PROJECT_ROOT};

    # 環境変数 HOYA_SITE
    $req->env->{HOYA_SITE} = $ENV{HOYA_SITE};

    my $c = Hoya::Controller->new({
        req      => $req,
        conf     => $conf,
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
