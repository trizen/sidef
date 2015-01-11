package Sidef::Variable::ClassVar {

    use 5.014;
    our $AUTOLOAD;

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;
        $self->{class}{__VARS__}{$self->{name}};
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
