package Sidef::Types::Number::Positive {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = sub {
            $_[1];
        };
    }

};

1;
