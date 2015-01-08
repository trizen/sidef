package Sidef::Types::Bool::Bool {

    use overload
      q{bool} => \&get_value,
      q{""}   => sub { ${$_[0]} ? 'true' : 'false' };

    our @ISA = qw(
      Sidef::Object::Object
      );

    {
        my %bool = (
                    true  => (bless \(my $t = 1),  __PACKAGE__),
                    false => (bless \(my $f = ''), __PACKAGE__),
                   );

        sub new {
            my (undef, $bool) = @_;
            $bool{$bool ? 'true' : 'false'};
        }

        *call = \&new;

        sub true  { $bool{true} }
        sub false { $bool{false} }
    }

    sub get_value {
        ${$_[0]};
    }

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

    # Ternary operator (BOOL ? TrueExpr : FalseExpr)
    *{__PACKAGE__ . '::' . '?'} = sub {
        my ($self, $code) = @_;
        Sidef::Types::Bool::Ternary->new(code => $code, bool => $self->get_value);
    };

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->get_value ? 'true' : 'false');
    }

};

1
