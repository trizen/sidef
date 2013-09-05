package Sidef::Types::Bool::Bool {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';
    use overload q{bool} => sub { ${$_[0]} eq 'true' };

    our @ISA = qw(Sidef::Convert::Convert);

    {
        my %bool = (
                    true  => (bless \(my $t = 'true'),  __PACKAGE__),
                    false => (bless \(my $f = 'false'), __PACKAGE__),
                   );

        sub new {
            my (undef, $bool) = @_;
            $bool{$bool ? 'true' : 'false'};
        }

        sub true { $bool{true} }

        sub false { $bool{false} }
    }

    sub get_value {
        ${$_[0]} eq 'true';
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '!'} = sub {
            my ($self, $bool) = @_;
            $self->_is_bool($bool) || return;

            $$bool eq 'true'
              ? $self->false
              : $self->true;
        };

        *{__PACKAGE__ . '::' . '&&'} = \&and;
        *{__PACKAGE__ . '::' . '||'} = \&or;

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            if ($$self eq 'true') {
                my $result = Sidef::Types::Block::Code->new($code)->run;
                return Sidef::Types::Bool::Ternary->new({code => $result, bool => $self->true});
            }

            return Sidef::Types::Bool::Ternary->new({code => $code, bool => $self->false});
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

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }
}
