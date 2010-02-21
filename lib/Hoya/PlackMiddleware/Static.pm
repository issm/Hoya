# modification from Plack::Middleware::Static;
package Hoya::PlackMiddleware::Static;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::File;

use Plack::Util::Accessor qw/encoding/;

use Hoya::Util;
use Hoya::Re;

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle_static($env);
    return $res if $res;

    return $self->app->($env);
}

sub _handle_static {
    my($self, $env) = @_;

    my $path = do {
        local $_ = $env->{PATH_INFO};
        my $matched = $_ =~ Hoya::Re::PATH_STATIC;
        return  unless $matched;
        $_;
    } or return;

    $self->{file} ||= Plack::App::File->new({
        root     => "site/$env->{HOYA_SITE}/$env->{HOYA_SKIN}",
        encoding => $self->encoding,
    });
    local $env->{PATH_INFO} = $path; # rewrite PATH
    return $self->{file}->call($env);
}

1;
__END__

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

Tokuhiro Matsuno, Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Builder>

=cut


