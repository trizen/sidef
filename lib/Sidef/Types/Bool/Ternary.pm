
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Ternary {

    use parent qw(Sidef);

    sub new {
        my (undef, $hash_ref) = @_;
        bless $hash_ref, __PACKAGE__;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . ':'} = sub {
            my ($self, $code) = @_;

            if ($self->{bool}) {
                return $self->{code};
            }

            Sidef::Types::Block::Code->new($code)->run;
        };
    }

};

1;
