dsh_type 'DBI';

# $_env  : 環境変数
# $_conf : 設定
# $_dsh  : データソースハンドラ


sub sample {
    my $self = shift;

    my $sel = $_dsh->q('SELECT 1');
    $sel
}
