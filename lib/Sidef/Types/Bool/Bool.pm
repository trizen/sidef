
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Bool {

    use parent qw(Sidef::Convert::Convert);
    use overload q{bool} => sub { ${$_[0]} eq 'true' };

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

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

        *{__PACKAGE__ . '::' . '&&'} = sub {
            my ($self, $code) = @_;

            if ($self) {
                my (@results) = $exec->execute(struct => $code);
                return $results[-1];
            }

            $self->false;
        };

        *{__PACKAGE__ . '::' . '||'} = sub {
            my ($self, $code) = @_;

            if (not $self) {
                my (@results) = $exec->execute(struct => $code);
                return $results[-1];
            }

            $self->true;
        };

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            if ($self) {
                my @results = ref($code) eq 'HASH' ? $exec->execute(struct => $code) : $code;
                return Sidef::Types::Bool::Ternary->new({code => $results[-1], bool => $self->true});
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

    sub is_false {
        my ($self) = @_;
        $self->new($$self eq 'false');
    }

    sub not {
        my ($self) = @_;
        $self ? $self->false : $self->true;
    }

    *or  = \&{__PACKAGE__ . '::' . '||'};
    *and = \&{__PACKAGE__ . '::' . '&&'};

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

}

1;
