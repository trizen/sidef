package Sidef::Types::Block::Try {

    use 5.014;

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub try {
        my ($self, $code) = @_;

        my $error = 0;
        local $SIG{__WARN__} = sub { $self->{type} = 'warning'; $self->{msg} = $_[0]; $error = 1 };
        local $SIG{__DIE__}  = sub { $self->{type} = 'error';   $self->{msg} = $_[0]; $error = 1 };

        $self->{val} = eval { $code->run };

        if ($@ || $error) {
            $self->{catch} = 1;
        }

        $self;
    }

    sub catch {
        my ($self, $code) = @_;

        $self->{catch}
          ? $code->run(Sidef::Types::String::String->new($self->{type}),
                       Sidef::Types::String::String->new($self->{msg} =~ s/^\[.*?\]\h*//r)->chomp)
          : $self->{val};
    }

};

1
