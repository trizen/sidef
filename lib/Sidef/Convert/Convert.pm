package Sidef::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    our @ISA = qw(Sidef);

    use overload q{""} => \&stringify;

    sub stringify {
        if (ref($_[0]) eq 'Sidef::Types::Regex::Regex') {
            return $_[0]{regex};
        }

        if ($_[0]->isa('SCALAR') || $_[0]->isa('REF')) {
            return ${$_[0]};
        }

        $_[0];
    }

    sub to_s {
        my ($self) = @_;

        if (Sidef->_is_array($self)) {
            return Sidef::Types::String::String->new(join(' ', map { $_->get_value } @{$self}));
        }

        if (Sidef->_is_hash($self)) {
            return Sidef::Types::String::String->new(join(' ', map { $_->to_s } @{$self->to_a}));
        }

        if (Sidef->_is_regex($self)) {
            return Sidef::Types::String::String->new($self->{regex});
        }

        Sidef::Types::String::String->new("$$self");
    }

    *toStr     = \&to_s;
    *to_str    = \&to_s;
    *toString  = \&to_s;
    *to_string = \&to_s;

    sub to_obj {
        my ($self, $obj) = @_;
        return $self if ref($self) eq ref($obj);
        $obj->new($self);
    }

    *to_object = \&to_obj;

    sub to_i {
        Sidef::Types::Number::Number->new_int($_[0]->get_value);
    }

    *to_integer = \&to_i;
    *toInt      = \&to_i;
    *to_int     = \&to_i;
    *toInteger  = \&to_i;

    sub to_rat {
        Sidef::Types::Number::Number->new_rat($_[0]->get_value);
    }

    *to_rational = \&to_rat;
    *to_r        = \&to_rat;
    *toRat       = \&to_rat;
    *toRational  = \&to_rat;

    sub to_complex {
        Sidef::Types::Number::Complex->new($_[0]->get_value);
    }

    *toComplex = \&to_complex;
    *to_c      = \&to_complex;

    sub to_num {
        Sidef::Types::Number::Number->new($_[0]->get_value);
    }

    *toNum     = \&to_num;
    *to_number = \&to_num;
    *toNumber  = \&to_num;

    sub to_float {
        Sidef::Types::Number::Number->new_float($_[0]->get_value);
    }

    *to_f    = \&to_float;
    *toFloat = \&to_float;

    sub to_file {
        Sidef::Types::Glob::File->new($_[0]->get_value);
    }

    *toFile = \&to_file;

    sub to_dir {
        Sidef::Types::Glob::Dir->new($_[0]->get_value);
    }

    *toDir = \&to_dir;

    sub to_bool {
        Sidef::Types::Bool::Bool->new($_[0]->get_value);
    }

    *toBool = \&to_bool;

    sub to_byte {
        Sidef::Types::Byte::Byte->new(CORE::ord($_[0]->get_value));
    }

    *toByte = \&to_byte;

    sub to_char {
        Sidef::Types::Char::Char->call($_[0]->get_value);
    }

    *toChar = \&to_char;

    sub to_regex {
        Sidef::Types::Regex::Regex->new($_[0]->get_value);
    }

    *toRe    = \&to_regex;
    *to_re   = \&to_regex;
    *toRegex = \&to_regex;

    sub to_bytes {
        Sidef::Types::Byte::Bytes->call($_[0]->get_value);
    }

    *toBytes = \&to_bytes;

    sub to_chars {
        Sidef::Types::Char::Chars->call($_[0]->get_value);
    }

    *toChars = \&to_chars;

    sub to_array {
        Sidef::Types::Array::Array->new($_[0]);
    }

    *toArray = \&to_array;

    sub to_caller {
        Sidef::Module::Caller->_new(module => $_[0]->get_value);
    }

    *toCaller = \&to_caller;

    sub to_fcaller {
        Sidef::Module::Func->_new(module => $_[0]->get_value);
    }

    *toFcaller = \&to_fcaller;
};

1
