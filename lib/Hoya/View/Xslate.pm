package Hoya::View::Xslate;
use strict;
use warnings;
use utf8;

use Text::Xslate;
use Encode;
use HTML::Entities;
use URI::Escape;
use Carp;
use Try::Tiny;
use Hoya::Util;

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/
        name type env conf
        q qq var action_name
        content error
        no_escape

        status content_type

        _path _path_alt
    /],
);




sub new {
    my ($class, $params) = @_;
    my $self = bless +{}, $class;

    $self->name( $params->{name} );
    $self->type( $params->{type} );
    $self->env( $params->{env} );
    $self->conf( $params->{conf} );
    $self->q( $params->{q} );
    $self->qq( $params->{qq} );
    $self->var( $params->{var} );
    $self->action_name( $params->{action_name} );

    return $self->_init($params);
}




sub _init {
    my ($self, $params) = @_;

    $self->_path(
        sprintf(
            '%s/%s/tx',
            $self->conf->{PATH}{SITE},
            $self->env->{HOYA_SKIN},
        )
    );

    $self->_path_alt(
        sprintf(
            '%s/site/default/%s/tx',
            $self->conf->{PATH}{ROOT},
            $self->env->{HOYA_SKIN},
        )
    );

    $self->content('');
    $self->error(0);

    return $self;
}




sub go {
    my ($self, $params) = @_;
    my $content = '';

    my $name = $self->name;
    my $env  = $self->env;
    my $conf = $self->conf;
    my $var  = $self->var;
    my $name2path = name2path($name);

    # テンプレートスケルトンのパス
    # 最終代替テンプレートとして使用する
    my $path_skel = "$env->{HOYA_ROOT}/skel/skin/tx";

    my $viewfile = sprintf(
        '%s/%s.tx',
        $self->_path,
        $name2path,
    );

    my $tx = Text::Xslate->new(
        path => [
            $self->_path,      # 指定
            $self->_path_alt,  # 代替
            $path_skel,        # 最終代替
        ],
        suffix    => '.tx',
        cache_dir => "$conf->{PATH}{TMP}/xslate_cache",
        verbose   => 2,
    );

    # インポート用変数の準備
    my %var_import = ();
    for my $k (keys %{$var->{__import__}}) {
        $var_import{$k} = $var->{__import__}{$k};
        $var->{__import__}{$k} = undef;
        delete $var->{__import__}{$k};
    }
    $var->{__import__} = undef;
    delete $var->{__import__};

    my ($_url, $_url_noparam) = ($conf->{LOCATION}{URL});
    ($_url_noparam = $_url) =~ s/\?.*$//;

    my $vars = +{
        env => $env,
        conf => $conf,
        q    => $self->q,
        qq   => $self->qq,
        var  => $var,
        %var_import,

        URL                   => $_url,
        URL_NOPARAM           => $_url_noparam,
        URL_UNESCAPED         => de(uri_unescape($_url)),
        URL_NOPARAM_UNESCAPED => de(uri_unescape($_url_noparam)),

        VIEW_NAME   => $name,
        ACTION_NAME => $self->action_name,
    };

    try {
        $content = $tx->render(
            name2path( $self->name . '.tx' ),
            $vars,
        );
    } catch {
        $self->error(1);
        $content = shift;
        $content = << "        ...";
<pre>
** error **
$content
</pre>
        ...
    };

    return $self->content( en $content );
}




1;
__END__

=head1 NAME

Hoya::View::Xslate - View class using Text::Xslate.

=head1 SYNOPSIS

  use Hoya::View::Xslate;

=head1 DESCRIPTION

Hoya::View::Xslate is

=head1 METHODS

=over 4

=item init

initialize.

=item go

go.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
