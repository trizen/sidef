package Sidef::Types::Block::Gather {

    use 5.014;

    sub new {
        my (undef, $block) = @_;
        bless {block => $block}, __PACKAGE__;
    }

    sub gather {
        my ($self) = @_;

        local $self->{values} = [];

        sub take {
            my ($self, @args) = @_;
            push @{$self->{values}}, @args;
        }

        $self->{block}->run;
        Sidef::Types::Array::Array->new(@{$self->{values}});
    }
}

1;
