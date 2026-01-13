# Sidef Programming Language Tutorial

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Language Fundamentals](#language-fundamentals)
- [Data Types](#data-types)
- [Control Flow](#control-flow)
- [Functions and Methods](#functions-and-methods)
- [Object-Oriented Programming](#object-oriented-programming)
- [Advanced Features](#advanced-features)

---

## Introduction

Sidef is a modern, high-level programming language designed for versatile general-purpose applications, drawing inspiration from Ruby, Raku, and Julia.

```
            **   **         ****   *           *********   *********
          * * ** * *        ****   **          ** ** **    ** ** **
           **   **          ****   ***         *********   *  *  *
  **        **        **    ****   *  *        ******      ******
* * *     * * *     * * *   ****   ** **       ** **       ** **
 **        **        **     ****   ******      ******      *  *
       **   **              ****   *  *  *     *********   ***
     * * ** * *             ****   ** ** **    ** ** **    **
      **   **               ****   *********   *********   *
```

**Resources:**
- [Official Book](https://trizen.gitbook.io/sidef-lang/)
- [PDF Documentation](https://github.com/trizen/sidef/releases/download/26.01/sidef-book.pdf)
- [GitHub Repository](https://github.com/trizen/sidef)

---

## Installation

### Prerequisites

**IMPORTANT**: Sidef requires the following C libraries:
- [GMP](https://gmplib.org/) - GNU Multiple Precision Arithmetic Library
- [MPFR](http://www.mpfr.org/) - Multiple Precision Floating-Point Reliable Library
- [MPC](http://www.multiprecision.org/) - Multiple Precision Complex Library

### Platform-Specific Installation

#### Windows

Download the portable 32-bit executable:
- [sidef-26.01.exe.zip](https://github.com/trizen/sidef/releases/download/26.01/sidef-26.01.exe.zip)

#### Linux

**Arch Linux:**
```bash
trizen -S sidef
```

**Debian/Ubuntu/Linux Mint:**
```bash
sudo apt install libgmp-dev libmpfr-dev libmpc-dev libc-dev cpanminus
cpanm --sudo -n Sidef
```

**From MetaCPAN:**
```bash
cpan Sidef
# Or without testing (faster):
cpan -T Sidef
```

**From Git Source:**
```bash
wget 'https://github.com/trizen/sidef/archive/master.zip' -O 'master.zip'
unzip 'master.zip'
cd 'sidef-master'
perl Build.PL
sudo ./Build installdeps
sudo ./Build install
```

#### Android (Termux)

```bash
pkg install perl make clang libgmp libmpfr libmpc
cpan -T Sidef
```

### Verification

After installation, verify Sidef is working:
```bash
sidef -h
sidef -v
```

---

## Getting Started

### Hello World

Create a file `hello.sf` with:

```ruby
#!/usr/bin/sidef

say "Hello, 世界"
```

Run it:
```bash
sidef hello.sf
```

### File Extension

By convention, Sidef scripts use the `.sf` extension.

---

## Language Fundamentals

### Syntax Overview

#### Operator Precedence

Sidef handles operator precedence uniquely—whitespace controls precedence:

```ruby
1+2 * 3+4       # means: (1+2) * (3+4) = 21
1 + 2 * 3       # means: ((1 + 2) * 3) = 9
1+2*3           # means: (1 + (2 * 3)) = 7
```

**Best practices:**
```ruby
var n = 1 + 2       # WRONG: parsed as (var n = 1) + 2
var n = 1+2         # correct
var n = (1 + 2)     # better - explicit grouping
```

#### Controlling Precedence

Use backslash (`\`) or dot prefix (`.`) to control precedence:

```ruby
1 + 2 \* 3      # means: (1 + (2 * 3))
1 + 2 .* 3      # same as above
```

Multi-line method chaining:
```ruby
say "abc".uc      \
         .reverse \
         .chars

# Equivalent to:
say "abc".uc.reverse.chars
```

### Keywords

Core language keywords:

**Declaration:**
- `var` - lexical variable
- `local` - local dynamic variable
- `func` - function
- `class` - class
- `module` - module
- `subset` - subset type
- `struct` - structure
- `const` - runtime dynamic constant
- `static` - runtime static variable
- `define` - compile-time static constant
- `enum` - enumeration

**Control Flow:**
- `if`, `elsif`, `else`
- `with`, `orwith`
- `while`, `loop`, `for`
- `try`, `catch`
- `given`, `when`, `case`
- `gather`, `take`
- `return`, `break`, `next`, `continue`

**I/O and Utilities:**
- `say`, `print`
- `read`, `warn`, `die`
- `eval`, `del`
- `assert`, `assert_eq`, `assert_ne`
- `include`, `import`

**Special Values:**
- `nil` - undefined value
- `true`, `false` - boolean values

### Prefix Operators

```ruby
>               # alias for 'say'
>>              # alias for 'print'
+               # scalar context
-               # negative value
++, --          # increment/decrement
~               # logical not
\               # reference
*               # dereference
:               # hash initializer
!               # boolean negation
^               # exclusive range (0 to n-1)
@               # array context
@|              # list context
√               # square root
```

### Postfix Operators

```ruby
++, --          # post-increment/decrement
!               # factorial
!!              # double-factorial
...             # unpack to list
```

---

## Data Types

### Built-in Types

Core types in Sidef:

**Numeric:**
- `Number` (Num) - rational/integer/floating-point
- `Complex` - complex numbers
- `Fraction` - generic fractions
- `Gauss` - Gaussian integers
- `Quadratic` - quadratic integers
- `Quaternion` - quaternions
- `Polynomial` (Poly) - polynomials
- `PolynomialMod` (PolyMod) - modular polynomials
- `Mod` - modular arithmetic

**Collections:**
- `Array` (Arr) - ordered list
- `Hash` - key-value pairs
- `Set` - unique elements
- `Bag` - multiset
- `Pair` - two-element tuple
- `Vector`, `Matrix` - mathematical vectors/matrices
- `Range`, `RangeNum`, `RangeStr` - ranges

**Text:**
- `String` (Str) - text strings
- `Regex` (Regexp) - regular expressions

**I/O:**
- `File`, `FileHandle`
- `Dir`, `DirHandle`
- `Pipe`, `Socket`

**Other:**
- `Bool` - boolean
- `Block` - code block
- `Ref` - reference
- `Time`, `Date` - temporal types
- `Sys`, `Sig` - system interaction
- `Math` - mathematical functions

### Numbers

#### Integer Literals

```ruby
255              # decimal
0xff             # hexadecimal
0377             # octal
0b1111_1111      # binary (underscores for readability)
```

#### Decimal Numbers

Decimals are stored as rational numbers:

```ruby
1.234            # stored as 617/500
.1234            # 0.1234
1234e-5          # 0.01234
12.34e5          # 1234000

say (0.1 + 0.2 == 0.3)   #=> true (exact rational arithmetic)
```

#### Floating-Point

Create floating-point values with `f` suffix:

```ruby
12345f           # floating-point
12.34f           # floating-point
1.5e9f           # floating-point

var f = 12.345.float   # convert to float
```

Default precision is 192 bits. Change with `-P` flag:
```bash
sidef -P100 script.sf  # 100 decimal places
```

Or dynamically:
```ruby
say sqrt(2)                     #=> 1.41421...
local Num!PREC = 42.numify      # 42 bits precision
say sqrt(2)                     #=> 1.414213562
```

#### Complex Numbers

```ruby
3:4              # 3+4i
3+4i             # 3+4i
3+4.i            # 3+4i
Complex(3,4)     # 3+4i

sqrt(-1)         # 1i
log(-1)          # πi
(3+4i)**2        # -7+24i
```

#### Special Number Types

**Modular Arithmetic:**
```ruby
var a = Mod(13, 19)
a += 15             # Mod(9, 19)
a *= 99             # Mod(17, 19)
say a**42           # Mod(11, 19)
```

**Gaussian Integers:**
```ruby
var a = Gauss(3,4)
var b = Gauss(17,19)
say a*b             #=> Gauss(-1112, 2466)
```

**Polynomials:**
```ruby
var p = Poly([1,2,3])           # x^2 + 2x + 3
var q = Poly("2*x^2 + 3*x - 5")
say p*q                         # polynomial multiplication
```

### Strings

#### String Quotes

Double-quoted strings support interpolation and escapes:

```ruby
var name = "World"
say "Hello, #{name}!"    # interpolation
say "Line 1\nLine 2"     # escape sequences
```

Single-quoted strings are literal:

```ruby
say 'No interpolation: #{name}'
say 'Literal backslash: \n'
```

Unicode quotes:
```ruby
var dstr = „double quoted"
var sstr = ‚single quoted'
```

Symbol notation:
```ruby
:word == 'word'
:foo  == 'foo'
```

#### Special Quote Operators

```ruby
%q{single {} quoted}        # single-quoted
%Q«double «» quoted»        # double-quoted
%w(word1 word2)             # word array
%W(interpolated words)      # double-quoted words
<single words>              # word array
«double «quoted» words»     # double-quoted words
%r/regex/                   # regex
%f"filename.txt"            # File object
%d'/directory'              # Dir object
%p(command)                 # Pipe object
%x(shell command)           # backticks
```

#### Heredocs

```ruby
var str = <<'EOF'
literal text
no interpolation
EOF

var str = <<-"EOT"
    indented heredoc
    with interpolation: #{1+2}
    EOT
```

#### Common String Methods

```ruby
"hello".uc              # uppercase → "HELLO"
"HELLO".lc              # lowercase → "hello"
"hello world".tc        # titlecase → "Hello world"
"hello world".wc        # wordcase → "Hello World"
"  text  ".trim         # remove whitespace → "text"
"hello".reverse         # → "olleh"
"hello".length          # → 5

"hello".contains("ll")  # true
"hello".begins_with("he") # true
"hello".ends_with("lo")   # true
"hello".index("ll")     # 2

"a,b,c".split(',')      # ["a", "b", "c"]
"hello".chars           # ["h", "e", "l", "l", "o"]
```

### Arrays

#### Array Creation

```ruby
var arr = [1, 2, 3, 4, 5]
var arr = Array(1, 2, 3, 4, 5)
```

#### Array Operations

```ruby
arr[0] = 6              # assignment
arr[3][4] = "hi"        # autovivification
arr[-1]                 # last element
arr[0, 2]               # slice: first and third elements

# Methods
arr.push(6)             # append
arr.pop                 # remove last
arr.shift               # remove first
arr.unshift(0)          # prepend
arr.length              # size
arr.reverse             # reversed copy
arr.sort                # sorted copy
```

#### Functional Methods

```ruby
[1,2,3,4,5].grep { _ > 2 }              # [3,4,5]
[1,2,3].map { _**2 }                    # [1,4,9]
[3,1,2].sort                            # [1,2,3]
[1,2,3].reduce { |a,b| a + b }          # 6
[1,2,3].each { |n| say n }              # iteration
```

#### Array Metaoperators

**Unroll (element-wise):**
```ruby
[1,2,3] »+« [4,5,6]         # [5,7,9]
```

**Map:**
```ruby
[1,2,3] »*» 4               # [4,8,12]
```

**Reduce:**
```ruby
[1,2,3]«+»                  # 6
```

**Cross product:**
```ruby
[1,2] ~X+ [3,4]             # [4,5,5,6]
```

**Zip:**
```ruby
[1,2] ~Z+ [3,4]             # [4,6]
```

### Hashes

#### Hash Creation

```ruby
var hash = Hash(
    name => 'John',
    age  => 42,
)

var hash = :(name => 'John', age => 42)
```

#### Hash Access

```ruby
hash{:name}                 # get value
hash{:name} = 'Jane'        # set value
hash{:a, :b, :c}            # multiple values
```

#### Hash Methods

```ruby
hash.keys                   # all keys
hash.values                 # all values
hash.has(:name)             # check key exists
hash.delete(:age)           # remove key
hash.sort_by { |k,v| v }    # sort by value
```

### Ranges

#### Range Creation

```ruby
1..10                # 1 to 10 (inclusive)
1..^10               # 1 to 9 (exclusive end)
10^..1               # 10 to 1 (exclusive start)
```

#### Range Operations

```ruby
(1..10) + 2          # 3..12 (shift)
(1..10) * 2          # 2..20 (stretch)
(1..10).reverse      # 10..1
(1..10).by(0.5)      # step by 0.5

# Iteration
for i in (1..5) {
    say i
}
```

### Sets and Bags

#### Sets

```ruby
var s1 = Set('a', 'b', 'c')
var s2 = Set('b', 'c', 'd')

s1 & s2              # intersection
s1 | s2              # union
s1 - s2              # difference
s1 ^ s2              # symmetric difference
```

#### Bags (Multisets)

```ruby
var b1 = Bag('a', 'b', 'b', 'c')
b1.count('b')        # 2
```

---

## Control Flow

### Conditional Statements

#### if/elsif/else

```ruby
if (condition) {
    # code
}
elsif (other_condition) {
    # code
}
else {
    # code
}
```

#### with Statement

Tests for defined (non-nil) values:

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

#### Ternary Operator

```ruby
var result = (condition ? true_value : false_value)
```

### Switch Statements

#### given/when

Pattern matching with smartmatch:

```ruby
given (value) {
    when (1) { say "one" }
    when (2) { say "two" }
    when (/^\d+$/) { say "number" }
    else { say "other" }
}
```

#### case

Boolean expression testing:

```ruby
given (x) {
    case (x < 0) { say "negative" }
    case (x == 0) { say "zero" }
    case (x > 0) { say "positive" }
}
```

### Loops

#### while Loop

```ruby
while (condition) {
    # code
}
```

#### do-while Loop

```ruby
do {
    # code
} while (condition)
```

#### for Loop

```ruby
# Traditional
for (var i = 0; i < 10; i++) {
    say i
}

# For-in
for item in collection {
    say item
}

# With block variable
for (1..10) { |i|
    say i
}
```

#### loop (Infinite)

```ruby
loop {
    # infinite loop
    break if condition
}
```

#### Range-based Iteration

```ruby
5.times { |i|
    say i               # 0,1,2,3,4
}

5.of { |i| i**2 }       # [0,1,4,9,16]
5.by { .is_prime }      # [2,3,5,7,11]
```

### Loop Control

```ruby
break               # exit loop
next                # skip to next iteration
continue            # fall through (in given/when)
```

---

## Functions and Methods

### Function Declaration

```ruby
func greet(name) {
    say "Hello, #{name}!"
}

greet("World")
```

### Function Features

#### Default Parameters

```ruby
func greet(name="World") {
    say "Hello, #{name}!"
}

greet()         # Hello, World!
greet("Alice")  # Hello, Alice!
```

#### Variadic Functions

```ruby
func sum(*args) {
    args.reduce('+')
}

say sum(1,2,3,4)    # 10
```

#### Named Parameters

```ruby
func div(a, b) {
    a / b
}

say div(b: 5, a: 35)    # 7
```

#### Type Constraints

```ruby
func concat(String a, String b) {
    a + b
}

concat("hello", "world")    # OK
concat(1, 2)                # runtime error
```

#### Return Types

```ruby
func add(a, b) -> Number {
    a + b
}
```

### Recursion

```ruby
func factorial(n) {
    return 1 if (n <= 1)
    n * factorial(n - 1)
}

say factorial(5)    # 120
```

Anonymous recursion:
```ruby
func fib(n) {
    n < 2 ? n : (__FUNC__(n-1) + __FUNC__(n-2))
}
```

### Closures

```ruby
func make_counter(start=0) {
    var count = start
    func {
        ++count
    }
}

var counter = make_counter(10)
say counter()    # 11
say counter()    # 12
```

### Pattern Matching

```ruby
func fib ((0)) { 0 }
func fib ((1)) { 1 }
func fib  (n)  { fib(n-1) + fib(n-2) }

say fib(10)    # 55
```

With blocks:
```ruby
func fib(Number n {_ <= 1} = 0) { n }
func fib(Number n) { fib(n-1) + fib(n-2) }
```

### Multiple Dispatch

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

### Method Caching

```ruby
func fib(n) is cached {
    return n if (n <= 1)
    fib(n-1) + fib(n-2)
}

say fib(100)    # Fast with memoization
```

---

## Object-Oriented Programming

### Classes

#### Basic Class

```ruby
class Person(name, age) {

    method greet {
        say "Hello, I'm #{name} and I'm #{age} years old"
    }

    method birthday {
        self.age++
    }
}

var person = Person(name: "Alice", age: 30)
person.greet()
person.birthday()
say person.age    # 31
```

#### Class Attributes

```ruby
class Example(a, b) {
    has c = 3
    has d = (a + c)

    method sum {
        a + b + c + d
    }
}
```

#### Initialization

```ruby
class Example(value) {
    has processed

    method init {
        processed = (value * 2)
    }
}
```

#### Type Constraints

```ruby
class Person(String name, Number age) {
    # name must be String, age must be Number
}
```

### Structs

Lightweight data containers:

```ruby
struct Point {
    Number x,
    Number y,
}

var p = Point(x: 10, y: 20)
say p.x    # 10
```

### Subsets

Type refinement:

```ruby
subset Integer  < Number  { |n| n.is_int }
subset Positive < Integer { |n| n.is_pos }

func square_root(Positive n) {
    n.sqrt
}
```

---

## Advanced Features

### Regular Expressions

#### Basic Matching

```ruby
if ("hello world" =~ /world/) {
    say "Match!"
}

# Capture groups
var match = "hello world".match(/(\w+) (\w+)/)
say match[0]    # hello
say match[1]    # world
```

#### Global Matching

```ruby
var text = "a cat, a dog and a fox"
while (var m = text.match(/\ba\h+(\w+)/g)) {
    say m[0]
}
# Output: cat, dog, fox
```

### Smart Matching

```ruby
"hello" ~~ /^h/           # true
"oo" ~~ "foobar"          # false
"a" ~~ %w(a b c)          # true
/^b/ ~~ %w(foo bar)       # true
```

### Lazy Evaluation

```ruby
say (^Inf -> lazy.grep{.is_prime}.first(10))
# First 10 primes without memory overhead
```

### Lazy Methods

Partial application:

```ruby
var add10 = 10.method('+')
say [1,2,3].map(add10)    # [11, 12, 13]
```

### Pipeline Operator

```ruby
25 |> :sqrt |> :say              # 5
42 |> {_*3} |> {_*2} |> {_+1}    # 253
```

### Exception Handling

```ruby
try {
    die "Error!" if condition
}
catch { |msg|
    say "Caught: #{msg}"
}
```

### File Operations

```ruby
var file = File('/tmp/data.txt')

# Read
var content = file.read
var lines = file.lines

# Write
file.write(text)
file.append(more_text)

# Edit in place
file.edit { |line|
    line.gsub(/old/, 'new')
}
```

### Modules

```ruby
module math::utils {
    func double(n) { n * 2 }
    func triple(n) { n * 3 }
}

say math::utils::double(21)    # 42
```

### gather/take

Lazy list building:

```ruby
var list = gather {
    for i in (1..10) {
        take(i) if i.is_prime
    }
}
say list    # [2, 3, 5, 7]
```

---

## Best Practices

### Style Guidelines

1. **Use explicit parentheses** for complex expressions
2. **Prefer meaningful names** over abbreviations
3. **Use type constraints** where appropriate
4. **Leverage functional methods** (map, grep, reduce)
5. **Cache expensive recursive functions**

### Performance Tips

1. Use `define` for compile-time constants
2. Cache recursive functions with `is cached`
3. Prefer lazy evaluation for large datasets
4. Use appropriate numeric types (Int vs Float vs Rational)
5. Profile with `-r` flag to see parsed structure

### Common Patterns

**Hash with Array values creation:**
```ruby
var hash = Hash()
hash{:key} := [] << 1
hash{:key} := [] << 2
say hash{:key}  #=> [1, 2]
```

**Conditional assignment:**
```ruby
var x = nil
x := some_func1()
x := some_func2()   # calls some_func2() if x == nil
```

---

## Resources

- **Official Documentation:** [https://trizen.gitbook.io/sidef-lang/](https://trizen.gitbook.io/sidef-lang/)
- **Source Code:** [https://github.com/trizen/sidef](https://github.com/trizen/sidef)
- **Example Scripts:** [https://github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)
- **MetaCPAN:** [https://metacpan.org/pod/Sidef](https://metacpan.org/pod/Sidef)

---

*This tutorial covers the essentials of Sidef. For complete documentation, refer to the official book and POD documentation.*
