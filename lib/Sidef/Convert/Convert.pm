package Sidef::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    use overload;
    use Sidef::Types::Bool::Bool;

    sub to_str {
        my ($self) = @_;
        UNIVERSAL::isa($self, 'SCALAR')
          || UNIVERSAL::isa($self, 'REF')
          ? Sidef::Types::String::String->new(overload::StrVal($self) ? "$self" : defined($$self) ? "$$self" : "")
          : $self;
    }

    *to_s = \&to_str;

    sub to_obj {
        my ($self, $obj) = @_;
        return $self if ref($self) eq ref($obj);
        $obj->new($self);
    }

    sub to_int {
        Sidef::Types::Number::Number->new($_[0])->int;
    }

    *to_i = \&to_int;

    sub to_num {
        Sidef::Types::Number::Number->new($_[0]);
    }

    *to_n = \&to_num;

    sub to_float {
        Sidef::Types::Number::Number->new($_[0])->float;
    }

    *to_f = \&to_float;

    sub to_rat {
        Sidef::Types::Number::Number->new($_[0])->rat;
    }

    *to_r = \&to_rat;

    sub to_array {
        Sidef::Types::Array::Array->new($_[0]);
    }

    *to_a = \&to_array;

    sub to_file {
        Sidef::Types::Glob::File->new("$_[0]");
    }

    sub to_dir {
        Sidef::Types::Glob::Dir->new("$_[0]");
    }

    sub to_bool {
        $_[0]
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *to_b = \&to_bool;

    sub to_regex {
        Sidef::Types::Regex::Regex->new("$_[0]");
    }

    *to_re = \&to_regex;

    sub to_caller {
        Sidef::Module::OO->__NEW__("$_[0]");
    }

    sub to_fcaller {
        Sidef::Module::Func->__NEW__("$_[0]");
    }
};

1
