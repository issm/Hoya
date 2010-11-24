use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../extlib";

use Test::More;
use Test::These;
use Hoya::Util;


test_these {
    case +{
        p00 => 'foo',
        p01 => 'foo_bar',
        p02 => 'foo_bar_baz',

        p11 => 'foo-bar',
        p12 => 'foo-bar-baz',

        p21 => 'foo_bar-baz',
        p22 => 'foo-bar_baz',
    };

    code { name2class(shift) };

    success_each +{
        p00 => sub { is shift, 'Foo' },
        p01 => sub { is shift, 'Foo::Bar' },
        p02 => sub { is shift, 'Foo::Bar::Baz' },

        p11 => sub { is shift, 'FooBar' },
        p12 => sub { is shift, 'FooBarBaz' },

        p21 => sub { is shift, 'Foo::BarBaz' },
        p22 => sub { is shift, 'FooBar::Baz' },
    };

    error_each +{
        p00 => sub { fail 'Should pass: ' . shift },
        p01 => 'p00',
        p02 => 'p00',

        p11 => 'p00',
        p12 => 'p00',

        p21 => 'p00',
        p22 => 'p00',
    };
};



done_testing;
