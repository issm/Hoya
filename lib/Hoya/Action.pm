package Hoya::Action;
use strict;
use warnings;
use utf8;
use parent qw/Exporter Class::Accessor::Faster/;
no warnings 'redefine';

use Plack::Session;
use Params::Validate qw/:all/;
use Hash::MultiValue;
use Carp;
use Try::Tiny;
use Hoya::Util;
use Hoya::Factory::Action;
use Hoya::Form::Validator;
use Hoya::Re;

use Data::Page;

our @EXPORT = qw/
                    BEFORE GET POST AFTER
                    finish
                /;


our $FINISH = '__FINISH_ACTION__';

my @METHODS = qw/BEFORE GET POST AFTER/;

my $CONTENT_TYPE = {
    json => 'text/javascript',  #'application/json',
    xml  => 'application/xml',  #'text/xml',

    # binary
    zip  => 'application/zip',
    pdf  => 'application/pdf',
};


# name:         アクション名
# req:          is-a Plack::Request
# conf:
# q:
# qq:
# up:
# mm:            is-a Hoya::MetaModel
# vars:
# cookies:
# base_name:     大元のアクション名
# sub_name:      継承元のアクション名
# backward_name: フォワーディング元のアクション名
sub new {
    my $class = shift;
    my $param = shift || {};
    my $self = bless $class->SUPER::new($param), $class;
    $class->mk_accessors(
        qw/name req env conf q qq up mm page
           vars cookies logger pass_name
           base_name sub_name backward_name
           status content_type charset
           data
           _super
           _as_binary _filehandle
          /
    );

    return $self->_init;
}


sub _init {
    my $self = shift;

    $self->env($self->req->env);
    $self->pass_name($self->name);
    $self->logger($self->req->logger);

    $self->status(200)  unless $self->status;
    $self->content_type(
        $self->conf->{CONTENT_TYPE_DEFAULT} || 'text/plain'
    )  unless $self->content_type;
    $self->charset('utf-8')  unless $self->charset;

    $self->_main();
    return $self;
}


sub _to_time {
    my ($self, $t) = @_;
    return  unless defined $t;

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
    my $pass = $self->get_param;

    my $req_meth = $self->req->method;
    $req_meth = 'GET'  unless defined $req_meth;

    # BEFORE
    $pass = $self->__BEFORE__($pass);
    # GET
    if (
        (!defined $pass->{name}  ||  $pass->{name} eq '')  &&
        $pass->{name} ne $FINISH  &&
        $req_meth eq 'GET'
    ) {
        $pass = $self->__GET__($pass);
    }

    # POST
    if (
        (!defined $pass->{name}  ||  $pass->{name} eq '')  &&
        $pass->{name} ne $FINISH  &&
        $req_meth eq 'POST'
    ) {
        $pass = $self->__POST__($pass);
    }

    # AFTER
    if (
        (!defined $pass->{name} || $pass->{name} eq '') &&
        $pass->{name} ne $Hoya::Action::FINISH
    ) {
        $pass = $self->__AFTER__($pass);
    }
    $pass->{name} = ''  unless defined $pass->{name};

    # 最終処理
    if ($pass->{name} eq ''  ||  $pass->{name} eq $FINISH) {
        $pass->{name} = $self->name;
    }

    $self->update_param($pass);
    return $pass;
}


#
sub __BEFORE { '' }
sub __GET    { '' }
sub __POST   { '' }
sub __AFTER  { '' }


# 次の各メソッドを生成する
#   __BEFORE__
#   __GET__
#   __POST__
#   __AFTER__
for my $METH (@METHODS) {
    no strict 'refs';

    my $class = __PACKAGE__;
    my $method = "__${METH}__";

    *{"${class}::${method}"} = sub {
        my ($self, $pass) = @_;
        my $ret;  # pass
        $self->update_param($pass);

        try {
            # 継承元であるアクションクラスが存在する場合，
            # 先にそのクラスの同名メソッドを実行する
            if (defined $self->_super) {
                $ret = $self->_super->${method}($pass);
                $self->update_param($ret);
                if (
                    (defined $ret->{name}  &&  $ret->{name} ne '')  ||
                        $ret->{name} eq $FINISH
                    ) {
                    return $ret;
                }
            }
            #warn D sprintf('%s @ %s', $self->name, $METH);

            # ユーザ定義ロジックを実行する
            my $__meth = "__${METH}";
            my $name_pass = $self->${__meth};
            $self->pass_name($name_pass);

            $ret = $self->get_param;
            return $ret;
        }
        catch {
            my $msg = shift;
            my $name = name2path $self->name;
            my $text = << "...";
**** Error in "${METH}" method in "action file": pl/action/${name}.pl ****

$msg
...
            croak $text;
        };
    }
}
#sub __BEFORE__ {
#    my ($self, $pass) = @_;
#    my $ret;  # pass
#    $self->update_param($pass);
#
#    try {
#        if (defined $self->_super) {
#            $ret = $self->_super->__BEFORE__($pass);
#            $self->update_param($ret);
#            if (
#                (defined $ret->{name}  &&  $ret->{name} ne '')  ||
#                $ret->{name} eq $FINISH
#            ) {
#                 return $ret;
#            }
#        }
#
#        # ユーザ定義ロジックを実行する
#        my $name_pass = $self->__BEFORE;
#
#        $ret = $self->get_param;
#        $ret->{name} = $name_pass;
#    }
#    catch {
#        my $msg = shift;
#        my $name = $self->name;
#        my $text = << "...";
#[error\@action::$name/BEFORE] $msg
#...
#        croak $text;
#    };
#
#    return $ret;
#}


sub update_param {
    my ($self, $param) = @_;
    # name
    $self->pass_name($param->{name})
        if defined $param->{name};
    # vars
    $self->vars($param->{var})
        if exists $param->{var}  &&  ref $param->{var} eq 'HASH';
    # q
    $self->q($param->{q})
        if exists $param->{q}  &&  ref $param->{q} eq 'HASH';
    # qq
    $self->qq($param->{qq})
        if exists $param->{qq}  &&  ref $param->{qq} eq 'HASH';
    # cookies
    $self->cookies($param->{cookies})
        if exists $param->{cookies}  &&  ref $param->{cookies} eq 'HASH';
    # status
    $self->status($param->{status})
        if exists $param->{status}  &&  ref $param->{status} eq '';
    # content_type
    $self->content_type($param->{content_type})
        if exists $param->{content_type}  &&  ref $param->{content_type} eq '';
    # charset
    $self->charset($param->{charset})
        if exists $param->{charset}  &&  ref $param->{charset} eq '';
    # data
    $self->data($param->{data})
        if exists $param->{data}  &&  (ref $param->{data}) =~ /ARRAY|HASH/;

    my $ret = $self->get_param;
    $ret->{name} = $param->{name}  if exists $param->{name};

    return $ret;
}

sub get_param {
    my $self = shift;
    return {
        name         => defined $self->pass_name ? $self->pass_name : '',
        var          => $self->vars,
        q            => $self->q,
        qq           => $self->qq,
        cookies      => $self->cookies,
        status       => $self->status,
        content_type => $self->content_type,
        charset      => $self->charset,
        data         => $self->data,
    };
}


sub _main {}




sub var {
    my ($self, $name, $value) = @_;
    return  unless is_def $name;
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

    if ($size % 2 == 0) {
        while (@args) {
            my $k = shift @args;
            my $v = shift @args;
            next  unless ref $k eq '';  # $kはスカラであるべき
            $self->vars->{$k} = $v;

        }
    }
    elsif ($size == 1  &&  ref $args[0] eq 'HASH') {
        $self->vars(
            merge_hash($self->vars, $args[0])
        );
    }

    return $self->vars
}
sub get_var {
    my ($self, @names) = @_;
    return  unless @names;

    if (wantarray) {
        return
            map {
                my $v = $self->vars->{$_};
                $v = $self->vars->{__import__}{$_}
                    if (!is_def($v)  &&  exists $self->vars->{__import__}{$_});
                $v;
            } @names;
    }
    else {
        if (is_def($names[0])) {
            my $v = $self->vars->{$names[0]};
            $v = $self->vars->{__import__}{$names[0]}
                if (!is_def($v)  &&  exists $self->vars->{__import__}{$names[0]});
            return $v;
        }
        else {
            return;
        }
    }
}

sub import_var {
    my ($self, @args) = @_;
    return  unless @args;

    my ($name, $value, $more) = @args;

    if (
      (grep $name eq $_, @Hoya::NAMES_IMPORT_FORBIDDEN)
    ) {
        my $text = << "...";
**** Error: The variable "${name}" is forbidden to import! ****

...
        croak $text;
    }

    #
    if (is_def($more)  &&  scalar(@args) % 2 == 0) {
        local @_ = @args;
        while(@_) {
            my ($n, $v) = (shift, shift);
            $self->vars->{__import__}{$n} = $v;
        }
    }
    elsif (is_def $name, $value) {
        $self->vars->{__import__}{$name} = $value;
        return $value;
    }
    elsif (is_def $name, $self->vars->{$name}) {
        $self->vars->{__import__}->{$name} = $self->vars->{$name};
        $self->vars->{$name} = undef;
        delete $self->vars->{$name};
        return $value;
    }

    return;
}


sub session {
    my $self = shift;
    # getter
    if (!defined $_[0]) {
        return $self->_get_session;
    }
    elsif (!defined $_[1]  &&  ref $_[0] eq '') {
        return $self->_get_session(@_);
    }
    # setter
    else {
        return $self->_set_session(@_);
    }
}
sub remove_session {
    my ($self, $name) = @_;
    delete $self->req->session->{$name}
        if exists $self->req->session->{$name};
}
sub expire_session {
    my $self = shift;
    my $session = Plack::Session->new($self->env);
    return $session->expire;
}
sub _get_session {
    my $self = shift;
    my ($name) = @_;

    return defined $name
        ? $self->req->session->{$name}
        : $self->req->session
    ;
}
sub _set_session {
    my $self = shift;
    my ($name, $value) = @_;

    if (is_def $name, $value) {
        $self->req->session->{$name} = $value;
    }

    return $value;
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
sub remove_cookie {
    my ($self, $name) = @_;
    return $self->_set_cookie($name, '', undef, undef, -60*60);
}
sub _get_cookie {
    my $self = shift;
    my ($name) = @_;
    #
    if (!defined $name) {
        return de $self->req->cookies;
    }
    #
    else {
        return de $self->req->cookies->{$name};
    }
}
sub _set_cookie {
    my $self = shift;
    my ($name, $value, $path, $domain, $expires, $expires_on_close);

    # hashref type or Hash::MultiValue
    if (ref $_[0] eq 'HASH'  or  ref $_[0] eq 'Hash::MultiValue') {
        my $c = shift;
        $name    = $c->{name};
        $value   = $c->{value};
        $path    = $c->{path};
        $domain  = $c->{domain};
        $expires = $c->{expires};
        $expires_on_close = $c->{expires_on_close} || 0;
    }
    # array type
    elsif (defined $_[0]  &&  defined $_[1]) {
        ($name, $value, $path, $domain, $expires, $expires_on_close) = @_;
    }
    # others
    else {
        return {};
    }

    $self->cookies->{$name} = {
        value  => $value,
        path   => $path    || $self->conf->{COOKIE}{PATH},
        domain => $domain  || $self->conf->{COOKIE}{DOMAIN},
    };
    if (
        ! $expires_on_close  &&
        ( defined $expires  or  defined $self->conf->{COOKIE}{EXPIRES} )
    ) {
        $self->cookies->{$name}{expires}
            = $self->_to_time($expires || $self->conf->{COOKIE}{EXPIRES});
    }

    return $self->cookies->{$name};
}



# $action->super($name_super);
sub super {
    my ($self, $name) = @_;

    if ($name eq $self->name) {
        my $name = $self->name;
        my $text = << "...";
**** Error: cannot call itself as "super action"! ****

...
        croak $text;
    }

    my $super = Hoya::Factory::Action->new({
        name      => $name,
        req       => $self->req,
        conf      => $self->conf,
        q         => $self->q,
        qq        => $self->qq,
        up        => $self->up,
        mm        => $self->mm,
        vars      => $self->vars,
        cookies   => $self->cookies,
        base_name => $self->base_name,
        sub_name  => $self->name,
    });

    $self->_super($super);
    return $super;
}


# forward($name_forwarded);
sub forward {
    my ($self, $name) = @_;

    if ($name eq $self->name) {
        my $name = $self->name;
        my $text = << "...";
**** Error: cannot call itself as "forwarded action"! ****

...
        croak $text;
    }

    my $forwarded = Hoya::Factory::Action->new({
        name           => $name,
        req            => $self->req,
        conf           => $self->conf,
        q              => $self->q,
        qq             => $self->qq,
        up             => $self->up,
        mm             => $self->mm,
        vars           => $self->vars,
        cookies        => $self->cookies,
        base_name      => $self->base_name,
        backward_name  => $self->name,
    });
    my $pass_forwarded = $forwarded->go;
    $self->update_param($pass_forwarded);
    return $pass_forwarded->{name};
}
sub fw { return shift->forward(@_); }

# $model = $a->model($name);
# @models = $a->model($name1, $name2, ...);
sub model {
    my ($self, @names) = @_;
    return  unless @names;
    return $self->mm->get_model(@names);
}


# $validator = $a->new_validator();
# $validator = $a->new_validator($form_name);
sub new_validator {
    my ($self, $name, $rule) = @_;
    $name = $self->name  unless defined $name;

    return Hoya::Form::Validator->new({
        name => $name,
        conf => $self->conf,
        q    => $self->q,
    });
}


# $bool = $a->is_submitted_as($name);
sub is_submitted_as {
    my ($self, $name) = @_;
    my $q = $self->q;
    return ( $q->get($name) || defined $q->get($name . '.x') ) ? 1 : 0;
}


sub as_json {
    my ($self, $param) = @_;
    $self->content_type($CONTENT_TYPE->{json});
    return;
}
sub is_as_json {
    return shift->content_type eq $CONTENT_TYPE->{json} ? 1 : 0;
}

sub as_xml {
    my ($self, $param) = @_;
    $self->content_type($CONTENT_TYPE->{xml});
    return;
}
sub is_as_xml {
    return shift->content_type eq $CONTENT_TYPE->{xml} ? 1 : 0;
}

sub as_binary {
    my ($self, $type) = @_;
    $self->_as_binary(1);
    $self->content_type( $CONTENT_TYPE->{$type} )
        if defined $type  &&  defined $CONTENT_TYPE->{$type};
    return;
}
sub is_as_binary {
    my ($self) = @_;
    return $self->_as_binary ? 1 : 0;
}

sub filehandle {
    my ($self, $path) = @_;
    unless ( -f $path ) {
        carp $!;
        return;
    }
    open my $fh, '<', $path  or  (carp $!  &&  return);
    $self->_filehandle($fh);
}


# $pagination = $a->get_pagination($total, $num, $page);
sub get_pagination {
    my $self = shift;
    my ($total, $num, $page) = @_;
    my $dp = Data::Page->new(
        $total,
        $num,
        $page || 1,
    );

    my $pg = +{
        page => +{
            this     => $page,
            first    => $dp->first_page,
            last     => $dp->last_page,
            next     => $dp->next_page,
            prev     => $dp->previous_page, #synonym of 'previous'
            previous => $dp->previous_page,
        },
        entries => +{
            num       => $num,
            from      => $dp->first,
            to        => $dp->last,
            total     => $total,
            this_page => $dp->entries_on_this_page,
        },
    };
    $pg->{p} = $pg->{page};
    $pg->{e} = $pg->{entries};

    return $pg;
}


#
sub q_fill_empty {
    my ($self, @keys) = @_;
    @keys = ()  unless defined $keys[0];
    my $q = $self->q;
    for my $k (@keys) {
        $q->add($k => '')  unless defined $q->get($k);
    }
    $self->q($q);
}




#### exported ####
# finish;
#
# should be used in "action file" like:
#   return finish;
# or can be used at last of code, like:
#   finish;
sub finish {
    return $FINISH;
}



#### exported 4 below ####
# BEFORE \&code;
sub BEFORE (&) {  ## no critic
    # (caller 0)[0] でクラス名を取得している
    _bind_method((caller 0)[0], 'BEFORE', shift || sub {''});
}
# GET \&code;
sub GET (&) {  ## no critic
    _bind_method((caller 0)[0], 'GET', shift || sub {''});
}
# POST \&code;
sub POST (&) {  ## no critic
    _bind_method((caller 0)[0], 'POST', shift || sub {''});
}
# AFTER \&code;
sub AFTER (&) {  ## no critic
    _bind_method((caller 0)[0], 'AFTER', shift || sub {''});
}

# _bind_method($class, $method, \&code);
# $action->_bind_method($class, $method, \&code);
sub _bind_method {
    shift  if scalar(@_) == 4;
    my ($class, $method, $code) = @_;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${class}::__${method}"} = sub { $code->(); };
    }
}



1;
__END__

=head1 NAME

Hoya::Action - "Action" class.

=head1 SYNOPSIS

  use Hoya::Action;

=head1 DESCRIPTION

Hoya::Action, Hoya::Ation::* are

=head1 METHODS

=over 4

=item init

initialize.

=item go

Go.

=item session

=item session($name)

=item session($name, $value)

Gets/Sets session value.

=item remove_session($name)

Removes session value which isi associated with $name.

=item expire_session

Expires session.

=item cookie

=item cookie($name)

=item cookie($name, $value, $path, $domain, $expires)

=item cookie(\%opts)

Gets/Sets cookie.

\%opts

- name
- value
- path
- domain
- expires
Time to be expired. If undefined, uses conf.COOKIE.EXPIRES instead, if defined that.
- expires_on_close
Forces expiring on closing browser.

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

=item set_var(\%var)

Sets variables that are available on "view".

When 1st argument is hashref, \%var is merged to "variable hash".

=item import_var($name)

=item import_var($name, $value)

Sets variable to be available directly at View, as $hoge, not $var->{hoge}.

=item q_fill_empty(@keys)

Sets "empty string" if $action->q->get($key) is undefined.

=item finish

[exported]

Finish "action propagation".

=back

=head1 FUNCTIONS IN "ACTION FILE"

=over 4

=item super($name)

Extends action named $name.

=item model($model1, $model2, ...)

Get "model" named $model1, $model2, ...

=item new_validator($name)

Returns new Hoya::Form::Validator object.

=item as_json

JSON-response mode.

=item $bool = is_as_json

Is JSON-response mode?

=item as_xml

XML-response mode.

=item is_as_xml

Is XML-response mode?

=item as_binary($type)

Binary-response mode. To respond binary data, ->filehandle($fh) or ->data($data) is required.

=item $bool = is_as_binary

Is binary-response mode?

=item filehandle($path)

Sets filehandle of file which described in $path.

=item BEFORE \&callback

[exported]

Proceeds \&callback BEFORE GET/POST function. Common for GET and POST request methods.

In \&callback, first argument($_[0]) refers Hoya::Action::* object.

=item GET \&callback

[exported]

Proceeds \&callback on GET request method.

=item POST \&callback

[exported]

Proceeds \&callback on POST request method.

=item AFTER \&callback

[exported]

Proceeds \&callback AFTER GET/POST function. Common for GET and POST request methods.

=back

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
