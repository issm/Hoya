use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../extlib";

use Test::More qw/no_plan/;
#plan tests => 1;

use Hoya::Re;
use Hoya::Util;

my ($target, $cases) = (qr//, {});

sub test_these {
    die '$target need to be Regexp.'
        unless ref $target eq 'Regexp';

    for my $c_pass (@{$cases->{pass}}) {
        like $c_pass, $target;
    }

    for my $c_fail (@{$cases->{fail}}) {
        unlike $c_fail, $target;
    }
}

sub p {
    #diag "\n[35m", @_, "[m\n";
    #diag @_;
}


#--------------------------------------------------------------------------------
#
p 'NON_SPACE';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::NON_SPACE;
$cases  = {
    pass => [
        'a',
        'xxxx',
        'hoge fuga',
        ' a  ',
        ' a b c ',
        << '...',
     a
...
    ],

    fail => [
        '',
        ' ',
        << '...',
...
        << '...',

...
    ],
};
test_these;

#--------------------------------------------------------------------------------
#
p 'NUM';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::NUM;
$cases  = {
    pass => [
        '1',
        '123',
        '+45',
        '-678',
    ],
    fail => [
        ' 1',
        ' -2 ',
        '1+',
        '++1',
        '--1',
        '',
        'a',
        'abc',
    ],
};
test_these;

$target = Hoya::Re::NUM('^');
$cases  =  {
    pass => [
        1,
        +2,
        -3,
        '1',
        '+2',
        '-3',
        '1a',
        '+2b',
        '-3c',
        '1 ',
        '+2 ',
        '-3 ',
        '1324b',
    ],

    fail => [
        'a1',
        ' 1',
    ],
};
test_these;

$target = Hoya::Re::NUM('$');
$cases  =  {
    pass => [
        1,
        +2,
        -3,
        '1',
        '+2',
        '-3',
        'a1',
        'b+2',
        'c-3',
        'abc123',
        'def+456',
        'gh-789',
    ],

    fail => [
        ' 1 ',
        ' 2b',
    ],
};
test_these;

$target = Hoya::Re::NUM(' ');
$cases  =  {
    pass => [
        1,
        +2,
        -3,
        ' 1',
        ' +22',
        ' -333',
        '1 ',
        '+22 ',
        '-333',
        ' 1 ',
        ' +22 ',
        ' -333 ',
    ],

    fail => [
        ' 1a',
        ' +2b',
        ' -3c',
        'a1 ',
        'b+2 ',
        'c-3 ',
    ],
};
test_these;

#
$target = Hoya::Re::NUM(4);
$cases  = {
    pass => [
        '1324',
        '9999',
        '0000',
        '+9876',
        1_333,
    ],
    fail => [
        '333',
        '55555',
        ' -4434',
        '1_333',
    ],
};
test_these;

#
$target = Hoya::Re::NUM;
$cases  = {
    pass => [
        '1',
        2,
        -5,
        +3,
        10,
        '21',
        +134,
    ],
    fail => [
    ],
};
test_these;


#--------------------------------------------------------------------------------
#
p 'ALPHABET';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::ALPHABET;
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;


#--------------------------------------------------------------------------------
#
p 'ALPHANUM';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::ALPHANUM;
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;


#--------------------------------------------------------------------------------
#
p 'UNIQUE_KEY';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::UNIQUE_KEY;
$cases  = {
    pass => [
        (map unique_key, 1..100),
        (map unique_key(2), 1..100),
    ],

    fail => [
    ],
};
test_these;

$target = Hoya::Re::UNIQUE_KEY(7);
$cases  = {
    pass => [
        (map { substr(unique_key, 1); } 1..100),
    ],

    fail => [
        (map unique_key, 1..100),
    ],
};
test_these;

$target = Hoya::Re::UNIQUE_KEY(16);
$cases  = {
    pass => [
        (map unique_key(2), 1..100),
    ],

    fail => [
        (map unique_key(1), 1..100),
        (map unique_key(3), 1..100),
    ],
};
test_these;

$target = Hoya::Re::UNIQUE_KEY;
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;




#--------------------------------------------------------------------------------
#
p 'FLAG';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::FLAG;
$cases  = {
    pass => [
        '1',
        '0',
        1,
        0,
    ],

    fail => [
        '',
        -1,
        2,
        1.1,
    ],
};
test_these;

#--------------------------------------------------------------------------------
#
p 'HIRAGANA';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::HIRAGANA;
$cases  = {
    pass => [
        'あ',
        'あいうえお',
        'が',
        'ん',
    ],

    fail => [
        '',
        '愛',
        'あa',
        '　',
    ],
};
test_these;

$target = Hoya::Re::HIRAGANA(5);
$cases  = {
    pass => [
        'あいうえお',
        'がぎぐげご',
    ],

    fail => [
        'あ',
        'あい',
        'あいう',
        'あいうえ',
        'あいうえおお',
    ],
};
test_these;

$target = Hoya::Re::HIRAGANA('^');
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;

$target = Hoya::Re::HIRAGANA('$');
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;

$target = Hoya::Re::HIRAGANA(' ');
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;

#--------------------------------------------------------------------------------
#
p 'KATAKANA';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::KATAKANA;
$cases  = {
    pass => [
        'ア',
        'アイウエオ',
        'ガギグ',
        'ン',
    ],

    fail => [
        '',
        '愛',
        'アa',
        '　',
    ],
};
test_these;

$target = Hoya::Re::KATAKANA(5);
$cases  = {
    pass => [
        'アイウエオ',
        'ガギグゲゴ',
    ],

    fail => [
        '',
        'ア',
        'アイ',
        'アイウ',
        'アイウエ',
        'アイウエオオ',
    ],
};
test_these;

$target = Hoya::Re::KATAKANA('^');
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;

$target = Hoya::Re::KATAKANA('$');
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;

$target = Hoya::Re::KATAKANA(' ');
$cases  = {
    pass => [
    ],

    fail => [
    ],
};
test_these;



#--------------------------------------------------------------------------------
#
p 'HIRA_KATA';
#
#--------------------------------------------------------------------------------



#--------------------------------------------------------------------------------
#
p '_DOMAIN';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::DOMAIN;
$cases  = {
    pass => [
        'example.jp',
        'example.co.jp',
        'example.ne.jp',
        'example.or.jp',
        'example.com',
        'example.net',
        'example.org',
        'sub.example.jp',
        'bar.foo.example.jp',
        'baz.bar.foo.example.co.jp',
    ],

    fail => [
        '',
        'hoge',
    ],
};
test_these;


#--------------------------------------------------------------------------------
#
p 'EMAIL';
#
#--------------------------------------------------------------------------------
$target = Hoya::Re::EMAIL;
$cases  = {
    pass => [
        'user@example.com',
    ],

    fail => [
    ],
};
test_these;
