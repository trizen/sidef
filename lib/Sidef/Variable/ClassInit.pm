package Sidef::Variable::ClassInit {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub set_params {
        my ($self, $names) = @_;
        $self->{vars} = $names;
    }

    sub set_block {
        my ($self, $block) = @_;
        $self->{block} = $block;
        $self;
    }

    sub add_method {
        my ($self, $name, $method) = @_;
        $self->{methods}{$name} = $method;
        $self;
    }

    sub add_vars {
        my ($self, $vars) = @_;
        push @{$self->{def_vars}}, @{$vars};
        $self;
    }
};

1;
