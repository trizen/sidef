#!perl -T

use utf8;
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

use Sidef;

my $code = <<'EOT';

class Animal(String name, Number age)  {
    method speak { "..." }
}

class Dog(String color) < Animal {
    method speak { "woof" }
    method ageHumanYears { self.age * 7 }
}

class Cat < Animal {
    method speak { "meow" }
}

var dog = Dog(name: "Sparky", age: 6, color: "white")
var cat = Cat(name: "Mitten", age: 3)

[dog, cat]
EOT

my $sidef = Sidef->new(name => 'oo_inheritance');
my $objs = $sidef->execute_code($code);

my $dog = $objs->[0];
my $cat = $objs->[1];

is("${\($dog->speak)}",         "woof");
is("${\($cat->speak)}",         "meow");
is("${\($dog->color)}",         "white");
is("${\($dog->ageHumanYears)}", "42");
is("${\($cat->age)}",           "3");
is("${\($cat->name)}",          "Mitten");
is("${\($dog->name)}",          "Sparky");
is("${\($dog->age)}",           "6");
