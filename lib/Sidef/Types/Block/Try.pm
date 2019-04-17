package Sidef::Types::Block::Try {

    use utf8;
    use 5.016;

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub try {
        my ($self, $block) = @_;

        my $error = 0;
        local $SIG{__WARN__} = sub { $self->{type} = 'warning'; $self->{msg} = $_[0]; $error = 1 };
        local $SIG{__DIE__}  = sub { $self->{type} = 'error';   $self->{msg} = $_[0]; $error = 1 };

        $self->{val} = [eval { $block->run }];

        if ($@ || $error) {
            $self->{catch} = 1;
        }

        $self;
    }

    sub catch {
        my ($self, $block) = @_;

        my @ret;

        if (defined($block) and $self->{catch}) {
            @ret = $block->run(Sidef::Types::String::String->new($self->{type}),
                               Sidef::Types::String::String->new($self->{msg} =~ s/^\[.*?\]\h*//r)->chomp);
        }
        else {
            @ret = @{$self->{val}};
        }

        wantarray ? @ret : $ret[-1];
    }

};

1
