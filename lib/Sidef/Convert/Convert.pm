package Sidef::Convert::Convert {

    # This module is used only as parent!

    use 5.014;
    our @ISA = qw(Sidef);

    state $array_like = {
                         'Sidef::Types::Array::Array' => 1,
                         'Sidef::Types::Array::Pair'  => 1,
                         'Sidef::Types::Byte::Bytes'  => 1,
                         'Sidef::Types::Char::Chars'  => 1,
                        };

    use overload q{""} => \&stringify;

    sub stringify {
        if (ref($_[0]) eq 'Sidef::Types::Regex::Regex') {
            return $_[0]{regex};
        }

        require Scalar::Util;
        my $type = Scalar::Util::reftype($_[0]);
        if ($type eq 'SCALAR' or $type eq 'REF') {
            return ${$_[0]};
        }

        $_[0];
    }

    sub to_s {
        my ($self) = @_;

        if (exists $array_like->{ref $self}) {
            return Sidef::Types::String::String->new(join(' ', map { $_->get_value } @{$self}));
        }
        elsif (ref $self eq 'Sidef::Types::Hash::Hash') {
            return Sidef::Types::String::String->new(join(' ', map { $_->to_s } @{$self->to_a}));
        }
        elsif (ref $self eq 'Sidef::Types::Regex::Regex') {
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
        my ($self) = @_;
        $self->_is_number($self, 1, 1) || $self->_is_string($self)
          ? Sidef::Types::Number::Number->new_int($$self)
          : ();
    }

    *to_integer = \&to_i;
    *toInt      = \&to_i;
    *to_int     = \&to_i;
    *toInteger  = \&to_i;

    sub to_rat {
        my ($self) = @_;
        $self->_is_number($self, 1, 1) || $self->_is_string($self)
          ? Sidef::Types::Number::Number->new_rat($$self)
          : ();
    }

    *to_rational = \&to_rat;
    *to_r        = \&to_rat;
    *toRat       = \&to_rat;
    *toRational  = \&to_rat;

    sub to_complex {
        my ($self) = @_;
        $self->_is_number($self, 1, 1) || $self->_is_string($self)
          ? Sidef::Types::Number::Complex->new($self)
          : ();
    }

    *toComplex = \&to_complex;
    *to_c      = \&to_complex;

    sub to_num {
        my ($self) = @_;
            $self->_is_number($self, 1, 1) ? $self
          : $self->_is_string($self) ? Sidef::Types::Number::Number->new($$self)
          :                            ();
    }

    *toNum     = \&to_num;
    *to_number = \&to_num;
    *toNumber  = \&to_num;

    sub to_float {
        my ($self) = @_;
            $self->_is_number($self, 1, 1) ? $self
          : $self->_is_string($self) ? Sidef::Types::Number::Number->new_float($$self)
          :                            ();
    }

    *to_f    = \&to_float;
    *toFloat = \&to_float;

    sub to_file {
        my ($self) = @_;
        $self->_is_string($self) || return;
        Sidef::Types::Glob::File->new($$self);
    }

    *toFile = \&to_file;

    sub to_dir {
        my ($self) = @_;
        $self->_is_string($self) || return;
        Sidef::Types::Glob::Dir->new($$self);
    }

    *toDir = \&to_dir;

    sub to_bool {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self);
    }

    *toBool = \&to_bool;

    sub to_byte {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Byte::Byte->new(CORE::ord $$self);
    }

    *toByte = \&to_byte;

    sub to_char {
        my ($self) = @_;
        Sidef::Types::Char::Char->call($self);
    }

    *toChar = \&to_char;

    sub to_regex {
        my ($self) = @_;
        $self->_is_number($self, 0, 1) || $self->_is_string($self) || return;
        Sidef::Types::Regex::Regex->new($$self);
    }

    *toRe    = \&to_regex;
    *to_re   = \&to_regex;
    *toRegex = \&to_regex;

    sub to_bytes {
        my ($self) = @_;
        Sidef::Types::Byte::Bytes->call($self);
    }

    *toBytes = \&to_bytes;

    sub to_chars {
        my ($self) = @_;
        Sidef::Types::Char::Chars->call($self);
    }

    *toChars = \&to_chars;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self);
    }

    *toArray = \&to_array;

    sub to_caller {
        my ($self) = @_;
        $self->_is_string($self) || return;
        Sidef::Module::Caller->_new(module => $$self);
    }

    *toCaller = \&to_caller;

    sub to_fcaller {
        my ($self) = @_;
        $self->_is_string($self) || return;
        Sidef::Module::Func->_new(module => $$self);
    }

    *toFcaller = \&to_fcaller;
};

1
