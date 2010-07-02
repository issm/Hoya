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
my ($DIR_ALT_CSS, $DIR_ALT_JS, $DIR_ALT_IMG);

my @IE = map "ie$_", reverse 6..9, '';



my $_name;
my $_env;
my $_conf;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/name env conf
                            _page_conf
                           /;

    return $self->_init;
}


sub _init {
    my ($self) = @_;
    $_name = $self->name;
    $_env  = $self->env;
    $_conf = $self->conf;

    $self->_page_conf($self->conf->{PAGE});

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

    $DIR_ALT_CSS = sprintf '%s/site/default/%s/css', $_conf->{PATH}{ROOT}, $_env->{HOYA_SKIN};
    $DIR_ALT_JS  = sprintf '%s/site/default/%s/js',  $_conf->{PATH}{ROOT}, $_env->{HOYA_SKIN};
    $DIR_ALT_IMG = sprintf '%s/site/default/%s/img', $_conf->{PATH}{ROOT}, $_env->{HOYA_SKIN};

    $self;
}


sub import_css {
    my ($self) = @_;
    my $disable_ie_specific = $self->_page_conf->{DISABLE_IE_SPECIFIC} || 0;

    #
    # common
    #
    my $pre_c = $self->_page_conf->{PATH_PREFIX}{COMMON};
    my $is_pre_c = (defined $pre_c  &&  $pre_c ne '') ? 1 : 0;

    for my $n_c (@$CSS_COMMON) {
        my $f = "${n_c}.css";
        my ($css, $css_alt) = (
            $is_pre_c
                ?  "${DIR_CSS}/${pre_c}/$f"
                :  "${DIR_CSS}/$f",
            $is_pre_c
                ?  "${DIR_ALT_CSS}/${pre_c}/$f"
                :  "${DIR_ALT_CSS}/$f",
        );
        if (-f $css || -f $css_alt) {
            my $path = $is_pre_c
                ?  "css/${pre_c}/$f"  :  "css/$f";
            push @$CSS_IMPORT, $path;
        }

        unless ($disable_ie_specific) {
            for my $ie (@IE) {
                my $f_ie = "${n_c}-${ie}.css";
                my ($css_ie, $css_ie_alt) = (
                    $is_pre_c
                        ?  "${DIR_CSS}/${pre_c}/${f_ie}"
                        :  "${DIR_CSS}/${f_ie}",
                    $is_pre_c
                        ?  "${DIR_ALT_CSS}/${pre_c}/${f_ie}"
                        :  "${DIR_ALT_CSS}/${f_ie}",
                );
                if (-f $css_ie || -f $css_ie_alt) {
                    my $path_ie = $is_pre_c
                        ?  "css/${pre_c}/${f_ie}"  :  "css/${f_ie}";
                    push @{$CSS_IMPORT_IE->{$ie}}, $path_ie;
                }
            }
        }
    }

    #
    # page
    #
    my $name2path = name2path($_name);
    my $pre_p = $self->_page_conf->{PATH_PREFIX}{PAGE};
    my $is_pre_p = (defined $pre_p  &&  $pre_p ne '') ? 1 : 0;

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

    for my $n_p (
        reverse(@common_page),
        $name2path,
    ) {
        my $f = "${n_p}.css";
        my ($css, $css_alt) = (
            $is_pre_p
                ?  "${DIR_CSS}/${pre_p}/$f"
                :  "${DIR_CSS}/$f",
            $is_pre_p
                ?  "${DIR_ALT_CSS}/${pre_p}/$f"
                :  "${DIR_ALT_CSS}/$f",
        );
        if (-f $css || -f $css_alt) {
            my $path = $is_pre_p
                ?  "css/${pre_p}/$f"  :  "css/$f";
            push @$CSS_IMPORT, $path;
        }

        unless ($disable_ie_specific) {
            for my $ie (@IE) {
                my $f_ie = "${n_p}-${ie}.css";
                my ($css_ie, $css_ie_alt) = (
                    $is_pre_p
                        ?  "${DIR_CSS}/${pre_p}/${f_ie}"
                        :  "${DIR_CSS}/${f_ie}",
                    $is_pre_p
                        ?  "${DIR_ALT_CSS}/${pre_p}/${f_ie}"
                        :  "${DIR_ALT_CSS}/${f_ie}",
                );
                if (-f $css_ie || -f $css_ie_alt) {
                    my $path_ie = $is_pre_p
                        ?  "css/${pre_p}/${f_ie}"  :  "css/${f_ie}";
                    push @{$CSS_IMPORT_IE->{$ie}}, $path_ie;
                }
            }
        }
    }

    return ($CSS_IMPORT, $CSS_IMPORT_IE);
}


sub import_js {
    my ($self) = @_;
    my $disable_ie_specific = $self->_page_conf->{DISABLE_IE_SPECIFIC} || 0;

    #
    # common
    #
    my $pre_c = $self->_page_conf->{PATH_PREFIX}{COMMON};
    my $is_pre_c = (defined $pre_c  &&  $pre_c ne '') ? 1 : 0;

    for my $n_c (@$JS_COMMON) {
        my $f = "${n_c}.js";
        my ($js, $js_alt) = (
            $is_pre_c
                ?  "${DIR_JS}/${pre_c}/$f"
                :  "${DIR_JS}/$f",
            $is_pre_c
                ?  "${DIR_ALT_JS}/${pre_c}/$f"
                :  "${DIR_ALT_JS}/$f",
        );
        if (-f $js || -f $js_alt) {
            my $path = $is_pre_c
                ? "js/${pre_c}/$f" : "js/$f";
            push @$JS_IMPORT, $path;
        }


        unless ($disable_ie_specific) {
            for my $ie (@IE) {
                my $f_ie = "${n_c}-${ie}.js";
                my ($js_ie, $js_ie_alt) = (
                    $is_pre_c
                        ?  "${DIR_JS}/${pre_c}/${f_ie}"
                        :  "${DIR_JS}/${f_ie}",
                    $is_pre_c
                        ?  "${DIR_ALT_JS}/${pre_c}/${f_ie}"
                        :  "${DIR_ALT_JS}/${f_ie}",
                );
                if (-f $js_ie || -f $js_ie_alt) {
                    my $path_ie = $is_pre_c
                        ?  "js/${pre_c}/${f_ie}"  :  "js/${f_ie}";
                    push @{$JS_IMPORT_IE->{$ie}}, $path_ie;
                }
            }
        }
    }

    #
    # page
    #
    my $name2path = name2path($_name);
    my $pre_p = $self->_page_conf->{PATH_PREFIX}{PAGE};
    my $is_pre_p = (defined $pre_p  &&  $pre_p ne '') ? 1 : 0;

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

    for my $n_p (
        reverse(@common_page),
        $name2path,
    ) {
        my $f = "${n_p}.js";
        my ($js, $js_alt) = (
            $is_pre_p
                ?  "${DIR_JS}/${pre_p}/$f"
                :  "${DIR_JS}/$f",
            $is_pre_p
                ?  "${DIR_ALT_JS}/${pre_p}/$f"
                :  "${DIR_ALT_JS}/$f",
        );
        if (-f $js || -f $js_alt) {
            my $path = $is_pre_p
                ?  "js/${pre_p}/$f"  :  "js/$f";
            push @$JS_IMPORT, $path;
        }

        unless ($disable_ie_specific) {
            for my $ie (@IE) {
                my $f_ie = "${n_p}-${ie}.js";
                my ($js_ie, $js_ie_alt) = (
                    $is_pre_p
                        ?  "${DIR_JS}/${pre_p}/${f_ie}"
                        :  "${DIR_JS}/${f_ie}",
                    $is_pre_p
                        ?  "${DIR_ALT_JS}/${pre_p}/${f_ie}"
                        :  "${DIR_ALT_JS}/${f_ie}",
                );
                if (-f $js_ie || -f $js_ie_alt) {
                    my $path_ie = $is_pre_p
                        ?  "js/${pre_p}/${f_ie}"  :  "js/${f_ie}";
                    push @{$JS_IMPORT_IE->{$ie}}, $path_ie;
                }
            }
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
