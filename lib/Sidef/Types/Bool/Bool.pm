
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Bool {

    use parent qw(Sidef::Convert::Convert);
    use overload q{bool} => sub { ${$_[0]} eq 'true' };

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        my ($class, $bool) = @_;

        # Decide if true or false
        $bool = $bool ? 'true' : 'false';

        bless \$bool, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '&&'} = sub {
            my ($self, $code) = @_;

            if ($self) {
                my @results = $exec->execute(struct => $code);
                return $results[-1];
            }

            __PACKAGE__->false;
        };

        *{__PACKAGE__ . '::' . '||'} = sub {
            my ($self, $code) = @_;

            if (not $self) {
                my @results = $exec->execute(struct => $code);
                return $results[-1];
            }

            __PACKAGE__->true;
        };

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            if ($self) {
                my @results = $exec->execute(struct => $code);
                return Sidef::Types::Bool::Ternary->new({code => $results[-1], bool => __PACKAGE__->true});
            }

            return Sidef::Types::Bool::Ternary->new({code => $code, bool => __PACKAGE__->false});
        };
    }

    sub true {
        my ($self) = @_;
        __PACKAGE__->new(1);
    }

    sub false {
        my ($self) = @_;
        __PACKAGE__->new(0);
    }

    sub is_true {
        my ($self) = @_;
        __PACKAGE__->new($$self eq 'true');
    }

    sub is_false {
        my ($self) = @_;
        __PACKAGE__->new($$self eq 'false');
    }

    sub not {
        my ($self) = @_;
        $self ? __PACKAGE__->false : __PACKAGE__->true;
    }

    sub or {
        my ($self, $code) = @_;

        if ($self->is_true) {
            return $self;
        }

        my @results = $exec->execute(struct => $code);

        if ($results[-1]->is_true) {
            return Sidef::Types::Bool::Or->true;
        }

        return $self;
    }

    sub else {
        my ($self, $code) = @_;

        if ($self->is_false) {

            if (ref $code eq __PACKAGE__) {
                return $code;
            }

            $exec->execute(struct => $code);
        }

        return $self;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

}

1;
