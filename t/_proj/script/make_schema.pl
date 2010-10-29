#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "${FindBin::Bin}/../lib", "$ENV{HOME}/works/Hoya/master/lib";
use DBIx::Skinny::Schema::Loader qw/make_schema_at/;
use Hoya::Config::Core;
use Hoya::Util;

$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/..";

my $conf = Hoya::Config::Core->new->as_hashref->{DSH}{skinny};

print make_schema_at(
    'HoyaTest::DB::Test',
    {},
    [ "dbi:$conf->{TYPE}:$conf->{NAME}", $conf->{USER}, $conf->{PASSWD} ],
) . "\n";


__END__
