package Hoya::Model;
use strict;
use warnings;
use utf8;
use parent qw/Class::Accessor::Fast/;
use Params::Validate qw/:all/;
use Hash::MultiValue;
use Data::Page;
use Carp;
use Try::Tiny;
use Hoya::Re;
use Hoya::Util;

our $dsh_name = 'skinny';

my @accessors = qw/name env conf dsh h
                   _dsh_name _logger
                  /;

__PACKAGE__->mk_accessors(@accessors);


# パラメータのバリデーションに問題があった場合の処理
validation_options(
    on_fail => sub {
        croak @_;
    },
);



# sub import {
#     my $class = shift;
#     my $caller = caller(0);
#     my @EXPORT = qw//;
#     no strict 'refs';
#     for my $f (@EXPORT) {
#         *{"$caller\::$f"} = \&{"$f"};
#     }
# }





sub new {
    my ($class, $params) = @_;
    my $self = bless $class->SUPER::new($params), $class;
    return $self->_init;
}


sub _init {
    my $self = shift;
    $self->_logger( $self->env->{'psgix.logger'} );

    {
        no strict 'refs';
        my $ref = ref($self);
        $self->_dsh_name( ${"$ref\::dsh_name"} || $Hoya::Model::dsh_name );
        $self->h( $self->dsh->{ $self->_dsh_name } );
    };

    return $self;
}





# # dsh_typeメソッドと同義
# sub dsh_name {
#     my $self_or_name = shift;
#     my $ref = ref($self_or_name);

#     no strict 'refs';

#     # 関数呼び出し
#     if ($ref eq '') {
#         my $caller = caller(0);
#         ${"$caller\::dsh_name"} = $self_or_name;
#         return $self_or_name;
#     }
#     # メソッド呼び出し
#     elsif ($ref =~ /^[^:]+::Model::/) {
#         my $name = shift;
#         ${"$ref\::dsh_name"} = $name;
#         return $name;
#     }
# }

# sub dsh_type { dsh_name(@_); }


# sub hogehoge {
#     my $self = shift;
# }




1;
__END__

=head1 NAME

Hoya::Model - Basic "model" class.

=head1 SYNOPSIS

  use Hoya::Model;

=head1 DESCRIPTION

Hoya::Model is

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
