# $_env  : 環境変数
# $_conf : 設定
# $_q    : HTTPクエリ
# $_qq   : URLマップパラメータ
# $_mm   : メタモデル

# 指定のアクションを継承する
#super 'hogehoge';


# 事前処理（各種メソッド共通）
BEFORE {
    my $self = shift;

    $self->set_var(
        hello => 'Hello, world!',
    );

    '';
};


# GETメソッド処理
GET {
    my $self = shift;

    '';
};


# POSTメソッド処理
POST {
    my $self = shift;

    '';
};


# 事後処理（各種メソッド共通）
AFTER {
    my $self = shift;

    '';
};


#warn d "**** END: $_name";
