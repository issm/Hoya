dsh_type 'DBI';

sub sample {
    my $self = shift;

    my $sel = $_dsh->q('SELECT 1');
    $sel
}


__END__
$_env  : 環境変数
$_conf : 設定
$_dsh  : データソースハンドラ
