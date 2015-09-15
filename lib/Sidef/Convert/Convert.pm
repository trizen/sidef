package Sidef::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    use overload;

    sub to_s {
        my ($self) = @_;
        $self->isa('SCALAR')
          || $self->isa('REF')
          ? Sidef::Types::String::String->new(overload::StrVal($self) ? "$self" : defined($$self) ? "$$self" : "")
          : $self;
    }

    *to_str = \&to_s;

    sub to_obj {
        my ($self, $obj) = @_;
        return $self if ref($self) eq ref($obj);
        $obj->new($self);
    }

    sub to_i {
        Sidef::Types::Number::Number->new_int($_[0]->get_value);
    }

    *to_int = \&to_i;

    sub to_rat {
        Sidef::Types::Number::Number->new_rat($_[0]->get_value);
    }

    *to_rational = \&to_rat;
    *to_r        = \&to_rat;

    sub to_complex {
        Sidef::Types::Number::Complex->new($_[0]->get_value);
    }

    *to_c = \&to_complex;

    sub to_n {
        Sidef::Types::Number::Number->new($_[0]->get_value);
    }

    *to_num    = \&to_n;
    *to_number = \&to_n;

    sub to_float {
        Sidef::Types::Number::Number->new_float($_[0]->get_value);
    }

    *to_f = \&to_float;

    sub to_file {
        Sidef::Types::Glob::File->new($_[0]->get_value);
    }

    sub to_dir {
        Sidef::Types::Glob::Dir->new($_[0]->get_value);
    }

    sub to_bool {
        Sidef::Types::Bool::Bool->new($_[0]->get_value);
    }

    sub to_byte {
        Sidef::Types::Byte::Byte->new(CORE::ord($_[0]->get_value));
    }

    sub to_char {
        Sidef::Types::Char::Char->call($_[0]->get_value);
    }

    sub to_regex {
        Sidef::Types::Regex::Regex->new($_[0]->get_value);
    }

    *to_re = \&to_regex;

    sub to_bytes {
        Sidef::Types::Byte::Bytes->call($_[0]->get_value);
    }

    sub to_chars {
        Sidef::Types::Char::Chars->call($_[0]->get_value);
    }

    sub to_array {
        Sidef::Types::Array::Array->new($_[0]);
    }

    sub to_caller {
        Sidef::Module::OO->__NEW__($_[0]->get_value);
    }

    sub to_fcaller {
        Sidef::Module::Func->__NEW__($_[0]->get_value);
    }
};

1
