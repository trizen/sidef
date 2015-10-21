package Sidef::Variable::ClassInit {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub __set_params__ {
        my ($self, $names) = @_;
        $self->{__VARS__} = $names;
    }

    sub __set_block__ {
        my ($self, $block) = @_;
        $self->{__BLOCK__} = $block;
        $self;
    }

    sub __add_method__ {
        my ($self, $name, $method) = @_;
        $self->{__METHODS__}{$name} = $method;
        $self;
    }

    sub __add_vars__ {
        my ($self, $vars) = @_;
        push @{$self->{__DEF_VARS__}}, @{$vars};
        $self;
    }
};

1;
