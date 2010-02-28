package Hoya::Form;
use strict;
use warnings;
use utf8;
use parent qw/Class::Accessor::Faster/;


use YAML::Syck;
use Carp;
use Try::Tiny;
use Hoya::Util;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/req conf name
                            _rules
                           /;

    return $self->_init;
}

sub _init {
    my ($self, $param) = @_;

    $self->_rules($self->_load);

    return $self;
}


sub _load {
    my $self = shift;
    my $rulefile;

    #
    $rulefile = sprintf(
        '%s/form.yml',
        $self->conf->{PATH}{CONF},
    );
    unless (-f $rulefile) {
        $rulefile = sprintf(
            '%s/form/%s.yml',
            $self->conf->{PATH}{CONF},
            name2path($self->name),
        );
    }
    croak 'Form-rule file does not exist: ' . $rulefile
        unless -f $rulefile;

    try {
        my $rule = LoadFile($rulefile);
        if (exists $rule->{$self->name}) {
            $rule = $rule->{$self->name};
        }
        return $rule;
    }
    catch {
        croak 'The format of form-rule file is invalid: ' . shift;
    };
}




1;
__END__

=head1 NAME

Hoya::FormValidator - Validates form values.

=head1 SYNOPSIS

  use Hoya::FormValidator;

=head1 DESCRIPTION

Hoya::FormValidator is.

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
