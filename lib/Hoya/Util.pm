package Hoya::Util;
use strict;
use warnings;
use utf8;
use base qw/Exporter/;
use UUID::Tiny;
use Encode;
use Data::Recursive::Encode;
use Data::Dumper qw/Dumper/;
use Data::Dump qw/dump ddx/;
use Hash::Merge qw/merge/;
use Hash::MultiValue;
use Carp;
use Try::Tiny;

our @EXPORT = qw/
                    self_param
                    name2path
                    d
                    D
                    printlog
                    random_key
                    en
                    de
                    is_def
                    merge_hash
                    notify
                /;

Hash::Merge::set_behavior('RIGHT_PRECEDENT');


sub new {
    my ($self, $classname) = ( {}, shift );
    my %param = @_;
    bless($self, $classname);
    $self->{$_} = $param{$_}  for keys %param;
    $self->init(@_);
    $self;
}


sub init {
  my ($self, $param) = self_param(@_);
  #warn __PACKAGE__, " -> ", ( caller )[0];
}



sub self_param {
    #@_ = @$_[0]  if( ref $_[0] eq 'ARRAY' );
    return  (scalar @_) % 2
        ?  (shift, defined @_ ? {@_} : {})
        :  ({}, defined @_ ? {@_} : {})
    ;
}


sub name2path {
    # v 第1引数がスカラの場合，$self = {} → OO的メソッドと直接呼び出しのどちらにも対応（のつもり）
    my $self = ref $_[0]  ?  shift  :  {};
    my $path = shift || $self->{name} || '';
    $path =~ s{_}{/}g;
    $path =~ s{^/}{_};
    $path =~ s{//}{/_}g;
    return $path;
}




sub d { dump @_; }
sub D { Dumper @_; }


sub printlog {
    my ($fmt, @vars) = @_;
    my @t = reverse((localtime time)[0..5]);
    $t[0] += 1900; $t[1]++;
    printf(
        "[%s] %s\n",
        sprintf('%04d-%02d-%02d %02d:%02d:%02d', @t),
        sprintf($fmt, @vars)
    );
}




sub random_key {
    my $n = shift || 1;
    my $s = shift;

    my $ret = '';
    my $uuid_n = join '', map {
        my $uuid = defined $s
            ? create_UUID(UUID_V3, $s) : create_UUID();
        UUID_to_string($uuid);
    } 1 .. $n;
    $uuid_n =~ s/-//g;

    my @map = qw/ 0 1 2 3 4 5 6 7 8 9 _ -
                  a b c d e f g h i j k l m n o p q r s t u v w x y z
                  A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
                /;
    my @c = split '', $uuid_n;

    while (@c) {
        my @a = (shift @c, shift @c, shift @c, shift @c);
        my $sum = 0;
        for my $a (@a) {
            $sum += eval(sprintf '0x%s', ($a||'00')) || 0;
        }
        $ret .= $map[$sum];
    }
    return $ret;
}


sub en {
    my ($data, $charset_to) = @_;
    $data = ''  unless defined $data;
    $charset_to = 'utf-8'  unless defined $charset_to;
    my $ref = ref $data;
    # SCALAR
    if ($ref eq '') {
        return encode($charset_to, $data);
    }
    # ARRAY / HASH
    elsif ($ref =~ /^(ARRAY|HASH)$/) {
        return Data::Recursive::Encode->encode($charset_to, $data);
    }
    # Hash::MultiValue
    elsif ($ref eq 'Hash::MultiValue') {
        my $flatten = [$data->flatten];
        $flatten = Data::Recursive::Encode->encode($charset_to, $flatten);
        return Hash::MultiValue->new(@$flatten);
    }
}


sub de {
    my ($data, $charset_from) = @_;
    $data = ''  unless defined $data;
    $charset_from = 'utf-8'  unless defined $charset_from;
    my $ref = ref $data;
    # SCALAR
    if ($ref eq '') {
        try {
            return decode($charset_from, $data);
        }
        catch {
            return $data;
        };
    }
    # ARRAY / HASH
    elsif ($ref =~ /^(ARRAY|HASH)$/) {
        try {
            return Data::Recursive::Encode->decode($charset_from, $data);
        }
        catch {
            return $data;
        };
    }
    # Hash::MultiValue object
    elsif ($ref eq 'Hash::MultiValue') {
        try {
            my $flatten = [$data->flatten];
            $flatten = Data::Recursive::Encode->decode($charset_from, $flatten);
            return Hash::MultiValue->new(@$flatten);
        }
        catch {
            return $data;
        };
    }
}


sub is_def {
    my @vars = @_;
    return 0  unless @vars;

    my $defined = 1;
    while (@vars) {
        my $v = shift @vars;
        $defined &&= (defined $v ? 1 : 0);
        last  unless $defined;
    }
    $defined;
}


sub merge_hash {
    my ($hash1, $hash2) = @_;
    return merge($hash1, $hash2);
}


sub notify {
    my $message = shift;

    try {
        eval 'use Log::Dispatch::DesktopNotification;';
        my $logger = Log::Dispatch::DesktopNotification->new(
            name      => 'notify',
            min_level => 'debug',
            app_name  => en('Hoya notification'),
            title     => en('Hoya::Util::notify'),
            sticky    => 1,
            priority  => 2,
        );
        #eval 'use Log::Dispatch::MacGrowl;';
        #my $logger = Log::Dispatch::MacGrowl->new(
        #);
        $logger->log(
            level   => 'debug',
            message => en($message) ,
        );
    }
    catch {
    };
}



1;
__END__

=head1 NAME

Hoya::Util - Utilities.

=head1 SYNOPSIS

  use Hoya::Util;

=head1 DESCRIPTION

Hoya::Util is

=head1 EXPORTED FUNCTIONS

=over 4

=item name2path($name)

$path = name2path('foo_bar_baz');  # 'foo/bar/baz'

=item d($var)

synonym for "Dumper()" using Data::Dumper.

=item D($var)

synonym for "Data::Dumper->Dump()".

=item en($data [, $charset_to])

Encodes $data to character set $charset_to. $charset_to default to 'utf-8'.

Encodes each data recursively, if $data is complex (hashref or arrayref).

Encodes each pair, if $data is Hash::MultiValue object.

=item de($data [, $charset_from])

Decodes $data to utf-8 from character set $charset_from. $charset_from default to 'utf-8'.

Decodes each data recursively, if $data is complex (hashref or arrayref).

Decodes each pair, if $data is Hash::MultiValue object.

=item is_def($var1, $var2, ...)

Returns "TRUE" if all arguments ($var1, $var2, ...) are defined. Otherwise, returns "FALSE".

=item merge_hash(\%hash1, \%hash2)

Merges hashref \%hash2 to \%hash1 and returns hashref which is merged.

Using Hash::Merge.

=item random_key([$n, $str])

Returns "random" string with length a multiple of 8 (8 * $n). Defaut, $n is set to 1.

If $str is set, return "hashed" string based on $str.

=item notify($message);

Notify.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
