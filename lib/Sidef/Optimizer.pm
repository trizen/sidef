package Sidef::Optimizer {

    use 5.014;

    my %addr;

    sub new {
        my (undef, %opts) = @_;
        %addr = ();
        bless \%opts, __PACKAGE__;
    }

    sub optimize_expr {
        my ($self, $expr) = @_;

        my $obj = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $obj = $self->optimize($obj);
        }
        elsif ($ref eq "Sidef::Variable::Variable") {
            if ($obj->{type} eq 'var') {
                ## ok
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                state $x = require Scalar::Util;
                if ($addr{Scalar::Util::refaddr($obj)}++) {
                    ## ok
                }
                else {
                    $obj->{value} = $self->optimize_expr({self => $obj->{value}});
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            state $x = require Scalar::Util;
            if ($addr{Scalar::Util::refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{__BLOCK__} = $self->optimize_expr({self => $obj->{__BLOCK__}});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            state $x = require Scalar::Util;
            if ($addr{Scalar::Util::refaddr($obj)}++) {
                ## ok
            }
            else {
                my %code = $self->optimize($obj->{code});
                $obj->{code} = \%code;
            }
        }
        elsif ($ref eq 'Sidef::Types::Array::HCArray') {
            foreach my $i (0 .. $#{$obj}) {
                if (ref($obj->[$i]) eq 'HASH') {
                    $obj->[$i] = $self->optimize_expr($obj->[$i]);
                }
            }
        }

        if (not exists $expr->{ind} and not exists $expr->{call}) {
            return $obj;
        }

        $obj = {
                self => $obj,
                (exists($expr->{ind})  ? (ind  => []) : ()),
                (exists($expr->{call}) ? (call => []) : ()),
               };

        # Indices
        if (exists $expr->{ind}) {
            foreach my $i (0 .. $#{$expr->{ind}}) {
                $obj->{ind}[$i] =
                  [map { $self->optimize_expr(ref($_) eq 'HASH' ? $_ : {self => $_->get_value}) } @{$expr->{ind}[$i]}];
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $i (0 .. $#{$expr->{call}}) {
                my $call = $expr->{call}[$i];

                # Method call
                my $method = $call->{method};
                if (ref($method) eq 'HASH') {
                    $method = $self->optimize_expr($method);
                }

                $obj->{call}[$i] = {method => $method};

                # Method arguments
                if (exists $call->{arg}) {
                    foreach my $j (0 .. $#{$call->{arg}}) {
                        my $arg = $call->{arg}[$j];
                        push @{$obj->{call}[$i]{arg}},
                          ref $arg eq 'HASH' ? do { my %arg = $self->optimize($arg); \%arg } : $arg;
                    }
                }
            }
        }

        return $obj;
    }

    sub optimize {
        my ($self, $struct) = @_;

        my %opt_struct;
        my @classes = keys %{$struct};
        foreach my $class (@classes) {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                push @{$opt_struct{$class}}, scalar $self->optimize_expr($struct->{$class}[$i]);
            }
        }

        wantarray ? %opt_struct : $#{$opt_struct{$classes[-1]}} > 0 ? \%opt_struct : $opt_struct{$classes[-1]}[-1];
    }
};

1;

__END__

use utf8;
use 5.014;
use strict;
use warnings;

# The directory where Sidef lives
use lib qw(..);

# Load the Sidef main module
use Sidef;

#$SIG{__WARN__} = sub {die @_};

# Initialize a new parser
my $parser = Sidef::Parser->new();

# Parse some code and store the returned parse-tree
my $struct = $parser->parse_script(code => <<'SIDEF_CODE');


var arr = [[1],2,3];
say arr[0][0];
say arr[1];
say arr[2];

say arr[[1, 2]].dump;

say arr[4..1].dump;

var x = -1;
say [1,2,3,4,5][++x];
say [1,2,3,4,5][x++];
say [1,2,3,4,5][x];
say [1,2,3,4,5][x++];
say [1,2,3,4,5][++x];

say(((("hello"))));
[((((("hi".say; "kitty")))))].dump.say;
["a","b",("c".uc, "d")].dump.say;

[["a","b","c"]].dump.say;

func factorial(n is Num) {
    n > 0 ? (factorial.call(n-1) * n) : 1;
};

say factorial(5);
say (((("hello world"))));
((((("Hello"))))).say;

var x = 10;
while(x > 1) {
    say x;
    x -= 1;
};

if (false) {
    say "first true";
}
elsif ("y".say) {
    say "second true";
};


func A(m, n) {
    m == 0 ? (n + 1)
           : (n == 0 ? A(m - 1, 1)
                     : A(m - 1, A(m, n - 1)));
};

say A(1,4);

say "All done!";

SIDEF_CODE

use Data::Dump qw(pp);
my $opt        = Sidef::Optimizer->new;
my %opt_struct = $opt->optimize($struct);
pp \%opt_struct;

Sidef::Types::Block::Code->new(\%opt_struct)->run;
