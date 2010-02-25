package Hoya::Controller;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Try::Tiny;

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

my $_logger;
my $_mm; # メタモデル（Hoya::MetaModelオブジェクト）
my $_action;
my $_view;

#
sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors qw/req app_name/;

    return $self->_init;
}

#
sub _init {
    my $self = shift;

    $_env = $self->req->env;
    $_conf = Hoya::Config->new({
        req => $self->req,
    })->get;
    $_q  = {}; # Hash::MultiValueオブジェクト
    $_qq = {}; # Hash::MultiValueオブジェクト
    $_up = {}; # Hash::MultiValueオブジェクト

    return $self;
}



sub go {
    my $self = shift;
    my $req = $self->req;

    # Plack::Response
    my $res = $req->new_response(404);

    #
    # logger
    #
    $_logger = $_env->{'psgix.logger'};

    #
    # metamodel
    #
    $_mm = Hoya::MetaModel->new({
        env  => $_env,
        conf => $_conf,
    });

    #
    # url mapping (dispatching)
    #
    my ($url_mapper, $action_info);
    $url_mapper = Hoya::Mapper::URL->new({
        req      => $req,
        conf     => $_conf,
        app_name => $self->app_name,
    });
    $action_info = $url_mapper->get_action_info;

    #
    # q, qq, up
    #
    ($_q, $_up) = $self->_decode_queries;
    $_qq = $action_info->{qq};  # Hash::MultiValueオブジェクト

    #
    # user agent mapping
    #
    #my ($ua_mapper, $ua_info);
    #$ua_mapper = Hoya::Mapper::UserAgent->new({
    #    req  => $req,
    #    conf => $_conf,
    #});
    #$ua_info = $ua_mapper->get_info;
    #$_conf->{UA_INFO} = $ua_info;

    #
    # skin
    #
    #$_conf->{SKIN_NAME} = $_conf->{UA_INFO}{name} || 'default';

    #
    # action
    #
    my ($view_info);
    $_action = Hoya::Factory::Action->new({
        name => $action_info->{name},
        req  => $self->req,
        conf => $_conf,
        q    => $_q,
        qq   => $_qq,
        up   => $_up,
        mm   => $_mm,
    });
    $view_info = $_action->go;

    #
    # cookieを発行する
    #
    $res->cookies(en $_action->cookies);

    #
    # ビュー名がURL書式の場合：そのURLへのリダイレクト処理を行う
    #
    if ($view_info->{name} =~ qr{^(?:https?|ftp)://}) {
        my $url_to = $view_info->{name};
        $res->redirect($url_to);
    }
    #
    # ビュー名がURL書式でない場合：通常の処理を行う
    #
    else {
        $res->status($_action->status);
        $res->content_type($_action->content_type);

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
        });
        #$_view->no_escape(1);
        $_view->go;

        $res->status($_view->status)
            if defined $_view->status;
        $res->content_type($_view->content_type)
            if defined $_view->content_type;

        $res->content($_view->content);
    }

    #
    # PSGI formatting
    #
    my $psgi = $res->finalize;
    push @$psgi, [$_conf->{SKIN_NAME}];
    # ^ PSGIフォーマットに「スキン」情報を追加

    return $psgi;
}



sub _decode_queries {
    my $self = shift;
    my ($q, $up);
    my $req = $self->req;

    $q  = de $req->parameters; # Hash::MultiValueオブジェクト
    $up = $req->uploads;       # Hash::MultiValueオブジェクト

    $up->each(
        sub {
            my (undef, $f) = @_;
            $f->{filename} = de $f->filename;
        }
    );

    return ($q, $up);
}



1;
__END__

=head1 NAME

Hoya::Controller - "Controller" class.

=head1 SYNOPSIS

  use Hoya;

=head1 DESCRIPTION

Hoya::Controller is

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
