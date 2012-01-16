package Hoya::Mapper::URL;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use YAML::Syck;
use URI::Escape;
use Hash::Merge qw/merge/;
use Hash::MultiValue;
use Carp;
use Try::Tiny;

use Hoya::Util;

my $_env;
my $_conf;
my $_app_name;
my $_map_rule;
my $_map_var;


#
sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors(qw/env conf app_name/);
    return $self->_init;
}

#
sub _init {
    my $self = shift;
    $_env      = $self->env;
    $_conf     = $self->conf;
    $_app_name = $self->app_name;
    $_map_rule = {};
    $_map_var  = {};

    $self->_load_map  if defined $_app_name;
    return $self;
}



# _load_map();
sub _load_map {
    my $self = shift;
    my $yamlfile = "$_conf->{PATH}{CONF}/urlmap.yml";
    try {
        my $map = de LoadFile($yamlfile);
        $_map_var = $map->{VAR}
            if exists $map->{VAR};
        $_map_rule = $map->{$_app_name}
            if exists $map->{$_app_name};
    }
    catch {
        return 0;
    };
    return 1;
}


# _get_path_info();
sub _get_path_info {
  my $self = shift;
  my $path_info = de $_env->{PATH_INFO};
  $path_info =~ s{^/}{};

  return $path_info;
}


# get_action_info();
sub get_action_info {
    my $self = shift;
    my $action_info = {
        name => '',
        qq   => Hash::MultiValue->new(),
    };
    my $path_info = $self->_get_path_info();

    my ($matched, @params, $rule_applied);

    # v パス正規表現内の「変数」展開用正規表現
    # v $hoge or ${hoge}
    my $re_var = qr/(?:\$([a-zA-Z0-9_]+) | \$\{([^\}]+)\} )/x;

    #
    # ルールを検索する
    #
    my $re_path_matched = '';
    for my $pair (@$_map_rule) {
        my $re_path = (keys %$pair)[0];  # ペアのキー（パスの正規表現）
        my $re_path_eval = $re_path;     # 「変数」展開用
        # $re_path内の「変数」を展開する
        1 while (
            $re_path_eval =~ s/$re_var/$_map_var->{$1 || $2} || '';/gex
        );

        $matched =
            (@params = $path_info =~ qr/$re_path_eval/x) ? 1 : 0;
        # v マッチした，または，以前にマッチしている
        if ($matched) {
            $re_path_matched = $re_path;
            $rule_applied = $pair->{$re_path} || [];
            # $rule_applied がスカラ値の場合，arrayrefの要素に変換する
            $rule_applied = [$rule_applied]
                if (ref $rule_applied eq '');
            #
            $rule_applied = [[], {}]
                unless defined $rule_applied->[0];

            last;
        }
    }

    #
    # $rule_applied にアクション名（スカラ値）が存在しない場合
    # $re_path 登場以降を再スキャンし，
    # 最初に登場するアクション名を $rule_applied に追加する
    #
    unless (grep {ref $_ eq ''} @$rule_applied) {
        my $path_appeared = 0;
        for my $pair (@$_map_rule) {
            my $re_path = (keys %$pair)[0];
            $path_appeared = 1  if $re_path eq $re_path_matched;
            next  unless $path_appeared;

            my $rule = $pair->{$re_path};
            $rule = [$rule]  if (ref $rule eq '');

            if (
                my ($action_name) = grep {
                    (ref $_ eq '')  &&  defined $_;
                } @$rule
            ) {
                push @$rule_applied, $action_name;
                last;
            }
        }
    }

    #
    # ルールからアクションの情報を生成する
    #
    if (defined $rule_applied) {
        my ($param, $const) = ([], {});
        for my $i (@$rule_applied) {
            if (ref $i eq '')      { $action_info->{name} = $i; }
            if (ref $i eq 'ARRAY') { $param = $i; }
            if (ref $i eq 'HASH')  { $const = $i; }
        }

        if ($action_info->{name} eq '') {
            croak sprintf(
                '[error] Name of action, to be mapped, is not defined'
                    . ' at matched path-info-regexp "%s"'
                    . ', check conf/urlmap.yml.',
                $re_path_matched,
            );
        }

        #
        if (defined $param  &&  ref $param eq 'ARRAY') {
            for (my $i = 0; $i < scalar @$param; $i++) {
                my $k = $param->[$i];
                $action_info->{qq}->add($k, $params[$i])
                    if defined $params[$i];
            }
        }
        #
        if (defined $const  &&  ref $const eq 'HASH') {
            while (my ($k, $v) = each %$const) {
                $action_info->{qq}->add($k, $v);
            }
        }

    }

    return $action_info;
}



1;
__END__

=head1 NAME

Hoya::Mapper::URL - Maps "path_info" to "action" info under the "rule".

=head1 SYNOPSIS

  use Hoya::Mapper::URL;

=head1 DESCRIPTION

Hoya::Mapper::URL is

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
