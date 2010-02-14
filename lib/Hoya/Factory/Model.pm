package Hoya::Factory::Model;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Error qw/:try/;
use Hoya::Util;

__PACKAGE__->mk_accessors(qw/name env conf dsh/);


my $_name;
my $_env;
my $_conf;
my $_dsh;



sub init {
    my ($self) = self_param @_;
    $_name = $self->name;
    $_env  = $self->env;
    $_conf = $self->conf;
    $_dsh  = $self->dsh;

    my $model;

    try {
        my $pl   = $self->_load;
        my $code = $self->_generate_as_string($pl);
        eval $code;
        $model = eval << "...";
Hoya::Model::${_name}->new({
    env  => \$_env,
    conf => \$_conf,
    dsh  => \$_dsh,
})->init;
...
    }
    catch Error with {
        carp shift->text;
    };

    return $model;
}



sub _load {
    my $self = shift;
    my $pl = sprintf(
        '%s/%s.pl',
        $_conf->{PATH}{MODEL},
        name2path($_name),
    );

    my $buff;
    try {
        local $/;
        open my $fh, '<', $pl or die $!;
        $buff = de <$fh>;
        close $fh;
        $buff =~ s/__(?:END|DATA)__.*$//s; # __END__ 以降を削除する
    }
    catch Error with {
        #carp shift->text;
        my $text = sprintf(
            '[notice] Model file not found: %s',
            $_name,
        );
        carp $text;
        $buff = '';
    };

    return $buff;
}


sub _generate_as_string {
    my ($self, $pl) = @_;
    $pl ||= '';

    my $model_class = "Hoya::Model::${_name}";

    return sprintf(
        << '...',
package %s;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Error qw/:try/;
use Hoya::Util;

my $_env;
my $_conf;
my $_DSH;
my $_dsh;
my $_dsh_type;


__PACKAGE__->mk_accessors(qw/env conf dsh/);

sub init {
    my ($self) = self_param @_;
    $_env  = $self->env;
    $_conf = $self->conf;
    $_DSH  = $self->dsh;

    $_dsh_type = $self->dsh_type || 'YAML';
    $_dsh  = $_DSH->{$_dsh_type} || undef;

    $self;
}


sub dsh_type ($) {
    my $val_or_self = shift;
    # 引数が値の場合
    if (ref $val_or_self eq '') {
        $_dsh_type = $val_or_self;
    }
    # そうでない場合
    else {
        return $_dsh_type;
    }
}


# プラグインコード
%s


1;
__END__

init

========


dsh_type
...
        $model_class,
        $pl,
    );
}





1;
__END__

=head1 NAME

Hoya::Factory::Model - Generates "Model Class" dynamically.

=head1 SYNOPSIS

  use Hoya::Factory::Model;

=head1 DESCRIPTION

Hoya::Factory::Model is

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