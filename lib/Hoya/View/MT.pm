package Hoya::View::MT;
use strict;
use warnings;
use utf8;

use base qw/Class::Accessor::Faster/;

use Text::MicroTemplate::Extended;
use Text::MicroTemplate;
use Encode;
use HTML::Entities;
use URI::Escape;
use Carp;
use Try::Tiny;

use Hoya::Page;

use Hoya::Util;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;


    {
        no strict 'refs';

        # T::MT::encoded_string を名前空間指定なしで利用できるようにする
        *{"${class}::encoded_string"} = \&Text::MicroTemplate::encoded_string;
    }


    $class->mk_accessors(
        qw/name type env conf
           q qq var action_name
           content error
           no_escape

           status content_type

           _path _path_alt
          /
    );

    return $self->_init;
}


sub _init {
    my ($self) = @_;


    $self->_path(
        sprintf(
            '%s/%s/mt',
            $self->conf->{PATH}{SITE},
            $self->env->{HOYA_SKIN},
        )
    );

    $self->_path_alt(
        sprintf(
            '%s/site/default/%s/mt',
            $self->conf->{PATH}{ROOT},
            $self->env->{HOYA_SKIN},
        )
    );

    $self->content('');
    $self->error(0);

    $self;
}



sub go {
    my ($self) = @_;

    my $name = $self->name;
    my $env  = $self->env;
    my $conf = $self->conf;
    my $var  = $self->var;
    my $name2path = name2path($name);

    # テンプレートスケルトンのパス
    # 最終代替テンプレートとして使用する
    my $path_skel = "$env->{HOYA_ROOT}/skel/skin/mt";

    my $viewfile = sprintf(
        '%s/%s.mt',
        $self->_path,
        $name2path,
    );

    my $content = '';

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

    my $mt =
        Text::MicroTemplate::Extended->new(
            include_path  => [
                $self->_path,      # 指定
                $self->_path_alt,  # 代替
                $path_skel,        # 最終代替
            ],
            template_args => {
                env  => $env,
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

            },
            use_cache => 1,
        );
    #
    #if (-f $viewfile) {
    if (1) {
        try {
            $content = $mt->render(
                name2path($self->name)
            )->as_string;
        }
        catch {
            $self->error(1);
            $content = shift;
            $content = << "...";
<pre>
** error **
$content
</pre>
...
        };
    }
    #
    else {
        my $text = sprintf(
            '[error] View "%s" not found.',
            $self->name,
        );
        croak $text;

        try {
            $content = $mt->render('_error')->as_string;
        }
        catch {
            $self->error(1);
            $content = shift;
            $content = << "...";
<pre>
** error **
$content
template: ${name}.mt
skin:     $env->{HOYA_SKIN}
</pre>
...
        };
    }

    if ($self->no_escape) {
        $content = decode_entities $content;
    }

    $self->content(en $content);
}



1;
__END__

=head1 NAME

Hoya::View::MT - View class using Text::MicroTemplate::Extended.

=head1 SYNOPSIS

  use Hoya::View::MT;

=head1 DESCRIPTION

Hoya::View::MT is

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
