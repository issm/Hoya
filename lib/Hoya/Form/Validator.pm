package Hoya::Form::Validator;
use strict;
use warnings;
use utf8;
use parent qw/Hoya::Form/;

use Params::Validate;
use List::MoreUtils qw/uniq/;
use Hash::MultiValue;
use Carp;
use Try::Tiny;
use Hoya::Util;

sub OK                 {  0; }
sub REQUIRED           { 10; }
sub NUM_MISMATCHED     { 20; }
sub RE_MISMATCHED      { 30; }
sub SIZE_TOO_SHORT     { 40; }
sub SIZE_TOO_LONG      { 50; }
sub DEPENDENCY_INVALID { 60; }


sub _result {
    my ($self, $code) = @_;
    return {
        code => $code,
        text => '',
    };
}


sub check {
    my ($self, $q) = @_; # ref $q eq 'Hash::MultiValue';

    my $q_fixed = Hash::MultiValue->new;
    my $results = Hash::MultiValue->new;

    my $rules = Hash::MultiValue->new(%{$self->_rules || {}});
    my $okng = 0;

    #
    # ルールの記述はあるが，クエリに存在しないフィールドについてチェックする
    #
    $rules->each(sub
    {
        my ($field, $rule) = @_;

        #
        # required
        #
        unless ($q->get_all($field) || $rule->{optional}) {
            #
            # default
            #
            if (exists $rule->{default}) {
                $results->add(
                    $field,
                    $self->_result(OK),
                );
                $q_fixed->add($field, $rule->{default});
                return;
            }
            #
            #
            #
            else {
                $results->add(
                    $field,
                    $self->_result(REQUIRED),
                );

                $q_fixed->add($field, undef);
                $okng |= REQUIRED;
                return;
            }
        }
    });

    #
    # クエリに存在するフィールドについてチェックする
    #
    $q->each(sub
    {
        my ($f, $v) = @_;
        my $v_fixed = $v;
        my $rule = $rules->get($f);

        #
        # LFize
        #
        { $v_fixed =~ s/(?:\x0d\x0a?|\x0a)//g; }

        # ルールが存在しない場合
        unless (defined $rule) {
            $q_fixed->add($f, $v_fixed);
            return;
        }

        #
        # trim
        #
        if ($rule->{trim}) {
            $v_fixed =~ s/(?:^\s*|\s*$)//g;
        }

        #
        # optional
        #
        if ($rule->{optional}  &&  $v_fixed eq '') {
            $results->add(
                $f,
                $self->_result(OK),
            );
            $q_fixed->add($f, $v_fixed);
            return;
        }

        #
        # type?
        #


        #
        # num
        #
        {
            my @v = $q->get_all($f);
            if (scalar(@v) != ($rule->{num} || 1)) {
                $results->add(
                    $f,
                    $self->_result(NUM_MISMATCHED),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= NUM_MISMATCHED;
                return;
            }
        }

        #
        # re
        #
        if (exists $rule->{re}) {
            my $re = $rule->{re};
            try {
                if (my ($_m) = $re =~ /^\+(.*)$/) {
                    $re = eval "Hoya::Re::$_m";
                }
                else {
                    $re = qr/$re/;
                }
            }
            catch {
                my $msg = shift;
                croak << "...";
[Hoya::Form::Validator] Invalid regexp: $f -> re: $msg'
...
            };

            if ($v_fixed !~ /$re/) {
                $results->add(
                    $f,
                    $self->_result(RE_MISMATCHED),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= RE_MISMATCHED;
                return;
            }
        }

        #
        # min
        #
        if (exists $rule->{min}) {
            my $min = $rule->{min};

            if ($min !~ /^\d+$/) {
                croak << "...";
[Hoya::Form::Validator] Invalid format: $f -> min
...
            }

            if (length($v_fixed) < int($min)) {
                $results->add(
                    $f,
                    $self->_result(SIZE_TOO_SHORT),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= SIZE_TOO_SHORT;
                return;
            }
        }

        #
        # max
        #
        if (exists $rule->{max}) {
            my $max = $rule->{max};

            if ($max !~ /^\d+$/) {
                croak << "...";
[Hoya::Form::Validator] Invalid format: $f -> max
...
            }

            if (length($v_fixed) > int($max)) {
                $results->add(
                    $f,
                    $self->_result(SIZE_TOO_LONG),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= SIZE_TOO_LONG;
                return;
            }

        }

        #
        # depends
        #
        if (exists $rule->{depends}) {
            $rule->{depends} = [$rule->{depends}]
                if ref $rule->{depends} eq '';
            my $depends = $rule->{depends};
            my @exists = grep {
                defined($q_fixed->get($_)) || defined($q->get($_));
            } @$depends;
            #warn D [scalar(@exists), scalar(@$depends)];

            if (scalar(@exists) != scalar(@$depends)) {
                $results->add(
                    $f,
                    $self->_result(DEPENDENCY_INVALID),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= DEPENDENCY_INVALID;
                return;
            }
        }
        #
        # ok
        #
        {
            $results->add(
                $f,
                $self->_result(OK),
            );
            $q_fixed->add($f, $v_fixed);
        }
    });

    return wantarray ? ($okng, $results, $q_fixed) : $okng;
}




1;
__END__

=head1 NAME

Hoya::Form::Validator - Validates form values.

=head1 SYNOPSIS

  use Hoya::Form::Validator;

=head1 DESCRIPTION

Hoya::Form::Validator is.

=head1 METHODS

=over 4

=item new(\%opts)

constructs.

options:

name: 'form name'. Defaults to 'action name'.

req:  Request object, which is-a Plack::Request or HTTPx::Weblet.

conf: Config hashref.

=item ($okng, $details, $q_fixed) = check($query)

$query is-a Hash::MultiValue.

returns:

$okng: 0 if valid. Otherwise, non-zero (positive) value.

$details: results of each field.

$q_fixed: fixed values through validation. is-a Hash::MultiValue.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
