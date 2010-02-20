package Hoya::Factory::Action;
use strict;
use warnings;
use utf8;
use base qw/Class::Accessor::Faster/;

use Carp;
use Try::Tiny;
use Hoya::Util;

my @METHODS = qw/BEFORE GET POST AFTER/;

my $_name;


#
__PACKAGE__->mk_accessors(
    qw/name req conf q qq up mm view_name var/
);


sub init {
    my $self = shift;

    $_name = $self->name;

    my $action;

    try {
        my $pl   = $self->_load;
        my $code = $self->_generate_as_string($pl);
        eval $code               or die $!;
        $action = eval << "..."  or die $!;
Hoya::Action::${_name}->new({
    name => \$_name,
    req  => \$self->req,
    conf => \$self->conf,
    q    => \$self->q,
    qq   => \$self->qq,
    up   => \$self->up,
    mm   => \$self->mm,
})->init;
...
    }
    catch {
        die shift;
    };

    return $action;
}



# _load();
sub _load {
    my $self = shift;
    my $pl = sprintf(
        '%s/%s.pl',
        $self->conf->{PATH}{ACTION},
        name2path($_name),
    );

    my $buff;

    try {
        local $/;
        open my $fh, '<', $pl or die $!;
        $buff = de <$fh>;
        close $fh;
        $buff =~ s/__(?:END|DATA)__.*$//s; # __END__ 以降を削除する
    }
    catch {
        #carp shift;
        my $text = sprintf(
            '[notice] Action file not found: %s',
            $_name,
        );
        carp $text;
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
#carp d 'SET; ' . ((caller 0)[3]);
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

#carp d 'GET: ' . ((caller 0)[3]);

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
    catch {
        carp shift;
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

use Params::Validate qw/:all/;
use Hash::MultiValue;
use Carp;
use Try::Tiny;

use Hoya::Util;
#use Hoya::Action;
use Hoya::Factory::Action;

my $_name;
my $_req;
my $_env;
my $_conf;
my $_q;
my $_qq;
my $_up;
my $_m;
my $_mm;
my $_logger;

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



__PACKAGE__->mk_accessors(
    qw/name req conf q qq up mm view_name var
       status content_type cookies
      /
);

sub init {
    my $self = shift;

    $_name = $self->name;
    $_req  = $self->req;
    $_env  = $_req->{env};
    $_conf = $self->conf;
    $_q    = $self->q;
    $_qq   = $self->qq;
    $_up   = $self->up;
    $_mm   = $self->mm;
    $_m    = Hash::MultiValue->new;
    $_logger = $_env->{'psgix.logger'};

    $_var = {};

    $self->status(200);
    $self->content_type(
        $_conf->{CONTENT_TYPE_DEFAULT} || 'text/plain'
    );
    $self->cookies({});

    $self->_main();
    return $self;
}

sub cookie {
    my $self = shift;
    # getter
    if (!defined $_[0]) {
        return $self->_get_cookie;
    }
    elsif (!defined $_[1]  &&  ref $_[0] eq '') {
        return $self->_get_cookie(@_);
    }
    # setter
    else {
        return $self->_set_cookie(@_);
    }
}
# remove_cookie($name);
sub remove_cookie {
    my ($self, $name) = @_;
    return $self->cookie($name, '', undef, undef, -60*60);
}
sub _get_cookie {
    my $self = shift;
    my ($name) = @_;
    #
    if (!defined $name) {
        return de $_req->cookies;
    }
    #
    else {
        return de $_req->cookies->{$name};
    }
}
sub _set_cookie {
    my $self = shift;
    my ($name, $value, $path, $domain, $expires);

    # hashref type or Hash::MultiValue
    if (ref $_[0] eq 'HASH'  or  ref $_[0] eq 'Hash::MultiValue') {
        my $c = shift;
        $name    = $c->{name};
        $value   = $c->{value};
        $path    = $c->{path};
        $domain  = $c->{domain};
        $expires = $c->{expires};
    }
    # array type
    elsif (defined $_[0]  &&  defined $_[1]) {
        ($name, $value, $path, $domain, $expires) = @_;
    }
    # others
    else {
        return {};
    }

    $self->cookies->{$name} = {
        value  => $value,
        path   => $path    || $_conf->{COOKIE}{PATH},
        domain => $domain  || $_conf->{COOKIE}{DOMAIN},
    };
    if (defined $expires  or  defined $_conf->{COOKIE}{EXPIRES}) {
        $self->cookies->{$name}{expires}
            = $self->_to_time($expires || $_conf->{COOKIE}{EXPIRES});
    }

    return $self->cookies->{$name};
}

sub _to_time {
    my ($self, $t) = @_;
    return undef  unless defined $t;

    my ($n, $u_sec, $u_min, $u_hour, $u_day, $u_week)
        = $t =~ /^\s*
                 ([\+\-]?\d+)
                 (?:(s|sec) | (m|min) | (h|hour) | (d|day) | (w|week))?
                 \s*$
                /x;
    my $rate = 1;
    if ($u_min)  { $rate = 60; }
    if ($u_hour) { $rate = 60 * 60; }
    if ($u_day)  { $rate = 60 * 60 * 24; }
    if ($u_week) { $rate = 60 * 60 * 24 * 7; }

    return time + int($n) * $rate;
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

    if (
        $_view_info->{name} eq ''  ||
        $_view_info->{name} eq $Hoya::FINISH_ACTION
    ) {
        $_view_info->{name} = $_name;
    }

    return $_view_info;
}


sub var {
    my ($self, $name, $value) = @_;
    return undef  unless is_def $name;

    # setter
    if (is_def $name, $value) {
        return $self->set_var($name, $value);
    }
    # getter
    elsif (is_def $name) {
        return $self->get_var($name);
    }
}

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


sub super ($) {
    my $name = shift;
    return undef  if ref $name =~ /^Hoya::Action::/;
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


sub model {
    my @names = @_;
    return $_m  unless @names;
    return $_m  if $names[0] =~ /^Hoya::Action::/;

    for my $name (@names) {
        $_m->add(
            $name,
            $_mm->get_model($name),
        );
    }

    return $_m;
}


sub _main {%s}

1;

__END__

=head1 NAME

Hoya::Action::* - "Action" class.

=head1 SYNOPSIS

  use Hoya::Action::*;

=head1 DESCRIPTION

Hoya::Action* is

=head1 METHODS

=over 4

=item init

initialize.

=item go

Go.

=item cookie

=item cookie($name)

=item cookie($name, $value, $path, $domain, $expires)

=item cookie(\%%opts)

Gets/Sets cookie.

\%%opts

- name
- value
- path
- domain
- expires
time to be expired.

Format of "expires"

can be set with "units" like '+3min', '-1d'.
available "units" are:
s / sec: second(s)
m / min: minute(s)
h / hour: hour(s)
d / day: day(s)
w / week: week(s)

=item remove_cookie($name)

Removes cookie which is associated with name $name.

=item var($name)

=item var($name, $var)

Gets/Sets variable associated with name $name. These variables are available on "view".

=item get_var($name1, $name2, ...)

Gets variables that are available on "view".

=item set_var($name1 => $var1, $name2 => $var2, ...)

=item set_var(\%%var)

Sets variables that are available on "view".

When 1st argument is hashref, \%%var is merged to "variable hash".

=item finish

Finish "action propagation".

=back

=head1 FUNCTIONS IN "ACTION FILE"

=over 4

=item super $name

Extends action named $name.

=item model $model1, $model2, ...

Include "model" named $model1, $model2, ...

=item BEFORE \&callback

Proceeds \&callback BEFORE GET/POST function. Common for GET and POST request methods.

In \&callback, first argument($_[0]) refers Hoya::Action;;* object.

=item GET \&callback

Proceeds \&callback on GET request method.

=item POST \&callback

Proceeds \&callback on POST request method.

=item AFTER \&callback

Proceeds \&callback AFTER GET/POST function. Common for GET and POST request methods.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
...
        $action_class,
        $methods,
        $methods_xx,
        $pl,
    );

}





1;
__END__

=head1 NAME

Hoya::Factory::Action - Generates "Action Class" dynamically.

=head1 SYNOPSIS

  use Hoya::Factory::Action;

=head1 DESCRIPTION

Hoya::Factory::Action is

=head1 METHODS

=over 4

=item init

initialize.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
