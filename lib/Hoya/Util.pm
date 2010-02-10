package Hoya::Util;
use strict;
use warnings;
use utf8;
use base qw/Exporter/;
use UUID::Tiny;
use Encode;
use Data::Recursive::Encode;
use Data::Dumper qw/Dumper/;
use Hash::Merge qw/merge/;
use Error;

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
                /;
our %EXPORT_TAGS = (
    base  => [
        qw/
              self_param
              name2path
              random_key
              en
              de
              is_def
              merge_hash
          /
      ],
    debug => [
        qw/
              printlog
              d
              D
          /
      ],
);


Hash::Merge::set_behavior('RIGHT_PRECEDENT');


#
#  コンストラクタ
#
sub new {
    my ($self, $classname) = ( {}, shift );
    my %param = @_;
    bless($self, $classname);
    $self->{$_} = $param{$_}  for keys %param;
    $self->init(@_);
    $self;
}


#
#  初期化する
#
sub init {
  my ($self, $param) = self_param(@_);
  #warn __PACKAGE__, " -> ", ( caller )[0];
}



#
#  exported
#  自身への参照とパラメータハッシュリファレンスを取得する
#
sub self_param {
    #@_ = @$_[0]  if( ref $_[0] eq 'ARRAY' );
    return  (scalar @_) % 2
        ?  (shift, defined @_ ? {@_} : {})
        :  ({}, defined @_ ? {@_} : {})
    ;
}


#
#  exported and OO
#  自身もしくは指定したの名前にちなんだパス的文字列を取得する
#  ex.  dir_hoge_index  -> dir/hoge/index
#  ex.  _hoge_fuga_piyo -> _hoge/fuga/piyo
#
#  @return  scalar
#
sub name2path {
    # v 第1引数がスカラの場合，$self = {} → OO的メソッドと直接呼び出しのどちらにも対応（のつもり）
    my $self = ref $_[0]  ?  shift  :  {};
    my $path = shift || $self->{name} || '';
    $path =~ s{_}{/}g;
    $path =~ s{^/}{_};
    $path =~ s{//}{/_}g;
    return $path;
}




#  exported
#  Data::Dumper::Dumper のラッパ的なもの
sub d { Dumper @_; }
sub D { Data::Dumper->Dump(@_); }


#  exported
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



#  exported
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


# exported
# en($data, $charset_to);
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
}

# exported
# de($data, $charset_from);
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
        catch Error with {
            return $data;
        };
    }
    # ARRAY / HASH
    elsif ($ref =~ /^(ARRAY|HASH)$/) {
        try {
            return Data::Recursive::Encode->decode($charset_from, $data);
        }
        catch Error with {
            return $data;
        };
    }
}


# exported
# is_def($var1, $var2, ...);
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


# exported
# merge_hash(\%hash1, \%hash2);
sub merge_hash {
    my ($hash1, $hash2) = @_;
    return merge($hash1, $hash2);
}



1;

