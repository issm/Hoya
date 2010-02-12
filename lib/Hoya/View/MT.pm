package Hoya::View::MT;
use strict;
use warnings;
use utf8;

use base qw/Class::Accessor::Faster/;

use Text::MicroTemplate::Extended;
use Encode;
use HTML::Entities;
use Error qw/:try/;

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


__PACKAGE__->mk_accessors(
    qw/name type env conf
       q qq var action_name
       content error
       no_escape

       status content_type
      /
);


sub init {
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
        $_conf->{PATH}{SKIN},
        $_conf->{SKIN_NAME},
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

    my $mt =
        Text::MicroTemplate::Extended->new(
            include_path  => $_path,
            template_args => {
                env  => $_env,
                conf => $_conf,
                q    => $_q,
                qq   => $_qq,
                var  => $_var,

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
        catch Error with {
            $self->error(1);
            $content = shift->text;
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
        try {
            $content = $mt->render('_error')->as_string;
        }
        catch Error with {
            $self->error(1);
            $content = shift->text;
            $content = << "...";
<pre>
** error **
$content
template: $_name
skin:     $_conf->{SKIN_NAME}
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

init;


go;
