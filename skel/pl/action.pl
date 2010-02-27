# アクションを継承する
#a->super qw/common/;

# モデルを読み込む
#my @models = a->model qw/sample foo bar/;

# 事前処理（各種メソッド共通）
BEFORE {
    a->var('hello', 'Hello, world!');

    '';
};


# GETメソッド処理
GET {

    '';
};


# POSTメソッド処理
POST {

    '';
};


# 事後処理（各種メソッド共通）
AFTER {

    '';
};



__END__

=head1 DSL記述方法

=over 4

=item BEFORE {...};

リクエストメソッド特化処理の事前に処理を行います．メソッド共通です．

=item GET {...};

GETメソッドに特化した処理を行います．

=item POST {...};

POSTメソッドに特化した処理を行います．

=item AFTER {...};

リクエストメソッド特化処理の事後に処理を行います．メソッド共通です．


=item a

 アクションオブジェクトへの参照です．

=item a->super($name);

アクション $name を継承します．

=item a->model($model1, $model2, ...);

モデル $model1，$model2，．．．を読み込みます．

=item a->var($name, $value);

=item a->var($name);

ビューで参照可能な変数をセットします．また，セットした変数を取得します．

=item a->cookie($name)

指定した名前に対応するCookieの値を取得します．リクエストに含まれているCookieが対象です．

=item a->cookie($name, $value);

指定した名前と値でCookieを設定します．レスポンスオブジェクトが対象となります．

=item a->remove_cookie($name);

指定した名前のCookieを削除します．

=item a->session($name);

=item a->session($name, $value);

セッション情報を取得・設定します．

=item a->remove_session($name);

セッション情報のうち，指定した名前のものを削除します．

=back


=head1 その他利用可能なメソッド

a->req    : リクエストオブジェクト（Plack::Request/HTTPx::Webletオブジェクト）
a->env    : 環境変数
a->conf   : 設定
a->q      : HTTPクエリ          # Hash::Multivalueオブジェクト
a->qq     : URLマップパラメータ   # Hash::Multivalueオブジェクト
a->up     : アップロードファイル  # Hash::Multivalueオブジェクト
a->logger : ロガー # Log::Dispatch->logメソッドへのリファレンス

=cut
