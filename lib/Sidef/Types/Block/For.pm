package Sidef::Types::Block::For {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, @args) = @_;
        $self->{arg} = \@args;
        $self;
    }

    sub foreach {
        my ($self, $arr) = @_;
        $self->{arg} = $arr;
        $self;
    }

    sub do {
        my ($self, $code) = @_;
        ref($self->{arg}) eq 'ARRAY'
          ? $code->for(@{$self->{arg}})
          : $self->{arg}->each($code);
    }
};

1
