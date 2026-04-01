# Sidef — Advanced Programming Guide

<div align="center">

**Intermediate and advanced techniques for experienced Sidef programmers**

[Official Documentation](https://trizen.gitbook.io/sidef-lang/) • [GitHub](https://github.com/trizen/sidef) • [Example Scripts](https://github.com/trizen/sidef-scripts) • [Try Online](https://tio.run/#sidef)

</div>

---

> **Prerequisites:** This guide assumes you already have Sidef installed and working, and that you are comfortable with the fundamentals — variables, control flow, basic functions, simple arrays and hashes, and basic OOP. If you need a refresher on those, see the Beginner's Guide first.

---

## Table of Contents

1. [Command-Line Flags and the REPL](#1-command-line-flags-and-the-repl)
2. [Special Quote Operators and Strings](#2-special-quote-operators-and-strings)
3. [Advanced Functions](#3-advanced-functions)
4. [Metaoperators](#4-metaoperators)
5. [Sets, Bags, and Pairs](#5-sets-bags-and-pairs)
6. [Ranges in Depth](#6-ranges-in-depth)
7. [Lazy Evaluation, gather/take, and Enumerators](#7-lazy-evaluation-gathertake-and-enumerators)
8. [Advanced OOP](#8-advanced-oop)
9. [Special Numeric Types](#9-special-numeric-types)
10. [Number Theory](#10-number-theory)
11. [Arbitrary Precision and Floating-Point](#11-arbitrary-precision-and-floating-point)
12. [Functional Programming Patterns](#12-functional-programming-patterns)
13. [Regular Expressions](#13-regular-expressions)
14. [File and Directory I/O](#14-file-and-directory-io)
15. [Perl Module Integration](#15-perl-module-integration)
16. [Sorting Algorithms](#16-sorting-algorithms)
17. [Dynamic Programming and Memoization](#17-dynamic-programming-and-memoization)
18. [Matrix and Vector Arithmetic](#18-matrix-and-vector-arithmetic)
19. [Encoding, Compression, and Cryptography Patterns](#19-encoding-compression-and-cryptography-patterns)
20. [Putting It All Together: Larger Examples](#20-putting-it-all-together-larger-examples)
21. [Further Resources](#21-further-resources)

---

## 1. Command-Line Flags and the REPL

Beyond just running `sidef script.sf`, there are several useful flags worth knowing.

```bash
# Run a one-liner
sidef -e 'say 10.primes'

# Set floating-point precision to 50 decimal places
sidef -P50 -e 'say Num.pi'

# Print the parsed representation of a script (useful for debugging precedence)
sidef -r script.sf

# Run with warnings enabled
sidef -W script.sf

# Compile to Perl (advanced: inspect generated code)
sidef -C script.sf
```

In the REPL, you can inspect any value just by typing it — no `say` needed:

```
$ sidef
> 2**100
1267650600228229401496703205376
> 100.factorial.len
158
> "hello".chars.reverse.join
olleh
```

---

## 2. Special Quote Operators and Strings

Sidef has a rich set of quoting mechanisms beyond plain strings.

### Word Arrays

```ruby
var fruits = %w(apple banana cherry)
# Equivalent to: ["apple", "banana", "cherry"]

var paths = <usr local bin>
# Also a word array: ["usr", "local", "bin"]
```

### Heredocs

```ruby
var poem = <<'EOF'
Roses are red,
Violets are blue.
No interpolation here: #{1+2}
EOF

var greeting = <<-"EOT"
    Hello, #{name}!
    Today is a great day.
    EOT
```

The `<<-` form strips leading whitespace so the closing delimiter can be indented naturally.

### Shell Execution

```ruby
var ls_output = %x(ls -la)
var files     = %x(find . -name "*.sf").lines
```

### Symbol Literals

Symbols are just single-quoted strings with a compact notation — useful as hash keys:

```ruby
var h = Hash(:name => "Alice", :age => 30)
say h{:name}    # Alice
```

### String Interpolation Tricks

Any expression can be interpolated inside `#{}`:

```ruby
var n = 12
say "The #{n}th prime is #{n.prime}"    # The 12th prime is 37
say "Sum 1..100 = #{(1..100).sum}"      # Sum 1..100 = 5050
```

Multi-line method chaining with backslash continuation:

```ruby
say "hello world" \
    .split(' ')   \
    .map { .tc }  \
    .join(' ')
# => Hello World
```

---

## 3. Advanced Functions

### Default and Named Parameters

```ruby
func greet(name = "World", punct = "!") {
    say "Hello, #{name}#{punct}"
}

greet()                        # Hello, World!
greet("Alice")                 # Hello, Alice!
greet(name: "Bob", punct: ".") # Hello, Bob.
greet(punct: "?")              # Hello, World?
```

### Variadic Functions

```ruby
func sum(*nums) {
    nums.reduce(0, '+')
}
say sum(1, 2, 3, 4, 5)    # 15

func log_all(String prefix, *msgs) {
    msgs.each { |m| say "#{prefix}: #{m}" }
}
log_all("INFO", "started", "running", "done")
```

### Return Type Constraints

```ruby
func square(Number n) -> Number {
    n**2
}

func greet(String name) -> String {
    "Hello, #{name}!"
}
```

### Multiple Dispatch

Sidef resolves calls to the most specific matching overload:

```ruby
func describe(String s)  { say "String:  #{s}" }
func describe(Number n)  { say "Number:  #{n}" }
func describe(Array  a)  { say "Array:   #{a}" }

describe("hi")    # String:  hi
describe(42)      # Number:  42
describe([1,2,3]) # Array:   [1, 2, 3]
```

### Pattern Matching in Function Arguments

Match on literal values using double parentheses:

```ruby
func fib ((0)) { 0 }
func fib ((1)) { 1 }
func fib  (n)  { fib(n-1) + fib(n-2) }

say fib(10)    # 55
```

Match on value predicates (block guards):

```ruby
func sign(Number n { _ < 0 })  { -1 }
func sign(Number n { _ == 0 }) {  0 }
func sign(Number n { _ > 0 })  {  1 }

say sign(-7)    # -1
say sign(0)     #  0
say sign(5)     #  1
```

### Closures and Higher-Order Functions

```ruby
func make_adder(n) {
    func(x) { x + n }
}

var add10 = make_adder(10)
var add42 = make_adder(42)

say add10(5)     # 15
say add42(100)   # 142
say [1,2,3].map(add10)    # [11, 12, 13]
```

Closures capture their environment by reference, so they can act as stateful objects:

```ruby
func make_counter(start = 0) {
    var n = start
    Hash(
        inc  => func { ++n },
        dec  => func { --n },
        get  => func {   n },
        reset => func { n = start },
    )
}

var c = make_counter(10)
c{:inc}()
c{:inc}()
c{:inc}()
say c{:get}()    # 13
c{:reset}()
say c{:get}()    # 10
```

### Anonymous Self-Reference with `__FUNC__`

```ruby
func fib(n) {
    n < 2 ? n : (__FUNC__(n-1) + __FUNC__(n-2))
}
```

This is especially useful in lambdas that need to recurse without a name:

```ruby
var factorial = func(n) {
    n <= 1 ? 1 : (n * __FUNC__(n-1))
}
say factorial(10)    # 3628800
```

### Lazy Partial Application

Turn any method into a reusable function via `.method(name)`:

```ruby
var double = 2.method('*')
say [1, 2, 3, 4].map(double)    # [2, 4, 6, 8]

var inc = 1.method('+')
say (1..5).map(inc).to_a        # [2, 3, 4, 5, 6]
```

---

## 4. Metaoperators

Sidef has powerful array metaoperators that eliminate most explicit loops.

### Element-wise (Unroll): `»OP«`

Apply an operator between two arrays element by element:

```ruby
[1,2,3] »+«  [10,20,30]    # [11, 22, 33]
[4,9,16] »**« [0.5, 0.5, 0.5]    # [2, 3, 4]  (sqrt)
```

### Map: `»OP»` and `«OP«`

Apply an operator or method to every element:

```ruby
[1,2,3,4] »*» 10    # [10, 20, 30, 40]
[1,2,3,4] «*« 10    # [10, 20, 30, 40]

["hello","world"] >>uc()>>    # ["HELLO", "WORLD"]
[1,4,9,16] >>sqrt()>>         # [1, 2, 3, 4]
```

### Reduce: `«OP»`

Fold an array with an operator:

```ruby
[1,2,3,4,5]«+»     # 15
[1,2,3,4,5]«*»     # 120
[3,1,4,1,5]«max»   # 5
```

### Cross Product: `~X`

```ruby
[1,2] ~X   [3,4]     # [[1,3],[1,4],[2,3],[2,4]]
[1,2] ~X+  [3,4]     # [4, 5, 5, 6]   (cross with +)
[1,2] ~X*  [3,4]     # [3, 4, 6, 8]   (cross with *)
```

### Zip: `~Z`

```ruby
[1,2,3] ~Z  [4,5,6]    # [[1,4],[2,5],[3,6]]
[1,2,3] ~Z+ [4,5,6]    # [5, 7, 9]
```

### Practical Example

Dot product of two vectors without any explicit loop:

```ruby
func dot(a, b) {
    (a »*« b)«+»
}

say dot([1,2,3], [4,5,6])    # 32  (= 1*4 + 2*5 + 3*6)
```

---

## 5. Sets, Bags, and Pairs

### Sets

Sets hold unique elements and support standard set operations:

```ruby
var evens  = Set(2, 4, 6, 8, 10)
var primes = Set(2, 3, 5, 7, 11)

say (evens & primes)    # Set(2)          — intersection
say (evens | primes)    # Set(2,3,4,5,6,7,8,10,11) — union
say (evens - primes)    # Set(4,6,8,10)   — difference
say (evens ^ primes)    # symmetric difference

say evens.has(4)        # true
say evens.len           # 5
```

Convert back to sorted array:

```ruby
say (evens | primes).to_a.sort    # [2, 3, 4, 5, 6, 7, 8, 10, 11]
```

### Bags (Multisets)

A `Bag` is like a `Set` but tracks how many times each element appears:

```ruby
var letters = Bag("a", "b", "a", "c", "b", "a")

say letters.count("a")    # 3
say letters.count("b")    # 2
say letters.keys.sort     # ["a", "b", "c"]
```

Bags are useful for frequency analysis:

```ruby
var words = "the cat sat on the mat the cat".split(' ')
var freq  = Bag(words...)

freq.keys.sort_by { freq.count(_) }.reverse.each { |w|
    say "#{w}: #{freq.count(w)}"
}
# the: 3
# cat: 2
# sat: 1
# on:  1
# mat: 1
```

### Pairs

A `Pair` is a lightweight two-element tuple:

```ruby
var p = Pair("key", "value")
say p.first     # key
say p.second    # value

# Pairs are returned by hash iteration:
Hash(a => 1, b => 2).each_pair { |pair|
    say "#{pair.first} => #{pair.second}"
}
```

---

## 6. Ranges in Depth

### Arithmetic on Ranges

Ranges support arithmetic operators that produce new ranges:

```ruby
(1..10) + 5     # 6..15
(1..10) * 2     # 2..20
(2..20).by(2)   # even numbers: 2,4,6,...,20
```

### Custom Step with `by`

```ruby
for x in ((0..1).by(0.1)) {
    print "#{x} "
}
# 0 0.1 0.2 ... 1

for x in ((10 ^.. 1).by(3)) {
    print "#{x} "
}
# 9 6 3
```

### `upto` / `downto` / `by` Chaining

```ruby
(-2 `upto` 2 `by` 0.5).each { |x|
    say x
}
```

### Range Methods

```ruby
(1..100).sum                # 5050
(1..10).prod                # 3628800  (10!)
(1..20).grep { .is_prime }  # [2,3,5,7,11,13,17,19]
(1..Inf).lazy.grep { .is_prime }.first(10)  # first 10 primes
```

---

## 7. Lazy Evaluation, gather/take, and Enumerators

Lazy evaluation is one of Sidef's most powerful features for handling large or infinite sequences without memory overhead.

### The `.lazy` Chain

```ruby
# First 10 numbers that are both a perfect square and have digit sum 10
var result = (1..Inf).lazy \
    .map { _**2 } \
    .grep { .digits.sum == 10 } \
    .first(5)

say result    # [64, 361, 1225, 2116, 3025]
```

### gather/take

`gather` runs a block and collects every value passed to `take`:

```ruby
# Collect twin prime pairs up to 100
var twins = gather {
    for p in (primes(3, 100)) {
        take([p, p+2]) if (p+2).is_prime
    }
}
say twins
# [[3,5],[5,7],[11,13],[17,19],[29,31],[41,43],[59,61],[71,73]]
```

`gather`/`take` can also build trees or nested structures:

```ruby
# Pascal's triangle rows
var pascal = gather {
    var row = [1]
    10.times {
        take(row.clone)
        row = [1, (row ~Z+ row.slice(1))..., 1]
    }
}
pascal.each { |row| say row.join(" ") }
```

### Enumerators (Custom Lazy Sequences)

`Enumerator` lets you define your own infinite (or finite) lazy generators:

```ruby
# Fibonacci sequence
var fibs = Enumerator({ |yield|
    var (a, b) = (0, 1)
    loop {
        yield(a)
        (a, b) = (b, a+b)
    }
})

say fibs.first(10)    # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
say fibs.nth(51)      # 12586269025  (1-indexed)
```

Enumerators supports various methods with conditional blocks, such as:

```ruby
say fibs.first(8, { .is_prime })  # [2, 3, 5, 13, 89, 233, 1597, 28657]
say fibs.nth(5, { .is_even })     # 144
say fibs.while { _ <= 1000 }      # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987]
```

Collatz sequence as an enumerator:

```ruby
func collatz_seq(n) {
    Enumerator({ |yield|
        while (n != 1) {
            yield(n)
            n = (n.is_even ? (n>>1) : (3*n + 1))
        }
        yield(1)
    })
}

say collatz_seq(27).to_a.len    # steps to reach 1: 112
```

---

## 8. Advanced OOP

### The `init` Method

`init` runs automatically after object construction and is useful for derived attribute setup:

```ruby
class Circle(Number radius) {
    has area
    has circumference

    method init {
        area          = (Num.pi * radius**2)
        circumference = (2 * Num.pi * radius)
    }

    method scale(Number factor) {
        Circle(radius * factor)
    }
}

var c = Circle(5)
say c.area.round(-4)                    # 78.5398
say c.scale(2).circumference.round(-4)  # 62.8319
```

### Method Overriding and `super`

```ruby
class Shape {
    method area { 0 }
    method describe { "Shape with area #{self.area.round(2)}" }
}

class Rectangle(Number w, Number h) < Shape {
    method area { w * h }
}

class Square(Number side) < Rectangle {
    method init {
        # a square is a rectangle with equal sides
    }

    method area { side**2 }
}

var s = Square(5)
say s.describe    # Shape with area 25
```

### Subsets for Type Refinement

Subsets act as refined types and can be used in function signatures, providing automatic validation:

```ruby
subset EvenInt < Number { |n| n.is_int && n.is_even }
subset OddInt  < Number { |n| n.is_int && n.is_odd  }
subset PosNum  < Number { |n| n > 0 }

func half(EvenInt n)        { n / 2 }
func next_odd(OddInt n)     { n + 2 }
func log_safe(PosNum x)     { x.log }

say half(8)           # 4
say next_odd(7)       # 9
say log_safe(Num.e)   # 1
```

### Mixins with Modules

Modules are first-class namespaces that can be used as mixins:

```ruby
module Printable {
    method print_info {
        say "#{self.class}: #{self}"
    }
}

module Serializable {
    method to_string {
        self.class + "(" + self.to_a.join(", ") + ")"
    }
}

class Point(Number x, Number y) {
    include Printable
    include Serializable

    method to_a { [x, y] }
    method to_s { "(#{x}, #{y})" }
}

var p = Point(3, 4)
p.print_info        # Point: (3, 4)
say p.to_string     # Point(3, 4)
```

### Operator Overloading

```ruby
class Vector2D(Number x, Number y) {

    method +(Vector2D other) {
        Vector2D(x + other.x, y + other.y)
    }

    method *(Number scalar) {
        Vector2D(x * scalar, y * scalar)
    }

    method magnitude {
        (x**2 + y**2).sqrt
    }

    method to_s { "<#{x}, #{y}>" }
}

var v1 = Vector2D(1, 2)
var v2 = Vector2D(3, 4)

say (v1 + v2)        # <4, 6>
say (v1 * 3)         # <3, 6>
say v2.magnitude     # 5
```

---

## 9. Special Numeric Types

### Modular Arithmetic (`Mod`)

`Mod(n, m)` creates a number in ℤ/mℤ — all operations are automatically reduced modulo `m`:

```ruby
var a = Mod(13, 19)
var b = Mod(7,  19)

say (a + b)     # Mod(1, 19)   (13+7 = 20 ≡ 1 mod 19)
say (a * b)     # Mod(15, 19)
say a**100      # Mod(6, 19)   — fast modular exponentiation

# Modular inverse
say a.inv     # Mod(3, 19)  since 13*3 = 39 ≡ 1 mod 19
```

`Mod` is ideal for cryptographic and number-theoretic computations:

```ruby
# Fermat's little theorem: a^(p-1) ≡ 1 (mod p) for prime p, gcd(a,p)=1
var p = 97
var a = Mod(42, p)
say a**(p-1)    # Mod(1, 97)
```

### Gaussian Integers (`Gauss`)

Gaussian integers are complex numbers `a + bi` where both `a` and `b` are integers:

```ruby
var g1 = Gauss(3, 4)
var g2 = Gauss(1, -2)

say (g1 + g2)   # Gauss(4, 2)
say (g1 * g2)   # Gauss(11, -2)   (= 3-6i+4i+8 = 11-2i)
say g1.norm     # 25              (= 3² + 4²)
say g1.conj     # Gauss(3, -4)

# Factorize a Gaussian integer
say Gauss(5, 0).factor    # Gauss(2+i) * Gauss(2-i)
```

### Polynomials (`Poly`)

```ruby
var p = Poly([1, -3, 2])     # x² - 3x + 2
var q = Poly([1, 1])         # x + 1

say (p * q)                  # x³ - 2x² - x + 2
say p.eval(0)                # 2
say p.eval(1)                # 0   (1 is a root)
say p.eval(2)                # 0   (2 is a root)

# Polynomial from roots
say Poly.from_roots([1, 2, 3])    # x³ - 6x² + 11x - 6

# Derivative
say p.derivative    # 2x - 3
```

### Modular Polynomials (`PolyMod`)

Polynomials over a finite field:

```ruby
var p = PolyMod([1, 0, 1], 2)     # x² + 1 over GF(2)
var q = PolyMod([1, 1],    2)     # x + 1  over GF(2)

say (p * q)    # x³ + x² + x + 1 (mod 2)
```

### Quaternions

```ruby
var q1 = Quaternion(1, 2, 3, 4)    # 1 + 2i + 3j + 4k
var q2 = Quaternion(5, 6, 7, 8)

say (q1 + q2)  # Quaternion(6, 8, 10, 12)
say (q1 * q2)  # Quaternion(-60, 12, 30, 24)
say q1.norm    # sqrt(1+4+9+16) = sqrt(30)
say q1.conj    # Quaternion(1, -2, -3, -4)
```

---

## 10. Number Theory

Sidef has exceptional built-in support for number-theoretic functions — far beyond what most languages offer out of the box.

### Primality and Prime Generation

```ruby
say (2**31 - 1)               # 2147483647
say (2**31 - 1 -> is_prime)   # true (Mersenne prime)

# nth prime
say 1000.prime    # 7919

# Primes in a range
say primes(1000, 1100)    # all primes between 1000 and 1100

# Prime counting function π(n)
say prime_count(10**6)    # 78498
```

### Factorization

```ruby
say factor(12)              # [2, 2, 3]
say factor(2**64 + 1)       # full factorization of large numbers

# Factor as pairs [prime, exponent]
say factor_exp(360)         # [[2,3],[3,2],[5,1]]

# Euler's totient φ(n)
say euler_phi(360)          # 96

# Number of divisors σ₀(n)
say sigma(360, 0)           # 24

# Sum of divisors σ₁(n)
say sigma(360, 1)           # 1170

# Sum of squares of divisors σ₂(n)
say sigma(360, 2)           # 63050

# List of divisors
say divisors(36)            # [1, 2, 3, 4, 6, 9, 12, 18, 36]
```

### GCD, LCM, and Extended GCD

```ruby
say gcd(48, 18)         # 6
say lcm(4, 6)           # 12
say gcd(0, 7)           # 7

# Extended Euclidean algorithm: returns (x, y, gcd) where gcd = a*x + b*y
var (x, y, g) = 48.gcdext(18)
say "#{g} = 48*#{x} + 18*#{y}"    # 6 = 48*(-1) + 18*3

# Modular inverse: x such that a*x ≡ 1 (mod m)
say invmod(7, 11)    # 8  (since 7*8 = 56 ≡ 1 mod 11)
```

### Modular Arithmetic Functions

```ruby
# Modular exponentiation: base^exp mod m
say powmod(2, 100, 10**9 + 7)

# Jacobi symbol
say jacobi(5, 11)    # 1  (5 is a quadratic residue mod 11)

# Modular square root (Tonelli-Shanks)
say sqrtmod(4, 7)    # 2  (2² ≡ 4 mod 7)

# Multiplicative order: smallest k > 0 with a^k ≡ 1 (mod m)
say znorder(2, 7)    # 3
```

### Sieve of Eratosthenes (Manual Implementation)

This example shows how to implement a sieve yourself to understand how Sidef's builtins work under the hood:

```ruby
func sieve(limit) {
    var composite = limit.of(false)
    var primes    = []

    for p in (2..limit.isqrt) {
        if (!composite[p]) {
            var j = p*p
            while (j <= limit) {
                composite[j] = true
                j += p
            }
        }
    }

    for n in (2..limit) {
        primes << n if !composite[n]
    }
    primes
}

say sieve(50)    # [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
```

### Miller-Rabin Primality Test (Manual)

```ruby
func miller_rabin(n, witnesses) {
    return false if (n < 2)
    return true  if ((n == 2) || (n == 3))
    return false if (n.is_even)

    # Write n-1 as 2^r * d
    var (r, d) = (0, n - 1)
    while (d.is_even) { d >>= 1; ++r }

    for a in witnesses {
        next if (a >= n)
        var x = powmod(a, d, n)
        next if ((x == 1) || (x == n-1))

        var composite = true
        (r-1).times {
            x = powmod(x, 2, n)
            if (x == n-1) { composite = false; break }
        }
        return false if composite
    }
    true
}

# Deterministic for n < 3,215,031,751 with these witnesses:
func is_prime_mr(n) {
    miller_rabin(n, [2, 3, 5, 7])
}

say is_prime_mr(104729)     # true
say is_prime_mr(104731)     # false
say 25.by(is_prime_mr)      # first 25 primes
```

### Chinese Remainder Theorem

Find `x` such that `x ≡ a₁ (mod m₁)` and `x ≡ a₂ (mod m₂)`, etc.:

```ruby
# Built-in CRT
say Math.chinese([2,3], [3,5], [2, 7])    # 23  (23≡2 mod 3, 23≡3 mod 5, 23≡2 mod 7)

# Manual CRT for two congruences
func crt2(a1, m1, a2, m2) {
    var (u, _, g) = m1.gcdext(m2)
    die "No solution" if ((a2 - a1) % g != 0)
    var lcm = m1.lcm(m2)
    ((a1 + (m1 * u * ((a2 - a1) / g))) % lcm + lcm) % lcm
}

say crt2(3, 5, 5, 7)    # 33  (33≡3 mod 5, 33≡5 mod 7)
```

### Arithmetic Functions and Multiplicativity

```ruby
# Möbius function μ(n)
say moebius(1)     #  1
say moebius(6)     #  1   (6 = 2·3, squarefree, two prime factors)
say moebius(12)    #  0   (12 = 2²·3, not squarefree)
say moebius(30)    # -1   (30 = 2·3·5, three prime factors)

# Liouville function λ(n)
say liouville(12)    # 1   (Ω(12) = 3, (-1)³ = -1? — check actual output)

# Omega functions
say omega(12)       # 2   (distinct prime factors: 2, 3)
say bigomega(12)    # 3   (with multiplicity: 2,2,3)

# Sum over divisors
var n = 100
say divisors(n).sum               # 217  (sigma(100))
say divisors(n).sum{.euler_phi}   # == n   (Gauss identity)
```

---

## 11. Arbitrary Precision and Floating-Point

Sidef's rationals are exact, but you can explicitly use arbitrary-precision floats when needed.

### Exact Rational Arithmetic

```ruby
# Rationals never accumulate floating-point error
say (1/3 + 1/3 + 1/3 == 1)    # true
say (0.1 + 0.2 == 0.3)        # true

var r = 355/113
say r                          # 355/113
say r.as_float                 # 3.14159292...
say r.numerator                # 355
say r.denominator              # 113
```

### High-Precision Floats

```ruby
# Dynamic precision change (local scope)
local Num!PREC = 1000.numify    # 1000 bits ≈ 301 decimal places

say Num.pi        # π to 300+ places
say exp(1)        # e to 300+ places
say sqrt(2)       # √2 to 300+ places
```

Command-line precision:

```bash
sidef -P200 -e 'say pi'    # 200 decimal places of π
```

### Computing π via the AGM

The arithmetic-geometric mean converges doubly-exponentially to π:

```ruby
local Num!PREC = 200.numify

func agm_pi {
    var a = 1
    var b = (1 / sqrt(2))
    var t = 0.25
    var p = 1f

    64.times {
        var a1 = ((a + b) / 2)
        var b1 = sqrt(a * b)
        var t1 = (t - (p * (a - a1)**2))
        (a, b, t, p) = (a1, b1, t1, p*2)
    }

    (a + b)**2 / (4 * t)
}

say agm_pi()
```

### Continued Fractions

```ruby
# Represent a number as a continued fraction
say (355/113 -> cfrac)     # [3, 7, 16]

# Convergents of √2
var sqrt2_cf = Enumerator({ |yield|
    var (p0, p1, q0, q1) = (1, 1, 0, 1)
    yield(p1/q1)
    loop {
        var (a, b) = (p1 + p0, q1 + q0)
        # Determine next coefficient via the actual CF expansion of √2
        var coeff = (((a.float / b.float) > sqrt(2.float)) ? 1 : 2)
        (p0, p1) = (p1, coeff*p1 + p0)
        (q0, q1) = (q1, coeff*q1 + q0)
        yield(p1/q1)
    }
})

# Best rational approximations to √2
sqrt2_cf.first(8).each { |r|
    say "#{r.as_frac}\t≈  #{r.round(-8)}"
}
```

---

## 12. Functional Programming Patterns

### Function Composition

```ruby
func compose(*fns) {
    func(x) {
        fns.reverse.reduce({ |acc, f| f(acc) }, x)
    }
}

var process = compose(
    func(x) { x * 2 },
    func(x) { x + 3 },
    func(x) { x ** 2 },
)

say process(4)    # ((4**2) + 3) * 2 = 38
```

### Memoization with `is cached`

Cache is automatically invalidated per unique argument tuple:

```ruby
func count_partitions(n, k = n) is cached {
    return 1 if (n == 0)
    return 0 if ((n < 0) || (k == 0))
    count_partitions(n - k, k) + count_partitions(n, k - 1)
}

say count_partitions(20)    # 627
say count_partitions(50)    # 204226
```

### Trampolining (Avoid Stack Overflow for Deep Recursion)

For very deep recursion you can use an explicit stack:

```ruby
func flatten_deep(arr) {
    var result = []
    var stack  = [arr]

    while (stack) {
        var item = stack.pop
        if (item.is_a(Array)) {
            stack.push(item...)
        } else {
            result.unshift(item)
        }
    }
    result
}

say flatten_deep([1, [2, [3, [4, [5]]]], 6])    # [1, 2, 3, 4, 5, 6]
```

### Transducer-Style Pipeline

```ruby
# Composable pipeline using closures
func filtering(pred) { func(acc, x) { pred(x) ? (acc << x) : acc } }
func mapping(f)      { func(acc, x) { acc << f(x) } }

var xform = [
    filtering({ _ > 3 }),
    mapping({ _ ** 2 }),
    filtering({ _ < 100 }),
]

var input = 1..10
var result = input.reduce({ |acc, x|
    xform.reduce({ |a, f| f(a, x) }, acc)
}, [])

say result    # [16, 25, 36, 49, 64, 81]
```

### Currying

```ruby
func curry(f, *bound) {
    func(*args) { f(bound..., args...) }
}

func add(a, b, c) { a + b + c }

var add5 = curry(:add, 5)
var add5_10 = curry(:add, 5, 10)

say add5(3, 2)     # 10
say add5_10(7)     # 22
```

---

## 13. Regular Expressions

### Capture Groups and Named Captures

```ruby
var date = "2024-03-15"

# Indexed captures
var m = date.match(/(\d{4})-(\d{2})-(\d{2})/)
say m[0]    # 2024
say m[1]    # 03
say m[2]    # 15

# Named captures
var n = date.match(/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/)
say n{:year}    # 2024
say n{:month}   # 03
```

### Global Matching and `gmatch`

```ruby
var text = "The price is $3.99 and $12.50 and $0.75"

# Collect all matches
var prices = []
while (var m = text.match(/\$(\d+\.\d+)/g)) {
    prices << m[0].to_r
}
say prices         # [3.99, 12.5, 0.75]
say prices.sum     # 17.24
```

### Substitution

```ruby
var s = "Hello, World!"

# Replace first
say s.sub(/World/, "Sidef")        # Hello, Sidef!

# Replace all (g flag)
say "aabbcc".gsub(/([a-z])\1/, { |m| m[0].uc })    # AaBbCc — hmm
say "banana".gsub(/a/, "o")        # bonono

# In-place edit on a file
File("config.txt").edit { |line|
    line.gsub(/localhost/, "127.0.0.1")
}
```

### Smart Matching `~~`

```ruby
"hello" ~~ /^h/            # true  — regex
"foo"   ~~ "foobar"        # false — substring?
"a"     ~~ %w(a b c)       # true  — element of array
/^b/    ~~ %w(foo bar)     # true  — any element matches
42      ~~ (1..100)         # true  — in range
```

### Splitting and Joining

```ruby
"one two  three".split(/\s+/)         # ["one","two","three"]
"a1b2c3".split(/(?<=\d)(?=\D)/)       # ["a1","b2","c3"]

var csv = "name,age,city"
var fields = csv.split(',')
say fields.join(" | ")    # name | age | city
```

---

## 14. File and Directory I/O

### Reading Files

```ruby
# Entire file as string
var content = File("data.txt").read

# Line by line (memory efficient)
File("data.txt").each_line { |line|
    say line.trim
}

# All lines as array
var lines = File("data.txt").lines

# Read and parse a CSV-like file
File("data.csv").each_line { |line|
    var (name, age, city) = line.trim.split(',')...
    say "#{name} is #{age} years old, lives in #{city}"
}
```

### Writing Files

```ruby
File("out.txt").write("First line\n")
File("out.txt").append("Second line\n")

# Write multiple lines
var lines = (1..5).map { "Line #{_}" }
File("out.txt").write(lines.join("\n") + "\n")
```

### Directory Operations

```ruby
# List files in a directory
Dir(".").each { |entry|
    say entry if entry =~ /\.sf$/
}

# Recursive file finder
func find_files(dir, pattern) {
    gather {
        Dir(dir).each_r { |f|
            take(f) if (f =~ pattern)
        }
    }
}

find_files(".", /\.sf$/).each { |f| say f }
```

### File Metadata

```ruby
var f = File("script.sf")

say f.exists        # true/false
say f.size          # size in bytes
say f.mtime         # modification time
say f.is_file       # true
say f.is_dir        # false
say f.abs_path      # absolute path
```

### Pipe and Shell Integration

```ruby
# Run a command and iterate its output lines
Pipe("ls -la").each_line { |line|
    say line if line =~ /\.sf$/
}

# Capture output
var git_log = %x(git log --oneline -10)
git_log.lines.each { |line| say line.trim }
```

---

## 15. Perl Module Integration

Any CPAN module can be used directly, making Sidef's ecosystem enormous.

### Object-Oriented Perl Modules

```ruby
# HTTP requests
var ua       = require('LWP::UserAgent').new
var response = ua.get('https://api.github.com')
say response.decoded_content

# JSON encoding/decoding
var json    = require('JSON')
var encoded = json.encode(Hash(name => "Alice", scores => [98, 87, 92]))
say encoded

var decoded = json.decode('{"x":1,"y":2}')
say decoded{:x}    # 1
```

### Functional Perl Modules

```ruby
var posix = frequire('POSIX')
say posix.floor(3.7)    # 3
say posix.ceil(3.2)     # 4

var list_util = frequire('List::Util')
say list_util.sum(1..10)    # 55
say list_util.max(3,1,4,1,5,9,2,6)    # 9
say list_util.shuffle([1..10]...)
```

### Using Perl's DBI for Databases

```ruby
var dbi = require('DBI')
var dbh = dbi.connect("dbi:SQLite:dbname=test.db", "", "")

dbh.do("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
dbh.do("INSERT INTO users VALUES (1, 'Alice')")

var sth = dbh.prepare("SELECT * FROM users WHERE id = ?")
sth.execute(1)

while (var row = sth.fetchrow_hashref) {
    say "#{row{:id}}: #{row{:name}}"
}
dbh.disconnect
```

---

## 16. Sorting Algorithms

Sidef makes it easy to implement and compare classic algorithms.

### Quicksort

```ruby
func quicksort(arr) {
    return arr if (arr.len <= 1)
    var pivot = arr[arr.len / 2]
    var left  = arr.grep { _ < pivot }
    var mid   = arr.grep { _ == pivot }
    var right = arr.grep { _ > pivot }
    [quicksort(left)..., mid..., quicksort(right)...]
}

say quicksort([3, 6, 8, 10, 1, 2, 1])    # [1, 1, 2, 3, 6, 8, 10]
```

### Merge Sort

```ruby
func merge(a, b) {
    var result = []
    while (a && b) {
        result << (a[0] <= b[0] ? a.shift : b.shift)
    }
    [result..., a..., b...]
}

func mergesort(arr) {
    return arr if (arr.len <= 1)
    var mid = arr.len / 2
    merge(mergesort(arr[0 .. mid-1]), mergesort(arr[mid .. arr.end]))
}

say mergesort([5, 2, 8, 1, 9, 3])    # [1, 2, 3, 5, 8, 9]
```

### Radix Sort

```ruby
func radix_sort(arr, base = 10) {
    return arr if (arr.len <= 1)
    var max_val = arr.max
    var exp = 1

    while (max_val / exp >= 1) {
        var buckets = base.of { [] }
        arr.each { |n|
            buckets[(n / exp) % base] << n
        }
        arr = buckets.flat
        exp *= base
    }
    arr
}

say radix_sort([170, 45, 75, 90, 802, 24, 2, 66])
# [2, 24, 45, 66, 75, 90, 170, 802]
```

### Sorting with Schwartzian Transform

```ruby
# Sort strings by their vowel count (efficient — compute key once)
var words = %w(programming sidef beautiful algorithm lazy quick)

var sorted = words
    .map { |w| [w, w.count("aeiou")] }
    .sort_by { _[1] }
    .map { _[0] }

say sorted    # sorted from fewest to most vowels
```

---

## 17. Dynamic Programming and Memoization

### Longest Common Subsequence

```ruby
func lcs(String a, String b) is cached {
    return ""  if (!a || !b)
    if (a[-1] == b[-1]) {
        lcs(a[0..-2], b[0..-2]) + a[-1]
    } else {
        var s1 = lcs(a[0..-2], b)
        var s2 = lcs(a, b[0..-2])
        s1.len >= s2.len ? s1 : s2
    }
}

say lcs("ABCBDAB", "BDCABA")    # BDAB (or BCAB, BCBA — one LCS)
```

### Edit Distance (Levenshtein)

```ruby
func edit_distance(String a, String b) is cached {
    return b.len if (!a)
    return a.len if (!b)

    if (a[0] == b[0]) {
        edit_distance(a[1..], b[1..])
    } else {
        1 + [
            edit_distance(a[1..], b),       # delete
            edit_distance(a, b[1..]),       # insert
            edit_distance(a[1..], b[1..]),  # replace
        ].min
    }
}

say edit_distance("kitten", "sitting")    # 3
say edit_distance("Sunday", "Saturday")  # 3
```

### 0/1 Knapsack Problem

```ruby
func knapsack(capacity, weights, values, n) is cached {
    return 0 if (n == 0 || capacity == 0)

    if (weights[n-1] > capacity) {
        knapsack(capacity, weights, values, n-1)
    } else {
        [
            values[n-1] + knapsack(capacity - weights[n-1], weights, values, n-1),
            knapsack(capacity, weights, values, n-1),
        ].max
    }
}

var weights  = [2, 3, 4, 5]
var values   = [3, 4, 5, 6]
var capacity = 8

say knapsack(capacity, weights, values, weights.len)    # 10
```

---

## 18. Matrix and Vector Arithmetic

### Matrix Basics

```ruby
var A = Matrix([[1,2],[3,4]])
var B = Matrix([[5,6],[7,8]])

say A + B     # [[6,8],[10,12]]
say A * B     # [[19,22],[43,50]]
say A.T       # transpose: [[1,3],[2,4]]
say A.det     # determinant: -2
say A.inv     # inverse
```

### Matrix Exponentiation (Fast Fibonacci)

Matrix exponentiation runs in O(log n) and can compute Fibonacci numbers efficiently:

```ruby
func matmul(A, B) {
    var n = A.len
    n.of { |i|
        n.of { |j|
            (0..n-1).map { |k| A[i][k] * B[k][j] }.sum
        }
    }
}

func matpow(M, n) {
    return M if (n == 1)
    var half = matpow(M, n >> 1)
    var sq   = matmul(half, half)
    n.is_odd ? matmul(sq, M) : sq
}

func fib_fast(n) {
    return n if (n <= 1)
    matpow([[1,1],[1,0]], n)[0][1]
}

say fib_fast(100)    # 354224848179261915075
say fib_fast(1000)   # (a very large number)
```

### Solving Linear Systems

```ruby
# Ax = b  →  x = A⁻¹ b
var A = Matrix([[2, 1], [5, 7]])
var b = Matrix([[11], [13]])

var x = A.inv * b
say x    # [[3], [-1]]  — solution: x₁=3, x₂=-1
```

---

## 19. Encoding, Compression, and Cryptography Patterns

### Run-Length Encoding

```ruby
func rle_encode(String s) {
    gather {
        var chars = s.chars
        var i = 0
        while (i < chars.len) {
            var c = chars[i]
            var count = 1
            while (i+count < chars.len && chars[i+count] == c) {
                ++count
            }
            take([c, count])
            i += count
        }
    }
}

func rle_decode(pairs) {
    pairs.map { |p| p[0] * p[1] }.join
}

var encoded = rle_encode("aaabbbccddddee")
say encoded    # [["a",3],["b",3],["c",2],["d",4],["e",2]]
say rle_decode(encoded)    # aaabbbccddddee
```

### Caesar Cipher

```ruby
func caesar_encrypt(String text, Number shift) {
    text.chars.map { |c|
        if (c =~ /[a-zA-Z]/) {
            var base = c =~ /[A-Z]/ ? 'A'.ord : 'a'.ord
            ((c.ord - base + shift) % 26 + base).chr
        } else {
            c
        }
    }.join
}

func caesar_decrypt(String text, Number shift) {
    caesar_encrypt(text, 26 - shift)
}

var msg = "Hello, World!"
var enc = caesar_encrypt(msg, 13)    # ROT13
say enc                              # Uryyb, Jbeyq!
say caesar_decrypt(enc, 13)          # Hello, World!
```

### XOR One-Time Pad (Demonstration)

```ruby
func xor_crypt(String text, String key) {
    var key_bytes  = key.bytes
    var text_bytes = text.bytes
    var klen       = key_bytes.len

    text_bytes.map_kv { |i, b|
        b ^ key_bytes[i % klen]
    }.map { .chr }.join
}

var plaintext  = "Attack at dawn"
var key        = "SECRET"
var ciphertext = xor_crypt(plaintext, key)
var recovered  = xor_crypt(ciphertext, key)

say recovered == plaintext    # true
```

### RSA Key Generation Sketch

```ruby
# Generate two random primes
var p = random_prime(10**50, 10**51)
var q = random_prime(10**50, 10**51)
var n = p * q
var phi = (p-1) * (q-1)

# Public exponent
var e = 65537
die "Bad e" if gcd(e, phi) != 1

# Private exponent
var d = invmod(e, phi)

# Encrypt and decrypt
var msg        = 42
var ciphertext = powmod(msg, e, n)
var decrypted  = powmod(ciphertext, d, n)

say decrypted == msg    # true
```

---

## 20. Putting It All Together: Larger Examples

### Prime Sieve with Segmented Output

This finds all twin prime pairs up to a given limit, neatly formatted:

```ruby
func twin_primes(limit) {
    gather {
        var prev = 2
        primes(3, limit).each { |p|
            take([prev, p]) if (p - prev == 2)
            prev = p
        }
    }
}

twin_primes(200).each_with_index { |pair, i|
    say "#{ '%3d' % (i+1) }. (#{pair[0]}, #{pair[1]})"
}
```

### Goldbach's Conjecture Verification

Every even integer greater than 2 is the sum of two primes:

```ruby
func goldbach(n) {
    return nil if (n <= 2 || n.is_odd)
    primes(2, n/2).first { |p| (n - p).is_prime }
        .then { |p| [p, n - p] }
}

for n in (4..50 `by` 2) {
    var (a, b) = goldbach(n)...
    say "#{n} = #{a} + #{b}"
}
```

### Conway's Game of Life

```ruby
func game_of_life(grid, generations) {
    var rows = grid.len
    var cols = grid[0].len

    func neighbors(r, c) {
        var count = 0
        for dr in (-1..1) {
            for dc in (-1..1) {
                next if (dr == 0 && dc == 0)
                var nr = r + dr
                var nc = c + dc
                if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
                    count += grid[nr][nc]
                }
            }
        }
        count
    }

    func step(g) {
        rows.of { |r|
            cols.of { |c|
                var n = neighbors(r, c)
                (g[r][c] == 1) ? (n ~~ [2,3] ? 1 : 0)
                               : (n == 3 ? 1 : 0)
            }
        }
    }

    generations.times { grid = step(grid) }
    grid
}

# Glider initial state
var glider = [
    [0,1,0,0,0],
    [0,0,1,0,0],
    [1,1,1,0,0],
    [0,0,0,0,0],
    [0,0,0,0,0],
]

func render(g) {
    g.each { |row| say row.map{ _ ? "█" : "·" }.join }
    say ""
}

render(glider)
var next_gen = game_of_life(glider, 1)
render(next_gen)
```

### Dijkstra's Shortest Path

```ruby
func dijkstra(graph, source) {
    var dist    = Hash()
    var visited = Set()

    graph.keys.each { |v| dist{v} = Inf }
    dist{source} = 0

    loop {
        # Pick unvisited vertex with smallest distance
        var u = graph.keys
            .grep { !visited.has(_) && dist{_} < Inf }
            .min_by { dist{_} }

        break if (u == nil)
        visited.add(u)

        graph{u}.each { |v, weight|
            var alt = dist{u} + weight
            dist{v} = alt if (alt < dist{v})
        }
    }
    dist
}

var graph = Hash(
    A => Hash(B => 4, C => 2),
    B => Hash(D => 3, C => 1),
    C => Hash(B => 1, D => 5),
    D => Hash(),
)

var distances = dijkstra(graph, :A)
distances.keys.sort.each { |v|
    say "A → #{v} : #{distances{v}}"
}
# A → A : 0
# A → B : 3  (A→C→B)
# A → C : 2
# A → D : 6  (A→C→B→D)
```

### Arithmetic Coder (Sketch)

A simplified arithmetic coder demonstrates how frequency models are used in compression:

```ruby
func build_model(String text) {
    var freq = Hash()
    text.chars.each { |c| freq{c} := 0; freq{c}++ }
    var total = text.len

    var model = Hash()
    var cumul = 0r
    freq.keys.sort.each { |c|
        var p = freq{c} / total
        model{c} = [cumul, cumul + p]
        cumul += p
    }
    model
}

var model = build_model("aabbbc")
model.keys.sort.each { |c|
    say "#{c}: [#{model{c}[0].as_float.round(4)}, #{model{c}[1].as_float.round(4)})"
}
```

---

## 21. Further Resources

### Official Documentation

- 📘 [Sidef GitBook](https://trizen.gitbook.io/sidef-lang/) — Complete language reference
- 📄 [PDF Book](https://github.com/trizen/sidef/releases/download/26.04/sidef-book.pdf) — Offline reading
- 🔢 [Number Theory Tutorial](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_TUTORIAL.md) — Deep dive into Sidef's mathematical functions

### Example Script Collections

- 📂 [sidef-scripts](https://github.com/trizen/sidef-scripts) — Hundreds of real Sidef programs organized by category:
  - `Math/` — Number theory, factorization algorithms, primality tests, special functions
  - `Encoding/` — Huffman, arithmetic coding, BWT, LZW, run-length encoding
  - `Encryption/` — RSA, one-time pad, XOR
  - `Compression/` — Gzip, bzip2, LZ77, LZW compressors
  - `Games/` — Conway's Game of Life, snake, Bulls and Cows
  - `Graph/` — Dijkstra, Kosaraju's SCC algorithm
  - `Genetic/` — Genetic algorithms
  - `Image/` — Fractal generation (Sierpinski, Koch, Mandelbrot, Barnsley fern)
  - `Sort/` — Classic sorting algorithms

### Community

- 💬 [GitHub Discussions](https://github.com/trizen/sidef/discussions)
- 🌹 [RosettaCode Examples](https://rosettacode.org/wiki/Sidef) — Side-by-side comparisons with other languages
- 🧪 [Try It Online](https://tio.run/#sidef) — Experiment without installing anything

---

<div align="center">

**Happy coding with Sidef! 🚀**

*Guide for intermediate and advanced users — assumes Sidef is already installed*

</div>
