package Sidef::Types::Glob::Backtick {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        my (undef, $backtick) = @_;
        bless \$backtick, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]};
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '`'} = sub {
            my ($self) = @_;
            Sidef::Types::String::String->new(scalar `$$self`)->decode_utf8;
        };
    }
};

1
