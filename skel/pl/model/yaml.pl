dsh_name 'yaml';


sub sample {
    my $self = shift;

    [];
}


__END__

=head1 利用可能変数

$self->env    : 環境変数
$self->conf   : 設定
$self->h      : データソースハンドラ
$self->logger : ロガー # Log::Dispatch->logメソッドへのリファレンスa
