package Sidef::Types::Bool::Ternary {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . ':'} = sub {
            my ($self, $code) = @_;

            $self->{bool}
              && return $self->{code};

            Sidef::Types::Block::Code->new($code)->run;
        };
    }

}
