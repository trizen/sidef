package Sidef::Types::Block::Try {

    use utf8;
    use 5.016;

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub try {
        my ($self, $block) = @_;

        my $error = 0;
        local $SIG{__DIE__} = sub { $self->{msg} = $_[0]; $error = 1 };

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
            chomp(my $msg = $self->{msg});
            @ret = $block->run(Sidef::Types::String::String->new($msg));
        }
        else {
            @ret = @{$self->{val}};
        }

        wantarray ? @ret : $ret[-1];
    }

};

1
