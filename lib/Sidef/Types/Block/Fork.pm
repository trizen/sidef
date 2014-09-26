package Sidef::Types::Block::Fork {

    use 5.014;

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    sub get {
        my ($self) = @_;

        exists($self->{result})
          or return;

        # Wait for the process to finish
        waitpid($self->{pid}, 0);

        my $ref = do($self->{result});
        unlink(delete $self->{result});
        $ref;
    }

    *wait = \&get;
};

1
