dsh_type 'DBI';

sub sample {
    my $self = shift;

    my $sel = $_dsh->q('SELECT 1');
    $sel
}


__END__

=head1 利用可能変数

$_env    : 環境変数
$_conf   : 設定
$_dsh    : データソースハンドラ
$_logger : ロガー # Log::Dispatch->logメソッドへのリファレンスa
