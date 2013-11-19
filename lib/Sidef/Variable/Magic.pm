package Sidef::Variable::Magic {

    use 5.014;
    use strict;
    use warnings;

    use overload q{""} => \&get_value;

    our $AUTOLOAD;

    sub new {
        my (undef, $var, $numeric) = @_;
        bless {ref => $var, numeric => $numeric}, __PACKAGE__;
    }

    sub set_value {
        my ($self, $value) = @_;
        ${$self->{ref}} = $value->get_value;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = \&set_value;
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

};

1;
