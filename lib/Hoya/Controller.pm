package Hoya::Controller;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Error qw/:try/;

use Hoya::Util;
use Hoya::Config;
use Hoya::Mapper::URL;
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
        env => $_env,
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

    # action
    my ($view_info);
    $_action = Hoya::Factory::Action->new({
    #Hoya::Factory::Action->new({
        name => $action_info->{name},
        req  => $self->req,
        conf => $_conf,
        q    => $_q,
        qq   => $_qq,
    })->init;
    $view_info = $_action->go;
    warn d $view_info;

    # view
    $_view = Hoya::View->new({
        env  => $req->{env},
        conf => $_conf,
        var  => {},
    })->init;
    $_view->go;

    my $res = $req->new_response(200);
    $res->content_type('text/html');
    #$res->content('Hello Plack!' . '@' . $self->app_name);
    $res->content($_view->content);
    $res->finalize;
}



1;
__END__
