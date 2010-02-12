package Hoya::Controller;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Error qw/:try/;

use Hoya::Util;
use Hoya::Config;
use Hoya::Mapper::URL;
use Hoya::Mapper::UserAgent;
use Hoya::MetaModel;
use Hoya::Factory::Action;
use Hoya::View;

my $_env;
my $_conf;

my $_q;  # クエリパラメータ群
my $_qq; # URLマッピングによって得られるパラメータ群
my $_up; # Plack::Request::Uploadオブジェクトの集合

my $_mm; # メタモデル（Hoya::MetaModelオブジェクト）
my $_action;
my $_view;



#
__PACKAGE__->mk_accessors(qw/req app_name/);

#
sub init {
    my $self = shift;

    $_env = $self->req->{env};
    $_conf = Hoya::Config->new({
        req => $self->req,
    })->init->get;

    $_q  = {}; # Hash::MultiValueオブジェクト
    $_qq = {}; # Hash::MultiValueオブジェクト
    $_up = {}; # Hash::MultiValueオブジェクト

    return $self;
}



sub go {
    my $self = shift;
    my $req = $self->req;

    # metamodel
    $_mm = Hoya::MetaModel->new({
        env  => $_env,
        conf => $_conf,
    })->init;

    # url mapping
    my ($url_mapper, $action_info);
    $url_mapper = Hoya::Mapper::URL->new({
        req      => $req,
        conf     => $_conf,
        app_name => $self->app_name,
    })->init;
    $action_info = $url_mapper->get_action_info;

    # q, qq, up
    $_q  = de $req->parameters; # Hash::MultiValueオブジェクト
    $_qq = $action_info->{qq};  # Hash::MultiValueオブジェクト
    $_up = $req->uploads;       # Hash::MultiValueオブジェクト

    # ua mapping
    my ($ua_mapper, $ua_info);
    $ua_mapper = Hoya::Mapper::UserAgent->new({
        req  => $req,
        conf => $_conf,
    })->init;
    $ua_info = $ua_mapper->get_info;
    $_conf->{UA_INFO} = $ua_info;

    # skin
    $_conf->{SKIN_NAME} = $_conf->{UA_INFO}{name} || 'default';

    # action
    my ($view_info);
    $_action = Hoya::Factory::Action->new({
        name => $action_info->{name},
        req  => $self->req,
        conf => $_conf,
        q    => $_q,
        qq   => $_qq,
        up   => $_up,
        mm   => $_mm,
    })->init;
    $view_info = $_action->go;

    # view
    $_view = Hoya::View->new({
        name => $view_info->{name},
        type => 'MT',
        env  => $req->{env},
        conf => $_conf,
        q    => $view_info->{q},
        qq   => $view_info->{qq},
        var  => $view_info->{var},
        action_name => $_action->name,
    })->init;
    #$_view->no_escape(1);
    $_view->go;


    # Plack::Response
    my $res = $req->new_response(200);
    $res->content_type('text/html');
    $res->content($_view->content);
    my $psgi = $res->finalize;  # PSGIフォーマット

    push @$psgi, [$_conf->{SKIN_NAME}];
    # ^ PSGIフォーマットに「スキン」情報を追加

    return $psgi;
}



1;
__END__
