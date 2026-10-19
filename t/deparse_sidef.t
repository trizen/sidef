#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;

use Test::More;

use Sidef;

binmode(Test::More->builder->output,         ':utf8');
binmode(Test::More->builder->failure_output, ':utf8');

# Parses the code, and deparses it back into Sidef code
sub deparse {
    my ($code) = @_;
    my $sidef = Sidef->new(name => 'deparse_sidef');
    return $sidef->compile_code($code, 'Sidef');
}

# The code is deparsed as expected, and the generated code is stable:
# parsing and deparsing the generated code gives the same code again.
sub check {
    my ($name, $code, $expected) = @_;

    my $deparsed = deparse($code);
    is($deparsed, $expected, "$name: deparsed code");
    is(deparse($deparsed), $deparsed, "$name: stable");
}

my @tests = (

    # The precedence of the operators is never used: the operands are always parenthesized
    ['precedence',        'say 1 + 2 * 3',  "say(1 + (2 * 3))\n"],
    ['left-associative',  'say 10 - 3 - 2', "say((10 - 3) - 2)\n"],
    ['grouping',          'say ((1 + 2) * 3)', "say((1 + 2) * 3)\n"],
    ['unary minus and power', 'say (-2 ** 2, (-2) ** 2, 2 ** -2)', "say(-(2 ** 2), (-2) ** 2, 2 ** (-2))\n"],
    ['unary operators',   'var x = 1; say (!x == 1, !(x == 1), -x * 2)', "var x = 1\nsay((!x) == 1, !(x == 1), (-x) * 2)\n"],
    ['assignments',       'var (a, b) = (1, 2); a = b = 3; (a = 4) += 5; a += b *= 2',
     "var (a, b) = (1, 2)\na = (b = 3)\n(a = 4) += 5\n(a += b) *= 2\n"],
    ['declarations',      'var (a, b) = (1, 2); var c = a + b * 2; say c', "var (a, b) = (1, 2)\nvar c = (a + (b * 2))\nsay c\n"],
    ['logical operators', 'var (a, b, c) = (1, 2, 3); say (a and b or c, a and (b or c), a || b && c)',
     "var (a, b, c) = (1, 2, 3)\nsay((a and b) or c, a and (b or c), a || (b && c))\n"],

    # Chained comparisons are written explicitly
    ['comparison chain',  'var (a, b) = (1, 2); say (a < b < 3)',   "var (a, b) = (1, 2)\nsay((a < b) && (b < 3))\n"],
    ['comparison groups', 'var (a, b) = (1, 2); say ((a < b) < 3)', "var (a, b) = (1, 2)\nsay((a < b) < 3)\n"],
    ['ternary',           'var x = 1; say (x ? 2 : x ? 3 : 4); say ((x ? 2 : 3) ? 4 : 5)',
     "var x = 1\nsay(x ? 2 : (x ? 3 : 4))\nsay((x ? 2 : 3) ? 4 : 5)\n"],
    ['statement modifiers', 'var (a, b) = (1, 2); say "yes" if (a < b && b > 0)', "var (a, b) = (1, 2)\nsay \"yes\" if ((a < b) && (b > 0))\n"],

    # Numbers: the rational numbers are not converted into decimal numbers
    ['rational numbers',  'say 1.5; say 0.1 + 0.2; say 3/2', "say Number(\"3/2\")\nsay(Number(\"1/10\") + Number(\"1/5\"))\nsay(3 / 2)\n"],

    # Calls, blocks and the topic variable
    ['blocks', 'say [1,2,3].map { _ * 2 }.grep { _.is_even }.sum', "say [1, 2, 3].map { _ * 2 }.grep { .is_even }.sum\n"],
    ['block parameters', 'say [[1,2]].map { |a, b| a + b }', "say [[1, 2]].map { |a, b| a + b }\n"],
    ['hyper operators', 'var a = [1,2]; say (a »+» a); say (a «+»); say (a ~Z* a)', "var a = [1, 2]\nsay(a »+» a)\nsay a«+»\nsay(a ~Z* a)\n"],
    ['method without arguments', 'var x = [1]; say x.first.call', "var x = [1]\nsay x.first.call\n"],

    # Strings
    ['interpolation', 'var x = 1; say "x = #{x + 1}\n"',  "var x = 1\nsay \"x = #{x + 1}\\n\"\n"],
    ['escapes',       'say "a \\"q\\" \\#{b} \\\\"',      "say \"a \\\"q\\\" \\#{b} \\\\\"\n"],
    ['hash keys',     'var h = Hash(); h{:a} = 1; say h{"a b"}', "var h = Hash()\nh{:a} = 1\nsay h{\"a b\"}\n"],

    # Declarations
    ['variables', 'var (a, b) = (1, 2); var c = a; say c; say b', "var (a, b) = (1, 2)\nvar c = a\nsay c\nsay b\n"],
    ['functions', 'func f(n, m = 2) { return n * m if n; return 0 }; say f(1)',
     "func f(n, m = 2) {\n    return (n * m) if n\n    return 0\n}\n\nsay f(1)\n"],
    ['default values', 'func f(n, m = n + 1) { m }; say f(1)', "func f(n, m = (n + 1)) {\n    m\n}\n\nsay f(1)\n"],
    ['classes', 'class A(x) { method double { x * 2 } }; class B(y) < A { has z = 1; method tripple { y * 3 } }; say B(1).tripple',
     "class A(x) {\n    method double {\n        self{:x} * 2\n    }\n}\n\nclass B(y) < A {\n    has z = 1\n\n    method tripple {\n        self{:y} * 3\n    }\n}\n\nsay B(1).tripple\n"],

    # Control flow
    ['if', 'var x = 5; if (x > 3) { say "big" } elsif (x == 3) { say 3 } else { say "small" }',
     "var x = 5\n\nif (x > 3) {\n    say \"big\"\n} elsif (x == 3) {\n    say 3\n} else {\n    say \"small\"\n}\n"],
    ['for', 'for i in (1..3) { next if i == 2; say i }', "for i in (1..3) {\n    next if (i == 2)\n    say i\n}\n"],
    ['c-style for', 'for (var i = 0; i < 2; i++) { say i }', "for (var i = 0; i < 2; i++) {\n    say i\n}\n"],
    ['do-while', 'var i = 0; do { i++ } while (i < 3)', "var i = 0\ndo { i++ } while (i < 3)\n"],
);

foreach my $test (@tests) {
    check(@{$test});
}

#
## The generated code must parse into the same program
#

my @programs = (
    'var (a, b, c) = (1, 2, 3); say [a < b < c, (a < b) < c, a < (b < c), -a ** 2, (-a) ** 2, !(a == b), a ** b ** c, (a ** b) ** c]',
    'var a = 5; a += 2 *= 3; (a = 1) += 1; a = (a += 1); say a',
    'func f(n) { n < 2 ? n : f(n - 1) + f(n - 2) }; say f(10)',
    'var x = [1,2,3]; say (x.map { _ ** 2 }.sum, x »*» x, x[0], x[-1], x[0..1])',
    'say "interpolation: #{[1,2].map { _ + 1 }.join(\', \')} and #{1 + 2}"',
    'var h = Hash(a => 1); h{:b} = 2; say h{:a, :b}; say h.keys.sort',
    'class A(x) { method double { x * 2 } }; say A(3).double',
    'var i = 0; do { i++ } while (i < 3); say i',
    'var a = [1,2,3]; say (a «+»); say (a »+» a); say (a ~Z* a)',
);

foreach my $program (@programs) {

    my $deparsed = deparse($program);

    my $run = sub {
        my ($code) = @_;
        my $sidef  = Sidef->new(name => 'deparse_sidef_run');
        my $perl   = $sidef->compile_code($code, 'Perl');
        my $output = '';
        {
            local *STDOUT;
            open(STDOUT, '>', \$output);
            $sidef->execute_perl($perl);
        }
        return $output;
    };

    is($run->($deparsed), $run->($program), "same output: $program");
}

done_testing();
