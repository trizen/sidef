package Sidef::Lazy::Lazy {

    use 5.014;

    our $AUTOLOAD;

    sub new {
        my (undef, $self) = @_;
        bless {root => $self}, __PACKAGE__;
    }

    sub START {
        my ($self) = @_;

        my $root = $self->{root};

        my @result;
        foreach my $item (@{$root}) {

            my $obj;
            foreach my $method (@{$self->{methods}}) {
                my $name = $method->{name};
                $obj = Sidef::Types::Array::Array->new($item)->$name(@{$method->{arg}});
                @{$obj} || last;
            }

            push @result, @{$obj};
        }

        Sidef::Types::Array::Array->new(@result);
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        push @{$self->{methods}},
          scalar {
                  name => $method,
                  arg  => \@arg,
                 };

        $self;
    }
};

1
