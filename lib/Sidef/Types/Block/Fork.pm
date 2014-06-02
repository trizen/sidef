package Sidef::Types::Block::Fork {

    use 5.014;

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    sub get {
        my ($self) = @_;

        # Wait for the process to finish
        waitpid($self->{pid}, 0);

        my $ref = do($self->{result});
        unlink $self->{file};
        $ref;
    }

    sub unlink {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(unlink $self->{result});
    }
};

1
