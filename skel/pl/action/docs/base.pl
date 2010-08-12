use File::Path qw/make_path/;
use File::Basename;
use Hoya::X::Text::MediawikiFormat;
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

    $html = wiki_format($data);

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
            $path = 'index'  if $path eq '';

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
