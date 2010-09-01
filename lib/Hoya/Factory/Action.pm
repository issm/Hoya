package Hoya::Factory::Action;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Try::Tiny;
use Hoya::Util;
use Hoya::Action;

my @METHODS = qw/BEFORE GET POST AFTER/;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/name req conf q qq up mm view_name
                            cookies vars
                            sub_name base_name
                           /;

    return $self->_init;
}


sub _init {
    my $self = shift;

    my $action_class = 'Hoya::Action::' . name2class($self->name);
    my $action;

    try {
        my $pl   = $self->_load;
        my $code = $self->_generate_as_string($pl);
        eval $code;
        die $@  if $@;

        $action = "$action_class"->new({
            name      => $self->name,
            req       => $self->req,
            conf      => $self->conf,
            q         => $self->q,
            qq        => $self->qq,
            up        => $self->up,
            mm        => $self->mm,
            cookies   => $self->cookies,
            vars      => $self->vars,
            sub_name  => $self->sub_name,
            base_name => $self->base_name || $self->name,
        });
    }
    catch {
        my $msg = shift;
        my $name = name2path $self->name;
        my $text = << "...";
**** Error in "action file": pl/action/${name}.pl ****

$msg
...
        croak $text;
    };

    return $action;
}



# _load();
sub _load {
    my $self = shift;
    my $pl = sprintf(
        '%s/%s.pl',
        $self->conf->{PATH}{ACTION},
        name2path($self->name),
    );

    my $buff;
    try {
        local $/;
        open my $fh, '<', $pl or die $!;
        $buff = de <$fh>;
        close $fh;
        $buff =~ s/__(?:END|DATA)__.*$//s; # __END__ 以降を削除する
    }
    catch {
        my $msg  = shift;
        my $name = $self->name;
        my $path = name2path $name;
        my $text = << "...";
**** Action "$name" not found, check existence: pl/action/${path}.pl ****

$msg
...
        croak $text;
        $buff = '';
    };

    return $buff;
}



#
sub _generate_as_string ($) {
    my ($self, $pl) = @_;
    $pl ||= '';

    my $code_fmt = << '...';
package Hoya::Action::%s;
use strict;
use warnings;
no warnings 'closure';  #ad-hoc
use utf8;
use parent qw/Hoya::Action/;
use Hoya::Action;

use Hash::MultiValue;
use Carp;
use Try::Tiny;

use Hoya::Util;
use Hoya::Factory::Action;


{
    no warnings;

    # overwrite of Hoya::Action::_main
    sub _main {
        use warnings;
        no warnings 'redefine';

        my $self = shift;
        #$self->SUPER::_main(@_);

        {
            no warnings;
            sub a { return $self; }
            sub A { return $self; }
            sub r { return $self->req; }
        }

        %s
    }
}

1;
__END__
...
    return sprintf(
        $code_fmt,
        name2class($self->name),
        $pl,
    );
}





1;
__END__

=head1 NAME

Hoya::Factory::Action - Generates "Action Class" dynamically.

=head1 SYNOPSIS

  use Hoya::Factory::Action;

=head1 DESCRIPTION

Hoya::Factory::Action is

=head1 METHODS

=over 4

=item init

initialize.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
