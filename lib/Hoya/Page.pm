package Hoya::Page;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Try::Tiny;
use Hoya::Util;


my ($CSS_COMMON, $JS_COMMON);
my ($CSS_IMPORT, $JS_IMPORT);
my ($CSS_IMPORT_IE, $JS_IMPORT_IE);
my ($DIR_CSS, $DIR_JS, $DIR_IMG);

my @IE = map "ie$_", reverse 6..9, '';



my $_name;
my $_env;
my $_conf;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/name env conf/;

    return $self->_init;
}


sub _init {
    my ($self) = @_;
    $_name = $self->name;
    $_env  = $self->env;
    $_conf = $self->conf;

    $CSS_COMMON = $_conf->{PAGE}{CSS_COMMON};
    $JS_COMMON  = $_conf->{PAGE}{JS_COMMON};

    ($CSS_IMPORT, $JS_IMPORT) = ([], []);
    ($CSS_IMPORT_IE, $JS_IMPORT_IE) = ({}, {});

    for my $ie (@IE) {
        $CSS_IMPORT_IE->{$ie} = [];
        $JS_IMPORT_IE->{$ie}  = [];
    }

    $DIR_CSS = sprintf '%s/%s/css', $_conf->{PATH}{SITE}, $_env->{HOYA_SKIN};
    $DIR_JS  = sprintf '%s/%s/js',  $_conf->{PATH}{SITE}, $_env->{HOYA_SKIN};
    $DIR_IMG = sprintf '%s/%s/img', $_conf->{PATH}{SITE}, $_env->{HOYA_SKIN};

    $self;
}


sub import_css {
    my ($self) = @_;

    # common
    for my $n_c (@$CSS_COMMON) {
        my $path = sprintf '%s/%s.css', $DIR_CSS, $n_c;
        my $url  = sprintf 'css/%s.css', $n_c;
        if (-f $path) {
            push @$CSS_IMPORT, $url;
        }

        for my $ie (@IE) {
            my $path_ie = sprintf '%s/%s-%s.css', $DIR_CSS, $n_c, $ie;
            my $url_ie  = sprintf 'css/%s-%s.css', $n_c, $ie;
            if (-f $path_ie) {
                push @{$CSS_IMPORT_IE->{$ie}}, $url_ie;
            }
        }
    }

    # page
    my $name2path = name2path($_name);

    my @common_page = ();
    my @dir_ = split '/', $name2path;
    pop @dir_;  # '*.css' を取り除く
    do {
        my $css_ = sprintf(
            '%s/_common',
            join('/', @dir_),
        );
        $css_ =~ s{^/}{};
        push @common_page, $css_;
    } while (pop @dir_);

    for my $n_p (reverse(@common_page), $name2path) {
        my $path = sprintf '%s/%s.css', $DIR_CSS, $n_p;
        my $url  = sprintf 'css/%s.css', $n_p;

        push @$CSS_IMPORT, $url  if -f $path;

        for my $ie (@IE) {
            my $path_ie = sprintf '%s/%s-%s.css', $DIR_CSS, $n_p, $ie;
            my $url_ie  = sprintf 'css/%s-%s.css', $n_p, $ie;
            push @{$CSS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
        }
    }

    return ($CSS_IMPORT, $CSS_IMPORT_IE);
}


sub import_js {
    my ($self) = @_;

    # common
    for my $n_c (@$JS_COMMON) {
        my $path = sprintf '%s/%s.js', $DIR_JS, $n_c;
        my $url = sprintf 'js/%s.js', $n_c;
        push @$JS_IMPORT, $url  if -f $path;

        for my $ie (@IE) {
            my $path_ie = sprintf '%s/%s-%s.js', $DIR_JS, $n_c, $ie;
            my $url_ie  = sprintf 'js/%s-%s.js', $n_c, $ie;
            push @{$JS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
        }
    }

    # page
    my $name2path = name2path($_name);

    my @common_page = ();
    my @dir_ = split '/', $name2path;
    pop @dir_;  # '*.js' を取り除く
    do {
        my $js_ = sprintf(
            '%s/_common',
            join('/', @dir_),
        );
        $js_ =~ s{^/}{};
        push @common_page, $js_;
    } while (pop @dir_);

    for my $n_p (reverse(@common_page), $name2path) {
        my $path = sprintf '%s/%s.js', $DIR_JS, $n_p;
        my $url  = sprintf 'js/%s.js', $n_p;
        push @$JS_IMPORT, $url  if -f $path;

        for my $ie (@IE) {
            my $path_ie = sprintf '%s/%s-%s.js', $DIR_JS, $n_p, $ie;
            my $url_ie  = sprintf 'js/%s-%s.js', $n_p, $ie;
            push @{$JS_IMPORT_IE->{$ie}}, $url_ie  if -f $path_ie;
        }
    }

    return ($JS_IMPORT, $JS_IMPORT_IE);
}


1;
__END__

=head1 NAME

Hoya::Page - Utilities for "web page".

=head1 SYNOPSIS

  use Hoya::Page;

=head1 DESCRIPTION

Hoya::Factory::Action is

=head1 METHODS

=over 4

=item init

initialize.

=item import_css

searches "css" files and returns those info.

=item import_js

searches "js" files and return those info.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
