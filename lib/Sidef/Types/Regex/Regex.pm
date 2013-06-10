
use 5.014;
use strict;
use warnings;

package Sidef::Types::Regex::Regex {

    use parent qw(Sidef::Convert::Convert);

    sub new {
        my (undef, $regex, $mod) = @_;

        $mod //= q{^};
        my $str_re = "(?$mod:$regex)";

        bless \$str_re, __PACKAGE__;
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

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('/' . $$self =~ s{/}{\\/}gr . '/');
    }
}

1;
