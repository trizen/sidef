#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 18;

use Sidef;

my $counter = 0;

sub run_sidef {
    my ($code) = @_;
    return Sidef->new(name => 'class_features_' . ++$counter)->execute_code($code);
}

sub str { "${\($_[0])}" }

# Multiple inheritance and the method resolution order (C3)
{
    my $o = run_sidef(<<'EOT');
class Base(id = 1) { method who { "Base" } }
class Left(l = "L") < Base { method who { "Left" } }
class Right(r = "R") < Base { method who { "Right" } }
class Diamond(d = "D") < Left, Right { method info { [id, l, r, d] } }
class Diamond2 < Right, Left { }
[Diamond(7, "a", "b", "c"), Diamond2()]
EOT

    my ($diamond, $diamond2) = @{$o};

    is(str($diamond->who),  'Left',  'the first parent wins');
    is(str($diamond2->who), 'Right', 'the order of the parents matters');
    is(str($diamond->info), '[7, "a", "b", "c"]', 'inherited parameters come first');
    is(str($diamond->l),    'a',     'the accessors of the inherited fields');
}

# Every class of a diamond is initialized once
{
    my $o = run_sidef(<<'EOT');
var count = 0
class CBase { method init { count++ } }
class CLeft < CBase { }
class CRight < CBase { }
class CDiamond < CLeft, CRight { }
CDiamond()
count
EOT
    is(str($o), '1', 'init is called once for a diamond');
}

# Fields: parameters, attributes, defaults that depend on other parameters, overriding
{
    my $o = run_sidef(<<'EOT');
class A(x = 1, y = 2) { has z = x + y }
class B(x = 10) < A { }
class C < B { has y = 100 }
class D(a, b = a * 2) { has c = a + b; has (d, e) = (c + 1, c + 2) }
[B(2, 5), C(3), D(3)]
EOT

    my ($b, $c, $d) = @{$o};

    is(join(',', map { str($b->$_) } qw(x y z)), '5,2,7',     'redeclared parameters are placed last');
    is(join(',', map { str($c->$_) } qw(x y z)), '3,100,103', 'an attribute overrides an inherited parameter');
    is(join(',', map { str($d->$_) } qw(a b c d e)), '3,6,9,10,11', 'attributes and defaults');
}

# A class that is redefined, is the same class
{
    my $o = run_sidef(<<'EOT');
class R(a = 1) { method one { "one" } }
class R(b = 2) { method two { "two" } }
class R(c = 3) { method three { "three" } }
R()
EOT
    is(join(',', map { str($o->$_) } qw(a b c one two three)), '1,2,3,one,two,three');
}

# Classes that are declared at run-time get their own scope
{
    my $o = run_sidef(<<'EOT');
func make(n) { class Local(v = n) { method get { v } }; Local() }
var objs = []
for i in (1..3) { class InLoop(k = i) { method k2 { k * 2 } }; objs << InLoop() }
[make(1).get, make(2).get, objs.map { .k2 }]
EOT
    is(str($o->[0]), '1');
    is(str($o->[1]), '2');
    is(str($o->[2]), '[2, 4, 6]');
}

# Multimethods are found in all the ancestors
{
    my $o = run_sidef(<<'EOT');
class MA { method f(Number n) { n; "number" } }
class MB < MA { }
class MC < MB { method f(String s) { s; "string" } }
class MD < MA { method f(Array a) { a; "array" } }
class ME < MC, MD { }
[ME().f(1), ME().f("x"), ME().f([1])]
EOT
    is(join(',', map { str($_) } @{$o}), 'number,string,array');
}

# Slurpy parameters, structs and types
{
    my $o = run_sidef(<<'EOT');
class S(first, *rest) { }
struct Point { Number x, Number y = 5 }
class T(Number n) { }
[S(1, 2, 3), Point(1), (try { T("x"); "no error" } catch { "type error" })]
EOT
    is(str($o->[0]->rest),     '[2, 3]',     'slurpy parameter');
    is(str($o->[1]->y),        '5',          'struct');
    is(str($o->[2]),           'type error', 'types of the parameters are checked');
}

# Extending a built-in class with a parent
{
    my $o = run_sidef(<<'EOT');
class Custom { method in_blue { "blue" } }
class String << Custom { method in_red { "red" } }
["x".in_red, "x".in_blue]
EOT
    is(join(',', map { str($_) } @{$o}), 'red,blue');
}

# Classes can be inherited in the following lines (interactive mode)
{
    my $o = run_sidef(<<'EOT');
class Foo(a) { method m { a + 1 } }
class Bar(b = 2) < Foo { }
Bar(1, 5).m
EOT
    is(str($o), '2');
}
