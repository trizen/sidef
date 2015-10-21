package Sidef::Types::Bool::Bool {

    use overload
      q{bool} => \&get_value,
      q{0+}   => \&get_value,
      q{""}   => \&dump;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    {
        my $true  = (bless \(my $t = 1), __PACKAGE__);
        my $false = (bless \(my $f = 0), __PACKAGE__);

        sub new {
            $_[1] ? $true : $false;
        }

        *call = \&new;

        sub true  { $true }
        sub false { $false }
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

    sub not {
        my ($self) = @_;
        $self->get_value ? $self->false : $self->true;
    }

    *is_false = \&not;
    *flip     = \&not;
    *toggle   = \&not;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->get_value ? 'true' : 'false');
    }

};

1
