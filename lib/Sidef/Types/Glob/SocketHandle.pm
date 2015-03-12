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
        Sidef::Types::Bool::Bool->new(
                                    CORE::setsockopt($self->{fh}, $level->get_value, $optname->get_value, $optval->get_value));
    }

    *sockopt = \&setsockopt;

    sub bind {
        my ($self, $name) = @_;
        Sidef::Types::Bool::Bool->new(CORE::bind($self->{fh}, $name->get_value));
    }

    sub listen {
        my ($self, $queuesize) = @_;
        Sidef::Types::Bool::Bool->new(CORE::listen($self->{fh}, $queuesize->get_value));
    }

    sub accept {
        my ($self, @args) = @_;
        CORE::accept(my $fh, $self->{fh}) || return;
        Sidef::Types::Glob::SocketHandle->new(fh => $fh);
    }

};

1
