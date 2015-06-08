package Sidef::Sys::Sys {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        my (undef, %opt) = @_;
        CORE::bless \%opt, __PACKAGE__;
    }

    sub exit {
        my ($self, $code) = @_;
        exit($code // 0);
    }

    sub alarm {
        my ($self, $sec) = @_;

        state $x = require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::alarm($sec->get_value));
    }

    sub ualarm {
        my ($self, $sec) = @_;

        state $x = require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::ualarm($sec->get_value));
    }

    sub sleep {
        my ($self, $sec) = @_;

        state $x = require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::sleep($sec->get_value));
    }

    sub nanosleep {
        my ($self, $sec) = @_;

        state $x = require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::nanosleep($sec->get_value));
    }

    *nanoSleep = \&nanosleep;

    sub usleep {
        my ($self, $sec) = @_;

        state $x = require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::usleep($sec->get_value));
    }

    sub osname {
        my ($self) = @_;
        Sidef::Types::String::String->new($^O);
    }

    *osName = \&osname;

    sub user {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getlogin);
    }

    *getlogin = \&user;

    sub umask {
        my ($self, $mode) = @_;

        if (defined($mode)) {
            return Sidef::Types::Number::Number->new(CORE::umask($mode->get_value));
        }

        Sidef::Types::Number::Number->new(CORE::umask);
    }

    sub ref {
        my ($self, $obj) = @_;
        Sidef::Types::String::String->new(CORE::ref $obj);
    }

    sub sidef {
        my ($self) = @_;

        state $x = require File::Spec;
        Sidef::Types::String::String->new(File::Spec->rel2abs($0));
    }

    sub die {
        my ($self, @args) = @_;
        if (exists $self->{file_name}) {
            CORE::die(@args, " at $self->{file_name} line $self->{line}.\n");
        }
        else {
            CORE::die(@args, "\n");
        }
    }

    *raise = \&die;

    sub warn {
        my ($self, @args) = @_;
        if (exists $self->{file_name}) {
            CORE::warn(@args, " at $self->{file_name} line $self->{line}.\n");
        }
        else {
            CORE::warn(@args, "\n");
        }
    }

    sub print {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(print @args);
    }

    sub printf {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(printf @args);
    }

    sub printh {
        my ($self, $fh, @args) = @_;

        if (CORE::ref($fh) eq 'GLOB') {
            return Sidef::Types::Bool::Bool->new(print {$fh} @args);
        }
        elsif (eval { $fh->can('print') || $fh->can('AUTOLOAD') }) {
            return $fh->print(@args);
        }

        CORE::warn "[WARN] Sys.printh(): invalid object handle: `$fh'\n";
        return;
    }

    sub println {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(CORE::say @args);
    }

    *say = \&println;

    sub scanln {
        my ($self, $text) = @_;

        if (defined($text)) {
            $self->_is_string($text) || return;
            $text->print;
        }

        Sidef::Types::String::String->new(scalar unpack("A*", scalar <STDIN>));
    }

    *readln = \&scanln;

    sub read {
        my ($self, $type, @vars) = @_;

        if (@vars) {
            foreach my $var_ref (@vars) {
                $self->_is_var_ref($var_ref) || return;
                my $var = $var_ref->get_var;
                print "$var->{name}: ";
                chomp(my $input = <STDIN>);
                $var->set_value($type->new($input));
            }

            return $self;
        }

        if (defined $type) {
            chomp(my $input = <STDIN>);
            return $type->new($input);
        }

        chomp(my $input = <STDIN>);
        Sidef::Types::String::String->new($input);
    }

    sub open {
        my ($self, $var, $mode, $filename) = @_;
        $filename->to_file->open($mode, $var);
    }

    sub stdin {
        Sidef::Types::Glob::FileHandle->stdin;
    }

    sub stdout {
        Sidef::Types::Glob::FileHandle->stdout;
    }

    sub stderr {
        Sidef::Types::Glob::FileHandle->stderr;
    }

    sub opendir {
        my ($self, $var, $dirname) = @_;
        $dirname->to_dir->open($var);
    }

    sub eval {
        my ($self, @args) = @_;
        Sidef::Perl::Perl->eval(@args);
    }

    sub bless {
        my ($self, $obj, $class) = @_;
        CORE::bless $obj, $class;
    }

    sub copy {
        my ($self, $obj) = @_;
        state $x = require Storable;
        Storable::dclone($obj);
    }

    sub select {
        my ($self, $fh) = @_;
        CORE::select(CORE::ref($fh) eq 'GLOB' ? $fh : $fh->get_value);
    }

    sub system {
        my ($self, @args) = @_;
        Sidef::Types::Number::Number->new(CORE::system(@args));
    }

    *run = \&system;

    sub exec {
        my ($self, @args) = @_;
        CORE::exec(@args);
    }

    sub __GETPW__ {
        my ($self, $name, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = @_;
        $name // return;
        Sidef::Types::Array::Array->new(
                                        Sidef::Types::String::String->new($name),
                                        Sidef::Types::String::String->new($passwd),
                                        Sidef::Types::Number::Number->new($uid),
                                        Sidef::Types::Number::Number->new($gid),
                                        Sidef::Types::String::String->new($quota),
                                        Sidef::Types::String::String->new($comment),
                                        Sidef::Types::String::String->new($gcos),
                                        Sidef::Types::String::String->new($shell),
                                       );
    }

    sub setpwent {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::setpwent);
    }

    sub getpwuid {
        my ($self, $uid) = @_;
        $self->__GETPW__(CORE::getpwuid($uid->get_value));
    }

    sub getpwnam {
        my ($self, $name) = @_;
        $self->__GETPW__(CORE::getpwnam($name->get_value));
    }

    sub getpwent {
        my ($self) = @_;
        $self->__GETPW__(CORE::getpwent);
    }

    sub __GETGR__ {
        my ($self, $name, $passwd, $gid, $members) = @_;
        $name // return
          Sidef::Types::Array::Array->new(
                                          Sidef::Types::String::String->new($name),
                                          Sidef::Types::String::String->new($passwd),
                                          Sidef::Types::Number::Number->new($gid),
                                          Sidef::Types::Array::Array->new(
                                                             map { Sidef::Types::String::String->new($_) } split(' ', $members)
                                          ),
                                         );
    }

    sub setgrent {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::setgrent);
    }

    sub getgrent {
        my ($self) = @_;
        $self->__GETGR__(CORE::getgrent);
    }

    sub getgrgid {
        my ($self, $gid) = @_;
        $self->__GETGR__(CORE::getgrgid($gid->get_value));
    }

    sub getgrnam {
        my ($self, $name) = @_;
        $self->__GETGR__(CORE::getgrnam($name->get_value));
    }

    sub __GETHOST__ {
        my ($self, $name, $aliases, $addrtype, $length, @addrs) = @_;
        $name // return;
        Sidef::Types::Array::Array->new(
                                        Sidef::Types::String::String->new($name),
                                        Sidef::Types::String::String->new($aliases),
                                        Sidef::Types::String::String->new($addrtype),
                                        Sidef::Types::Number::Number->new($length),
                                        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } @addrs),
                                       );
    }

    sub sethostent {
        my ($self, $stayopen) = @_;
        Sidef::Types::Bool::Bool->new(CORE::sethostent($stayopen->get_value));
    }

    sub gethostbyaddr {
        my ($self, $addr, $addrtype) = @_;
        $self->__GETHOST__(CORE::gethostbyaddr($addr->get_value, $addrtype->get_value));
    }

    sub gethostbyname {
        my ($self, $name) = @_;
        $self->__GETHOST__(CORE::gethostbyname($name->get_value));
    }

    sub gethostent {
        my ($self) = @_;
        $self->__GETHOST__(CORE::gethostent);
    }

    sub __GETNET__ {
        my ($self, $name, $aliases, $addrtype, $net) = @_;
        $name // return;
        Sidef::Types::Array::Array->new(
                                        Sidef::Types::String::String->new($name),
                                        Sidef::Types::String::String->new($aliases),
                                        Sidef::Types::String::String->new($addrtype),
                                        Sidef::Types::String::String->new($net),
                                       );
    }

    sub setnetent {
        my ($self, $stayopen) = @_;
        Sidef::Types::Bool::Bool->new(CORE::setnetent($stayopen->get_value));
    }

    sub getnetbyaddr {
        my ($self, $addr, $addrtype) = @_;
        $self->__GETNET__(CORE::getnetbyaddr($addr->get_value, $addrtype->get_value));
    }

    sub getnetbyname {
        my ($self, $name) = @_;
        $self->__GETNET__(CORE::getnetbyname($name->get_value));
    }

    sub getnetent {
        my ($self) = @_;
        $self->__GETNET__(CORE::getnetent);
    }

    sub __GETPROTO__ {
        my ($self, $name, $aliases, $proto) = @_;
        $name // return;
        Sidef::Types::Array::Array->new(
                                        Sidef::Types::String::String->new($name),
                                        Sidef::Types::String::String->new($aliases),
                                        Sidef::Types::String::String->new($proto),
                                       );
    }

    sub setprotoent {
        my ($self, $stayopen) = @_;
        Sidef::Types::Bool::Bool->new(CORE::setprotoent($stayopen->get_value));
    }

    sub getprotobyname {
        my ($self, $name) = @_;
        $self->__GETPROTO__(CORE::getprotobyname($name->get_value));
    }

    sub getprotobynumber {
        my ($self, $num) = @_;
        $self->__GETPROTO__(CORE::getprotobynumber($num->get_value));
    }

    sub getprotoent {
        my ($self) = @_;
        $self->__GETPROTO__(CORE::getprotoent);
    }

    sub __GETSERV__ {
        my ($self, $name, $aliases, $port, $proto) = @_;
        $name // return;
        Sidef::Types::Array::Array->new(
                                        Sidef::Types::String::String->new($name),
                                        Sidef::Types::String::String->new($aliases),
                                        Sidef::Types::Number::Number->new($port),
                                        Sidef::Types::String::String->new($proto),
                                       );
    }

    sub setservent {
        my ($self, $stayopen) = @_;
        Sidef::Types::Bool::Bool->new(CORE::setservent($stayopen->get_value));
    }

    sub getservbyname {
        my ($self, $name, $proto) = @_;
        $self->__GETSERV__(CORE::getservbyname($name->get_value, $proto->get_value));
    }

    sub getservbyport {
        my ($self, $port, $proto) = @_;
        $self->__GETSERV__(CORE::getservbyport($port->get_value, $proto->get_value));
    }

    sub getservent {
        my ($self) = @_;
        $self->__GETSERV__(CORE::getservent);
    }

    #
    ## get/set priority
    #
    sub getpriority {
        my ($self, $which, $who) = @_;
        Sidef::Types::Number::Number->new(CORE::getpriority($which->get_value, $who->get_value));
    }

    sub setpriority {
        my ($self, $which, $who, $priority) = @_;
        Sidef::Types::Number::Number->new(CORE::setpriority($which->get_value, $who->get_value, $priority->get_value));
    }

    sub getppid {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::getppid);
    }

    #
    ## get/set the process group of a process
    #
    sub getpgrp {
        my ($self, $pid) = @_;
        Sidef::Types::Number::Number->new(CORE::getpgrp(defined($pid) ? $pid->get_value : ()));
    }

    sub setpgrp {
        my ($self, $pid, $pgrp) = @_;
        $pid  = defined($pid)  ? $pid->get_value  : 0;
        $pgrp = defined($pgrp) ? $pgrp->get_value : 0;
        Sidef::Types::Number::Number->new(CORE::setpgrp($pid, $pgrp));
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '>'}  = \&println;
        *{__PACKAGE__ . '::' . '>>'} = \&print;
    }

};

1
