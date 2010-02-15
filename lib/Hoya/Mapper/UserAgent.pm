package Hoya::Mapper::UserAgent;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use YAML::Syck;
use Carp;
use Try::Tiny;
use Hoya::Util;

our $UA_DEFAULT = 'default';

my $_req;
my $_env;
my $_conf;

my $_map_var;
my $_map_rule;


my $__map = [];


__PACKAGE__->mk_accessors(qw/req env conf/);


sub init {
  my $self = shift;
  $_req  = $self->req;
  $_env  = $_req->env;
  $_conf = $self->conf;

  $self->_load;

  $self;
}

sub _load {
  my $self = shift;
  my $mapfile = sprintf(
      '%s/uamap.yml',
      $_conf->{PATH}{CONF},
  );

  try {
      my $yaml = LoadFile($mapfile);
      $_map_var = $yaml->{__VAR__} || {};
      $_map_rule = $yaml->{rule} || [];
  }
  catch {
      carp shift;
  };

  1;
}


sub get_info {
    my ($self) = @_;
    my $ua_info = {
        name => 'default',
    };

    my $ua = $_req->user_agent;

    my ($matched, $rule_applied);

    my $re_var = qr/(?:\$([a-zA-Z0-9_]+) | \$\{([^\}]+)\} )/x;

    for my $pair (@$_map_rule) {
        my $re_ua = (keys %$pair)[0];
        my $re_ua_eval = $re_ua;
        # $re_ua内の「変数」を展開する
        1 while (
            $re_ua_eval =~ s/$re_var/$_map_var->{$1 || $2} || '';/gex
        );
        # v 以前にマッチしていなければ，パタンマッチを試みる
        unless ($matched) {
            $matched = ($ua =~ qr/$re_ua_eval/ix) ? 1 : 0;
        }
        # v マッチした，または，以前にマッチしている
        if ($matched) {
            my $rule = $pair->{$re_ua};
            if (defined $rule) {
                $rule_applied = $rule;
                last;
            }
        }
    }

    if (defined $rule_applied) {
        $ua_info->{name} = shift @$rule_applied;
    }

    return $ua_info;
}





1;
__END__

=head1 NAME

Hoya::Mapper::UserAgent - Maps user agent info to "skin" info uner the "rule".

=head1 SYNOPSIS

  use Hoya::Mapper::UserAgent;

=head1 DESCRIPTION

Hoya::Mapper::UserAgent is

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
