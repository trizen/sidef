package Sidef::Variable::ClassVar {

    use 5.014;
    our $AUTOLOAD;

    use overload q{""} => \&get_value;

    sub __new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;
        $self->{class}{__VARS__}{$self->{name}};
    }

    sub dump {
        my ($self) = @_;
        $self->get_value->dump;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my $var = Sidef::Variable::Variable->new(
                                                 type  => 'var',
                                                 name  => $self->{name},
                                                 value => $self->{class}{__VARS__}{$self->{name}},
                                                );

        my $result = $var->$name(@args);
        $self->{class}{__VARS__}{$self->{name}} = $var->get_value;
        $result;
    }
};

1
