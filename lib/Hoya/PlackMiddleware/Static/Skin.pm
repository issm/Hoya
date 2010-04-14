# modification from Plack::Middleware::Static;
package Hoya::PlackMiddleware::Static::Skin;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::File;

use Plack::Util::Accessor qw/path encoding site/;

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

    my $site = $self->site || $env->{HOYA_SITE};
    my $path_re = $self->path || Hoya::Re::PATH_STATIC_SKIN;
    my $path = do {
        local $_ = $env->{PATH_INFO};
        my $matched = $_ =~ $path_re;
        return  unless $matched;
        $_;
    } or return;

    my $static_root = "site/${site}/$env->{HOYA_SKIN}";
    $static_root = "$env->{PROJECT_ROOT}/$static_root"
        if $env->{PROJECT_ROOT};
    # v $env->{HOYA_SITE}における指定のファイルが存在しない場合，
    # v site/defaultにおける同名のファイルをリクエストする
    #     → うまくいかん
    unless (my @st = stat "${static_root}/$env->{PATH_INFO}") {
        return  if $site ne 'default';
        #$static_root = "site/default/$env->{HOYA_SKIN}";
        #$static_root = "$env->{PROJECT_ROOT}/$static_root"
        #    if $env->{PROJECT_ROOT};
    }

    $self->{file} ||= Plack::App::File->new({
        root     => $static_root,
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


