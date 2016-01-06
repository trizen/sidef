package Sidef::Types::Glob::Socket {

    use 5.014;
    our $AUTOLOAD;

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        my %CACHE;

        sub get_constant {
            my ($self, $name) = @_;

            if (exists $CACHE{$name}) {
                return $CACHE{$name};
            }

            state $x = require Socket;
            my $func = \&{'Socket' . '::' . $name};

            if (defined(&$func)) {
                return $CACHE{$name} = Sidef::Perl::Perl->to_sidef(scalar $func->());
            }

            die qq{[ERROR] Inexistent Socket constant "$name"!\n};
        }
    }

    sub open {
        my ($self, $domain, $type, $protocol) = @_;
        CORE::socket(my $fh, $domain->get_value, $type->get_value, $protocol->get_value) || return;
        Sidef::Types::Glob::SocketHandle->new(fh => $fh);
    }

    sub socketpair {
        my ($self, $socket1, $socket2, $domain, $type, $protocol) = @_;
        CORE::socketpair(my $sh1, my $sh2, $domain->get_value, $type->get_value, $protocol->get_value)
          || return (Sidef::Types::Bool::Bool::FALSE);
        ${$socket1} = Sidef::Types::Glob::SocketHandle->new(fh => $sh1);
        ${$socket2} = Sidef::Types::Glob::SocketHandle->new(fh => $sh2);
        (Sidef::Types::Bool::Bool::TRUE);
    }

    #
    ## gethost*
    #
    sub gethostbyname {
        my ($self, $name) = @_;
        Sidef::Types::String::String->new(CORE::gethostbyname($name->get_value) // return);
    }

    sub gethostbyaddr {
        my ($self, $addr, $addrtype) = @_;
        Sidef::Types::String::String->new(CORE::gethostbyaddr($addr->get_value, $addrtype->get_value) // return);
    }

    sub gethostent {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::gethostent() // return);
    }

    #
    ## getnet*
    #
    sub getnetbyname {
        my ($self, $name) = @_;
        Sidef::Types::String::String->new(CORE::getnetbyname($name->get_value) // return);
    }

    sub getnetbyaddr {
        my ($self, $addr, $addrtype) = @_;
        Sidef::Types::String::String->new(CORE::getnetbyaddr($addr->get_value, $addrtype->get_value) // return);
    }

    sub getnetent {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getnetent() // return);
    }

    #
    ## getserv*
    #
    sub getservbyname {
        my ($self, $name, $proto) = @_;
        Sidef::Types::String::String->new(CORE::getservbyname($name->get_value, $proto->get_value) // return);
    }

    sub getservbyport {
        my ($self, $port, $proto) = @_;
        Sidef::Types::String::String->new(CORE::getservbyport($port->get_value, $proto->get_value) // return);
    }

    sub getservent {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::getservent() // return);
    }

    #
    ## getproto*
    #
    sub getprotobynumber {
        my ($self, $num) = @_;
        Sidef::Types::String::String->new(CORE::getprotobynumber($num->get_value) // return);
    }

    sub getprotobyname {
        my ($self, $name) = @_;
        Sidef::Types::Number::Number->new(CORE::getprotobyname($name->get_value) // return);
    }

    sub getprotoent {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::getprotoent() // return);
    }

    #
    ## set*
    #
    sub sethostent {
        my ($self, $stayopen) = @_;
        (CORE::sethostent($stayopen->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub setnetent {
        my ($self, $stayopen) = @_;
        (CORE::setnetent($stayopen->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub setprotoent {
        my ($self, $stayopen) = @_;
        (CORE::setprotoent($stayopen->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub setservent {
        my ($self, $stayopen) = @_;
        (CORE::setservent($stayopen->get_value)) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    #
    ## Socket::* functions
    #

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        state $x = require Socket;
        my $func = \&{'Socket' . '::' . $name};

        if (defined(&$func)) {
            my @results = eval {
                $func->(map { $_->get_value } @args);
            };
            if ($@) {
                my $result = $func->(map { $_->get_value } @args);
                @results = $result;
            }
            return (
                    @results > 1
                    ? (map { Sidef::Perl::Perl->to_sidef($_) } @results)
                    : Sidef::Perl::Perl->to_sidef($results[0])
                   );
        }

        warn qq{[WARN] Inexistent Socket method "$name"!\n};
        return;
    }
};

1
