package Hoya::Controller;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use UNIVERSAL::require;
use Carp;
use Try::Tiny;

use Hoya::Util;
use Hoya::Mapper::URL;
use Hoya::MetaModel;
use Hoya::Factory::Action;
use Hoya::View;


#
sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors(qw/
        req conf app_name
        _logger _mm
    /);

    return $self->_init;
}

#
sub _init {
    my $self = shift;
    return $self;
}



sub go {
    my $self = shift;
    my $req  = $self->req;
    my $env  = $req->env;
    my $conf = $self->conf;

    # $env->{HOYA_SITE}, $env->{HOYA_SKIN} のいずれか/両方がセットされていない場合，終了
    if (
        (!exists $env->{HOYA_SITE} || $env->{HOYA_SITE} eq '')  ||
        (!exists $env->{HOYA_SKIN} || $env->{HOYA_SKIN} eq '')
    ) {
        croak '"HOYA_SITE" and/or "HOYA_SKIN" are/is not set, check them/it!';
    }

    # Plack::Response
    my $res = $req->new_response(404);

    #
    # logger
    #
    $self->_logger($env->{'psgix.logger'});

    #
    # metamodel
    #
    my $mm = Hoya::MetaModel->new({
        env  => $env,
        conf => $conf,
    });

    #
    # url mapping (dispatching)
    #
    my ($url_mapper, $action_info);
    $url_mapper = Hoya::Mapper::URL->new({
        env      => $req->env,
        conf     => $conf,
        app_name => $self->app_name,
    });
    $action_info = $url_mapper->get_action_info;

    #
    # q, qq, up
    #
    my ($q, $up) = $self->_decode_queries;
    my $qq = $action_info->{qq};  # Hash::MultiValueオブジェクト

    #
    # action
    #
    my ($view_info);
    my $action = Hoya::Factory::Action->new({
        name    => $action_info->{name},
        req     => $self->req,
        conf    => $conf,
        q       => $q,
        qq      => $qq,
        up      => $up,
        mm      => $mm,
        cookies => {},
        vars    => {
            __import__ => {},
        },
    });
    $view_info = $action->go;
    #
    # cookie発行の準備をする
    #
    $res->cookies(en $action->cookies);

    #
    # ビュー名がURL書式の場合：そのURLへのリダイレクト処理を行う
    #
    if ($view_info->{name} =~ qr{^(?:https?|ftp)://}) {
        my $url_to = $view_info->{name};
        $res->redirect($url_to);
    }
    #
    # レスポンスをセットアップする
    #
    else {
        $action->content_type(
            $self->conf->{CONTENT_TYPE_DEFAULT} || 'text/plain'
        )  unless $action->content_type;
        $action->charset('utf-8')  unless $action->charset;

        $res->status($action->status);
        $res->content_type(
            sprintf(
                '%s; charset=%s',
                $action->content_type,
                $action->charset,
            )
        );

        #
        # バイナリ出力モード
        #   ファイルハンドルまたはdataプロパティをレスポンスボディとする
        #
        if ($action->is_as_binary) {
            my $body = $action->_filehandle;
            $body = $action->data  unless defined $body;
            $res->content($body);
        }
        #
        # json出力モード
        #   戻り値をレスポンスボディとする
        #
        elsif ($action->is_as_json) {
            JSON->use;
            my $json = de JSON::encode_json($action->data || {});
            if (my $_callback = $q->get('callback')) {
                $json = "${_callback}(${json})";
            }

            $res->content(en $json);
        }
        #
        # xml出力モード
        #   戻り値をレスポンスボディとする
        #
        elsif ($action->is_as_xml) {
            XML::TreePP->use;
            # <response>...</response> のように挟むための準備
            my $data = {response => $action->data || {}};
            my $xml = XML::TreePP->new->write($data);
            $res->content(en $xml);
        }
        #
        # ビュー名がURL書式でない場合：通常の処理を行う
        #
        else {
            # view
            my $view = Hoya::View->new({
                name => $view_info->{name},
                type => $conf->{VIEW}{TYPE} || 'MT',
                env  => $req->env,
                conf => $conf,
                q    => $view_info->{q},
                qq   => $view_info->{qq},
                var  => $view_info->{var},
                action_name => $action->name,
            });
            #$view->no_escape(1);
            $view->go;

            $res->status($view->status)
                if defined $view->status;
            $res->content_type($view->content_type)
                if defined $view->content_type;

            $res->content($view->content);
        }
    }

    #
    # PSGI formatting
    #
    my $psgi = $res->finalize;
    #push @$psgi, [$conf->{SKIN_NAME}];
    # ^ PSGIフォーマットに「スキン」情報を追加
    # ^ Plack-0.9933でエラー．不要であれば，今後削除
    $mm->finish_dsh;
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
