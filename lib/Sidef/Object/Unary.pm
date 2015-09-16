package Sidef::Object::Unary {

    use utf8;
    use 5.014;

    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';
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
            Sidef::Types::Bool::Bool->new($_[1]);
        };

        *{__PACKAGE__ . '::' . '!'} = sub {
            Sidef::Types::Bool::Bool->new(not $_[1]);
        };

        *{__PACKAGE__ . '::' . '>'} = sub {
            Sidef::Types::Bool::Bool->new(say join(" ", @_[1 .. $#_]));
        };

        *{__PACKAGE__ . '::' . '>>'} = sub {
            Sidef::Types::Bool::Bool->new(print join(" ", @_[1 .. $#_]));
        };
    }
};

1;
