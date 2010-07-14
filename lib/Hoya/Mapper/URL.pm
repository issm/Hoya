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

    $class->mk_accessors qw/env conf app_name/;
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

    $self->_load_map;
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
    # 適用ルールを検索する
    #
    my $re_path_matched = '';
    for my $pair (@$_map_rule) {
        my $re_path = (keys %$pair)[0];
        my $re_path_eval = $re_path; # 「変数」展開用
        # $re_path内の「変数」を展開する
        1 while (
            $re_path_eval =~ s/$re_var/$_map_var->{$1 || $2} || '';/gex
        );
        # v 以前にマッチしていなければ，パタンマッチを試みる
        unless ($matched) {
            $matched = (@params = $path_info =~ qr/$re_path_eval/x) ? 1 : 0;
        }
        # v マッチした，または，以前にマッチしている
        if ($matched) {
            $re_path_matched = $re_path;
            my $rule = $pair->{$re_path};
            if (defined $rule) {
                $rule_applied = $rule;
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
package Sabae::Mapper::URL;
use strict;
use warnings;
use base qw( Class::Accessor::Fast::XS );
use Sabae::Class::Base qw( :debug );
use URI::Escape;
use YAML::Syck;

my $__config;
my $__map;
my $__var4map;
my $__request_path;



__PACKAGE__->mk_accessors(qw/ request config key /);


sub init {
  my $self = shift;
  $__config = $self->config;
  $__map    = $self->load_map;
  $__request_path = $self->get_request_path;
  $self;
}


sub load_map {
  my $self = shift;
  my $dir_conf = $__config->{PATH}{CONF}  ||  sprintf '%s/etc/conf', $__config->{PATH}{ROOT}  ||  '';
  my $map = {};

  if( -d $dir_conf ) {
    my $mapfile = $dir_conf . '/urlmap.yml';
    $map = -f $mapfile  ?  LoadFile( $mapfile )  :  {};
  }

  # マッピング内変数を抽出する
  if( exists $map->{__VAR__} ) {
    $__var4map = $map->{__VAR__}  ||  {};
    delete $map->{__VAR__};
  }

  $map;
}


sub get_request_path {
  my $self = shift;
  my $r = $self->request;

  # $ENV{REDIRECT_URL} は mod_rewrite 等でURLが書き換えられた場合（？）に入る

  my $url_home = $__config->{URL}{PATH_HOME}  ||  '\s*';
  my $request_uri = 
    #$ENV{REQUEST_URI} eq ( $ENV{REDIRECT_URL} || '' )
    $ENV{REQUEST_URI} eq ( $ENV{REDIRECT_URL} || $ENV{REQUEST_URI} )
      ?  $ENV{REQUEST_URI}  :  ( $ENV{REDIRECT_URL} || '' );
  # 2者が異なる場合，後者を優先．ex. 404 のような場合

  $request_uri =~ s/\?.*$//; # 末尾にクエリ文字列が残っている場合，これを削除
  $request_uri  = uri_unescape $request_uri;

  ( my $ret = $request_uri ) =~ s{/?($url_home)/?}{}x;
  $ENV{SABAE_REQUEST_PATH} = $ret;
}


sub __match_rule {
  my $self = shift;
  my $rule = shift  ||  {};
  my $path_re = $rule->{path_re} || $rule->{path_regexp} || '';

  my $re_var = qr/(?:\$([a-zA-Z0-9_]+ | \$\{([^\}]+)\}) )/x; # $hoge or ${hoge}
  1  while( $path_re =~ s/$re_var/$__var4map->{$1 || $2} || '';/gex );

  $__request_path =~ /$path_re/x;
}

sub url_to_action {
  my $self = shift;
  my $key = $self->key;
  my $action = {
    name  => '',
    param => {},
  };

  return $action  unless $key;

  my $urlmap = $__map->{$key}  ||  [];
  my $break = 0;
  for my $map ( @$urlmap ) {
    for my $rule ( @{$map->{rule}} ) {
      my @m;
      # REQUEST_PATH が一致
      if( exists $rule->{path}  &&  $__request_path eq $rule->{path} ) {
        $action->{name} = $map->{name}  ||  $map->{action};
        # const
        if( exists $rule->{const}  &&  ref $rule->{const} eq 'HASH' ) {
          for my $k ( keys %{$rule->{const}} ) {
            $action->{param}{$k} = $rule->{const}{$k}  ||  undef;
          }
        }
        $break = 1;
        last;
      }
      # REQUEST_PATH がマッチ
#      elsif(  ( exists $rule->{path_re}      &&  ( @m = $__request_path =~ m{$rule->{path_re}}x )     )  ||
#	      ( exists $rule->{path_regexp}  &&  ( @m = $__request_path =~ m{$rule->{path_regexp}}x ) )  ) {
      elsif( @m = $self->__match_rule($rule) ) {
        $action->{name} = $map->{name}  ||  $map->{action};
        # param
        if( exists $rule->{param}  &&  ref $rule->{param} eq 'ARRAY' ) {
          my $i = 0;
          for my $m ( @m ) {
            $rule->{param}->[ $i ]  ||  next;
            $action->{param}{ $rule->{param}->[$i] } = $m  ?  uri_unescape( $m )  :  undef;
            $i++;
          }
        }
        # const
        if( exists $rule->{const}  &&  ref $rule->{const} eq 'HASH' ) {
          for my $k ( keys %{$rule->{const}} ) {
            $action->{param}{$k} = $rule->{const}{$k}  ||  undef;
          }
        }
        $break = 1;
        last;
      }
    }
    last  if $break;
  }

  $action;
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
