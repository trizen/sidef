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
            if (ref $$self eq 'Sidef::Types::Block::Code') {
                $self = $$self->run;
            }
            Sidef::Types::String::String->new(scalar `$$self`);
        };
    }
};

1
