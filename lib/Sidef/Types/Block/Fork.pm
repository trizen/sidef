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

        # Return when the fork doesn't hold a result
        exists($self->{result})
          or return;

        state $x = require Storable;
        my $ref = eval { Storable::retrieve($self->{result}) };
        unlink(delete $self->{result});
        $ref;
    }

    *wait = \&get;
    *join = \&get;

    sub kill {
        my ($self, $signal) = @_;
        kill(defined($signal) ? $signal->get_value : 'KILL', $self->{pid});
    }
};

1
