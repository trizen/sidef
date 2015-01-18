package Sidef::Object::Unary {

    use utf8;
    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        *{__PACKAGE__ . '::' . '+'} = sub {
            $_[1];
        };

        *{__PACKAGE__ . '::' . '~'} = sub {
            $_[1]->not;
        };

        *{__PACKAGE__ . '::' . '-'} = sub {
            $_[1]->negate;
        };

        *{__PACKAGE__ . '::' . '√'} = sub {
            $_[1]->sqrt;
        };

        *{__PACKAGE__ . '::' . '?'} = sub {
            Sidef::Types::Bool::Bool->new($_[1]->get_value);
        };

        *{__PACKAGE__ . '::' . '!'} = sub {
            Sidef::Types::Bool::Bool->new(not $_[1]->get_value);
        };
    }
};

1;
