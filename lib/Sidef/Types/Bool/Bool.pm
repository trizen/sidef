
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Bool {

    use parent qw(Sidef::Convert::Convert);

    use overload
      q{bool} => sub { ${$_[0]} eq ${__PACKAGE__->true} },
      ;

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

            if ($self->is_true) {
                my $exec = Sidef::Exec->new();
                my @results = $exec->execute(struct => $code);

                return __PACKAGE__->new($results[-1]->is_true);
            }

            __PACKAGE__->false;
        };

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            if ($self->is_true) {
                my $exec = Sidef::Exec->new();
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
        $$self eq ${$self->true} ? $self->true : $self->false;
    }

    sub is_false {
        my ($self) = @_;
        $$self eq ${$self->false} ? $self->true : $self->false;
    }

    sub not {
        my ($self) = @_;
        $self->is_true ? __PACKAGE__->false : __PACKAGE__->true;
    }

    sub else {
        my ($self, $code) = @_;

        if ($self->is_false) {

            if (ref $code eq __PACKAGE__) {
                return $code;
            }

            my $exec = Sidef::Exec->new();
            $exec->execute(struct => $code);
        }

        return $self;
    }

}

1;
