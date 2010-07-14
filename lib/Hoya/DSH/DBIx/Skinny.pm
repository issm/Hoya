package Hoya::DSH::DBIx::Skinny;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Try::Tiny;
use Hoya::Util;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;
    $class->mk_accessors qw/name env conf cache
                            skinny
                           /;
    return $self->_init;
}

sub _init {
    my $self = shift;
    return $self->_setup;
    #return $self;
}


sub _setup {
    my $self = shift;
    my $db_conf = $self->conf->{DSH}{$self->name};

    my $skinny;
    try {
        my $module_name;
        if (
            ($module_name) = $db_conf->{MODULE} =~ /^\+(.*)$/
        ) {
            1;
        }
        else {
            $module_name = sprintf(
                '%s_DB_%s',
                $self->conf->{PROJECT_NAME},
                $db_conf->{MODULE},
            );
            $module_name = name2class $module_name;
        }

        eval "use ${module_name};";
        $skinny = ${module_name}->new;

        croak 'xxx'  unless defined $skinny;
    }
    catch {
        my $msg = shift;
        my $text = << "...";
**** Error in Hoya::DSH::DBIx::Skinny ****

$msg
...
        croak $text;
    };


    $self->skinny($skinny);
    return $self;
}


1;
