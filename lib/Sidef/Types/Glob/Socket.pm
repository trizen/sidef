package Sidef::Types::Glob::Socket {

    use utf8;
    use 5.016;
    our $AUTOLOAD;

    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';
        require Socket;

        foreach my $name (@Socket::EXPORT, @Socket::EXPORT_OK) {
            $name =~ /^[a-z]/i or next;
            *{__PACKAGE__ . '::' . $name} = sub {
                my ($self, @args) = @_;

                my $func = \&{'Socket' . '::' . $name};
                @args = map { $_->get_value } @args;

                my @results = eval { $func->(@args) };

                if ($@) {
                    @results = scalar $func->(@args);
                }

                return (
                        @results > 1
                        ? (map { Sidef::Perl::Perl->to_sidef($_) } @results)
                        : Sidef::Perl::Perl->to_sidef($results[0])
                       );
            };
        }
    }

    sub open {
        my ($self, $domain, $type, $protocol) = @_;
        CORE::socket(my $sh, $domain, $type, $protocol) || return undef;
        Sidef::Types::Glob::SocketHandle->new($sh);
    }

    sub socketpair {
        my ($self, $socket1, $socket2, $domain, $type, $protocol) = @_;
        CORE::socketpair(my $sh1, my $sh2, $domain, $type, $protocol)
          || return (Sidef::Types::Bool::Bool::FALSE);
        ${$socket1} = Sidef::Types::Glob::SocketHandle->new($sh1);
        ${$socket2} = Sidef::Types::Glob::SocketHandle->new($sh2);
        (Sidef::Types::Bool::Bool::TRUE);
    }

    #
    ## gethost*
    #
    sub gethostbyname {
        my ($self, $name) = @_;
        Sidef::Types::String::String->new(CORE::gethostbyname("$name") // return undef);
    }

    sub gethostbyaddr {
        my ($self, $addr, $addrtype) = @_;
        Sidef::Types::String::String->new(CORE::gethostbyaddr("$addr", "$addrtype") // return undef);
    }

    sub gethostent {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::gethostent() // return undef);
    }

    #
    ## getnet*
    #
    sub getnetbyname {
        my ($self, $name) = @_;
        Sidef::Types::String::String->new(CORE::getnetbyname("$name") // return undef);
    }

    sub getnetbyaddr {
        my ($self, $addr, $addrtype) = @_;
        Sidef::Types::String::String->new(CORE::getnetbyaddr("$addr", "$addrtype") // return undef);
    }

    sub getnetent {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getnetent() // return undef);
    }

    #
    ## getserv*
    #
    sub getservbyname {
        my ($self, $name, $proto) = @_;
        Sidef::Types::String::String->new(CORE::getservbyname("$name", $proto) // return undef);
    }

    sub getservbyport {
        my ($self, $port, $proto) = @_;
        Sidef::Types::String::String->new(CORE::getservbyport($port, $proto) // return undef);
    }

    sub getservent {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getservent() // return undef);
    }

    #
    ## getproto*
    #
    sub getprotobynumber {
        my ($self, $num) = @_;
        Sidef::Types::String::String->new(CORE::getprotobynumber(CORE::int($num)) // return undef);
    }

    sub getprotobyname {
        my ($self, $name) = @_;
        Sidef::Types::Number::Number->new(CORE::getprotobyname("$name") // (return undef));
    }

    sub getprotoent {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::getprotoent() // (return undef));
    }

    #
    ## set*
    #
    sub sethostent {
        my ($self, $stayopen) = @_;
        (CORE::sethostent($stayopen ? 1 : 0)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub setnetent {
        my ($self, $stayopen) = @_;
        (CORE::setnetent($stayopen ? 1 : 0)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub setprotoent {
        my ($self, $stayopen) = @_;
        (CORE::setprotoent($stayopen ? 1 : 0)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub setservent {
        my ($self, $stayopen) = @_;
        (CORE::setservent($stayopen ? 1 : 0)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }
};

1
