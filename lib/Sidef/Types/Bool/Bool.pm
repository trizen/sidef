
use 5.016;
use strict;
use warnings;

package Sidef::Types::Bool::Bool {

     use parent qw(Sidef::Convert::Convert);

  use overload
      q{bool} => sub { ${$_[0]} eq ${__PACKAGE__->true} },
      ;

    sub new {
        my ($class, $bool) = @_;
        bless \$bool, $class;
    }

    sub true {
        my ($self) = @_;
        __PACKAGE__->new('true');
    }

    sub false {
        my ($self) = @_;
        __PACKAGE__->new('false');
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
