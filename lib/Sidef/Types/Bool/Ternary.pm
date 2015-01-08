package Sidef::Types::Bool::Ternary {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    *{__PACKAGE__ . '::' . ':'} = sub {
        my ($self, $code) = @_;
        Sidef::Types::Block::Code->new($self->{bool} ? $self->{code} : $code)->run;
    };

};

1
