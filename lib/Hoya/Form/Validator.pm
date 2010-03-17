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

sub OK                 {   0; }
sub REQUIRED           { 101; }
sub NUM_MISMATCHED     { 201; }
sub NUM_TOO_FEW        { 202; }
sub NUM_TOO_MANY       { 203; }
sub RE_MISMATCHED      { 301; }
sub SIZE_TOO_SHORT     { 401; }
sub SIZE_TOO_LONG      { 402; }
sub VALUE_TOO_SMALL    { 501; }
sub VALUE_TOO_LARGE    { 502; }
sub DEPENDENCY_INVALID { 601; }


our $KEYNAME_TEXT = 'TEXT';


# _result($code);
sub _result {
    my ($self, $code, $field) = @_;
    return {
        code => $code,
        text => $self->_rules->{$field || ''}{$KEYNAME_TEXT}{$code}
                || $self->_rules->{$KEYNAME_TEXT}{$code}
                || '',
    };
}

# $value_fixed = _fix_value($value, $rule);
sub _fix_value {
    my ($self, $value, $rule) = @_;
    return undef  unless defined $value;

    $rule ||= {};
    my $value_fixed = $value;

    # LFize
    $value_fixed =~ s/(?:\x0d\x0a?|\x0a)/\x0a/g;

    # trim
    if ($rule->{trim}) {
        $value_fixed =~ s/(?:^\s*|\s*$)//g;
    }

    # z2h (zenkaku to hankaku)
    if ($rule->{z2h}) {
        $value_fixed =~ tr/０-９ａ-ｚＡ-Ｚ　/0-9a-zA-Z /;
    }

    return $value_fixed;
}


sub check {
    my ($self, $q) = @_; # $q is-a Hash::MultiValue;
    $q ||= $self->q;

    $self->_scope;

    my $q_fixed = Hash::MultiValue->new;
    my $results = Hash::MultiValue->new;

    my $rules = Hash::MultiValue->new(%{$self->_rules || {}});
    my $okng = 0;

    if ( $KEYNAME_TEXT ne 'TEXT') {
    }


    #
    # 「case」ルールの存在をチェックする
    #
    $rules->each(sub
    {
        my ($field, $rule) = @_;
        return  if $field eq $KEYNAME_TEXT;

        if (exists $rule->{case}) {
            my $v = $self->_fix_value($q->get($field), $rule);
            my $rules_sub = $rule->{case}{$v} || {};
            $rules->add($_, $rules_sub->{$_})  for keys %$rules_sub;
        }
    });


    #
    # ルールの記述はあるが，クエリに存在しないフィールドについてチェックする
    #
    $rules->each(sub
    {
        my ($field, $rule) = @_;
        return  if $field eq $KEYNAME_TEXT;

        #
        # required
        #
        unless (defined (($q->get_all($field))[0]) || $rule->{optional}) {
            #
            # type: check or checkbox
            #
            if ($rule->{type} =~ /^check(?:box)?$/) {
                #$q_fixed->add($field, undef);
                $q->add($field, undef);
                return;
            }
            #
            # default
            #
            elsif (exists $rule->{default}) {
                $results->add(
                    $field,
                    $self->_result(OK, $field),
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
                    $self->_result(REQUIRED, $field),
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
        my $rule = $rules->get($f);

        my @values = grep defined $_, $q->get_all($f);
        my $n_values = scalar @values;

        # ルールが存在しない場合
        unless (defined $rule) {
            $q_fixed->add($f, $v);
            return;
        }

        #
        my $v_fixed = $self->_fix_value($v, $rule);

        #
        # optional
        #
        if ($rule->{optional}  &&  $v_fixed eq '') {
            $results->add(
                $f,
                $self->_result(OK, $f),
            );
            $q_fixed->add($f, $v_fixed);
            return;
        }

        #
        # type?
        #


        #
        # num_min
        #
        if ($rule->{num_min}  &&  $n_values < $rule->{num_min}) {
            $results->add(
                $f,
                $self->_result(NUM_TOO_FEW, $f),
            );
            $q_fixed->add($f, $v_fixed);
            $okng |= NUM_TOO_FEW;
            return;
        }
        #
        # mun_max
        #
        if ($rule->{num_max}  &&  $n_values > $rule->{num_max}) {
            $results->add(
                $f,
                $self->_result(NUM_TOO_MANY, $f),
            );
            $q_fixed->add($f, $v_fixed);
            $okng |= NUM_TOO_MANY;
            return;
        }
        #
        # num
        #
        # num_min, num_max いずれとも未定義の場合に適用される
        unless ($rule->{num_min} || $rule->{num_max}){
            if ($n_values != ($rule->{num} || 1)) {
                $results->add(
                    $f,
                    $self->_result(NUM_MISMATCHED, $f),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= NUM_MISMATCHED;
                return;
            }
        }

        #
        # blank
        #
        if ($v_fixed eq '') {
            my $blank_allowed = $rule->{blank} || 0;
            my $OK_OR_REQUIRED = $blank_allowed ? OK : REQUIRED;
            $results->add(
                $f,
                $self->_result($OK_OR_REQUIRED, $f),
            );
            $q_fixed->add($f, $v_fixed);
            $okng |= $OK_OR_REQUIRED;
            return;
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
                    $self->_result(RE_MISMATCHED, $f),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= RE_MISMATCHED;
                return;
            }
        }

        #
        # size_min
        #
        if (exists $rule->{size_min}) {
            my $min = $rule->{size_min};

            if ($min !~ /^\d+$/) {
                croak << "...";
[Hoya::Form::Validator] Invalid format: $f -> size_min
...
            }

            if (length($v_fixed) < int($min)) {
                $results->add(
                    $f,
                    $self->_result(SIZE_TOO_SHORT, $f),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= SIZE_TOO_SHORT;
                return;
            }
        }

        #
        # size_max
        #
        if (exists $rule->{size_max}) {
            my $max = $rule->{size_max};

            if ($max !~ /^\d+$/) {
                croak << "...";
[Hoya::Form::Validator] Invalid format: $f -> size_max
...
            }

            if (length($v_fixed) > int($max)) {
                $results->add(
                    $f,
                    $self->_result(SIZE_TOO_LONG, $f),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= SIZE_TOO_LONG;
                return;
            }

        }

        #
        # val_min
        #
        if (exists $rule->{val_min}) {
            my $min = $rule->{val_min};

            if ($min !~ /^\d+$/) {
                croak << "...";
[Hoya::Form::Validator] Invalid format: $f -> val_min
...
            }

            if (int($v_fixed) < int($min)) {
                $results->add(
                    $f,
                    $self->_result(VALUE_TOO_SMALL, $f),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= VALUE_TOO_SMALL;
                return;
            }
        }

        #
        # val_max
        #
        if (exists $rule->{val_max}) {
            my $max = $rule->{val_max};

            if ($max !~ /^\d+$/) {
                croak << "...";
[Hoya::Form::Validator] Invalid format: $f -> val_max
...
            }

            if (int($v_fixed) > int($max)) {
                $results->add(
                    $f,
                    $self->_result(VALUE_TOO_LARGE, $f),
                );
                $q_fixed->add($f, $v_fixed);
                $okng |= VALUE_TOO_LARGE;
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
                    $self->_result(DEPENDENCY_INVALID, $f),
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
                $self->_result(OK, $f),
            );
            $q_fixed->add($f, $v_fixed);
        }
    });

    # 値がundefな項目を取り除く
    my $q_fixed_exclude_undef = Hash::MultiValue->new;
    $q_fixed->each(sub
    {
        my ($f, $v) = @_;
        $q_fixed_exclude_undef->add($f, $v)  if defined $v;
        return;
    });

    return wantarray ? ($okng, $results, $q_fixed_exclude_undef) : $okng;
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
