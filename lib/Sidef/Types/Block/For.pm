package Sidef::Types::Block::For {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, @args) = @_;
        $self->{arg} = \@args;
        $self;
    }

    *foreach = \&for;

    sub do {
        my ($self, $code) = @_;
        $code->for(@{$self->{arg}});
    }
};

1
