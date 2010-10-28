package Hoya::X::Mail;
use strict;
use utf8;
use base qw/Class::Accessor::Faster/;

use MIME::Lite;
use MIME::Types;
use File::Basename;
use Text::MicroTemplate::Extended;
use Try::Tiny;
use Carp;

use Hoya::Util;

my $_types;


sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;

    $class->mk_accessors(
        qw/from to cc bcc subject
           body signature _files
           smtp_host
           template_dir

           _error_message
          /
    );

    return $self->_init;
}

sub _init {
    my $self = shift;
    $self->_files([]);
    $self->_error_message('');

    $_types = MIME::Types->new;

    return $self;
}


sub body_from_template {
    my ($self, $params) = @_;
    my $var  = $params->{var} || {};
    my $name = $params->{name};
    my $body = '';

    $self->template_dir($params->{dir})
        if is_def $params->{dir};

    my $mt = Text::MicroTemplate::Extended->new(
        include_path  => $self->template_dir || '.',
        template_args => {
            env  => \%ENV,
            map {
                ($_ => $var->{$_});
            } keys %$var,
            # ^ 各変数を，テンプレートのトップの名前空間に結びつける
        },
        use_cache => 1,
    );

    try {
        $body = $mt->render(
            name2path($name)
        )->as_string;
    }
    catch {
        my $class = ref $self;
        carp shift;
        carp "[$class\::body_from_template] template named '$name' not found.";
    };

    $self->body($body);
    return $body;
}


sub attach {
    my ($self, @files) = @_;

    for my $f (@files) {
        next  unless $self->_check_file($f);
        push @{$self->_files}, $f;
    }

    return 1;
}

sub _check_file {
    my ($self, $file) = @_;
    my $class = ref $self;
    my $okng = 0;

    # ハッシュリファレンスでない
    if (ref $file ne 'HASH') {
        carp "[$class\::attach] not a hash reference.";
        return 0;
    }
    # ->{path} が指定されていない
    unless (is_def $file->{path}) {
        carp "[$class\::attach] path is required.";
        return 0;
    }
    # ->{path} が参照するファイルが存在しない
    unless (-f $file->{path}) {
        carp "[$class\::attach] file specified by 'path' not exists.";
        return 0;
    }

    $file->{name} = basename($file->{path})
        unless is_def $file->{name};

    $file->{type} = '' . $_types->mimeTypeOf($file->{path})
        unless is_def $file->{type};

    return 1;
}


sub send {
    my $self = shift;
    my $debug = shift;
    my $sent;

    $self->_error_message('');
    $self->body('')  unless is_def $self->body;

    try {
        my $class = ref $self;
        die "[$class] to, from, subject, body and/or smtp_host is/are not defined."
            unless is_def(
                $self->to,
                $self->from,
                $self->subject,
                $self->body,
                $self->smtp_host,
            );

        $self->subject(de $self->subject);
        $self->body(de $self->body);

        my $mail = MIME::Lite->new(
            From    => $self->from,
            To      => $self->to,
            Subject => $self->subject,
            #Cc      => '',
            #Bcc     => '',
            Type    => 'multipart/mixed',
        );

        $mail->attach(
            Type => 'TEXT',
            Data => $self->body,
        );

        for my $f (@{$self->_files}) {
            $mail->attach(
                Path        => $f->{path},
                Type        => $f->{type},
                Filename    => $f->{name},
                Desposition => 'attachment',
            );
        }

        $sent = $mail->send(
            'smtp',
            $self->smtp_host,
            Debug => $debug,
        );
    }
    catch {
        my $msg = shift;
        $self->_error_message($msg);
        carp $msg;
    };

    return $sent;
}



1;
__END__

=head1 NAME

Hoya::X::Mail - A mail sender using MIME::Lite

=head1 SYNOPSIS

  use Hoya::X::Mail;

=head1 DESCRIPTION

  Hoya::X::Mail is

=head1 METHODS

=over 4

=item new

new

=item init

init

=item body;

=item body($message);

gets/sets 'body'.

=item body_from_template(\%params);

message body using Text::MicroTemplate::Extended.

=item attach(\%file1, \%file2, ...);

=item send($debug);

send

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
