package Sidef::Types::Glob::Backtick {

    use 5.014;

    sub new {
        my (undef, $backtick) = @_;
        bless \$backtick, __PACKAGE__;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '`'} = sub {
            my ($self) = @_;
            if (ref $$self eq 'HASH') {
                state $exec = Sidef::Exec->new;
                $self = $exec->execute($$self);
            }
            Sidef::Types::String::String->new(scalar `$$self`);
        };
    }
};

1
