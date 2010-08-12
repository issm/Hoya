package Hoya::X::Text::MediawikiFormat;
use strict;
use warnings;
use base qw/Exporter/;
use Text::MediawikiFormat qw/wikiformat/;
use Hoya::Util;

our @EXPORT = qw/wiki_format
                /;

sub wiki_format {
    my ($data) = @_;
    my $html = $data = de $data;
    $html = _parse_table($html);
    $html = _parse_code_tag($html);
    $html = wikiformat($html);
    return $html;
}


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



# {{...}} な表記を <code>...</code> に置き換える
sub _parse_code_tag {
    my ($data) = @_;
    my $re_code_tag = qr/\{\{(.*?)\}\}/;
    $data =~ s{$re_code_tag}{<code>$1</code>}g;
    return $data;
}



1;
