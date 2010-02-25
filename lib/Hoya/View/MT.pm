package Hoya::View::MT;
use strict;
use warnings;
use utf8;

use base qw/Class::Accessor::Faster/;

use Text::MicroTemplate::Extended;
use Encode;
use HTML::Entities;
use Carp;
use Try::Tiny;

use Hoya::Page;

use Hoya::Util;

my $_path;
my $_name;
my $_env;
my $_conf;
my $_q;
my $_qq;
my $_var;
my $_action_name;

my $_page;

my $_no_escape = 0;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors(
        qw/name type env conf
           q qq var action_name
           content error
           no_escape
           
           status content_type
          /
    );

    return $self->_init;
}


sub _init {
    my ($self) = @_;
    $_name  = $self->name;
    $_env   = $self->env;
    $_conf  = $self->conf;
    $_q     = $self->q;
    $_qq    = $self->qq;
    $_var   = $self->var;
    $_action_name = $self->action_name;

    $_path = sprintf(
        '%s/%s/mt',
        $_conf->{PATH}{SITE},
        $_env->{HOYA_SKIN},
    );

    $self->content('');
    $self->error(0);

    $self;
}



sub go {
    my ($self) = @_;

    my $viewfile = sprintf(
        '%s/%s.mt',
        $_path,
        name2path($_name),
    );
    my $content = '';

    # インポート用変数の準備
    my %var_import = ();
    for my $k (keys %{$_var->{__import__}}) {
        $var_import{$k} = $_var->{__import__}{$k};
        $_var->{__import__}{$k} = undef;
        delete $_var->{__import__}{$k};
    }
    $_var->{__import__} = undef;
    delete $_var->{__import__};

    my $mt =
        Text::MicroTemplate::Extended->new(
            include_path  => $_path,
            template_args => {
                env  => $_env,
                conf => $_conf,
                q    => $_q,
                qq   => $_qq,
                var  => $_var,
                %var_import,

                URL  => $_conf->{LOCATION}{URL},

                VIEW_NAME   => $_name,
                ACTION_NAME => $_action_name,

            },
            use_cache => 1,
        );
    #
    if (-f $viewfile) {
        try {
            $content = $mt->render(
                name2path($_name)
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
            $_name,
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
template: ${_name}.mt
skin:     $_env->{HOYA_SKIN}
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
