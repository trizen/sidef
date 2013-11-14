package Sidef::Sys::Sys {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub exit {
        my ($self, $code) = @_;
        exit($code // 0);
    }

    sub alarm {
        my ($self, $sec) = @_;
        $self->_is_number($sec) || return;
        Sidef::Types::Bool::Bool->new(CORE::alarm($$sec));
    }

    sub ualarm {
        my ($self, $sec) = @_;

        $self->_is_number($sec) || return;

        require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::ualarm($$sec));
    }

    sub sleep {
        my ($self, $sec) = @_;
        $self->_is_number($sec) || return;
        Sidef::Types::Bool::Bool->new(CORE::sleep($$sec));
    }

    sub nanosleep {
        my ($self, $sec) = @_;

        $self->_is_number($sec) || return;

        require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::nanosleep($$sec));
    }

    *nanoSleep = \&nanosleep;

    sub usleep {
        my ($self, $sec) = @_;

        $self->_is_number($sec) || return;

        require Time::HiRes;
        Sidef::Types::Bool::Bool->new(Time::HiRes::usleep($$sec));
    }

    sub osname {
        my ($self) = @_;
        Sidef::Types::String::String->new($^O);
    }

    *osName = \&osname;

    sub user {
        my ($self) = @_;
        Sidef::Types::String::String->new(getlogin);
    }

    sub umask {
        my ($self, $mode) = @_;

        if (defined($mode)) {
            $self->_is_number($mode) || return;
            return Sidef::Types::Number::Number->new(CORE::umask($$mode));
        }

        Sidef::Types::Number::Number->new(CORE::umask);
    }

    sub ref {
        my ($self, $obj) = @_;
        Sidef::Types::String::String->new(CORE::ref $obj);
    }

    sub sidef {
        my ($self) = @_;

        require File::Spec;
        Sidef::Types::String::String->new(File::Spec->rel2abs($0));
    }

    sub die {
        my ($self, @args) = @_;
        CORE::die(@args);
    }

    sub warn {
        my ($self, @args) = @_;
        CORE::warn(@args);
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
        elsif (CORE::ref($fh) =~ /^Sidef::Types::Glob::/ and $fh->can('print')) {
            return $fh->print(@args);
        }

        CORE::warn "[WARN] Sys.printh(): invalid handle object!\n";
        return;
    }

    sub println {
        my ($self, @args) = @_;
        Sidef::Types::Bool::Bool->new(say @args);
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

}
