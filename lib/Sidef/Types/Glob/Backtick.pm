package Sidef::Types::Glob::Backtick {

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, $backtick) = @_;
        bless \$backtick, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]};
    }

    sub run {
        my ($self) = @_;
        Sidef::Types::String::String->new(scalar `$$self`)->decode_utf8;
    }

    *execute = \&run;
    *exec    = \&run;

    *{__PACKAGE__ . '::' . '`'} = \&run;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                                 'Backtick.new(' . Sidef::Types::String::String->new($self->get_value)->dump->get_value . ')');
    }
};

1
