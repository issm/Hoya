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
#use Hoya::MetaModel;
use Hoya::Factory::Action;
use Hoya::View;

my $_env;
my $_conf;

my $_q;  # クエリパラメータ群
my $_qq; # URLマッピングによって得られるパラメータ群
my $_mm; # metamodel
my $_action;
my $_view;



#
__PACKAGE__->mk_accessors(qw/req app_name/);

#
sub init {
    my $self = shift;

    # env
    $_env = $self->req->{env};
    # conf
    $_conf = Hoya::Config->new({
        req => $self->req,
    })->init->get;

    return $self;
}



sub go {
    my $self = shift;
    my $req = $self->req;

    # metamodel
    #$_mm = Hoya::MetaModel->new({
    #})->init;

    # url mapping
    my ($url_mapper, $action_info);
    $url_mapper = Hoya::Mapper::URL->new({
        env      => $_env,
        conf     => $_conf,
        app_name => $self->app_name,
    })->init;
    $action_info = $url_mapper->get_action_info;

    # q, qq
    $_q  = de $req->parameters;
    $_qq = $action_info->{qq};

    # ua mapping
    my ($ua_mapper, $ua_info);
    $ua_mapper = Hoya::Mapper::UserAgent->new({
        env  => $_env,
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
