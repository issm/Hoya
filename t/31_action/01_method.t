use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../../extlib", "${FindBin::Bin}/../_proj/lib";
use Test::More;
use Test::These;
use Hoya::Config::Core;
use Hoya::Util;
use Hoya::MetaModel;
use Hoya::Action;
use Plack::Request;
use Hash::MultiValue;


BEGIN {
    use_ok 'Hoya::Action';
}


$ENV{HOYA_PROJECT_ROOT} = "${FindBin::Bin}/../_proj";


my $conf = Hoya::Config::Core->new->as_hashref;
my $req  = Plack::Request->new(\%ENV);
my $q    = Hash::MultiValue->new(
    hoge => 1,
    fuga => 'b',
);
my $qq   = Hash::MultiValue->new(
    foo => 'x',
    bar => 2,
);
my $mm   = Hoya::MetaModel->new({ env => \%ENV, conf => $conf });


my $params = {
    name          => 'test',
    req           => $req,
    conf          => $conf,
    q             => $q,
    qq            => $qq,
    up            => $req->uploads,
    mm            => $mm,
    cookies       => {},
    vars          => {},
    # base_name     => $self->base_name || $self->name,
    # sub_name      => $self->sub_name,
    # backward_name => $self->backward_name,
};





#--------------------------------------------------------------------------------
#
# ->q_fill_empty
#
#--------------------------------------------------------------------------------

{
    my $a = Hoya::Action->new($params);
    my $q = $a->q;

    isnt $q->get('hoge'), undef;
    isnt $q->get('fuga'), undef;
    is $q->get('foo'), undef;
    is $q->get('bar'), undef;
    is $q->get('baz'), undef;

    $a->q_fill_empty(qw/foo bar/);

    isnt $q->get('hoge'), '';
    isnt $q->get('fuga'), '';
    is $q->get('foo'), '';
    is $q->get('bar'), '';
    is $q->get('baz'), undef;
}



done_testing;
