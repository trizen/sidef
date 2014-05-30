package Sidef::Types::Block::Fork {

    use 5.014;
    use Time::HiRes qw(sleep);

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    sub get {
        my ($self) = @_;

        while (-z $self->{result}) {
            sleep 0.01;
        }

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
