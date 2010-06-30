#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use File::Path qw/make_path/;
use File::Spec;
use File::Copy;


sub main {
    print 'Are you sure to setup directories? [y/N]: ';
    chomp(my $yn = lc <STDIN>);
    $yn ||= 'n';

    if ($yn eq 'y') {
        _setup();
    }
}


sub _setup {
    (my $hoya_root = $FindBin::Bin) =~ s{/[^/]+$}{};
    my $project_root = '.';
    my $makepath_opts_default = {
        mode     => 0755,
        verbose => 1,
    };

    my $umask_src = umask 0;

    {
        # bin, conf, doc, lib, log, script, t, www
        make_path (
            (map {
                "${project_root}/$_";
            } qw/bin conf doc lib, log script t www/),
            $makepath_opts_default,
        );

        # bin/plackup.sh
        _copy_file(
            "${hoya_root}/skel/bin/plackup.sh",
            "${project_root}/bin/plackup.sh",
            0755,
        );

        # conf/{base,additional}.yml
        # conf/{urlmap,uamap,form}.yml
        map {
            _copy_file(
                "${hoya_root}/skel/conf/${_}.yml",
                "${project_root}/conf/${_}.yml",
            );
        } qw/base additional
             urlmap uamap form
            /;

        # www/default.psgi
        _copy_file(
            "${hoya_root}/skel/www/default.psgi",
            "${project_root}/www/default.psgi",
        );
    }

    # tmp
    {
        make_path (
            "${project_root}/tmp",
            {
                mode    => 0777,
                verbose => 1,
            },
        );
    }

    # pl/{action,model}
    # data/{yaml,sql}
    # upload/default
    {
        make_path (
            "${project_root}/pl/action",
            "${project_root}/pl/model",

            "${project_root}/data/yaml",
            "${project_root}/data/sql",

            "${project_root}/upload/default",

            $makepath_opts_default,
        );
    }

    # site/default/default/{css,img,js,mt,tt}
    # s -> site/default/default
    {
        my $site_root = "${project_root}/site/default/default";
        make_path (
            (map {
                "${site_root}/$_";
            } qw/css img js mt tt/),
            $makepath_opts_default,
        );

        my $ln_target = "${project_root}/s";
        unless (-e $ln_target) {
            `/usr/bin/env ln -s $site_root $ln_target`;
        }
    }

    # hoya -> $hoya_root
    {
        my $ln_target = "${project_root}/hoya";
        unless (-e $ln_target) {
            `/usr/bin/env ln -s $hoya_root $ln_target`;
        }
    }


    umask $umask_src;
    return;
}


sub _create_files {
    my (@files) = @_;
    return undef  unless @files;

    my $umask_src = umask 0;
    for my $f (@files) {
        `touch $f`;
        chmod 0644, $f;
    }
    umask $umask_src;
    return;
}


sub _copy_file {
    my ($file_from, $file_to, $mode) = @_;
    return undef  unless $file_from && $file_to;
    $mode = 0644  unless defined $mode;

    if (-f $file_to) {
        warn "already exists: $file_to";
        return undef;
    }

    my $umask_src = umask 0;
    copy $file_from, $file_to;
    chmod $mode, $file_to;
    umask $umask_src;
    return;
}





main();
__END__
