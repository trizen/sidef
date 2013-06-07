
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Ternary {

    sub new {
        my ($class, $hash_ref) = @_;
        bless $hash_ref, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . ':'} = sub {
            my ($self, $code) = @_;

            if ($self->{bool}) {
                return $self->{code};
            }

            my $exec = Sidef::Exec->new();

            my @results =
              ref($code) eq 'Sidef::Types::Block::Code'
              ? $exec->execute(struct => $code)
              : $code;

            return $results[-1];
        };
    }

};

1;
