package Sidef::Types::Bool::Bool {

    use overload
      q{bool} => \&get_value,
      q{""}   => \&dump;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    {
        my %bool = (
                    true  => (bless \(my $t = 1), __PACKAGE__),
                    false => (bless \(my $f = 0), __PACKAGE__),
                   );

        sub new {
            my (undef, $bool) = @_;
            $bool{$bool ? 'true' : 'false'};
        }

        *call = \&new;

        sub true  { $bool{true} }
        sub false { $bool{false} }
    }

    sub get_value { ${$_[0]} }
    sub to_bool   { $_[0] }

    *{__PACKAGE__ . '::' . '|'} = sub {
        my ($self, $arg) = @_;
        $self->get_value ? $self : $arg;
    };

    *{__PACKAGE__ . '::' . '&'} = sub {
        my ($self, $arg) = @_;
        $self->get_value ? $arg : $self;
    };

    sub is_true {
        $_[0];
    }

    *isTrue = \&is_true;

    sub not {
        my ($self) = @_;
        $self->get_value ? $self->false : $self->true;
    }

    *is_false = \&not;
    *isFalse  = \&not;
    *flip     = \&not;
    *toggle   = \&not;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->get_value ? 'true' : 'false');
    }

};

1
