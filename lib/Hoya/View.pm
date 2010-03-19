package Hoya::View;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;


use Carp;
use Try::Tiny;

use Hoya::Page;
use Hoya::Util;

# 動的ロードにすると5.8.8系でエラーが出る(?)ので，ひとまずここで読み込む
use Hoya::View::MT; 


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/name type env conf q qq var action_name content/;

    return $self->_init;
}


sub _init {
    my $self = shift;
    my $view;

    $self->_init_page;

    my $view_class = 'Hoya::View::' . $self->type;
    try {
        eval "use ${view_class};";
    }
    catch {
        eval 'use Hoya::View::MT;';
    };

    try {
        $view = "$view_class"->new({
            name => $self->name,
            env  => $self->env,
            conf => $self->conf,
            q    => $self->q,
            qq   => $self->qq,
            var  => $self->var,
            action_name => $self->action_name,
        });
    }
    catch {
        carp shift;
        $view = undef;
    };

    return $view;
}


sub _init_page {
    my ($self) = @_;

    my $page = Hoya::Page->new({
        name => $self->name,
        env  => $self->env,
        conf => $self->conf,
    });

    my $var = $self->var;

    my @css_import = $page->import_css;
    my @js_import  = $page->import_js;
    ($var->{CSS_IMPORT}, $var->{CSS_IMPORT_IE}) = @css_import;
    ($var->{JS_IMPORT}, $var->{JS_IMPORT_IE})   = @js_import;

    return 1;
}


sub go {
    my $self = shift;
    my $content = 'Hello, world!';
    $self->content(en $content);
}


1;
__END__

=head1 NAME

Hoya::View - "View" class.

=head1 SYNOPSIS

  use Hoya::View;

=head1 DESCRIPTION

Hoya::View is

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
