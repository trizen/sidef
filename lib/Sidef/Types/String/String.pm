
use 5.014;
use strict;
use warnings;

package Sidef::Types::String::String {

    use parent qw(Sidef::Convert::Convert);

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
            __PACKAGE__->new($_[0] x $_[1]);
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            __PACKAGE__->new($_[0] . $_[1]);
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

        my @str = CORE::split(//, $$self);
        my $str_len = $#str;

        $offs = $$offs;
        $len = $$len if defined $len;

        $offs = 1 + $str_len + $offs if $offs < 0;
        $len = defined $len ? $len < 0 ? $str_len + $len : $offs + $len - 1 : $str_len;

        __PACKAGE__->new(CORE::join '', @str[$offs .. $len]);
    }

    sub insert {
        my ($self, $string, $pos, $len) = @_;

        $$len ||= 0;
        CORE::substr($$self, $$pos, $$len, $$string);

        return $self;
    }

    sub join {
        my ($self, $delim, @rest) = @_;
        __PACKAGE__->new(CORE::join($$delim, $$self, map { $$_ } @rest));
    }

    sub ord {
        my ($self) = @_;
        Sidef::Types::Byte::Byte->new(CORE::ord $$self);
    }

    sub reverse {
        my ($self) = @_;
        __PACKAGE__->new(scalar CORE::reverse $$self);
    }

    sub say {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::say $$self);
    }

    sub print {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::print $$self);
    }

    sub stat_file {
        my ($self) = @_;
        Sidef::Types::Glob::File->new($$self);
    }

    sub stat_dir {
        my ($self) = @_;
        Sidef::Types::Glob::Dir->new($$self);
    }
}

1;
