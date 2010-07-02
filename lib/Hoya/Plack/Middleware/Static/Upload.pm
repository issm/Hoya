# modification from Plack::Middleware::Static;
package Hoya::Plack::Middleware::Static::Upload;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::File;

use Plack::Util::Accessor qw/path encoding/;

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

    my $path_re = $self->path || Hoya::Re::PATH_STATIC_UPLOAD;
    my $path = do {
        local $_ = $env->{PATH_INFO};
        my $matched = $_ =~ $path_re;
        return  unless $matched;
        $_;
    } or return;
    warn D $env;
    my $project_root = $env->{HOYA_PROJECT_ROOT} || $env->{PROJECT_ROOT};
    my $static_root  = "upload/$env->{HOYA_SITE}";
    $self->{file} = Plack::App::File->new({
        root => $project_root
            ? "${project_root}/$static_root" : $static_root,
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


