# Sidef Programming Language - Beginner's Guide

<div align="center">

**A modern, high-level programming language implemented in Perl**

[Try Online](https://tio.run/#sidef) • [Official Documentation](https://trizen.gitbook.io/sidef-lang/) • [GitHub Repository](https://github.com/trizen/sidef)

</div>

---

## 📖 Table of Contents

1. [What is Sidef?](#what-is-sidef)
2. [Installation](#installation)
3. [Getting Started](#getting-started)
4. [Basic Syntax](#basic-syntax)
5. [Variables and Data Types](#variables-and-data-types)
6. [Operators](#operators)
7. [Control Flow](#control-flow)
8. [Functions](#functions)
9. [Arrays and Hashes](#arrays-and-hashes)
10. [Object-Oriented Programming](#object-oriented-programming)
11. [Advanced Features](#advanced-features)
12. [Interesting Examples](#interesting-examples)
13. [Best Practices](#best-practices)
14. [Resources](#resources)

---

## What is Sidef?

Sidef is a modern, expressive programming language that combines:

- 💎 The elegance of **Ruby**
- 🦋 The versatility of **Raku**
- 📐 The mathematical capabilities of **Julia**

### Key Features

| Category | Features |
|----------|----------|
| **Paradigms** | Object-oriented, Functional, Pattern matching, Multiple dispatch |
| **Numerics** | Big integers, Rational numbers, Arbitrary precision floats, Complex numbers |
| **Integration** | Seamless Perl module integration |
| **Evaluation** | Optional lazy evaluation, Lexical scoping, Closures |

---

## Installation

### Prerequisites

**IMPORTANT**: Sidef requires the following C libraries:
- [GMP](https://gmplib.org/) — GNU Multiple Precision Arithmetic Library
- [MPFR](http://www.mpfr.org/) — Multiple Precision Floating-Point Reliable Library
- [MPC](http://www.multiprecision.org/) — Multiple Precision Complex Library

### Platform-Specific Installation

**Linux (Debian/Ubuntu/Linux Mint):**
```bash
sudo apt install libgmp-dev libmpfr-dev libmpc-dev libc-dev cpanminus
cpanm --sudo -n Sidef
```

**Arch Linux:**
```bash
trizen -S sidef
```

**Windows:**
Download the portable executable from [GitHub Releases](https://github.com/trizen/sidef/releases)

**Android (Termux):**
```bash
pkg install perl make clang libgmp libmpfr libmpc
cpan -T Sidef
```

### Via CPAN

```bash
cpan Sidef
# Or without running tests (faster):
cpan -T Sidef
```

### Building from Source

```bash
wget 'https://github.com/trizen/sidef/archive/master.zip' -O 'master.zip'
unzip 'master.zip'
cd 'sidef-master'
perl Build.PL
sudo ./Build installdeps
sudo ./Build install
```

### Verify Installation

```bash
sidef -v
sidef -h
```

---

## Getting Started

### Your First Program

Create a file called `hello.sf`:

```ruby
#!/usr/bin/sidef

say "Hello, World!"
```

Run it:
```bash
sidef hello.sf
```

> 💡 **Tip**: Sidef files use the `.sf` extension by convention.

### One-liners

Use `-e` to run code directly from the command line — great for quick experiments:

```bash
sidef -e 'say "Hello, World!"'
sidef -e 'say 10.primes'
```

### Interactive REPL

Start the interactive Read-Eval-Print Loop by running `sidef` with no arguments:

```
$ sidef
Sidef 26.01, running on Linux, using Perl v5.42.0.
Type "help", "copyright" or "license" for more information.
> say "Hello!"
Hello!
> 2 + 3
5
```

### Try It Online

Experiment with Sidef instantly in your browser at **[https://tio.run/#sidef](https://tio.run/#sidef)** — no installation needed.

---

## Basic Syntax

### Printing Output

```ruby
say "Hello!"              # Prints with newline
print "No newline"        # Prints without newline
```

### Comments

```ruby
# This is a single-line comment

/*
   This is a
   multi-line comment
*/
```

### Variables

```ruby
var name = "Alice"        # String variable
var age = 25              # Number variable
var pi = 3.14159          # Decimal (stored as rational)
```

### Whitespace and Precedence

Sidef uses **whitespace-sensitive method chaining**: the rule is **no spaces bind tighter than spaces**. Operators written without surrounding spaces are grouped first; operators with spaces are chained left-to-right.

```ruby
1+2 * 3+4    # means: (1+2) * (3+4) = 21  (spaces chain left-to-right)
1+2*3        # means: 1 + (2*3)     = 7   (no spaces bind tighter)
```

> 📝 **Best Practice**: Use parentheses to make intent explicit:
> ```ruby
> var n = (1 + 2)    # always clear
> var n = 1+2        # also correct (no spaces: 1+2 is one unit)
> ```

Use backslash (`\`) or dot prefix (`.`) to control precedence in complex expressions:

```ruby
1 + 2 \* 3    # means: 1 + (2 * 3)
1 + 2 .* 3    # same as above
```

### Constants

Sidef provides three keywords for constants and persistent values:

| Keyword  | When evaluated | Can be reassigned | Use case |
|----------|---------------|-------------------|----------|
| `define` | Compile time  | No                | Compile-time constants |
| `const`  | Runtime, once | No                | Runtime constants evaluated once |
| `static` | Runtime, once | Yes               | Variables that persist across function calls |

```ruby
define PI = 3.14159         # compile-time constant
const  TAX_RATE = 0.07      # runtime constant (evaluated once)

func counter {
    static count = 0        # persists between calls
    ++count
}
say counter()    # 1
say counter()    # 2
```

---

## Variables and Data Types

### Numbers

```ruby
# Integers
var decimal = 255
var hex = 0xff
var binary = 0b11111111
var octal = 0377

# Decimals (exact rational arithmetic!)
var price = 19.99
say (0.1 + 0.2 == 0.3)    #=> true (no floating-point errors!)

# Complex numbers
var c = 3+4i
var c = Complex(3, 4)
```

### Strings

```ruby
var name = "World"

# Double quotes: interpolation enabled
say "Hello, #{name}!"     #=> Hello, World!

# Single quotes: literal string
say 'No interpolation: #{name}'

# Common string methods
"hello".uc                #=> "HELLO"
"HELLO".lc                #=> "hello"
"hello".reverse           #=> "olleh"
"hello".length            #=> 5
```

### Booleans

```ruby
var is_valid = true
var is_empty = false
```

---

## Operators

### Arithmetic

```ruby
10 + 5     #=> 15
10 - 5     #=> 5
10 * 5     #=> 50
10 / 5     #=> 2
10 % 3     #=> 1 (modulo)
10 ** 2    #=> 100 (power)
```

### Comparison

```ruby
5 == 5     #=> true
5 != 3     #=> true
5 > 3      #=> true
5 < 10     #=> true
5 >= 5     #=> true
5 <= 10    #=> true
```

### Logical

```ruby
true && false    #=> false (and)
true || false    #=> true (or)
!true            #=> false (not)
```

### Ranges

```ruby
1..10            # 1 to 10 (inclusive)
1..^10           # 1 to 9 (exclusive end)
^10              # 0 to 9
```

### Pipeline Operator

Chain operations left-to-right with `|>`:

```ruby
25 |> :sqrt |> :say              # 5
42 |> {_*3} |> {_*2} |> {_+1}   # 253
```

---

## Control Flow

### If/Elsif/Else

```ruby
var age = 18

if (age < 13) {
    say "Child"
}
elsif (age < 20) {
    say "Teenager"
}
else {
    say "Adult"
}
```

### Ternary Operator

```ruby
var status = (age >= 18 ? "Adult" : "Minor")
```

### with/orwith (Testing Defined Values)

`with` executes its block only when the value is defined (non-nil):

```ruby
with (some_value) { |val|
    say "Got: #{val}"
}
orwith (other_value) { |val|
    say "Or: #{val}"
}
else {
    say "Nothing defined"
}
```

### Given/When (Pattern Matching)

```ruby
given (value) {
    when (1) { say "One" }
    when (2) { say "Two" }
    when (/^\d+$/) { say "A number" }
    else { say "Something else" }
}
```

### While Loop

```ruby
var count = 0
while (count < 5) {
    say count
    count++
}
```

### do-while Loop

```ruby
do {
    say count
    count++
} while (count < 5)
```

### For Loop

```ruby
# For-in loop
for item in [1, 2, 3, 4, 5] {
    say item
}

# Range iteration
for i in (1..10) {
    say i
}

# Times method
5.times { |i|
    say "Iteration #{i}"
}
```

### Loop Control

```ruby
loop {
    # Infinite loop
    break if (condition)    # Exit loop
    next if (skip_this)     # Skip to next iteration
}
```

---

## Functions

### Basic Function

```ruby
func greet(name) {
    say "Hello, #{name}!"
}

greet("Alice")    #=> Hello, Alice!
```

### Default Parameters

```ruby
func greet(name = "World") {
    say "Hello, #{name}!"
}

greet()           #=> Hello, World!
greet("Bob")      #=> Hello, Bob!
```

### Return Values

```ruby
func add(a, b) {
    return a + b
}

var result = add(3, 4)    #=> 7

# Last expression is returned implicitly
func multiply(a, b) {
    a * b
}
```

### Variadic Functions

```ruby
func sum(*numbers) {
    numbers.sum
}

say sum(1, 2, 3, 4, 5)    #=> 15
```

### Named Parameters

```ruby
func divide(a, b) {
    a / b
}

say divide(b: 2, a: 10)    #=> 5
```

### Recursion

```ruby
func factorial(n) {
    return 1 if (n <= 1)
    n * factorial(n - 1)
}

say factorial(5)    #=> 120
```

### Memoization (Caching)

```ruby
func fib(n) is cached {
    return n if (n <= 1)
    fib(n-1) + fib(n-2)
}

say fib(50)    # Fast with memoization!
```

### Lambdas / Anonymous Functions

Blocks can be assigned to variables and called as functions:

```ruby
# Block syntax
var double = { |n| n * 2 }
say double(5)    # 10

# Arrow function syntax
var triple = ->(n) { n * 3 }
say triple(5)    # 15

var add = { |a, b| a + b }
say add(3, 4)    # 7
```

### Closures

A closure captures variables from its enclosing scope:

```ruby
func make_counter(start = 0) {
    var count = start
    func {
        ++count
    }
}

var counter = make_counter(10)
say counter()    # 11
say counter()    # 12
```

### Multiple Dispatch

Define multiple functions with the same name but different type signatures:

```ruby
func test(String s) {
    say "Got string: #{s}"
}

func test(Number n) {
    say "Got number: #{n}"
}

test("hello")    # Got string: hello
test(42)         # Got number: 42
```

### Pattern Matching in Functions

Match on specific values using double parentheses:

```ruby
func fib ((0)) { 0 }
func fib ((1)) { 1 }
func fib  (n)  { fib(n-1) + fib(n-2) }

say fib(10)    # 55
```

---

## Arrays and Hashes

### Arrays

```ruby
# Creation
var fruits = ["apple", "banana", "cherry"]
var numbers = Array(1, 2, 3, 4, 5)

# Access
say fruits[0]       #=> "apple"
say fruits[-1]      #=> "cherry" (last element)

# Modification
fruits.push("date")
fruits.pop          # Remove last
fruits.shift        # Remove first

# Useful methods
[1, 2, 3].length    #=> 3
[3, 1, 2].sort      #=> [1, 2, 3]
[1, 2, 3].reverse   #=> [3, 2, 1]
[1, 2, 3].sum       #=> 6
```

### Functional Array Methods

```ruby
# Map: transform each element
[1, 2, 3].map { _**2 }           #=> [1, 4, 9]

# Grep/Filter: select elements
[1, 2, 3, 4, 5].grep { _ > 2 }   #=> [3, 4, 5]

# Reduce: combine elements
[1, 2, 3, 4].reduce { |a, b| a + b }    #=> 10

# Each: iterate
[1, 2, 3].each { |n| say n }
```

### Hashes (Dictionaries)

```ruby
# Creation
var person = Hash(
    name => "Alice",
    age  => 30,
)

# Access
say person{:name}       #=> "Alice"
person{:city} = "NYC"   # Add new key

# Methods
person.keys             #=> ["name", "age", "city"]
person.values           #=> ["Alice", 30, "NYC"]
person.has(:name)       #=> true

# Iteration
person.each { |key, value|
    say "#{key}: #{value}"
}
```

---

## Object-Oriented Programming

### Classes

```ruby
class Person(name, age) {

    method greet {
        say "Hi, I'm #{name} and I'm #{age} years old."
    }

    method birthday {
        self.age++
        say "Happy birthday! Now I'm #{age}."
    }
}

# Create an instance
var alice = Person(name: "Alice", age: 25)

# Call methods
alice.greet()
alice.birthday()
say alice.age    #=> 26
```

### Class Attributes

```ruby
class Rectangle(width, height) {

    has area = (width * height)

    method perimeter {
        2 * (width + height)
    }
}

var rect = Rectangle(5, 3)
say rect.area        #=> 15
say rect.perimeter   #=> 16
```

### Class Inheritance

Use `< ParentClass` to inherit from another class:

```ruby
class Animal(String name, Number age) {
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
say dog.speak           # woof
say dog.ageHumanYears   # 42

var cat = Cat(name: "Mitten", age: 3)
say cat.speak           # meow
```

### Structs (Simple Data Containers)

```ruby
struct Point {
    Number x,
    Number y,
}

var p = Point(x: 10, y: 20)
say p.x    #=> 10
say p.y    #=> 20
```

### Subsets (Type Refinement)

```ruby
subset Integer  < Number  { |n| n.is_int }
subset Positive < Integer { |n| n.is_pos }

func square_root(Positive n) {
    n.sqrt
}
```

### Enumerations

`enum` assigns sequential integer values to named constants:

```ruby
enum {a, b, c}      # a=0, b=1, c=2
enum {x=10, y, z}   # x=10, y=11, z=12

say a    # 0
say y    # 11
```

### Modules

Group related functions and classes into namespaces:

```ruby
module math::utils {
    func double(n) { n * 2 }
    func triple(n) { n * 3 }
}

say math::utils::double(21)    # 42
```

---

## Advanced Features

### Regular Expressions

```ruby
# Basic matching
if ("hello world" =~ /world/) {
    say "Match!"
}

# Capture groups
var match = "hello world".match(/(\w+) (\w+)/)
say match[0]    # hello
say match[1]    # world

# Global matching
var text = "a cat, a dog and a fox"
while (var m = text.match(/\ba\h+(\w+)/g)) {
    say m[0]
}
# Output: cat, dog, fox
```

### Exception Handling

```ruby
try {
    die "Something went wrong!" if (condition)
}
catch { |msg|
    say "Caught: #{msg}"
}
```

### Lazy Evaluation

Defer computation until results are actually needed:

```ruby
# First 10 primes without building the whole list in memory
say (^Inf -> lazy.grep{.is_prime}.first(10))
```

### gather/take (Lazy List Building)

```ruby
var list = gather {
    for i in (1..10) {
        take(i) if i.is_prime
    }
}
say list    # [2, 3, 5, 7]
```

### Enumerators (Lazy Infinite Sequences)

`Enumerator` creates a lazy iterator that can represent infinite sequences:

```ruby
var primes = Enumerator({ |yield|
    for n in (2..Inf) {
        yield(n) if n.is_prime
    }
})
say primes.first(10)    # [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
say primes.nth(100)     # the 100th prime
```

### Perl Module Integration

Sidef can use any CPAN Perl module directly via `require` (object-oriented) or `frequire` (functional):

```ruby
# Object-oriented modules
var http = require('HTTP::Tiny').new
var response = http.get('http://example.com')
if (response{:success}) {
    say response{:content}
}

# Functional modules
var posix = frequire('POSIX')
say posix.ceil(3.14)    # 4
```

---

## Interesting Examples

### Fibonacci Sequence

```ruby
func fib(n) is cached {
    n <= 1 ? n : fib(n-1) + fib(n-2)
}

say 10.of { fib(_) }    #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

### Prime Numbers

```ruby
# Check if prime
say 17.is_prime        #=> true

# First 10 primes
say 10.primes          #=> [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

# Primes in a range
say primes(1, 50)      #=> [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
```

### FizzBuzz

```ruby
for i in (1..100) {
    say (
        i % 15 == 0 ? "FizzBuzz" :
        i % 3  == 0 ? "Fizz"     :
        i % 5  == 0 ? "Buzz"     :
        i
    )
}
```

### Sorting and Filtering

```ruby
var numbers = [64, 34, 25, 12, 22, 11, 90]

say numbers.sort                     #=> [11, 12, 22, 25, 34, 64, 90]
say numbers.grep { _ > 30 }          #=> [64, 34, 90]
say numbers.max                      #=> 90
say numbers.min                      #=> 11
```

### Sierpinski Triangle

```ruby
func sierpinski_triangle(n) {
    var triangle = ['*']
    { |i|
        var sp = (' ' * 2**i)
        triangle = (triangle.map {|x| sp + x + sp} +
                    triangle.map {|x| x + ' ' + x})
    } * n
    triangle.join("\n")
}

say sierpinski_triangle(4)
```

### Mandelbrot Set

```ruby
func mandelbrot(z, r=20) {
    var c = z
    r.times {
        z = (z*z + c)
        return true if (z.abs > 2)
    }
    return false
}

for y in (1 `downto` -1 `by` 0.05) {
    for x in (-2 `upto` 0.5 `by` 0.0315) {
        print(mandelbrot(Complex(x, y)) ? ' ' : '#')
    }
    print "\n"
}
```

### Reading and Writing Files

```ruby
# Read a file
var content = File("input.txt").read

# Read lines
File("input.txt").each_line { |line|
    say line
}

# Write to a file
File("output.txt").write("Hello, File!")

# Append to a file
File("output.txt").append("\nMore content")
```

---

## Best Practices

### Style Guidelines

1. **Use explicit parentheses** for complex expressions to make intent clear
2. **Prefer meaningful names** over abbreviations
3. **Use type constraints** in function signatures where appropriate
4. **Leverage functional methods** (`map`, `grep`, `reduce`) over manual loops
5. **Cache expensive recursive functions** with `is cached`

### Performance Tips

1. Use `define` for compile-time constants
2. Cache recursive functions with `is cached`
3. Prefer lazy evaluation for large or infinite datasets
4. Use appropriate numeric types (rational vs. float vs. integer)

### Common Patterns

**Conditional assignment (only if nil):**
```ruby
var x = nil
x := some_func1()
x := some_func2()   # calls some_func2() only if x is still nil
```

**Collecting results lazily:**
```ruby
var evens = gather {
    for i in (1..100) {
        take(i) if (i % 2 == 0)
    }
}
```

---

## Resources

### Official Resources

- 📘 [Sidef GitBook](https://trizen.gitbook.io/sidef-lang/) — Comprehensive language guide ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-book.pdf))
- 📝 [Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) ([local copy](TUTORIAL.md)) — Step-by-step tutorial ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf))
- 🔢 [Number Theory Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/NUMBER_THEORY_TUTORIAL.md) ([local copy](NUMBER_THEORY_TUTORIAL.md)) — Mathematical programming ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-number-theory.pdf))
- 📦 [MetaCPAN](https://metacpan.org/pod/Sidef) — CPAN package page

### Community & Examples

- 💬 [GitHub Discussions](https://github.com/trizen/sidef/discussions) — Q&A and community
- 🐛 [GitHub Issues](https://github.com/trizen/sidef/issues) — Bug reports and features
- 🌹 [RosettaCode Examples](https://rosettacode.org/wiki/Sidef) — Practical code examples
- 📂 [sidef-scripts](https://github.com/trizen/sidef-scripts) — Extensive collection of Sidef programs

### Try It Online

Experiment with Sidef instantly: **[Try It Online](https://tio.run/#sidef)**

---

<div align="center">

**Happy coding with Sidef! 🚀**

*Created with ❤️ for beginners*

</div>