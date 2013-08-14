package Sidef::Types::Bool::Bool {

    use 5.014;
    use strict;
    use warnings;
    use overload q{bool} => sub { ${$_[0]} eq 'true' };

    our @ISA = qw(Sidef::Convert::Convert);

    sub new {
        my (undef, $bool) = @_;

        $bool = $$bool if (ref $bool);

        # Decide if true or false
        $bool = $bool ? 'true' : 'false';

        bless \$bool, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]} eq 'true';
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '!'} = sub {
            my ($self, $bool) = @_;
            $self->_is_bool($bool) || return $self;
            $self->new(!$bool);
        };

        *{__PACKAGE__ . '::' . '&&'} = \&and;
        *{__PACKAGE__ . '::' . '||'} = \&or;

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            if ($self) {
                my $result = Sidef::Types::Block::Code->new($code)->run;
                return Sidef::Types::Bool::Ternary->new({code => $result, bool => $self->true});
            }

            return Sidef::Types::Bool::Ternary->new({code => $code, bool => $self->false});
        };
    }

    sub true {
        my ($self) = @_;
        $self->new(1);
    }

    sub false {
        my ($self) = @_;
        $self->new(0);
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
        $self ? $self->false : $self->true;
    }

    sub or {
        my ($self, $code) = @_;

        if (!$self) {
            return Sidef::Types::Block::Code->new($code)->run;
        }

        $self->true;
    }

    sub and {
        my ($self, $code) = @_;

        if ($self) {
            return Sidef::Types::Block::Code->new($code)->run;
        }

        $self->false;
    }

    sub flip {
        my ($self) = @_;
        $$self = $$self eq 'true' ? 'false' : 'true';
        $self;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }
}
