# The Sidef Programming Language

<div align="center">

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

**A modern, high-level programming language for versatile general-purpose applications**

[Website](https://github.com/trizen/sidef) • [Tutorial](https://github.com/trizen/sidef/blob/master/SIDEF_BEGINNER_GUIDE.md) • [Documentation](https://trizen.gitbook.io/sidef-lang/) • [Try Online](https://tio.run/#sidef) • [Discussions](https://github.com/trizen/sidef/discussions)

[![CPAN](https://img.shields.io/badge/CPAN-Sidef-blue)](https://metacpan.org/release/Sidef)
[![Perl](https://img.shields.io/badge/Perl-5.18%2B-blue)](https://www.perl.org/)
[![License](https://img.shields.io/badge/License-Artistic%202.0-green.svg)](https://www.perlfoundation.org/artistic-license-20.html)

</div>

---

## 🌟 Why Sidef?

Sidef is a modern, expressive programming language that combines the elegance of Ruby, the versatility of Raku, and the mathematical power of a built-in computer algebra system. It features **exact rational arithmetic by default**, an extensive **number theory library** (1,000+ functions), and seamless **Perl module integration** — making it equally at home for scripting, mathematical research, and general-purpose programming.

```ruby
# Exact rational arithmetic — no floating-point surprises
say (1/3 + 1/6)         #=> 1/2

# Built-in number theory
say (2**127 - 1)        #=> 170141183460469231731687303715884105727 (Mersenne prime)
say factor(2**64 - 1)   #=> [3, 5, 17, 257, 641, 65537, 6700417]

# Expressive, concise syntax
say 71.primes           #=> [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71]
```

## ✨ Key Features

**Programming Paradigms**
- Object-oriented programming with multiple dispatch
- Functional programming and pattern matching
- Lexical scoping and closures
- Keyword arguments and optional lazy evaluation

**Numeric Computing**
- Exact rational numbers by default
- Arbitrary-precision integers, floats, and complex numbers
- 1,000+ built-in number theory functions (backed by GMP, MPFR, MPC)
- Gaussian integers, quaternions, matrices, polynomials

**Language & Integration**
- Regular expressions and string interpolation
- Optional dynamic type checking
- Seamless Perl module integration
- REPL with interactive help (`-H` flag)

## 🚀 Quick Start

### Prerequisites

Sidef requires **Perl 5.18+** and the following C libraries:

| Library | Purpose |
|---------|---------|
| [GMP](https://gmplib.org/) | Big integers and rationals |
| [MPFR](https://www.mpfr.org/) | Arbitrary-precision floats |
| [MPC](https://www.multiprecision.org/mpc/) | Arbitrary-precision complex numbers |

**Debian/Ubuntu:**
```bash
sudo apt-get install libgmp-dev libmpfr-dev libmpc-dev
```

**Arch Linux:**
```bash
sudo pacman -S gmp mpfr libmpc
```

**Termux:**
```bash
pkg install perl make clang libgmp libmpfr libmpc
```

### Installation

**Via CPAN:**
```bash
cpan Sidef
# or (skip tests for faster install):
cpan -T Sidef
# or with cpanminus:
cpanm Sidef
```

**Build from source:**
```bash
git clone https://github.com/trizen/sidef.git
cd sidef
perl Makefile.PL
make
make test
make install
```

**Via AUR:**
```bash
trizen -S sidef
```

**Platform packages:**
- **Arch Linux**: [AUR package](https://aur.archlinux.org/packages/sidef/)
- **Slackware**: [SlackBuilds](https://slackbuilds.org/repository/15.0/perl/perl-Sidef/)
- **Other systems**: See [pkgs.org](https://pkgs.org/download/perl-Sidef)

### Hello World

```ruby
say "Hello, World!"
```

```bash
sidef hello.sf
sidef -E 'say "Hello, World!"'
sidef -i            # start the REPL
```

### Try It Online

Experiment with Sidef instantly at **[Try It Online](https://tio.run/#sidef)** without any installation.

## 🔤 Language at a Glance

### Variables and Types

```ruby
var name   = "Sidef"               # String
var num    = 42                    # Number (exact integer)
var ratio  = 3/7                   # Rational (exact)
var arr    = [1, 2, 3]             # Array
var hash   = Hash(a => 1, b => 2)  # Hash
var block  = {|n| n.is_prime }     # Block
```

### Functions and Pattern Matching

```ruby
func greet(name) { "Hello, #{name}!" }
say greet("world")    #=> Hello, world!

# Multi-dispatch / pattern matching
func fib({|n| n == 0 }) { 0 }
func fib({|n| n == 1 }) { 1 }
func fib(n) { fib(n-1) + fib(n-2) }

say fib(10)    #=> 55
```

### Object-Oriented Programming

```ruby
class Animal(name, sound) {
    method speak { say "#{name} says #{sound}!" }
}

class Dog(name) < Animal(name, "woof") {
    method fetch { say "#{name} fetches the ball!" }
}

var d = Dog("Rex")
d.speak    #=> Rex says woof!
d.fetch    #=> Rex fetches the ball!
```

### Functional Programming

```ruby
var nums = 1..10   # Range object

# Map, filter, reduce
var evens   = nums.grep { .is_even }              #=> [2, 4, 6, 8, 10]
var squares = nums.map  { |n| n**2 }              #=> [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
var total   = nums.reduce { |a, b| a + b }        #=> 55

say evens
say squares
say total
```

### Number Theory

```ruby
say primes(50, 100)          # array of primes in range [50, 100]
say prrime_count(10**9)      # number of primes up to 10^9
say prime(100)               # 100th prime => 541
say 12.divisors              # [1, 2, 3, 4, 6, 12]
say euler_phi(100)           # Euler's totient => 40
say gcd(48, 18)              # => 6
say is_prime(2**521 - 1)     # Mersenne prime check => true
```

### Lazy Evaluation

```ruby
# Infinite lazy list of primes
var lazy_primes = (2..Inf -> lazy.grep { .is_prime })
say lazy_primes.first(10)    #=> [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
```

## ⌨️ Command-Line Reference

```
sidef [options] [script.sf] [script-arguments]
```

| Flag | Description |
|------|-------------|
| `-E 'code'` | Execute a one-line program |
| `-e 'code'` | Alias for `-E` |
| `-i [file]` | Start the interactive REPL (optionally loading a file) |
| `-c` | Compile script to a stand-alone Perl program |
| `-C` | Check syntax only (parse without execution) |
| `-r` | Deparse program back to Sidef code |
| `-R lang` | Deparse to another language (`perl`, `sidef`) |
| `-P int` | Set floating-point precision in bits (default: 192) |
| `-O level` | Optimization level: `0` (none), `1` (recommended), `2` (max) |
| `-s` | Enable precompilation (cache compiled code) |
| `-t` | Test mode: treat all arguments as script files |
| `-D` | Dump the Abstract Syntax Tree (AST) |
| `-H` | Interactive help mode for exploring documentation |

**Examples:**
```bash
sidef -E 'say 10.of { |i| i**2 }'            # one-liner
sidef -i                                     # start REPL
sidef -i script.sf                           # run script in REPL
sidef -C script.sf                           # syntax check
sidef -c -o output.pl script.sf              # compile to Perl
sidef -P 400 -E 'say sqrt(2)'                # 400-bit precision
sidef -O1 script.sf                          # with optimization
sidef -r script.sf                           # deparse to Sidef
sidef -t tests/*.sf                          # run test files
```

## 🖥️ Interactive Mode (REPL)

Start the REPL with `sidef -i`:

```
$ sidef -i
sidef> say "Hello!"
Hello!
sidef> x = 2**64
18446744073709551616
sidef> x.is_prime
false
sidef> is_prime(2**127 - 1)
true
sidef> 1..10 -> map { .square }.sum
385
sidef> quit
```

Use `-H` to open interactive documentation help:
```bash
sidef -H
```

## 🎯 Code Examples

### Classes and Inheritance

```ruby
class Shape {
    method area { die "Not implemented" }
    method describe { say "I am a #{self.class} with area #{self.area}" }
}

class Circle(r) < Shape {
    method area { Num.pi * r**2 }
}

class Rectangle(w, h) < Shape {
    method area { w * h }
}

Circle(5).describe        #=> I am a Circle with area 78.539...
Rectangle(4, 6).describe  #=> I am a Rectangle with area 24
```

### Functional Array Processing

```ruby
# FizzBuzz in one line
say (1..20 -> map { |n|
    n%%15 ? "FizzBuzz" : (n%%3 ? "Fizz" : (n%%5 ? "Buzz" : n))
})

# Pipeline style
(1..50).grep { .is_prime } \
       .map  { .square } \
       .first(5) \
       .say    #=> [4, 9, 25, 49, 121]
```

### Number Theory One-Liners

```ruby
say 100.by { .is_prime }              # first 100 primes
say sum(1..100)                       #=> 5050
say prod(1..10)                       #=> 3628800  (10!)
say { .euler_phi }.map(1..10)         #=> [1, 1, 2, 2, 4, 2, 6, 4, 6, 4]
```

### The Y Combinator

Demonstrating functional programming with the [Y combinator](https://en.wikipedia.org/wiki/Fixed-point_combinator#Fixed-point_combinators_in_lambda_calculus):

```ruby
var y = ->(f) {->(g) {g(g)}(->(g) { f(->(*args) {g(g)(args...)})})}

var fac = ->(f) { ->(n) { n < 2 ? 1 : (n * f(n-1)) } }
say 10.of { |i| y(fac)(i) }     #=> [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880]

var fib = ->(f) { ->(n) { n < 2 ? n : (f(n-2) + f(n-1)) } }
say 10.of { |i| y(fib)(i) }     #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

### Sierpinski Triangle

ASCII generation of the [Sierpinski triangle](https://en.wikipedia.org/wiki/Sierpinski_triangle):

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

<details>
<summary>Show Output</summary>

```text
               *
              * *
             *   *
            * * * *
           *       *
          * *     * *
         *   *   *   *
        * * * * * * * *
       *               *
      * *             * *
     *   *           *   *
    * * * *         * * * *
   *       *       *       *
  * *     * *     * *     * *
 *   *   *   *   *   *   *   *
* * * * * * * * * * * * * * * *
```
</details>

### Mandelbrot Set

ASCII visualization of the [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set):

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

<details>
<summary>Show Output</summary>

```text

                                                            #
                                                        #  ###  #
                                                        ########
                                                       #########
                                                         ######
                                             ##    ## ############  #
                                              ### ###################      #
                                              #############################
                                              ############################
                                          ################################
                                           ################################
                                         #################################### #
                          #     #        ###################################
                          ###########    ###################################
                           ###########   #####################################
                         ############## ####################################
                        ####################################################
                     ######################################################
#########################################################################
                     ######################################################
                        ####################################################
                         ############## ####################################
                           ###########   #####################################
                          ###########    ###################################
                          #     #        ###################################
                                         #################################### #
                                           ################################
                                          ################################
                                              ############################
                                              #############################
                                              ### ###################      #
                                             ##    ## ############  #
                                                         ######
                                                       #########
                                                        ########
                                                        #  ###  #
                                                            #

```
</details>

### More Examples

Explore an extensive collection of Sidef programs at **[github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)**

## 📚 Documentation & Learning Resources

| Resource | Description |
|----------|-------------|
| **[Beginner's Guide](https://github.com/trizen/sidef/blob/master/SIDEF_BEGINNER_GUIDE.md)** | Start here if you're new to Sidef |
| **[Advanced Tutorial](https://github.com/trizen/sidef/blob/master/SIDEF_ADVANCED_GUIDE.md)** | Comprehensive language tutorial |
| **[Number Theory Tutorial](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_TUTORIAL.md)** | Mathematical programming with Sidef |
| **[Number Theory Reference](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_REFERENCE.md)** | Complete function reference for number theory |
| **[Number Theory Guide](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_GUIDE.md)** | Complete guide for computational number theory |
| **[Computational Algebra Guide](https://github.com/trizen/sidef/blob/master/COMPUTATIONAL_ALGEBRA_GUIDE.md)** | Complete guide for computational algebra |
| **[Sidef GitBook](https://trizen.gitbook.io/sidef-lang/)** | Full language guide |
| **[RosettaCode Examples](https://rosettacode.org/wiki/Sidef)** | Practical code examples across many tasks |

## 💬 Community & Support

Have questions or need help? Join the conversation:

- **[Discussion Forum](https://github.com/trizen/sidef/discussions/categories/q-a)** - Q&A and community discussions
- **[GitHub Issues](https://github.com/trizen/sidef/issues)** - Bug reports and feature requests

## 📦 Distribution Availability

| Platform | Package | Link |
|----------|---------|------|
| **CPAN** | `Sidef` | [metacpan.org](https://metacpan.org/release/Sidef) |
| **Package Search** | Multiple distributions | [pkgs.org](https://pkgs.org/download/perl-Sidef) |
| **Arch Linux** | `sidef` (AUR) | [AUR Package](https://aur.archlinux.org/packages/sidef/) |
| **Slackware** | `perl-Sidef` | [SlackBuilds.org](https://slackbuilds.org/repository/15.0/perl/perl-Sidef/) |

## 🤝 Contributing

Contributions of all kinds are welcome — bug reports, feature suggestions, documentation improvements, and pull requests. Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** for guidelines on:

- Reporting bugs and suggesting features
- Setting up a development environment
- Code style and commit message conventions
- The pull request review process

## 📄 License and Copyright

**Copyright © 2013-2026 Daniel Șuteu, Ioana Fălcușan**

This program is free software; you can redistribute it and/or modify it under the terms of the **Artistic License (2.0)**.

**Full license**: [perlfoundation.org/artistic-license-20.html](https://www.perlfoundation.org/artistic-license-20.html)

---

<div align="center">

**Made with ❤️ by the Sidef community**

[⭐ Star us on GitHub](https://github.com/trizen/sidef) • [📖 Read the docs](https://trizen.gitbook.io/sidef-lang/) • [💬 Join discussions](https://github.com/trizen/sidef/discussions)

</div>
