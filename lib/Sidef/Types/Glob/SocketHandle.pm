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
        local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
        (CORE::setsockopt($self->{fh}, $level->get_value, $optname->get_value, $optval->get_value))
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub getsockopt {
        my ($self, $level, $optname) = @_;
        Sidef::Types::String::String->new(
            CORE::getsockopt(
                $self->{fh},
                do {
                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                    $level->get_value;
                },
                $optname->get_value
              ) // return
        );
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
        (CORE::bind($self->{fh}, $name->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub listen {
        my ($self, $queuesize) = @_;
        (
         CORE::listen(
             $self->{fh},
             do {
                 local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                 $queuesize->get_value;
               }
         )
        )
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
        (CORE::connect($self->{fh}, $name->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub recv {
        my ($self, $length, $flags) = @_;
        CORE::recv(
            $self->{fh},
            (my $content),
            do {
                local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                $length->get_value;
            },
            $flags->get_value
                  ) // return;
        Sidef::Types::String::String->new($content);
    }

    sub send {
        my ($self, $msg, $flags, $to) = @_;
        CORE::send($self->{fh}, $msg->get_value, $flags->get_value, defined($to) ? $to->get_value : ());
    }

    sub shutdown {
        my ($self, $how) = @_;
        (CORE::shutdown($self->{fh}, $how->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

};

1
