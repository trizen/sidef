
use 5.014;
use strict;
use warnings;

package Sidef::Types::Regex::Regex {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class, $regex, $mod) = @_;

        $mod //= q{^};
        my $str_re = Sidef::Types::String::String->new("(?$mod:$regex)");

        bless \$str_re, $class;
    }

    sub matches {
        my ($self, $object) = @_;

        if (ref $object eq 'Sidef::Types::Array::Array') {
            foreach my $item (@{$object}) {
                my $bool = $self->matches($item);
                $bool && return $bool;
            }
        }

        Sidef::Types::Bool::Bool->new($object =~ $$self);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=~'} = \&matches;    # alias to the 'matches' method
    }

}

1;
