#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 24 March 2013
# http://trizen.googlecode.com

use 5.010;
use strict;
use warnings;

package Nil {

    sub new {
        my ($class) = @_;

        # return bless \undef, $class;  # not working!

        ## needs work...
    }
}

package Convert {

    use overload q{""} => sub { ${$_[0]} };

    sub to_s {
        my ($self) = @_;
        String->new("$$self");
    }

    sub to_i {
        my ($self) = @_;
        Number::Integer->new($$self);
    }

    sub to_f {
        my ($self) = @_;
        Number::Float->new($$self);
    }

    sub to_b {
        my ($self) = @_;
        $$self ? Bool->true : Bool->false;
    }
}

package Bool {

    our @ISA = qw(Convert);

    use overload
      q{bool} => sub { ${$_[0]} eq ${__PACKAGE__->true} },
      ;

    sub new {
        my ($class, $bool) = @_;
        bless \$bool, $class;
    }

    sub true {
        my ($self) = @_;
        __PACKAGE__->new('true');
    }

    sub false {
        my ($self) = @_;
        __PACKAGE__->new('false');
    }

    sub is_true {
        my ($self) = @_;
        $$self eq ${$self->true} ? $self->true : $self->false;
    }

    sub is_false {
        my ($self) = @_;
        $$self eq ${$self->false} ? $self->true : $self->false;
    }
}

package String {

    our @ISA = qw(Convert);

    sub new {
        my ($class, $str) = @_;
        bless \$str, $class;
    }

    sub uc {
        my ($self) = @_;
        __PACKAGE__->new(CORE::uc $$self);
    }

    sub lc {
        my ($self) = @_;
        __PACKAGE__->new(CORE::lc $$self);
    }

    sub reverse {
        my ($self) = @_;
        __PACKAGE__->new(scalar CORE::reverse $$self);
    }
}

package Number {

    our @ISA = qw(Convert);

    sub new {
        my ($class, $num) = @_;
        bless \$num, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'} = sub {
            my ($self, $div) = @_;
            __PACKAGE__->new($$self / $$div);
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $div) = @_;
            __PACKAGE__->new($$self * $$div);
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $div) = @_;
            __PACKAGE__->new($$self + $$div);
        };

        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $div) = @_;
            __PACKAGE__->new($$self - $$div);
        };

        *{__PACKAGE__ . '::' . '%'} = sub {
            my ($self, $div) = @_;
            __PACKAGE__->new($$self % $$div);
        };
    }

    sub sqrt {
        my ($self) = @_;
        Number::Float->new(CORE::sqrt $$self);
    }

    sub abs {
        my ($self) = @_;
        __PACKAGE__->new(CORE::abs $$self);
    }

    sub int {
        my ($self) = @_;
        Number::Integer->new($$self);
    }

    sub log {
        my ($self) = @_;
        Number::Float->new(CORE::log $$self);
    }

    sub log10 {
        my ($self) = @_;
        Number::Float->new(CORE::log($$self) / CORE::log(10));
    }

    sub log2 {
        my ($self) = @_;
        Number::Float->new(CORE::log($$self) / CORE::log(2));
    }
}

package Number::Float {

    our @ISA = qw(Number);

    sub new {
        my ($class, $float) = @_;
        bless \$float, $class;
    }
}

package Number::Integer {

    our @ISA = qw(Number);

    sub new {
        my $class = shift;
        my $int   = CORE::int shift;
        bless \$int, $class;
    }
}

####################### TESTS #########################

package main {

    local $\ = "\n";

    # my $nil = Nil->new();
    #print $nil;

    my $num = String->new('-25.23');
    print $num->to_f->abs->sqrt;

    print "log(100) in base 10 is ", Number->new(100)->log10;

    my $bool = Bool->true;

    if ($bool->is_false) {
        print "is false";
    }
    else {
        print "is not false";
    }

    if ($bool) {
        print "is true";
    }

    my $bf = Bool->false;

    if ($bf) {
        print "<$bf> is true";
    }
    else {
        print "<$bf> is false";
    }

    print $num->to_i->abs->to_s->reverse;

    {
        my $div = '/';
        my $x   = Number->new(24);
        my $y   = Number::Integer->new(4);
        print "$x / $y == ", $x->$div($y);    # so, '12->/4' is 12 divided by 4.
                                              # or, even better: '12./4', or...
                                              # why not just 12/4 ?
    }

    # An idea for a new programming language!!!

    my $code = "25.3->int->sqrt";

    if ($code =~ /\G(\d+(?:\.\d+)?)/gc) {
        my $number = Number::Float->new($1);
        while ($code =~ /\G->/gc) {
            if ($code =~ /\G(\w+)/gc) {
                $number = $number->$1;
            }
        }
        print "Number is <$number>\n";
    }

}
