use Text::MediawikiFormat qw/wikiformat/;
use File::Path qw/make_path/;
use File::Basename;
use Try::Tiny;

my $CSRF_TOKEN = 'QJjAkxIhbstQLyEEqxGM3CuWToFiRmEL';



GET {
    my $path = a->qq->get('path');
    $path = 'index'  unless defined $path && $path ne '';

    my $datadir  = a->conf->{PATH}{DATA} . '/docs';
    my $datafile = "${datadir}/${path}.txt";
    my $notfound = 0;
    $notfound = 1  unless -f $datafile;

    #
    # data -> html
    #
    my ($data, $html) = ('');;
    try {
        local $/;
        open my $fh, '<', $datafile  or  die $!;
        $data = <$fh>;
        close $fh;
    }
    catch {
        my $msg = shift;
        $data = << "...";
Error.
<pre>$msg</pre>
...

    };
    $html = $data = de $data;
    $html = _parse_table($html);
    $html = wikiformat($html);

    #
    # css
    #
    my $css = '';
    if (my $cssfile = "${datadir}/__style.css") {
        try {
            local $/;
            open my $fh, '<', $cssfile  or  die $!;
            $css = <$fh>;
            close $fh;
        }
        catch {
            my $msg = shift;
            carp $msg;
        };
    }
    $css = de $css;


    a->import_var(
        notfound   => $notfound,
        html       => $html,
        raw_data   => $data,
        css        => $css,

        csrf_token => $CSRF_TOKEN,
    );



    '';
};



POST {
    my ($q, $qq) = (a->q, a->qq);

    my $path = $qq->get('path') || '';
    my $csrf_token_submitted = $q->get('__csrf_token') || '';

    if ($csrf_token_submitted ne $CSRF_TOKEN) {
        a->status(403);
        return '';
    }

    my $datadir  = a->conf->{PATH}{DATA} . '/docs';


    #
    # command:create_page
    #
    if ($q->get('command:create_page')) {
        do {
            my $file = "${datadir}/${path}.txt";
            my $dir  = dirname $file;

            my $umask = umask 0;

            make_path $dir, {mode => 0775};

            open my $fh, '>', $file  or  die $!;
            print $fh '';
            close $fh;
            chmod 0664, $file;

            umask $umask;
        };
    }
    #
    # command:upadte
    #
    elsif ($q->get('command:update')) {
        my $data = $q->get('data');
    }


    return a->req->referer;


    '';
};






AFTER {


    '';
};





# 1行複数列記述形式には対応しない
sub _parse_table {
    my ($data) = @_;
    my $re = qr/\{\| ([^\n]*)? (.*?) \|\}/xs;

    my $re_head = qr/^ (\|\+ | \|- | ! | \|) /x;

    my $re_attr = qr/(?:([^\|]+)\|)?/;

    my $re_thtd    = qr/^[\|!] $re_attr ([^\|]*)$/x;
    my $re_tr      = qr/^\|- ([^\|]+)? $/x;
    my $re_caption = qr/^\|\+ $re_attr (.+) $/x;

    while (my ($attrs, $inner) = $data =~ $re) {
        my $html_inner   = '';
        my $html_caption = '';

        my (undef, @lines) = split /\n/, $inner;
        for my $l (@lines) {
            my ($h) = $l =~ $re_head;
            next  unless $h;

            # '|': td
            if ($h eq '|') {
                my ($a, $c) = $l =~ $re_thtd;
                $a = ''  unless defined $a;
                if (defined $c) {
                    ($l = "<td ${a}>${c}</td>") =~ s/ >/>/;
                }
            }
            # '!': th
            elsif ($h eq '!') {
                my ($a, $c) = $l =~ $re_thtd;
                $a = ''  unless defined $a;
                ($l = "<th ${a}>${c}</th>") =~ s/ >/>/;
            }
            # '|-': tr
            elsif ($h eq '|-') {
                my ($a) = $l =~ $re_tr;
                $a = ''  unless defined $a;
                ($l = "</tr>\n<tr ${a}>") =~ s/ >/>/;
            }
            # '|+': caption
            elsif ($h eq '|+') {
                my ($a, $c) = $l =~ $re_caption;
                $a = ''  unless defined $a;
                ($html_caption = "<caption ${a}>${c}</caption>") =~ s/ >/>/;
                $l = undef;
            }
        }
        $html_inner = join "\n", grep defined $_, @lines;

        my $html_table = << "...";
<table ${attrs}>
${html_caption}
<tr>
${html_inner}
</tr>
</table>
...
        $html_table =~ s{<tr>\s*</tr>}{}s;
        $data =~ s/$re/$html_table/;
    }



    return $data;
}
