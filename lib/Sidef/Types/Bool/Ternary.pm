
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Ternary {

    use parent qw(Sidef::Types::Bool::Bool);

    sub new {
        my ($class, $val) = @_;
        bless $val, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . ':'} = sub {
            my ($self, $code) = @_;

            if ($self->{bool}) {
                return $self->{code};
            }

            my $exec = Sidef::Exec->new();
            my @results = $exec->execute(struct => $code);
            return $results[-1];
        };
    }

};

1;
