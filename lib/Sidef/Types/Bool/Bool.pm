
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

}

1;
