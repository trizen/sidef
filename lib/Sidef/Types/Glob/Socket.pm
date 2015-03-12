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

            require Socket;
            my $func = \&{'Socket' . '::' . $name};

            if (defined(&$func)) {
                return $CACHE{$name} = Sidef::Perl::Perl->to_sidef(scalar $func->());
            }

            warn qq{[WARN] ** Inexistent Socket constant "$name"!\n};
            return;
        }
    }

    sub open {
        my ($self, $domain, $type, $protocol) = @_;
        CORE::socket(my $fh, $domain->get_value, $type->get_value, $protocol->get_value) || return;
        Sidef::Types::Glob::SocketHandle->new(fh => $fh);
    }

    sub getprotobyname {
        my ($self, @args) = @_;
        Sidef::Types::Number::Number->new(scalar CORE::getprotobyname(map { $_->get_value } @args));
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        require Socket;
        my $func = \&{'Socket' . '::' . $name};

        if (defined(&$func)) {
            my @results = eval {
                $func->(map { $_->get_value } @args);
            };
            if ($@) {
                my $result = $func->(map { $_->get_value } @args);
                @results = $result;
            }
            if (@results > 1) {
                return Sidef::Types::Array::Array->new(map { Sidef::Perl::Perl->to_sidef($_) } @results);
            }
            return Sidef::Perl::Perl->to_sidef($results[0]);
        }

        warn qq{[WARN] ** Inexistent Socket method "$name"!\n};
        return;
    }
};

1
