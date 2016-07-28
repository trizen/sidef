package Sidef::Types::Glob::SocketHandle {

    use 5.014;
    use parent qw(
      Sidef::Types::Glob::FileHandle
      );

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub setsockopt {
        my ($self, $level, $optname, $optval) = @_;
        (CORE::setsockopt($self->{fh}, $level, "$optname", $optval))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub getsockopt {
        my ($self, $level, $optname) = @_;
        Sidef::Types::String::String->new(CORE::getsockopt($self->{fh}, $level, "$optname") // return);
    }

    sub getpeername {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getpeername($self->{fh}) // return);
    }

    sub getsockname {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getsockname($self->{fh}));
    }

    sub bind {
        my ($self, $name) = @_;
        CORE::bind($self->{fh}, "$name")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub listen {
        my ($self, $queuesize) = @_;

        CORE::listen($self->{fh}, $queuesize)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub accept {
        my ($self, @args) = @_;
        CORE::accept(my $fh, $self->{fh}) || return;
        Sidef::Types::Glob::SocketHandle->new(fh => $fh);
    }

    sub connect {
        my ($self, $name) = @_;
        CORE::connect($self->{fh}, "$name")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub recv {
        my ($self, $length, $flags) = @_;
        CORE::recv($self->{fh}, (my $content), $length, "$flags") // return;
        Sidef::Types::String::String->new($content);
    }

    sub send {
        my ($self, $msg, $flags, $to) = @_;
        CORE::send($self->{fh}, "$msg", "$flags", defined($to) ? $to->get_value : ())
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub shutdown {
        my ($self, $how) = @_;
        CORE::shutdown($self->{fh}, $how)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

};

1
