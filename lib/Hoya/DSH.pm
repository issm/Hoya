package Hoya::DSH;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Cache::FileCache;
use Carp;
use Try::Tiny;

use Hoya::Util;

# 動的ロードにすると5.8.8系でエラーが出る(?)ので，ひとまずここで読み込む
use Hoya::DSH::DBI; 
#use Hoya::DSH::YAML;

my $_env;
my $_conf;
my $_type;
my $_cache;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/env conf type/;

    return $self->_init;
}


sub _init {
    my $self = shift;
    $_env = $self->env;
    $_conf = $self->conf;
    $_type = $self->type;

    my $CACHE = $_conf->{CACHE};
    $_cache = Cache::FileCache->new({
        namespace          => $CACHE->{NAMESPACE},
        default_expires_in => $CACHE->{EXPIRES},
    });
    if ($CACHE->{LOCAL_TMP}) {
        $_cache->set_cache_root($_conf->{PATH}{FILECACHE});
    }

    my $dsh;
    my $dsh_class = "Hoya::DSH::${_type}";
    try {

        my $dsh = eval << "...";
use ${dsh_class};

${dsh_class}->new({
    env   => \$_env,
    conf  => \$_conf,
    cache => \$_cache,
});
...
        return $dsh;
    }
    catch {
        carp shift;
        return undef;
    };
}


1;
__END__

=head1 NAME

Hoya::DSH - "Data source handler".

=head1 SYNOPSIS

  use Hoya::DSH;

=head1 DESCRIPTION

Hoya::DSH is

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
