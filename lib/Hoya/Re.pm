package Hoya::Re;
use strict;
use utf8;
use Carp;

use Hoya::Util;

our @LABELS = qw/
    ANY
    NON_SPACE NON_SPACE_ML
    NUM ALPHABET ALPHANUM
    UNIQUE_KEY RANDOM_KEY
    FLAG
    HIRAGANA KATAKANA KANJI HANKANA
    DOMAIN
    EMAIL    EMAIL_OR_NULL
    URL
    DATETIME
    DATE
    TIME
    TEL      TEL_OR_NULL
    ZIPCODE  ZIPCODE_OR_NULL
    FILENAME FILENAME_OR_NULL
/;


my $_1_NUM        = qr/[0-9]/;
my $_1_ALPHABET   = qr/[0-9a-z]/i;
my $_1_ALPHANUM   = qr/[0-9a-z]/i;
my $_1_UNIQUE_KEY = qr/[0-9a-z-_]/i;
# ref: http://pentan.info/doc/unicode_database_block.html
my $_1_HIRAGANA   = qr/[\x{3040}-\x{309F}]/;
my $_1_KATAKANA   = qr/[\x{30A0}-\x{30FF}]/;
my $_1_KANJI      = qr/[\x{4E00}-\x{9FFF}]/;
my $_1_HANKANA    = qr/[\x{FF60}-\x{FF9F}]/;


sub import {
    no strict 'refs';
    my $caller = caller(0);

    for my $n (@LABELS) {
        *{"$caller\::RE_$n"} = \&{"$n"};
    }
}



# _re_by_arg($re, $n);
# _re_by_arg($re, $re_pre, $n);
# _re_by_arg($re, $re_pre, $re_post, $n);
sub _re_by_arg {
    my ($re, $re_pre, $re_post, $n) = @_;
    if (ref $re_pre ne 'Regexp') {
        $n = $re_pre;
        $re_pre = $re_post = qr//;
    }
    elsif (ref $re_post ne 'Regexp') {
        $n = $re_post;
        $re_post = qr//;
    }

    if (!defined $n)     { return qr/^     ${re_pre} ${re}+ ${re_post}        $/x; }
    elsif ($n eq '*')    { return qr/^     ${re_pre} ${re}* ${re_post}        $/x; }
    elsif ($n eq '^')    { return qr/^     ${re_pre} ${re}+ ${re_post}         /x; }
    elsif ($n eq '$')    { return qr/      ${re_pre} ${re}+ ${re_post}        $/x; }
    elsif ($n eq ' ')    { return qr/^ \s* ${re_pre} ${re}+ ${re_post}    \s* $/x; }
    elsif ($n = int($n)) { return qr/^     ${re_pre} ${re}{$n} ${re_post}     $/x; }
    else                 { return qr/      ${re_pre} ${re}+ ${re_post}         /x; }
}



sub PATH_STATIC_UPLOAD {
    return qr{(?:^/
                  (upload)
              )}x;
}

sub PATH_STATIC_SKIN {
    return qr{(?:
                  ^/(static|js|img|css)
                  |
                  \.(ico)$
              )}x;
}



sub ANY {
    return qr/.*/;
}

sub NON_SPACE {
    return qr/^\s* \S(.*\S)* \s*$/x;
    #return _re_by_arg(qr/\S/, @_);
}

sub NON_SPACE_ML {
    return qr/^\s* \S(.*\S)* \s*$/mx;
    #return _re_by_arg(qr/\S/, @_);
}


sub NUM {
    return _re_by_arg(
        qr/${_1_NUM}/,
        qr/[-+]?/,
        @_,
    );
}


sub ALPHABET {
    return _re_by_arg(
        qr/${_1_ALPHABET}/,
        @_,
    );
}


sub ALPHANUM {
    return _re_by_arg(
        qr/${_1_ALPHANUM}/,
        @_,
    );

    my $n = int(shift) || 1;
    return qr/^${_1_ALPHANUM}{$n}$/;
}


sub UNIQUE_KEY {
    return _re_by_arg(
        qr/${_1_UNIQUE_KEY}/,
        @_,
    );
}
sub RANDOM_KEY { return UNIQUE_KEY(@_); }


sub FLAG {
    return qr/^[01]$/;
}


sub HIRAGANA {
    return _re_by_arg(
        qr/${_1_HIRAGANA}/,
        @_,
    );
}


sub KATAKANA {
    return _re_by_arg(
        qr/${_1_KATAKANA}/,
        @_,
    );
}


sub KANJI {
    return _re_by_arg(
        qr/${_1_KANJI}/,
        @_,
    );
}


sub HANKANA {
    return _re_by_arg(
        qr/${_1_HANKANA}/,
        @_,
    );
}



sub DOMAIN {
    return qr/([0-9a-zA-Z-_]+\.)+
              (?:
                  (?:co|ne|or)\.jp|jp|
                  com|net|org|
                  local|
                  [a-zA-Z]{2,4}
              )
             /x;
}


sub EMAIL {
    my $DOMAIN = DOMAIN;
    return qr/^
              [^\@]+
              \@
              ${DOMAIN}
            $/ix;
}
sub EMAIL_OR_NULL {
    my $RE = EMAIL;
    return qr/(?:${RE}|^$)/;
}


sub URL {
    return qr{^
              https?://
              .*
              $}x;
}


sub DATETIME {
    return qr/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/;
}

sub DATE {
    return qr/^(\d{4})-(\d{2})-(\d{2})$/;
}

sub TIME {
    return qr/^(\d{2}):(\d{2}):(\d{2})$/;
}



sub TEL {
    return qr/^(?:
                  (?:\d{10,11}) |
                  (?:\d{2}-\d{4}-\d{4}) |
                  (?:\d{3}-\d{3}-\d{4}) |
                  (?:\d{4}-\d{2}-\d{4}) |
                  (?:\d{5}-\d{1}-\d{4}) |
                  (?:\d{3}-\d{4}-\d{4}) |
                  (?:\d{3}-\d{3}-\d{5})
              )
              $/x;
}
sub TEL_OR_NULL {
    my $RE = TEL;
    return qr/(?:${RE}|^$)/;
}


sub ZIPCODE {
    return qr/^(\d{3})-?(\d{4})$/x;
}
sub ZIPCODE_OR_NULL {
    my $RE = ZIPCODE;
    return qr/(?:${RE}|^$)/;
}


sub FILENAME {
    # exclude: / \ ¥ : ; < > ' " | * ? { }
    return qr/^[^\/\\\¥\:\;\<\>\'\"\|\*\?\{\}]+$/;
}
sub FILENAME_OR_NULL {
    my $RE = FILENAME;
    return qr/(?:${RE}|^$)/;
}



1;
__END__

=head1 NAME

Hoya::Re - Regexp collection often used in Hoya.

=head1 SYNOPSIS

  use Hoya::Re;

=head1 DESCRIPTION

Hoya::Re is

=head1 METHODS

=over 4

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
