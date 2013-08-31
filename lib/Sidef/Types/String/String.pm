package Sidef::Types::String::String {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $str) = @_;
        bless \$str, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '=~'} = \&match;
        *{__PACKAGE__ . '::' . '*'}  = \&times;
        *{__PACKAGE__ . '::' . '+'}  = \&append;

        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return;
            if ((my $ind = CORE::index($$self, $$string)) != -1) {
                return $self->new(CORE::substr($$self, 0, $ind) . CORE::substr($$self, $ind + CORE::length($$string)));
            }
            $self;
        };

        *{__PACKAGE__ . '::' . '=='} = \&is;

        *{__PACKAGE__ . '::' . '!='} = sub {
            my ($self, $string) = @_;
            ref($self) ne ref($string) and return Sidef::Types::Bool::Bool->true;
            Sidef::Types::Bool::Bool->new($$self ne $$string);
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            $self->new(substr($$self, 0, -1));
        };

        *{__PACKAGE__ . '::' . '>'} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return;
            Sidef::Types::Bool::Bool->new($$self gt $$string);
        };

        *{__PACKAGE__ . '::' . '<'} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return;
            Sidef::Types::Bool::Bool->new($$self lt $$string);
        };

        *{__PACKAGE__ . '::' . '>='} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return;
            Sidef::Types::Bool::Bool->new($$self ge $$string);
        };

        *{__PACKAGE__ . '::' . '<='} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return;
            Sidef::Types::Bool::Bool->new($$self le $$string);
        };

        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;

        *{__PACKAGE__ . '::' . '<<'} = sub {
            my ($self, $i) = @_;

            $self->_is_number($i) || return $self;

            my $len = CORE::length($$self);
            $i = $$i > $len ? $len : $$i;
            $self->new(CORE::substr($$self, $i));
        };

        *{__PACKAGE__ . '::' . '>>'} = sub {
            my ($self, $i) = @_;
            $self->_is_number($i) || return $self;
            $self->new(CORE::substr($$self, 0, -$$i));
        };

        *{__PACKAGE__ . '::' . '..'} = \&to;

        *{__PACKAGE__ . '::' . '^^'} = \&begins_with;
        *{__PACKAGE__ . '::' . '$$'} = \&ends_with;
    }

    sub match {
        if (ref($_[1]) eq 'Sidef::Types::Regex::Regex') {
            return $_[1]->matches($_[0]);
        }

        warn "[WARN] Expected a regex obj for method =~, not '", ref($_[1]), "'!\n";
        Sidef::Types::Bool::Bool->false;
    }

    sub to {
        my ($self, $string) = @_;
        Sidef::Types::Array::Array->new(map { $self->new($_) } $$self .. $$string);
    }

    sub cmp {
        my ($self, $string) = @_;
        $self->_is_string($string) || return Sidef::Types::Number::Number->new(-1);
        Sidef::Types::Number::Number->new($$self cmp $$string);
    }

    sub times {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self x $$num);
    }

    sub repeat {
        my ($self, $num) = @_;
        $num //= Sidef::Types::Number::Number->new(1);
        $self->times($num);
    }

    sub uc {
        my ($self) = @_;
        $self->new(CORE::uc $$self);
    }

    *toUpperCase = \&uc;

    sub is {
        my ($self, $string) = @_;
        ref($self) ne ref($string) and return Sidef::Types::Bool::Bool->false;
        Sidef::Types::Bool::Bool->new($$self eq $$string);
    }

    *equals = \&is;

    sub append {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        $self->new($$self . $$string);
    }

    sub ucfirst {
        my ($self) = @_;
        $self->new(CORE::ucfirst $$self);
    }

    *tc         = \&ucfirst;
    *titleCase  = \&ucfirst;
    *title_case = \&ucfirst;

    sub lc {
        my ($self) = @_;
        $self->new(CORE::lc $$self);
    }

    *toLowerCase = \&lc;

    sub lcfirst {
        my ($self) = @_;
        $self->new(CORE::lcfirst $$self);
    }

    sub tclc {
        my ($self) = @_;
        $self->new(CORE::ucfirst(CORE::lc($$self)));
    }

    sub charAt {
        my ($self, $pos) = @_;
        $self->_is_number($pos) || return $self;
        Sidef::Types::Char::Char->new(CORE::substr($$self, $$pos, 1));
    }

    *char_at = \&charAt;

    sub wordcase {
        my ($self) = @_;

        my $string = $1
          if ($$self =~ /\G(\s+)/gc);

        while ($$self =~ /\G(\S++)(\s*+)/gc) {
            $string .= CORE::ucfirst(CORE::lc($1)) . $2;
        }

        $self->new($string);
    }

    *wc       = \&wordcase;
    *wordCase = \&wordcase;

    sub chop {
        my ($self) = @_;
        $self->new(CORE::substr($$self, 0, -1));
    }

    sub chomp {
        my ($self) = @_;

        if (substr($$self, -1) eq "\n") {
            return $self->chop;
        }

        $self;
    }

    sub crypt {
        my ($self, $salt) = @_;
        $self->_is_string($salt) || return;
        $self->new(crypt($$self, $$salt));
    }

    sub substr {
        my ($self, $offs, $len) = @_;

        $self->_is_number($offs) || return $self;

        my @str = CORE::split(//, $$self);
        my $str_len = $#str;

        $offs = $$offs;

        if (defined $len) {
            $self->_is_number($len) || return $self;
            $len = $$len;
        }

        $offs = 1 + $str_len + $offs if $offs < 0;
        $len = defined $len ? $len < 0 ? $str_len + $len : $offs + $len - 1 : $str_len;

        __PACKAGE__->new(CORE::join '', @str[$offs .. $len]);
    }

    *substring = \&substr;

    sub insert {
        my ($self, $string, $pos, $len) = @_;

        ($self->_is_string($string) && $self->_is_number($pos))
          || return $self;

        if (defined $len) {
            $self->_is_number($len) || return $self;
        }
        else {
            $len = Sidef::Types::Number::Number->new(0);
        }

        CORE::substr($$self, $$pos, $$len, $$string);
        return $self;
    }

    *insert_at = \&insert;
    *insertAt  = \&insert;

    sub join {
        my ($self, $delim, @rest) = @_;
        $self->_is_string($delim) || return $self;
        __PACKAGE__->new(CORE::join($$delim, $$self, @rest));
    }

    sub index {
        my ($self, $substr, $pos) = @_;
        $self->_is_string($substr) || return $self;

        if (defined($pos)) {
            $self->_is_number($pos) || return $self;
        }

        Sidef::Types::Number::Number->new(
                                          defined($pos)
                                          ? CORE::index($$self, $$substr, $$pos)
                                          : CORE::index($$self, $$substr)
                                         );
    }

    *indexOf = \&index;

    sub ord {
        my ($self) = @_;
        Sidef::Types::Byte::Byte->new(CORE::ord($$self));
    }

    sub reverse {
        my ($self) = @_;
        __PACKAGE__->new(scalar CORE::reverse($$self));
    }

    sub say {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::say($$self));
    }

    *println = \&say;

    sub print {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(print $$self);
    }

    sub printf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf $$self, @arguments);
    }

    sub printlnf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf($$self . "\n", @arguments));
    }

    sub sprintf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(CORE::sprintf $$self, @arguments);
    }

    sub sprintlnf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(CORE::sprintf($$self . "\n", @arguments));
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        $self->_is_string($str) || return;

        if (ref($regex) ne 'Sidef::Types::Regex::Regex') {
            if ($regex->can('quotemeta')) {
                $regex = $regex->quotemeta();
            }
        }

        $self->new($$self =~ s{$regex}{$$str}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        $self->_is_string($str) || return;

        if (ref($regex) ne 'Sidef::Types::Regex::Regex') {
            if ($regex->can('quotemeta')) {
                $regex = $regex->quotemeta();
            }
        }

        $self->new($$self =~ s{$regex}{$$str}gr);
    }

    *gSub     = \&gsub;
    *gReplace = \&gsub;

    sub glob {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::glob($$self));
    }

    sub quotemeta {
        my ($self) = @_;
        __PACKAGE__->new(CORE::quotemeta($$self));
    }

    sub split {
        my ($self, $sep, $size) = @_;

        $size = defined($size) && ($self->_is_number($size) || return $self) ? $$size : 0;

        if (ref($sep) eq '') {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(' ', $$self, $size));
        }
        elsif (ref($sep) ne 'Sidef::Types::Regex::Regex') {
            if ($sep->can('quotemeta')) {
                $sep = $sep->quotemeta();
            }
        }

        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(/$sep/, $$self, $size));
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::length($$self));
    }

    *len = \&length;

    sub eval {
        my ($self) = @_;

        my $parser = Sidef::Parser->new(script_name => '/eval/');
        my $struct = eval { $parser->parse_script(code => $$self) } // {};

        warn $@ if $@;

        return scalar eval { Sidef::Types::Block::Code->new($struct)->run };
    }

    sub contains {
        my ($self, $string, $start_pos) = @_;
        $start_pos //= Sidef::Types::Number::Number->new(0);

        ($self->_is_number($start_pos) && $self->_is_string($string))
          || return Sidef::Types::Bool::Bool->false;

        if ($$start_pos < 0) {
            $$start_pos = CORE::length($$self) + $$start_pos;
        }

        Sidef::Types::Bool::Bool->new(CORE::index($$self, $$string, $$start_pos) != -1);
    }

    sub begins_with {
        my ($self, $string) = @_;

        $self->_is_string($string)
          || return Sidef::Types::Bool::Bool->false;

        CORE::length($$self) < (my $len = CORE::length($$string))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($$self, 0, $len) eq $$string
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *starts_with = \&begins_with;
    *startsWith  = \&begins_with;
    *beginsWith  = \&begins_with;

    sub ends_with {
        my ($self, $string) = @_;

        $self->_is_string($string)
          || return Sidef::Types::Bool::Bool->false;

        CORE::length($$self) < (my $len = CORE::length($$string))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($$self, -$len) eq $$string
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *endsWith = \&ends_with;

    sub warn {
        my ($self) = @_;
        print STDERR $$self;
    }

    sub die {
        my ($self) = @_;

        $self->warn;

        exit $! if $!;              # errno
        exit $? >> 8 if $? >> 8;    # child exit status
        exit 255;                   # last resort
    }

    sub unescape {
        my ($self) = @_;
        ${$self} =~ s{\\(\W)}{$1}gs;
        $self;
    }

    sub apply_escapes {
        my ($self) = @_;

        state $esc = {
                      n => "\n",
                      f => "\f",
                      b => "\b",
                      e => "\e",
                      r => "\r",
                      t => "\t",
                     };

        {
            local $" = q{};
            ${$self} =~ s{(?<!\\)(?:\\\\)*+\K\\([@{[keys %{$esc}]}])}{$esc->{$1}}go;
            ${$self} =~ s{(?<!\\)(?:\\\\)*+\K\\([LU])((?>[^\\]+|\\[^E])*)(\\E|\z)}{

                $1 eq 'L' ? CORE::lc($2) : CORE::uc($2);

            }eg;

            ${$self} =~ s{(?<!\\)(?:\\\\)*+\K\\([lu])(.)}{

                $1 eq 'l' ? CORE::lc($2) : CORE::uc($2);

            }egs;
        }

        return $self;
    }

    sub dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $$self =~ s{'}{\\'}gr . q{'});
    }
}
