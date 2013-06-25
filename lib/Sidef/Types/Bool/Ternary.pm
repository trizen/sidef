
use 5.014;
use strict;
use warnings;

package Sidef::Types::Bool::Ternary {

    use parent qw(Sidef);

    require Sidef::Exec;
    my $exec = Sidef::Exec->new;

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

            my @results = $exec->execute(struct => $code);
            $results[-1];
        };
    }

};

1;
