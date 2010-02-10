package Hoya::View;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Encode;
use Data::Recursive::Encode;
use Hoya::Util;

__PACKAGE__->mk_accessors(qw/env conf var content/);


sub init {
    my $self = shift;

    $self;
}


sub go {
    my $self = shift;


    my $content = 'ふがふが！';


    $self->content(en $content);
}

1;
