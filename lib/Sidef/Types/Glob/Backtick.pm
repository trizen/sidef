package Sidef::Types::Glob::Backtick {

    use parent qw(
      Sidef::Object::Object
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, $backtick) = @_;
        bless \$backtick, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub run {
        my ($self) = @_;
        Sidef::Types::String::String->new(scalar `$$self`);
    }

    *execute = \&run;
    *exec    = \&run;

    *{__PACKAGE__ . '::' . '`'} = \&run;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                                     'Backtick(' . Sidef::Types::String::String->new($self->get_value)->dump->get_value . ')');
    }
};

1
