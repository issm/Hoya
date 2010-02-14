# 指定のアクションを継承する
#super 'common';

# モデルを読み込む
#model 'sample', 'foo', 'bar';

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



__END__

=head1 DSL記述方法

=over 4

=item super $name;

アクション $name を継承します．

=item model $model1, $model2, ...;

モデル $model1，$model2，．．．を読み込みます．

例えば，
    model 'foo', 'bar';  # model qw/foo bar/; でもOK
とした場合，これらのモデルは，モデルハッシュ（Hash::MultiValueオブジェクト）$_mに対して
    $_m->{foo};
    $_m->get('foo');
のように参照することができます．

=item BEFORE {...};

リクエストメソッド特化処理の事前に処理を行います．メソッド共通です．

=item GET {...};

GETメソッドに特化した処理を行います．

=item POST {...};

POSTメソッドに特化した処理を行います．

=item AFTER {...};

リクエストメソッド特化処理の事後に処理を行います．メソッド共通です．

=back


=head1 利用可能変数

$_env    : 環境変数
$_conf   : 設定
$_m      : モデルハッシュ       # Hash::MultiValueオブジェクト
$_q      : HTTPクエリ          # Hash::Multivalueオブジェクト
$_qq     : URLマップパラメータ   # Hash::Multivalueオブジェクト
$_up     : アップロードファイル  # Hash::Multivalueオブジェクト
$_logger : ロガー # Log::Dispatch->logメソッドへのリファレンスa

=cut
