
use 5.014;
use strict;
use warnings;

package Sidef::Types::String::String {

    use parent qw(Sidef Sidef::Convert::Convert);

    sub new {
        my ($class, $str) = @_;
        bless \$str, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '=~'} = sub {
            $_[1]->matches($_[0]);
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $num) = @_;
            $self->_is_number($num) || return $self;
            ref($self)->new($$self x $$num);
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return $self;
            ref($self)->new($$self . $$string);
        };

        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return $self;
            Sidef::Types::Bool::Bool->new($$self eq $$string);
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            ref($self)->new(substr($$self, 0, -1));
        };

        *{__PACKAGE__ . '::' . '>'} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return $self;
            Sidef::Types::Bool::Bool->new($$self gt $$string);
        };

        *{__PACKAGE__ . '::' . '<'} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return $self;
            Sidef::Types::Bool::Bool->new($$self lt $$string);
        };

        *{__PACKAGE__ . '::' . '>='} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return $self;
            Sidef::Types::Bool::Bool->new($$self ge $$string);
        };

        *{__PACKAGE__ . '::' . '<='} = sub {
            my ($self, $string) = @_;
            $self->_is_string($string) || return $self;
            Sidef::Types::Bool::Bool->new($$self le $$string);
        };

        *{__PACKAGE__ . '::' . '..'} = sub {
            my ($self, $string) = @_;
            Sidef::Types::Array::Array->new(map { ref($self)->new($_) } $$self .. $$string);
        };
    }

    sub uc {
        my ($self) = @_;
        __PACKAGE__->new(CORE::uc $$self);
    }

    sub ucfirst {
        my ($self) = @_;
        __PACKAGE__->new(CORE::ucfirst $$self);
    }

    sub lc {
        my ($self) = @_;
        __PACKAGE__->new(CORE::lc $$self);
    }

    sub lcfirst {
        my ($self) = @_;
        __PACKAGE__->new(CORE::lcfirst $$self);
    }

    sub chop {
        my ($self) = @_;
        __PACKAGE__->new(CORE::chop $$self);
    }

    sub chomp {
        my ($self) = @_;

        CORE::chomp($$self) || return $self;
        __PACKAGE__->new($$self);
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

    sub insert {
        my ($self, $string, $pos, $len) = @_;

        $self->_is_string($string) || return $self;
        $self->_is_number($pos)    || return $self;

        if (defined $len) {
            $self->_is_number($len) || return $self;
        }
        else {
            $len = Sidef::Types::Number::Number->new(0);
        }

        CORE::substr($$self, $$pos, $$len, $$string);
        return $self;
    }

    sub join {
        my ($self, $delim, @rest) = @_;
        $self->_is_string($delim) || return $self;
        __PACKAGE__->new(CORE::join($$delim, $$self, @rest));
    }

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

    sub print {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(print $$self);
    }

    sub printf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf $$self, @arguments);
    }

    sub sprintf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(sprintf $$self, @arguments);
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::length($$self));
    }

    *len = \&length;    # alias for 'len'

    sub stat_file {
        my ($self) = @_;
        Sidef::Types::Glob::File->new($$self);
    }

    sub stat_dir {
        my ($self) = @_;
        Sidef::Types::Glob::Dir->new($$self);
    }

    sub eval {
        my ($self) = @_;

        my $parser = Sidef::Parser->new();
        my $struct = $parser->parse_script(code => $$self);

        my $exec = Sidef::Exec->new();
        my @results = $exec->execute(struct => $struct);

        return $results[-1];
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

            ${$self} =~ s{\\(.)}{$1}gs;
        }

        return $self;
    }
}

1;
