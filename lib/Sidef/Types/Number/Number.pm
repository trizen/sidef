
use 5.014;
use strict;
use warnings;

package Sidef::Types::Number::Number {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ( $class, $num ) = @_;
        bless \$num, $class;
    }

    {
        no strict 'refs';

        *{ __PACKAGE__ . '::' . '/' } = sub {
            my ( $self, $div ) = @_;
            __PACKAGE__->new( $$self / $$div );
        };

        *{ __PACKAGE__ . '::' . '*' } = sub {
            my ( $self, $div ) = @_;
            __PACKAGE__->new( $$self * $$div );
        };

        *{ __PACKAGE__ . '::' . '+' } = sub {
            my ( $self, $div ) = @_;
            __PACKAGE__->new( $$self + $$div );
        };

        *{ __PACKAGE__ . '::' . '-' } = sub {
            my ( $self, $div ) = @_;
            __PACKAGE__->new( $$self - $$div );
        };

        *{ __PACKAGE__ . '::' . '%' } = sub {
            my ( $self, $div ) = @_;
            __PACKAGE__->new( $$self % $$div );
        };
    }

    sub sqrt {
        my ($self) = @_;
        Number::Float->new( CORE::sqrt $$self );
    }

    sub abs {
        my ($self) = @_;
        __PACKAGE__->new( CORE::abs $$self );
    }

    sub int {
        my ($self) = @_;
        Number::Integer->new($$self);
    }

    sub log {
        my ($self) = @_;
        Number::Float->new( CORE::log $$self );
    }

    sub log10 {
        my ($self) = @_;
        Number::Float->new( CORE::log($$self) / CORE::log(10) );
    }

    sub log2 {
        my ($self) = @_;
        Number::Float->new( CORE::log($$self) / CORE::log(2) );
    }
};

1;
