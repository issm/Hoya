package Hoya::View;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;


use Error qw/:try/;

use Hoya::Page;
use Hoya::Util;


my $_name;
my $_type;
my $_env;
my $_conf;
my $_q;
my $_qq;
my $_var;
my $_action_name;
my $_content; # ?

my $_page;

__PACKAGE__->mk_accessors(qw/name type env conf q qq var action_name content/);


sub init {
    my $self = shift;
    my $ret;

    $_name = $self->name;
    $_type = $self->type;
    $_env  = $self->env;
    $_conf = $self->conf;
    $_q    = $self->q;
    $_qq   = $self->qq;
    $_var  = $self->var;
    $_action_name = $self->action_name;

    $self->_init_page;

    my $class = "Hoya::View::${_type}";
    try {
        eval "use ${class};";
    }
    catch Error with {
    }
    finally {
        $ret = eval << "...";
$class->new({
    name => \$_name,
    env  => \$_env,
    conf => \$_conf,
    q    => \$_q,
    qq   => \$_qq,
    var  => \$_var,
    action_name => \$_action_name,
})->init;
...
    };

    return $ret;
}


sub _init_page {
    my ($self) = @_;

    $_page = Hoya::Page->new({
        name => $_name,
        env  => $_env,
        conf => $_conf,
    })->init;

    my @css_import = $_page->import_css;
    my @js_import  = $_page->import_js;
    ($_var->{CSS_IMPORT}, $_var->{CSS_IMPORT_IE}) = @css_import;
    ($_var->{JS_IMPORT}, $_var->{JS_IMPORT_IE})   = @js_import;

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
