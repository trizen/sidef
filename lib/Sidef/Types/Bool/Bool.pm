package Sidef::Types::Bool::Bool {

    use overload q{bool} => \&get_value;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    {
        my %bool = (
                    true  => (bless \(my $t = 'true'),  __PACKAGE__),
                    false => (bless \(my $f = 'false'), __PACKAGE__),
                   );

        sub new {
            my (undef, $bool) = @_;
            $bool{$bool ? 'true' : 'false'};
        }

        sub true  { $bool{true} }
        sub false { $bool{false} }
    }

    sub get_value {
        ${$_[0]} eq 'true';
    }

    {
        *{__PACKAGE__ . '::' . '&&'} = \&and;
        *{__PACKAGE__ . '::' . '&'}  = \&and;

        *{__PACKAGE__ . '::' . '||'} = \&or;
        *{__PACKAGE__ . '::' . '|'}  = \&or;

        *{__PACKAGE__ . '::' . '^'}  = \&xor;
        *{__PACKAGE__ . '::' . '^^'} = \&xor;

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            if ($$self eq 'true') {
                my $result = Sidef::Types::Block::Code->new($code)->run;
                return
                  Sidef::Types::Bool::Ternary->new(code => $result,
                                                   bool => 1);
            }

            return Sidef::Types::Bool::Ternary->new(code => $code, bool => 0);
        };

        *{__PACKAGE__ . '::' . '?:'} = sub {
            my ($self, $code) = @_;

            my ($class) = keys %{$code};

            if ($$self eq 'true') {
                return Sidef::Types::Block::Code->new({$class => [$code->{$class}[0]]})->run;
            }

            return Sidef::Types::Block::Code->new({$class => [$code->{$class}[1]]})->run;
        };
    }

    sub is_true {
        my ($self) = @_;
        $self->new($$self eq 'true');
    }

    *isTrue = \&is_true;

    sub is_false {
        my ($self) = @_;
        $self->new($$self eq 'false');
    }

    *isFalse = \&is_false;

    sub not {
        my ($self) = @_;
        $$self eq 'true' ? $self->false : $self->true;
    }

    sub or {
        my ($self, $code) = @_;

        if ($$self ne 'true') {
            return Sidef::Types::Block::Code->new($code)->run;
        }

        $self->true;
    }

    sub and {
        my ($self, $code) = @_;

        if ($$self eq 'true') {
            return Sidef::Types::Block::Code->new($code)->run;
        }

        $self->false;
    }

    sub xor {
        my ($self, $val) = @_;

        if (($$self eq 'true' and $val) || ($$self eq 'false' and !$val)) {
            return $self->false;
        }

        $self->true;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

};

1
