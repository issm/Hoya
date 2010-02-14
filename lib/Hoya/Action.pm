package Hoya::Action;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Hoya::Util;
use Carp;
use Try::Tiny;

our $FINISH = '__FINISH_ACTION__';


my $_name;
my $_req;
my $_env;
my $_conf;

my $_q;
my $_qq;

my $_super;

my $_view_name;
my $_var;

my $_view_info = {
    name => '',
    var  => {},
    q    => {},
    qq   => {},
};

my $_code_BEFORE = sub { '' };
my $_code_GET    = sub { '' };
my $_code_POST   = sub { '' };
my $_code_AFTER  = sub { '' };

my $_ct_call_BEFORE = 0;
my $_ct_call_GET    = 0;
my $_ct_call_POST   = 0;
my $_ct_call_AFTER  = 0;


#
__PACKAGE__->mk_accessors(qw/name req conf q qq view_name var/);


sub init {
    my $self = shift;

    $_name = $self->name;
    $_req  = $self->req;
    $_env  = $_req->{env};
    $_conf = $self->conf;

    $_q  = $self->q;
    $_qq = $self->qq;

    $_var = {};

    try {
        my $pl = $self->_load;
        # eval
        eval $_env;
        eval $_conf;
        eval $_q;
        eval $_qq;
        eval $_var;
        eval $_super  if defined $_super;
        my $self;
        eval << "...";
$pl
...
    }
    catch {
        carp shift->text;
    };

    $self;
}


# go();
sub go {
    my $self = shift;
    $_view_info = {
        name => $self->name,
        var  => {},
        q    => $_q,
        qq   => $_qq,
    };
    my $req_meth = $self->req->method;

    my $view_name;
    # BEFORE
    #$view_name = $self->_xx_BEFORE();
    $view_name = $self->BEFORE();
    # GET
    if (
        (!defined $view_name  ||  $view_name eq '')  &&
        $view_name ne $FINISH  &&
        $req_meth eq 'GET'
    ) {
        #$view_name = $self->_xx_GET();
        $view_name = $self->GET();
    }
    # POST
    if (
        (!defined $view_name  ||  $view_name eq '')  &&
        $view_name ne $FINISH  &&
        $req_meth eq 'POST'
    ) {
        #$view_name = $self->_xx_POST();
        $view_name = $self->POST();
    }
    # AFTER
    if (
        (!defined $view_name || $view_name eq '') &&
        $view_name ne $FINISH
    ) {
        #$view_name = $self->_xx_AFTER();
        $view_name = $self->AFTER();
    }
    $view_name = ''  unless defined $view_name;

    $self->_reset_call_count();

    $_view_info->{name} = $view_name;
    $_view_info->{var} = $_var;

    return $_view_info;
}


# set_var($name, $value);
sub set_var {
    my ($self, @args) = @_;
    my $size = scalar @args;

    if ($size % 2 == 0) {
        while (@args) {
            my $k = shift @args;
            my $v = shift @args;
            next  unless ref $k eq '';  # $kはスカラであるべき
            $_var->{$k} = $v;
        }
    }
    elsif ($size == 1  &&  ref $args[0] eq 'HASH') {
        $_var = merge_hash($_var, $args[0]);
    }

    return $_var;
}


# finish();
sub finish {
    return $FINISH;
}



# _load();
sub _load {
    my $self = shift;
    my $pl = sprintf(
        '%s/%s.pl',
        $_conf->{PATH}{ACTION},
        name2path($self->name),
    );

    my $buff;

    try {
        local $/;
        open my $fh, '<', $pl or die $!;
        $buff = de <$fh>;
        close $fh;
    }
    catch {
        carp shift->text;
        $buff = '';
    };

    return $buff;
}


# _reset_call_count();
sub _reset_call_count {
    my $self = shift;
    $_ct_call_BEFORE = 0;
    $_ct_call_GET    = 0;
    $_ct_call_POST   = 0;
    $_ct_call_AFTER  = 0;
}


# extend($name);
sub _extend {
    my ($self, $name) = @_;

    my $action_ex = __PACKAGE__->new({
        name => $name,
        req  => $self->req,
        conf => $_conf,
        q    => $_q,
        qq   => $_qq,
    })->init;
    my $view_info_ex = $action_ex->go;

    return $view_info_ex;
}



# BEFORE $code;
# BEFORE();
sub BEFORE (&) {
    my $code_or_self = shift;
    if (ref $code_or_self eq 'CODE') {
        carp d "SET: ${_name}::BEFORE";
        $_code_BEFORE = $code_or_self;
    }
    elsif (ref $code_or_self eq 'Hoya::Action') {
        carp d "GET: ${_name}::BEFORE";
        return $code_or_self->_xx_BEFORE();
    }

}

# GET $code;
# GET();
sub GET (&) {
    my $code_or_self = shift;
    if (ref $code_or_self eq 'CODE') {
        carp d "SET: ${_name}::GET";
        $_code_GET = $code_or_self;
    }
    elsif (ref $code_or_self eq 'Hoya::Action') {
        carp d "GET: ${_name}::GET";
        return $code_or_self->_xx_GET();
    }

}

# POST $code;
# POST();
sub POST (&) {
    my $code_or_self = shift;
    if (ref $code_or_self eq 'CODE') {
        carp d "SET: ${_name}::POST";
        $_code_POST = $code_or_self;
    }
    elsif (ref $code_or_self eq 'Hoya::Action') {
        carp d "GET: ${_name}::POST";
        return $code_or_self->_xx_POST();
    }
}
# アクションファイル内から呼び出す
# AFTER $code;
sub AFTER (&) {
    my $code_or_self = shift;
    if (ref $code_or_self eq 'CODE') {
        carp d "SET: ${_name}::AFTER";
        $_code_AFTER = $code_or_self;
    }
    elsif (ref $code_or_self eq 'Hoya::Action') {
        carp d "GET: ${_name}::AFTER";
        #$_super->AFTER()  if defined $_super;
        #return $code_or_self->_xx_AFTER();
        try {
            throw Error  if ++$_ct_call_AFTER > 1;
            $_super->AFTER()  if defined $_super;
            return $code_or_self->_xx_AFTER();
        }
        catch {
            carp "${_name}::AFTER: cannot call recursively!";
        };
    }
}

# ファクションファイル内から呼び出す
# super $name
sub super ($) {
    my $name = shift;
    return undef  if $name eq $_name; # 再帰防止？

    $_super = __PACKAGE__->new({
        name => $name,
        req  => $_req,
        conf => $_conf,
        q    => $_q,
        qq   => $_qq,
    })->init;

    $_super;
}



#
sub _xx_BEFORE {
    my $self = shift;
    my $ret;
    try {
        throw Error  if ++$_ct_call_BEFORE > 1;
        #$_super->BEFORE()  if defined $_super;
        $ret = $_code_BEFORE->($self);
    }
    catch {
        carp "${_name}::BEFORE: cannot call recursively!";
    };
    return $ret;
}
#
sub _xx_GET {
    my $self = shift;
    my $ret;
    try {
        throw Error  if ++$_ct_call_GET > 1;

        if (defined $_super) {
            #$_super->GET();
        }

        $ret = $_code_GET->($self);
    }
    catch {
        carp "${_name}::GET: cannot call recursively!";
    };
    return $ret;
}
#
sub _xx_POST {
    my $self = shift;
    my $ret;
    try {
        throw Error  if ++$_ct_call_POST > 1;
        $ret = $_code_POST->($self);
    }
    catch {
        carp "${_name}::POST: cannot call recursively!";
    };
    return $ret;
}
#
sub _xx_AFTER {
    my $self = shift;
    my $ret;
    try {
        throw Error  if ++$_ct_call_AFTER > 1;
        $ret = $_code_AFTER->($self);
    }
    catch {
        carp "${_name}::AFTER: cannot call recursively!";
    };
    return $ret;
}


1;
__END__
