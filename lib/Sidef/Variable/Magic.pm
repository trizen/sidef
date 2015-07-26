package Sidef::Variable::Magic {

    use 5.014;
    our $AUTOLOAD;

    use overload q{""} => \&get_value;

    sub new {
        my (undef, $var, $numeric) = @_;
        bless {ref => $var, numeric => $numeric}, __PACKAGE__;
    }

    sub set_value {
        my ($self, $value) = @_;
        ${$self->{ref}} = $value->get_value;
    }

    sub get_value {
        my ($self) = @_;

        my $var = $self->{ref};
        my $type =
          $self->{numeric}
          ? 'Sidef::Types::Number::Number'
          : 'Sidef::Types::String::String';

        $type->new($$var);
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        $self->get_value->$method(@args);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '='} = \&set_value;
    }
};

1;
