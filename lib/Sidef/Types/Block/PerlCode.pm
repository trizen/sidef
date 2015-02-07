package Sidef::Types::Block::PerlCode {

    use 5.014;
    use parent qw(
      Sidef::Types::Block::Code
      );

    use overload '*' => \&repeat;

    sub new {
        my (undef, $sub) = @_;
        bless {code => $sub}, __PACKAGE__;
    }

    sub _execute {
        my ($self, @args) = @_;
        $self->{code}->(@args);
    }

    sub repeat {
        my ($self, $num) = @_;
        foreach my $i (1 .. $num) {
            local $_ = $i;
            $self->_execute;
        }
        $self;
    }

    sub run {
        my ($self) = @_;
        $self->_execute;
    }

    sub call {
        my ($self, @args) = @_;
        $self->_execute(@args);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeat;
    }

};

1
