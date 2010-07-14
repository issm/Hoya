dsh_name 'skinny';

sub hoge {
    my ($self) = @_;
    my $skinny = $self->dsh->skinny;
    $h->schema->schema_info;

    return;
}


__END__

=head1 利用可能変数

$self->env       : 環境変数
$self->conf      : 設定
$self->h         : データソースハンドラ
$self->h->skinny : DBIx::Skinny オブジェクト
$self->logger    : ロガー # Log::Dispatch->logメソッドへのリファレンスa
