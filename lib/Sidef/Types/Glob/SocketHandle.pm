package Sidef::Types::Glob::SocketHandle {

    use utf8;
    use 5.014;
    use parent qw(
      Sidef::Types::Glob::FileHandle
      );

    sub new {
        my (undef, $sh, $socket) = @_;

        bless {
               fh     => $sh,
               parent => $socket,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub setsockopt {
        my ($self, $level, $optname, $optval) = @_;
        (CORE::setsockopt($self->{fh}, $level, "$optname", $optval))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub getsockopt {
        my ($self, $level, $optname) = @_;
        Sidef::Types::String::String->new(CORE::getsockopt($self->{fh}, $level, "$optname") // return undef);
    }

    sub getpeername {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getpeername($self->{fh}) // return undef);
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
        my ($self) = @_;
        CORE::accept(my $sh, $self->{fh}) || return undef;
        Sidef::Types::Glob::SocketHandle->new($sh);
    }

    sub connect {
        my ($self, $name) = @_;
        CORE::connect($self->{fh}, "$name")
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub recv {
        my ($self, $length, $flags) = @_;
        my $content = "";
        CORE::recv($self->{fh}, $content, CORE::int($length), CORE::int($flags)) // return undef;
        Sidef::Types::String::String->new($content);
    }

    sub send {
        my ($self, $msg, $flags, $to) = @_;
        CORE::send($self->{fh}, "$msg", CORE::int($flags), defined($to) ? $to->get_value : ())
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
