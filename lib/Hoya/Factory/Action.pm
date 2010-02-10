package Hoya::Factory::Action;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Hoya::Util;
use Error qw/:try/;

my @METHODS = qw/BEFORE GET POST AFTER/;

my $_name;


#
__PACKAGE__->mk_accessors(qw/name req conf q qq view_name var/);


sub init {
    my $self = shift;

    $_name = $self->name;

    my $action;

    try {
        my $pl   = $self->_load;
        my $code = $self->_generate_as_string($pl);
        eval $code;
        $action = eval << "...";
Hoya::Action::${_name}->new({
    name => \$_name,
    req  => \$self->req,
    conf => \$self->conf,
    q    => \$self->q,
    qq   => \$self->qq,
})->init;
...
    }
    catch Error with {
        warn d shift->text;
    };

    return $action;
}



# _load();
sub _load {
    my $self = shift;
    my $pl = sprintf(
        '%s/%s.pl',
        $self->conf->{PATH}{ACTION},
        name2path($self->name),
    );

    my $buff;

    try {
        local $/;
        open my $fh, '<', $pl or die $!;
        $buff = de <$fh>;
        close $fh;
    }
    catch Error with {
        warn shift->text;
        $buff = '';
    };

    return $buff;
}



#
sub _generate_as_string ($) {
    my ($self, $pl) = @_;
    $pl ||= '';

    my $action_class = "Hoya::Action::${_name}";

    my ($methods, $methods_xx) = ('', '');

    for my $meth (@METHODS) {
        $methods .= sprintf(
            << '...',
sub %s (&) {
    my $code_or_self = shift;
    my $ret;

    if (ref $code_or_self eq 'CODE') {
        $_code_xx->{%s} = $code_or_self;
warn d 'SET; ' . ((caller 0)[3]);
    }
    elsif(ref $code_or_self eq '%s') {
        my $v = $code_or_self->get_param();
        $ret = $code_or_self->_xx_%s($v);
    };

    return $ret;
}
...
            $meth,
            $meth,
            $action_class,
            $meth,
        );

        $methods_xx .= sprintf(
            << '...',
sub _xx_%s {
    my ($self, $v) = @_;
    $v = $self->set_param($v);
    my $ret;
    my $ret_ = {};

warn d 'GET: ' . ((caller 0)[3]);

    try {
        if (defined $_super) {
            $ret = $_super->_xx_%s($v);
            $ret = $self->set_param($ret);
            if (
                (defined $ret->{name}  &&  $ret->{name} ne '')  ||
                $ret->{name} eq $Hoya::FINISH_ACTION
            ) {
                 return $ret;
            }
        }
        my $__name = $_code_xx->{%s}($self);
        $ret = $self->get_param;
        $ret->{name} = $__name;
    }
    catch Error with {
        warn shift->text;
    };

    return $ret;
}
...
            $meth,
            $meth,
            $meth,
            $action_class,
            $meth,
        );
    }



    return sprintf(
        << '...',
package %s;
use strict;
use warnings;
no warnings 'redefine';
no warnings 'closure';  #ad-hoc
use utf8;
use base qw/Class::Accessor::Faster/;

use Error qw/:try/;

use Hoya::Util;
#use Hoya::Action;
use Hoya::Factory::Action;

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

my $_code_xx = {
  BEFORE => sub {''},
  GET    => sub {''},
  POST   => sub {''},
  AFTER  => sub {''},
};



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

    $self->_main();
    return $self;
}


sub go {
    my $self = shift;
    $_view_info = $self->get_param;
    $_view_info->{name} = $self->name;

    my $req_meth = $self->req->method;

    #my $__view_info = {};

    # BEFORE
    #$__view_info = $self->BEFORE();
    #$_view_info = merge_hash($_view_info, $__view_info);
    $_view_info = $self->_xx_BEFORE($_view_info);

    # GET
    if (
        #(!defined $__view_info->{name}  ||  $__view_info->{name} eq '')  &&
        #$__view_info->{name} ne $Hoya::FINISH_ACTION  &&
        #$req_meth eq 'GET'
        (!defined $_view_info->{name}  ||  $_view_info->{name} eq '')  &&
        $_view_info->{name} ne $Hoya::FINISH_ACTION  &&
        $req_meth eq 'GET'
    ) {
        #$__view_info = $self->GET();
        #$_view_info = merge_hash($_view_info, $__view_info);
        $_view_info = $self->_xx_GET($_view_info);
    }

    # POST
    if (
        #(!defined $__view_info->{name}  ||  $__view_info->{name} eq '')  &&
        #$__view_info->{name} ne $Hoya::FINISH_ACTION  &&
        #$req_meth eq 'POST'
        (!defined $_view_info->{name}  ||  $_view_info->{name} eq '')  &&
        $_view_info->{name} ne $Hoya::FINISH_ACTION  &&
        $req_meth eq 'POST'
    ) {
        #$__view_info = $self->POST();
        #$_view_info = merge_hash($_view_info, $__view_info);
        $_view_info = $self->_xx_POST($_view_info);
    }

    # AFTER
    if (
        #(!defined $__view_info->{name} || $__view_info->{name} eq '') &&
        #$__view_info->{name} ne $Hoya::FINISH_ACTION
        (!defined $_view_info->{name} || $_view_info->{name} eq '') &&
        $_view_info->{name} ne $Hoya::FINISH_ACTION
    ) {
        #$__view_info = $self->AFTER();
        #$_view_info = merge_hash($_view_info, $__view_info);
        $_view_info = $self->_xx_AFTER($_view_info);
    }
    #$__view_info->{name} = ''  unless defined $__view_info->{name};
    $_view_info->{name} = ''  unless defined $_view_info->{name};

    return $_view_info;
}


# super $name
sub super ($) {
    my $name = shift;
    return undef  if $name eq $_name; # 再帰防止？

    $_super = Hoya::Factory::Action->new({
        name => $name,
        req  => $_req,
        conf => $_conf,
        q    => $_q,
        qq   => $_qq,
    })->init;

    $_super;
}



# set_var($name, $value);
sub set_var {
    my ($self, @args) = @_;
    my $size = scalar @args;

    if ($size %% 2 == 0) {
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

#
sub get_var {
    my ($self, @names) = @_;
    return undef  unless @names;

    if (wantarray) {
        return
            map $_var->{$_}, @names;
    }
    else {
        return defined $names[0]
            ? $_var->{$names[0]}
            : undef
        ;
    }
}



#
sub set_param {
    my ($self, $param) = @_;
    #$_name = $param->{name}  if exists $param->{name};
    #$_var = merge_hash($_var, $param->{var})
    $_var = $param->{var}
        if exists $param->{var}  &&  ref $param->{var} eq 'HASH';
    #$_q = merge_hash($_q, $param->{q})
    $_q = $param->{q}
        if exists $param->{q}  &&  ref $param->{q} eq 'HASH';
    #$_qq  = merge_hash($_qq, $param->{qq})
    $_qq = $param->{qq}
        if exists $param->{qq}  &&  ref $param->{qq} eq 'HASH';

    my $ret = $self->get_param;
    $ret->{name} = $param->{name}  if exists $param->{name};

    return $ret;
}

# get_param();
sub get_param {
    my $self = shift;
    return {
        #name => $_name,
        var  => $_var,
        q    => $_q,
        qq   => $_qq,
    };
}



# finish();
sub finish {
    return $Hoya::FINISH_ACTION;
}


# methods
%s

# methods_xx
%s


sub _main {%s}

1;
...
        $action_class,
        $methods,
        $methods_xx,
        $pl,
    );

}





1;
__END__
