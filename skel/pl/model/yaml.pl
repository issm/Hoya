dsh_type 'YAML';


sub sample {
    my $self = shift;

    [];
}


__END__

=head1 利用可能変数

$_env    : 環境変数
$_conf   : 設定
$_dsh    : データソースハンドラ
$_logger : ロガー # Log::Dispatch->logメソッドへのリファレンスa
