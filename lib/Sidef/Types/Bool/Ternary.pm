package Sidef::Types::Bool::Ternary {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    {
        *{__PACKAGE__ . '::' . ':'} = sub {
            my ($self, $code) = @_;

            $self->{bool}
              && return $self->{code};

            Sidef::Types::Block::Code->new($code)->run;
        };
    }

};

1
