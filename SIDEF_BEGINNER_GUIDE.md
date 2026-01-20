# Sidef Programming Language - Beginner's Guide

<div align="center">

**A modern, high-level programming language implemented in Perl**

[Try Online](https://tio.run/#sidef) • [Official Documentation](https://trizen.gitbook.io/sidef-lang/) • [GitHub Repository](https://github.com/trizen/sidef)

</div>

---

## 📖 Table of Contents

1. [What is Sidef?](#what-is-sidef)
2. [Installation](#installation)
3. [Your First Program](#your-first-program)
4. [Basic Syntax](#basic-syntax)
5. [Variables and Data Types](#variables-and-data-types)
6. [Operators](#operators)
7. [Control Flow](#control-flow)
8. [Functions](#functions)
9. [Arrays and Hashes](#arrays-and-hashes)
10. [Object-Oriented Programming](#object-oriented-programming)
11. [Common Examples](#common-examples)
12. [Resources](#resources)

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

### Quick Install (via CPAN)

```bash
cpan Sidef
```

### Platform-Specific

**Linux (Debian/Ubuntu):**
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

### Verify Installation

```bash
sidef --version
sidef --help
```

---

## Your First Program

Create a file called `hello.sf`:

```ruby
#!/usr/bin/sidef

say "Hello, World!"
```

Run it:
```bash
sidef hello.sf
```

> 💡 **Tip**:  Sidef files use the `.sf` extension by convention. 

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

### Important:  Whitespace and Precedence

Sidef handles operator precedence using whitespace: 

```ruby
var n = 1+2        # ✅ Correct:  n = 3
var n = (1 + 2)    # ✅ Better: explicit grouping
var n = 1 + 2      # ⚠️ Parsed differently! 
```

> 📝 **Best Practice**: Use parentheses for clarity or avoid spaces in simple expressions.

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

# Double quotes:  interpolation enabled
say "Hello, #{name}!"     #=> Hello, World!

# Single quotes:  literal string
say 'No interpolation:  #{name}'

# Common string methods
"hello". uc                #=> "HELLO"
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
fruits. push("date")
fruits.pop          # Remove last
fruits.shift        # Remove first

# Useful methods
[1, 2, 3]. length    #=> 3
[3, 1, 2].sort      #=> [1, 2, 3]
[1, 2, 3].reverse   #=> [3, 2, 1]
[1, 2, 3]. sum       #=> 6
```

### Functional Array Methods

```ruby
# Map: transform each element
[1, 2, 3]. map { _**2 }           #=> [1, 4, 9]

# Grep/Filter: select elements
[1, 2, 3, 4, 5].grep { _ > 2 }   #=> [3, 4, 5]

# Reduce: combine elements
[1, 2, 3, 4]. reduce { |a, b| a + b }    #=> 10

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
say person{: name}       #=> "Alice"
person{:city} = "NYC"   # Add new key

# Methods
person.keys             #=> ["name", "age", "city"]
person.values           #=> ["Alice", 30, "NYC"]
person.has(: name)       #=> true

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
        say "Happy birthday!  Now I'm #{age}."
    }
}

# Create an instance
var alice = Person(name: "Alice", age: 25)

# Call methods
alice. greet()
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
say rect. perimeter   #=> 16
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

---

## Common Examples

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

### HTTP Request (Using Perl Modules)

```ruby
var http = require('HTTP:: Tiny').new

var response = http.get('http://example.com')

if (response{: success}) {
    say response{:content}
}
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
say numbers. max                      #=> 90
say numbers.min                      #=> 11
```

---

## Resources

### Official Resources

- 📘 [Sidef GitBook](https://trizen.gitbook.io/sidef-lang/) - Comprehensive language guide
- 📝 [Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) - Step-by-step tutorial
- 🔢 [Number Theory Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/NUMBER_THEORY_TUTORIAL.md) - Mathematical programming

### Community

- 💬 [GitHub Discussions](https://github.com/trizen/sidef/discussions) - Q&A and community
- 🐛 [GitHub Issues](https://github.com/trizen/sidef/issues) - Bug reports and features
- 🌹 [RosettaCode Examples](https://rosettacode.org/wiki/Sidef) - Practical code examples

### Try It Online

Experiment with Sidef instantly: **[Try It Online](https://tio.run/#sidef)**

---

<div align="center">

**Happy coding with Sidef!  🚀**

*Created with ❤️ for beginners*

</div>