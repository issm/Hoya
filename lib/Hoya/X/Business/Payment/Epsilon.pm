package Hoya::X::Business::Payment::Epsilon;
use strict;
use warnings;
use parent qw/Hoya::X::Business::Payment/;
use Encode;
use Data::Recursive::Encode;
use XML::Simple;
use HTML::TreeBuilder;
use HTML::Entities;
use URI::Escape;
use HTTP::Request;
use HTTP::Request::Common;
use Try::Tiny;
use Hoya::Util;


__PACKAGE__->mk_accessors qw/contract_code passwd
                             _conf
                            /;


my $_conf = {
    url => {
        submit_method => '',
        get_sales    => '',
    },
};

my $_conf_test = {
    url => {
        submit_method => 'https://beta.epsilon.jp/cgi-bin/order/receive_order3.cgi',
        get_sales    => 'https://beta.epsilon.jp/client/getsales.cgi',
    },
};


sub _init {
    my ($self, $param) = @_;
    $self->_conf( $self->is_test ? $_conf_test : $_conf );
    return $self;
}



sub submit_method {
    my ($self, $param) = @_;
    $self->status(1);

    my $type = $param->{type};
    my $data = $param->{data};

    my $conf = $self->_conf;

    my $q = {
        contract_code => $self->contract_code,
        process_code  => 1,
        mission_code  => 1,
        xml           => 1,
    };

    for my $k (
        qw/user_id user_name user_name_kana user_mail_add user_tel
           item_code item_name item_price
           order_number
           st_code mission_code process_code conveni_code
           card_code card_number expire_m expire_y
           memo1 memo2
          /,
    ) {
        $q->{$k} = encode('cp932', $data->{$k})  if defined $data->{$k};
    }

    my $res = $self->ua->post($conf->{url}{submit_method}, $q);
    my $doc = $self->_parse_xml($res->content);

    my $result = {};
    for my $i ( @{$doc->{result}} ) {
        while ( my ($k, $v) = each %$i ) {
            $result->{$k} = $v;
        }
    }
    $self->result( $result );

    return $self->result->{result};
};


sub submit_card_info {
    my ($self, $param) = @_;
    my $result = {};
    my $target_url = $self->result->{redirect};

    my ($res, $html);

    $res = $self->ua->get($target_url);
    $html = $res->content;
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($html);
    $tree->elementify;
    my $e = $tree->look_down('name', 'trans_code');
    my $tx_code = $e->attr('value');
    $tree->delete;

    my $q = {
        trans_code  => $tx_code,
        card_code   => $param->{card_code},
        card_number => $param->{card_number},
        expire_m    => $param->{expire_m},
        expire_y    => $param->{expire_y},
        auth        => decode('utf-8', '登 録 Confirm'),
        xml         => 1,
    };
    $q->{$_} = encode('cp932', $q->{$_})  for keys %$q;

    $res = $self->ua->post($target_url, $q);
    my $headers = $res->headers;

    my $url_redirect = $headers->header('Location') || '';

    # 決済完了
    if ($url_redirect) {
        $result = {
            result   => 1,
            redirect => $url_redirect,
        };
    }
    # エラー
    else {
        $result = {
            result      => 0,
            error_code  => 1,
            error_text  => decode('utf-8', '申し訳ございません。通信上のエラーが発生しました。'),
        };

        $html = decode('cp932', $res->content);

        $tree = HTML::TreeBuilder->new;
        $tree->parse($html);

        # 経験に基づく
        my ($e_error) = $tree->look_down(
            _tag  => 'font',
            color => '#B20026',
        );
        if (defined $e_error) {
            $result->{error_text} = decode_entities( $e_error->{_content}[0] );
            ( $result->{error_code} ) = $result->{error_text} =~ /^(\d+):/;
        }

        $tree->delete;
    }

    $self->result( $result );
    return $result;
}




sub get_sales {
    my ($self, $param) = @_;
    my $tx_code    = $param->{tx_code};
    my $order_code = $param->{order_code};

    my $conf = $self->_conf;

    my $params_post = {};
    if (defined $tx_code)       { $params_post->{trans_code} = $tx_code; }
    elsif (defined $order_code) { $params_post->{order_number} = $order_code; }
    else {
        return;
    }

    my $req = POST  $conf->{url}{get_sales}, $params_post;
    $req->authorization_basic($self->contract_code, $self->passwd);

    my $res = $self->ua->request($req);
    my $doc = $self->_parse_xml($res->content);

    my $info = {};
    for my $i (@{$doc->{result}}) {
        for my $ii (keys %$i) {
            ($info->{$ii} = $i->{$ii}) =~ s/\+/ /g;
        }
    }

    return $info;
}



sub _parse_xml {
    my ($self, $xml) = @_;
    $xml = decode( 'cp932', uri_unescape($xml) );
    $xml =~ s/x-sjis-cp932/utf-8/;
    $xml =~ s/\&/&amp;/g;

    my $doc;
    try {
        $doc = XML::Simple::XMLin($xml, ForceArray => 1);
    }
    catch {
        local $Hoya::Util::DUMP_PREFIX = "[31m";
        warn Dc shift;
    };

    return $doc;
}



sub set_url {
    my ($self, $param) = @_;
    my $conf = $self->_conf;
    return $conf->{url}  if $self->is_test;

    while (my ($k, $v) = each %$param) {
        $conf->{url}{$k} = $v;
    }
    return $conf->{url};
}



1;
__END__

=head1 NAME

Hoya::X::Business::Payment::Epsilon - hoge.

=head1 SYNOPSIS

  use Hoya::X::Business::Payment;

=head1 DESCRIPTION

Hoya::X::Business::Payment is hoge.

=head1 CONSTRUCTOR

  $epsilon = Hoya::X::Business::Payment->new({
      type          => 'epsilon',
      test          => $is_test,
      contract_code => $contract_code,
      passwd        => $passwd,
  });

=head1 METHODS

=over 4

=item $result = $epsilon->submit_step1(\%params);

=item $sales_info = $epsilon->get_sales(\%params);

=item $epsilon->set_url(\%params);

Sets URL to send request to Epsilon.

This method works only in non "test" env. ($epsilon->is_test is "false")

=item $doc =  $epsilon->_parse_xml($xml_string);

=back


=cut
