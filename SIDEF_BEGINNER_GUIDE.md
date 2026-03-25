# Sidef Programming Language — Beginner's Guide

<div align="center">

**A modern, high-level programming language with beautiful syntax and powerful math**

[Try Online (no install needed)](https://tio.run/#sidef) • [Official Documentation](https://trizen.gitbook.io/sidef-lang/) • [GitHub](https://github.com/trizen/sidef)

</div>

---

## Table of Contents

1. [What is Sidef?](#1-what-is-sidef)
2. [Installation](#2-installation)
3. [Your First Program](#3-your-first-program)
4. [How to Run Sidef Code](#4-how-to-run-sidef-code)
5. [Comments](#5-comments)
6. [Variables](#6-variables)
7. [Numbers](#7-numbers)
8. [Strings](#8-strings)
9. [Booleans](#9-booleans)
10. [Operators and Expressions](#10-operators-and-expressions)
11. [Operator Precedence — The Most Important Rule](#11-operator-precedence-the-most-important-rule)
12. [Printing Output](#12-printing-output)
13. [Getting Input](#13-getting-input)
14. [Control Flow — Making Decisions](#14-control-flow-making-decisions)
15. [Loops](#15-loops)
16. [Functions](#16-functions)
17. [Arrays](#17-arrays)
18. [Hashes (Dictionaries)](#18-hashes-dictionaries)
19. [String Operations](#19-string-operations)
20. [Working with Files](#20-working-with-files)
21. [Error Handling](#21-error-handling)
22. [A Taste of Sidef's Math Powers](#22-a-taste-of-sidefs-math-powers)
23. [Beginner Projects to Try](#23-beginner-projects-to-try)
24. [Where to Learn More](#24-where-to-learn-more)

---

## 1. What is Sidef?

Sidef is a **modern, high-level programming language** that runs on top of Perl. It takes inspiration from several languages:

- **Ruby** — clean, readable syntax
- **Raku** — expressive features and metaoperators
- **Julia** — powerful mathematical capabilities

### Why learn Sidef?

- **Exact numbers by default.** Sidef stores decimals as exact fractions, so `0.1 + 0.2 == 0.3` is actually `true` — unlike most other languages.
- **Giant numbers, no effort.** It handles arbitrarily large integers and floats without any special libraries.
- **Rich built-in math.** Prime numbers, factorization, number theory — all built in.
- **Clean, readable syntax.** Code reads almost like plain English.
- **Functional and object-oriented.** You can mix styles naturally.

### A quick taste

```ruby
# Print the first 10 prime numbers
say 10.primes

# Exact decimal math (no floating-point surprises!)
say (0.1 + 0.2 == 0.3)    # true

# Factorial of 100 — a 158-digit number!
say 100!

# Sum all numbers from 1 to 100
say (1..100).sum
```

---

## 2. Installation

> 💡 **Want to try Sidef without installing anything?** Head to **[https://tio.run/#sidef](https://tio.run/#sidef)** and run code right in your browser.

Sidef requires three C math libraries: **GMP**, **MPFR**, and **MPC**. These provide big-number support. Your package manager handles them automatically with the commands below.

---

### Linux (Debian, Ubuntu, Linux Mint, and derivatives)

```bash
sudo apt install libgmp-dev libmpfr-dev libmpc-dev libc-dev cpanminus
cpanm --sudo -n Sidef
```

Then verify:
```bash
sidef -v
```

---

### Linux (Arch Linux / Manjaro)

```bash
trizen -S sidef
```

---

### macOS (with Homebrew)

```bash
brew install gmp mpfr libmpc
cpan Sidef
```

---

### Android (Termux)

```bash
pkg install perl make clang libgmp libmpfr libmpc
cpan -T Sidef
```

---

### Windows

Download the ready-to-run executable from the [GitHub Releases page](https://github.com/trizen/sidef/releases). Unzip and run `sidef.exe` from the command prompt.

---

### Installing via CPAN (any platform)

If you have Perl installed, you can always install via CPAN:

```bash
cpan Sidef
# Or skip the test suite for a faster install:
cpan -T Sidef
```

---

### Building from source

```bash
wget 'https://github.com/trizen/sidef/archive/master.zip' -O master.zip
unzip master.zip
cd sidef-master
perl Build.PL
sudo ./Build installdeps
sudo ./Build install
```

---

### Verify your installation

```bash
sidef -v    # Print version
sidef -h    # Print help
```

You should see something like:
```
Sidef 26.01, running on Linux, using Perl v5.38.2
```

---

## 3. Your First Program

Create a file called `hello.sf` (Sidef files use the `.sf` extension):

```ruby
#!/usr/bin/sidef

say "Hello, World!"
```

The first line (`#!/usr/bin/sidef`) is called a **shebang** — it's optional, but it tells the operating system which program to use to run this file. You can leave it out if you want.

Save the file and run it (see the next section for how to do that). You should see:

```
Hello, World!
```

Congratulations — you just ran your first Sidef program! 🎉

---

## 4. How to Run Sidef Code

### Run a script file

```bash
sidef hello.sf
```

### Run code directly from the command line (one-liners)

Use the `-e` flag for quick experiments:

```bash
sidef -e 'say "Hello!"'
sidef -e 'say (2 ** 10)'
sidef -e 'say 5.primes'
```

### The interactive REPL

Run `sidef` with no arguments to enter the interactive prompt, where you type expressions and see results immediately:

```
$ sidef
Sidef 26.01, running on Linux, using Perl v5.38.2
Type "help", "copyright" or "license" for more information.
> say "Hello!"
Hello!
> (2 + 3)
5
> 10.primes
[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
> 100!
93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000
```

The REPL is great for exploring the language and testing ideas. Press `Ctrl+D` or type `exit` to quit.

### Try it online

If you don't want to install anything, use the online playground: **[https://tio.run/#sidef](https://tio.run/#sidef)**

---

## 5. Comments

Comments are notes in your code that Sidef ignores when running. They're for humans, not computers.

```ruby
# This is a single-line comment.
say "Hello!"    # Comments can go at the end of a line too.

/*
   This is a multi-line comment.
   It can span as many lines as you need.
   Useful for longer explanations.
*/
say "After the comment block."
```

> 💡 **Good habit:** Write comments to explain *why* your code does something, not just *what* it does. Your future self will thank you.

---

## 6. Variables

A **variable** is a named container that holds a value. In Sidef, you declare variables with the `var` keyword.

```ruby
var name = "Alice"
var age  = 25
var pi   = 3.14159
```

Variable names can contain letters, numbers, and underscores, but must start with a letter or underscore. By convention, use lowercase with underscores for multiple words:

```ruby
var first_name = "Bob"
var item_count = 42
```

### Reassigning variables

You can change a variable's value at any time:

```ruby
var score = 0
say score    # 0

score = 10
say score    # 10

score = (score + 5)
say score    # 15
```

### Constants

Use `const` for values that should never change after being set:

```ruby
const MAX_SIZE  = 100
const SITE_NAME = "My Website"
```

Use `define` for values that are known at the time the code is parsed (compile-time):

```ruby
define PI     = 3.14159265358979
define GOLDEN = 1.61803398874989
```

### `static` — persistent across function calls

```ruby
func count_calls {
    static n = 0    # initialized once, persists between calls
    ++n
    say "Called #{n} times"
}

count_calls()    # Called 1 times
count_calls()    # Called 2 times
count_calls()    # Called 3 times
```

---

## 7. Numbers

Sidef has excellent number support. You don't need to worry about separate types for most uses — it handles integers, decimals, and large numbers automatically.

### Integer literals

```ruby
var a = 255          # decimal
var b = 0xff         # hexadecimal (same value: 255)
var c = 0b11111111   # binary      (same value: 255)
var d = 0377         # octal       (same value: 255)

# Underscores make large numbers readable
var million = 1_000_000
var big     = 1_234_567_890
```

### Decimal numbers (exact rational arithmetic)

This is one of Sidef's best features. Decimals are stored as exact fractions internally, so there are no floating-point surprises:

```ruby
say (0.1 + 0.2)           # 0.3  (exact!)
say (0.1 + 0.2 == 0.3)    # true (unlike most languages)
say (1/3 + 1/3 + 1/3)     # 1    (exact fraction arithmetic)
```

### Big integers

Sidef handles arbitrarily large numbers without any special setup:

```ruby
say (2 ** 100)        # 1267650600228229401496703205376
say 50.factorial      # a 65-digit number
say 100!              # a 158-digit number (! is factorial postfix)
```

### Useful number methods

```ruby
say 42.is_even        # true
say 43.is_odd         # true
say (-5).abs          # 5
say 3.14.floor        # 3
say 3.14.ceil         # 4
say 3.75.round        # 4
say 16.sqrt           # 4
say 2.log             # natural logarithm of 2
say 100.log10         # 2  (log base 10)

say 7.is_prime        # true
say 12.is_prime       # false
```

### Special values

```ruby
say Inf     # infinity
say -Inf    # negative infinity
say NaN     # not a number (result of invalid operations)
```

---

## 8. Strings

A string is a piece of text. Sidef has two kinds of string literals.

### Double-quoted strings (support interpolation)

```ruby
var name = "Alice"
say "Hello, #{name}!"           # Hello, Alice!
say "Two plus two is #{(2+2)}"  # Two plus two is 4
say "Tab:\there"                # Tab:    here
say "Newline:\nSecond line"     # prints on two lines
```

Inside `#{}` you can put any Sidef expression:

```ruby
var items = 5
say "You have #{items} item#{(items == 1 ? '' : 's')}."
# You have 5 items.
```

### Single-quoted strings (no interpolation)

```ruby
say 'Hello, #{name}!'    # Hello, #{name}!  (printed literally)
say 'No \n escape here'  # No \n escape here
```

### Concatenation

```ruby
var first = "Hello"
var second = "World"
say (first + ", " + second + "!")    # Hello, World!
```

### String repetition

```ruby
say ("ha" * 3)       # hahaha
say ("-" * 20)       # --------------------
```

### Multi-line strings (heredocs)

```ruby
var message = <<'END'
This is a
multi-line string.
No interpolation here.
END

var greeting = <<-"END"
    Hello, #{name}!
    Welcome to Sidef.
    END
```

---

## 9. Booleans

Boolean values are simply `true` and `false`.

```ruby
var is_raining = true
var is_sunny   = false

say is_raining    # true
say is_sunny      # false
```

### Falsy values

In Sidef, the following values are **falsy** (treated as false in conditions):
- `false`
- `nil` (the absence of a value)
- `0`
- `""` (empty string)

Everything else is **truthy**.

```ruby
if (0) {
    say "This won't print."
}

if ("hello") {
    say "This will print!"    # prints
}
```

### `nil` — the absence of a value

```ruby
var x = nil
say x.is_nil    # true

# Conditional assignment: only assign if currently nil
var result = nil
result := compute_value()    # only called if result is nil
```

---

## 10. Operators and Expressions

### Arithmetic operators

```ruby
say (10 + 3)    # 13  addition
say (10 - 3)    # 7   subtraction
say (10 * 3)    # 30  multiplication
say (10 / 3)    # 10/3 (exact fraction)
say (10 % 3)    # 1   modulo (remainder)
say (10 ** 3)   # 1000 exponentiation (power)
```

### Comparison operators

These return `true` or `false`:

```ruby
say (5 == 5)    # true  (equal)
say (5 != 3)    # true  (not equal)
say (5 >  3)    # true  (greater than)
say (5 <  10)   # true  (less than)
say (5 >= 5)    # true  (greater than or equal)
say (5 <= 10)   # true  (less than or equal)
```

### Logical operators

```ruby
say (true && false)    # false  (and — both must be true)
say (true || false)    # true   (or — at least one must be true)
say (!true)            # false  (not — flips true/false)
```

### Increment and decrement

```ruby
var n = 5
n++     # n is now 6
n--     # n is now 5
++n     # n is now 6 (prefix: increments before returning value)
```

### String comparison

```ruby
say ("apple" == "apple")    # true
say ("apple" != "banana")   # true
say ("apple" lt "banana")   # true  (alphabetically less than)
say ("banana" gt "apple")   # true  (alphabetically greater than)
```

---

## 11. Operator Precedence - The Most Important Rule

> ⚠️ **This is the single most important rule to understand in Sidef.** Get this wrong and your programs will produce surprising results.

Most languages have complex precedence rules (multiply before add, etc.). Sidef is different: **it uses whitespace to determine how operators group**.

### The rule: no spaces bind tighter than spaces

When operators are written **without spaces around them**, they are grouped into a single unit first. When operators are written **with spaces around them**, they are evaluated left to right.

```ruby
#
# Example 1: spaces between ALL operators → left to right
#
say (1 + 2 * 3 + 4)    # means: ((1+2) * 3) + 4 = 13
#          ↑
#     evaluated as: ((1 + 2) * 3) + 4

#
# Example 2: no spaces → binds tightly
#
say (1 + 2*3 + 4)      # means: 1 + (2*3) + 4 = 11
#         ↑
#     2*3 is one tight unit

#
# Example 3: mixing both
#
say (1+2 * 3+4)        # means: (1+2) * (3+4) = 21
#    ↑↑↑   ↑↑↑
#   tight  tight → each becomes a unit, then * is evaluated
```

### The safest approach: always use parentheses

When in doubt, use explicit parentheses. This always works correctly and makes your intention clear to anyone reading the code:

```ruby
# These are all clear and unambiguous:
var area    = (length * width)
var average = ((a + b + c) / 3)
var hyp     = ((a**2 + b**2).sqrt)
var tax     = (price * (1 + tax_rate))
```

### Using backslash or dot to override grouping

You can use `\` or a leading `.` to force a different grouping:

```ruby
say (1 + 2 \* 3)     # means 1 + (2 * 3) = 7
say (1 + 2 .* 3)     # same thing
```

### Summary table

| Expression    | Meaning            | Result |
|---------------|--------------------|--------|
| `1 + 2 * 3`   | `(1 + 2) * 3`      | 9      |
| `1 + 2*3`     | `1 + (2*3)`        | 7      |
| `1+2 * 3+4`   | `(1+2) * (3+4)`    | 21     |
| `(1 + 2) * 3` | `(1 + 2) * 3`      | 9      |

> 💡 **Best practice:** Until you are very comfortable with this rule, wrap every binary operation in its own parentheses. It costs nothing and prevents bugs.

---

## 12. Printing Output

```ruby
say "Hello, World!"       # prints with a newline at the end
print "No newline here"   # prints without a newline
say ""                    # prints a blank line
```

### Printing multiple values

```ruby
say "Name: ", "Alice"        # Name: Alice
say 1, 2, 3                  # 123
say [1, 2, 3]                # [1, 2, 3]
```

### The `>` shorthand

`>` is a shorthand alias for `say`:

```ruby
> "Hello!"    # same as: say "Hello!"
```

### Formatted output

```ruby
var name  = "Alice"
var score = 98.5

say "Player: #{name}, Score: #{score}"
# Player: Alice, Score: 98.5

# Formatting numbers
say "Pi ≈ #{Num.pi.round(4)}"    # Pi ≈ 3.1416
say "Big: #{(10**20).commify}"   # Big: 100,000,000,000,000,000,000
```

---

## 13. Getting Input

Read a line of input from the user with `read`:

```ruby
print "What is your name? "
var name = read(String)

say "Hello, #{name}!"
```

Read a number:

```ruby
print "Enter a number: "
var n = read(Number)

say "You entered: #{n}"
say "Its square is: #{(n ** 2)}"
```

### A simple interactive example

```ruby
print "Enter your age: "
var age = read(Number)

if (age >= 18) {
    say "You are an adult."
} else {
    say "You are a minor."
}
```

---

## 14. Control Flow - Making Decisions

### if / elsif / else

```ruby
var temperature = 22

if (temperature > 30) {
    say "It's hot outside!"
} elsif (temperature > 20) {
    say "It's a nice day."
} elsif (temperature > 10) {
    say "It's a bit chilly."
} else {
    say "It's cold — grab a coat!"
}
```

### Postfix if (inline conditions)

For simple one-line conditions, you can put `if` after the statement:

```ruby
say "You win!" if (score > 100)
say "Game over." if (lives == 0)
var n = read(Number)
die "Must be positive!" if (n < 0)
```

### Ternary operator

A compact way to pick one of two values:

```ruby
var age    = 20
var status = (age >= 18 ? "adult" : "minor")
say status    # adult
```

### unless (opposite of if)

```ruby
var logged_in = false
say "Please log in." unless logged_in
```

### given / when (pattern matching)

`given`/`when` is Sidef's switch-like construct. It uses "smart matching" to check each `when` clause:

```ruby
var day = "Monday"

given (day) {
    when ("Saturday") { say "Weekend!" }
    when ("Sunday")   { say "Weekend!" }
    when (/^Mon/)     { say "Start of the work week." }
    else              { say "A regular weekday." }
}
```

You can match against numbers, strings, regex patterns, and more.

### with / orwith (checking for defined values)

`with` runs its block only when the value is defined (not `nil`):

```ruby
var result = some_function()

with (result) { |val|
    say "Got a result: #{val}"
}
orwith (fallback_function()) { |val|
    say "Got fallback: #{val}"
}
else {
    say "Nothing was returned."
}
```

---

## 15. Loops

### while loop

Keeps running as long as the condition is true:

```ruby
var count = 1
while (count <= 5) {
    say "Count: #{count}"
    count++
}
```

Output:
```
Count: 1
Count: 2
Count: 3
Count: 4
Count: 5
```

### do-while loop

Runs the body at least once before checking the condition:

```ruby
var n = 0
do {
    n++
    say n
} while (n < 3)
# prints: 1, 2, 3
```

### for loop — iterating a range

```ruby
for i in (1..5) {
    say "Step #{i}"
}
```

### for loop — iterating an array

```ruby
var fruits = ["apple", "banana", "cherry"]
for fruit in fruits {
    say "I like #{fruit}"
}
```

### .times — repeat N times

```ruby
3.times {
    say "Hello!"
}
# prints Hello! three times

5.times { |i|
    say "Iteration #{i}"    # i goes from 0 to 4
}
```

### .each — iterate with a block

```ruby
[10, 20, 30].each { |n|
    say "Value: #{n}"
}
```

### loop — infinite loop with break

```ruby
var n = 1
loop {
    say n
    n++
    break if (n > 5)
}
```

### Loop control: next and break

```ruby
# next: skip to the next iteration
for i in (1..10) {
    next if (i % 2 == 0)    # skip even numbers
    say i
}
# prints: 1, 3, 5, 7, 9

# break: exit the loop early
for i in (1..100) {
    break if (i > 5)
    say i
}
# prints: 1, 2, 3, 4, 5
```

### Ranges with custom steps

```ruby
for i in ((0..20).by(5)) {
    say i    # 0, 5, 10, 15, 20
}

for i in ((10^..1).by(-1)) {
    say i    # 10, 9, 8, ..., 1
}
```

### Counting upward: .upto / downward: .downto

```ruby
1.upto(5) { |i| say i }     # 1 2 3 4 5
5.downto(1) { |i| say i }   # 5 4 3 2 1
```

---

## 16. Functions

Functions let you name and reuse pieces of code.

### Basic function

```ruby
func greet(name) {
    say "Hello, #{name}!"
}

greet("Alice")    # Hello, Alice!
greet("Bob")      # Hello, Bob!
```

### Return values

The last expression in a function is returned automatically. You can also use `return` explicitly:

```ruby
func add(a, b) {
    (a + b)    # returned automatically
}

func multiply(a, b) {
    return (a * b)    # explicit return
}

var sum     = add(3, 4)         # 7
var product = multiply(3, 4)    # 12
say sum      # 7
say product  # 12
```

### Default parameters

```ruby
func greet(name = "World", greeting = "Hello") {
    say "#{greeting}, #{name}!"
}

greet()                        # Hello, World!
greet("Alice")                 # Hello, Alice!
greet("Bob", "Good morning")   # Good morning, Bob!
```

### Named parameters

You can pass arguments by name, in any order:

```ruby
func make_box(width, height, depth) {
    say "Box: #{width} × #{height} × #{depth}"
}

make_box(width: 10, depth: 5, height: 3)
# Box: 10 × 3 × 5
```

### Variadic functions (any number of arguments)

```ruby
func sum(*numbers) {
    numbers.reduce(0, { |acc, n| (acc + n) })
}

say sum(1, 2, 3)          # 6
say sum(10, 20, 30, 40)   # 100
```

### Type constraints

You can require arguments to be a specific type:

```ruby
func square(Number n) {
    (n ** 2)
}

func shout(String s) {
    s.uc + "!!!"
}

say square(5)       # 25
say shout("hello")  # HELLO!!!
```

If you pass the wrong type, Sidef will raise an error.

### Recursion

A function can call itself — this is called **recursion**:

```ruby
func factorial(n) {
    return 1 if (n <= 1)
    (n * factorial((n - 1)))
}

say factorial(5)    # 120
say factorial(10)   # 3628800
```

### Memoization with `is cached`

`is cached` makes Sidef automatically remember results so the same calculation is never repeated:

```ruby
func fib(n) is cached {
    return n if (n <= 1)
    (fib((n - 1)) + fib((n - 2)))
}

say fib(10)     # 55
say fib(50)     # 12586269025  (fast, thanks to caching)
say fib(100)    # 354224848179261915075
```

Without `is cached`, `fib(50)` would take an impossibly long time.

### Anonymous functions (lambdas)

Functions can be stored in variables:

```ruby
var double = { |n| (n * 2) }
var square = { |n| (n ** 2) }
var add    = { |a, b| (a + b) }

say double(5)      # 10
say square(4)      # 16
say add(3, 7)      # 10
```

### Closures

A closure is a function that "remembers" the variables from where it was created:

```ruby
func make_counter(start = 0) {
    var count = start
    func {
        count++
        say "Count: #{count}"
    }
}

var counter_a = make_counter()
var counter_b = make_counter(10)

counter_a()    # Count: 1
counter_a()    # Count: 2
counter_b()    # Count: 11
counter_a()    # Count: 3  (independent from counter_b)
```

---

## 17. Arrays

An array is an ordered list of values. Arrays can hold any mix of types.

### Creating arrays

```ruby
var fruits   = ["apple", "banana", "cherry"]
var numbers  = [1, 2, 3, 4, 5]
var mixed    = [1, "hello", true, 3.14]
var empty    = []
```

### Accessing elements

Arrays are **zero-indexed** — the first element is at index 0:

```ruby
var fruits = ["apple", "banana", "cherry", "date"]

say fruits[0]     # apple   (first)
say fruits[1]     # banana  (second)
say fruits[-1]    # date    (last)
say fruits[-2]    # cherry  (second to last)
```

### Modifying arrays

```ruby
var arr = [1, 2, 3]

arr.push(4)        # add to end   → [1, 2, 3, 4]
arr.pop            # remove last  → [1, 2, 3]
arr.unshift(0)     # add to start → [0, 1, 2, 3]
arr.shift          # remove first → [1, 2, 3]

arr[1] = 99        # replace by index → [1, 99, 3]
```

### Useful array methods

```ruby
var nums = [3, 1, 4, 1, 5, 9, 2, 6]

say nums.length           # 8
say nums.sort             # [1, 1, 2, 3, 4, 5, 6, 9]
say nums.reverse          # [6, 2, 9, 5, 1, 4, 1, 3]
say nums.sum              # 31
say nums.min              # 1
say nums.max              # 9
say nums.uniq             # [3, 1, 4, 5, 9, 2, 6]  (remove duplicates)
say nums.first            # 3
say nums.last             # 6
say nums.first(3)         # [3, 1, 4]
```

### Functional array methods

These are the methods you'll use most often with arrays:

**`map`** — transform every element:

```ruby
var numbers = [1, 2, 3, 4, 5]
var squared = numbers.map { |n| (n ** 2) }
say squared    # [1, 4, 9, 16, 25]

var names   = ["alice", "bob", "carol"]
var uppered = names.map { .uc }
say uppered    # ["ALICE", "BOB", "CAROL"]
```

**`grep`** — keep only elements that match a condition:

```ruby
var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

var evens  = numbers.grep { .is_even }
var odds   = numbers.grep { .is_odd }
var big    = numbers.grep { |n| (n > 5) }

say evens    # [2, 4, 6, 8, 10]
say odds     # [1, 3, 5, 7, 9]
say big      # [6, 7, 8, 9, 10]
```

**`reduce`** — combine all elements into one value:

```ruby
var numbers = [1, 2, 3, 4, 5]

var sum     = numbers.reduce(0, { |acc, n| (acc + n) })
var product = numbers.reduce(1, { |acc, n| (acc * n) })

say sum       # 15
say product   # 120
```

**`each`** — loop over every element:

```ruby
["red", "green", "blue"].each { |color|
    say "Color: #{color}"
}
```

**`each_with_index`** — loop with both index and value:

```ruby
["a", "b", "c"].each_with_index { |val, i|
    say "#{i}: #{val}"
}
# 0: a
# 1: b
# 2: c
```

### Joining and splitting

```ruby
var words = ["Hello", "World", "from", "Sidef"]
say words.join(" ")     # Hello World from Sidef
say words.join(", ")    # Hello, World, from, Sidef
say words.join          # HelloWorldfromSidef

# word arrays with %w notation (shorthand for array of strings)
var fruits = %w(apple banana cherry)
# same as: ["apple", "banana", "cherry"]
```

### Slices

```ruby
var arr = [10, 20, 30, 40, 50]

say arr[1..3]      # [20, 30, 40]  (indices 1 to 3)
say arr[0..^3]     # [10, 20, 30]  (indices 0 to 2, exclusive end)
say arr[2..]       # [30, 40, 50]  (from index 2 to the end)
```

### Checking membership

```ruby
var fruits = ["apple", "banana", "cherry"]

say fruits.contains("banana")    # true
say fruits.contains("grape")     # false
say fruits.index("cherry")       # 2  (position of element)
```

### Ranges as arrays

```ruby
say (1..5).to_a           # [1, 2, 3, 4, 5]
say (1..10).grep { .is_prime }.to_a    # [2, 3, 5, 7]
```

---

## 18. Hashes (Dictionaries)

A hash stores key-value pairs. Keys are usually strings (or symbols), and values can be anything.

### Creating a hash

```ruby
var person = Hash(
    name => "Alice",
    age  => 30,
    city => "London",
)
```

### Accessing values

```ruby
say person{:name}    # Alice
say person{:age}     # 30
say person{:city}    # London
```

### Adding and changing values

```ruby
person{:email} = "alice@example.com"    # add new key
person{:age}   = 31                     # update existing key
```

### Checking if a key exists

```ruby
say person.has(:name)       # true
say person.has(:phone)      # false
```

### Removing a key

```ruby
person.delete(:city)
```

### Listing keys and values

```ruby
say person.keys      # ["name", "age", "email"]  (order may vary)
say person.values    # ["Alice", 31, "alice@example.com"]
say person.len       # 3
```

### Iterating a hash

```ruby
person.each { |key, value|
    say "#{key}: #{value}"
}
```

### Practical hash example

```ruby
# Count word frequencies
var text  = "the cat sat on the mat the cat"
var words = text.split(" ")
var freq  = Hash()

words.each { |word|
    freq{word} := 0    # set to 0 if not yet defined
    freq{word}++
}

freq.keys.sort.each { |word|
    say "#{word}: #{freq{word}}"
}
# cat: 2
# mat: 1
# on:  1
# sat: 1
# the: 3
```

---

## 19. String Operations

### Common string methods

```ruby
var s = "Hello, World!"

say s.uc            # HELLO, WORLD!  (uppercase)
say s.lc            # hello, world!  (lowercase)
say s.length        # 13
say s.reverse       # !dlroW ,olleH
say s.trim          # removes leading/trailing whitespace

say s.contains("World")      # true
say s.begins_with("Hello")   # true
say s.ends_with("!")         # true
say s.index("World")         # 7  (position where it starts)
```

### Searching and replacing

```ruby
var text = "I like cats and cats like me."

say text.sub("cats", "dogs")          # I like dogs and cats like me.  (first only)
say text.gsub("cats", "dogs")         # I like dogs and dogs like me.  (all)
say text.gsub(/cats?/, "animals")     # with regex pattern
```

### Splitting and joining

```ruby
var csv = "Alice,30,London"
var parts = csv.split(",")
say parts[0]    # Alice
say parts[1]    # 30
say parts[2]    # London

say parts.join(" | ")    # Alice | 30 | London
```

### Extracting substrings

```ruby
var s = "Hello, World!"

say s[0..4]       # Hello
say s[7..11]      # World
say s[0, 5]       # Hello  (start, length)
```

### Regular expressions (pattern matching)

Regular expressions let you match complex text patterns:

```ruby
var email = "user@example.com"

if (email =~ /\w+@\w+\.\w+/) {
    say "Valid email format."
}

# Capture parts of a match
var date  = "2024-03-15"
var match = date.match(/(\d{4})-(\d{2})-(\d{2})/)
say "Year:  #{match[0]}"    # 2024
say "Month: #{match[1]}"    # 03
say "Day:   #{match[2]}"    # 15
```

### Useful string conversions

```ruby
say "42".to_i       # converts string to integer: 42
say "3.14".to_r     # converts string to number:  3.14
say 42.to_s         # converts number to string: "42"
say 255.to_s(16)    # convert to hex string: "ff"
say 255.to_s(2)     # convert to binary string: "11111111"
```

---

## 20. Working with Files

### Reading a file

```ruby
# Read the entire file as a string
var content = File("myfile.txt").read
say content

# Read line by line (memory efficient for large files)
File("myfile.txt").each_line { |line|
    say line.trim
}

# Read all lines into an array
var lines = File("myfile.txt").lines
say "File has #{lines.len} lines."
```

### Writing a file

```ruby
# Write (overwrites any existing content)
File("output.txt").write("Hello, File!\n")

# Append (adds to the end without erasing)
File("output.txt").append("Second line.\n")
```

### Checking if a file exists

```ruby
var f = File("data.txt")

if (f.exists) {
    say "File found! Size: #{f.size} bytes."
    var content = f.read
} else {
    say "File not found."
}
```

### Practical file example

```ruby
# Save a shopping list to a file and read it back
var list = ["apples", "bread", "milk", "eggs"]
File("shopping.txt").write(list.join("\n") + "\n")

say "Saved shopping list. Reading it back:"
File("shopping.txt").each_line { |line|
    say "- #{line.trim}"
}
```

---

## 21. Error Handling

Use `try` and `catch` to handle errors gracefully:

```ruby
try {
    var result = (10 / 0)
    say result
}
catch { |error|
    say "An error occurred: #{error}"
}
```

### Raising errors yourself

```ruby
func divide(a, b) {
    die "Cannot divide by zero!" if (b == 0)
    (a / b)
}

try {
    say divide(10, 2)    # 5
    say divide(10, 0)    # raises error
}
catch { |msg|
    say "Error: #{msg}"
}
```

### Assertions (for debugging)

```ruby
var x = 5
assert(x > 0, "x must be positive")
assert_eq(x, 5, "x must be 5")
assert_ne(x, 0, "x must not be zero")
```

If an assertion fails, the program stops with a clear message.

---

## 22. A Taste of Sidef's Math Powers

One of Sidef's greatest strengths is its built-in mathematical capabilities. Here's a brief preview — these work out of the box, no libraries needed.

### Primes

```ruby
say 17.is_prime           # true
say 10.primes             # [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
say primes(100, 150)      # all primes between 100 and 150
say 1000.prime            # 7919  (the 1000th prime)
say prime_count(10**6)    # 78498 (number of primes up to a million)
```

### Factorization

```ruby
say factor(360)            # [2, 2, 2, 3, 3, 5]
say factor_exp(360)        # [[2,3],[3,2],[5,1]]  (prime, exponent pairs)
say divisors(36)           # [1, 2, 3, 4, 6, 9, 12, 18, 36]
say euler_phi(36)          # 12  (Euler's totient)
```

### GCD, LCM

```ruby
say gcd(48, 18)    # 6
say lcm(4,  6)     # 12
```

### Big numbers

```ruby
say (2 ** 1000)           # a 302-digit number
say 100.factorial         # a 158-digit number
say (10 ** 100)           # a googol
```

### Mathematical constants and functions

```ruby
say Num.pi              # π ≈ 3.14159265358979...
say Num.e               # e ≈ 2.71828182845904...
say sqrt(2)             # √2 ≈ 1.41421356237309...
say sin(Num.pi / 2)     # 1
say cos(0)              # 1
say log(Num.e)          # 1
say (2.718281828).log   # ≈ 1  (natural log)
```

### Number bases

```ruby
say 255.to_s(2)     # "11111111"  (binary)
say 255.to_s(16)    # "ff"        (hexadecimal)
say 255.to_s(8)     # "377"       (octal)
say "ff".to_i(16)   # 255         (hex string to integer)
```

---

## 23. Beginner Projects to Try

Work through these projects to practice what you've learned. They're ordered roughly from easiest to most challenging.

---

### Project 1: Temperature Converter

```ruby
func celsius_to_fahrenheit(c) {
    ((c * 9/5) + 32)
}

func fahrenheit_to_celsius(f) {
    ((f - 32) * 5/9)
}

print "Enter temperature in Celsius: "
var c = read(Number)

say "#{c}°C = #{celsius_to_fahrenheit(c).round(2)}°F"
say "#{c}°C = #{(c + 273.15).round(2)} K"
```

---

### Project 2: FizzBuzz

A classic exercise: for each number 1–100, print "Fizz" if divisible by 3, "Buzz" if by 5, "FizzBuzz" if by both, otherwise the number:

```ruby
for i in (1..100) {
    say (
        ((i % 15) == 0) ? "FizzBuzz" :
        ((i % 3)  == 0) ? "Fizz"     :
        ((i % 5)  == 0) ? "Buzz"     :
        i
    )
}
```

---

### Project 3: Simple Calculator

```ruby
func calculate(a, op, b) {
    given (op) {
        when ("+") { (a + b) }
        when ("-") { (a - b) }
        when ("*") { (a * b) }
        when ("/") {
            die "Cannot divide by zero!" if (b == 0)
            (a / b)
        }
        else { die "Unknown operator: #{op}" }
    }
}

print "First number:  "
var a = read(Number)
print "Operator (+, -, *, /): "
var op = read(String)
print "Second number: "
var b = read(Number)

try {
    say "Result: #{calculate(a, op, b)}"
}
catch { |msg|
    say "Error: #{msg}"
}
```

---

### Project 4: Guess the Number

```ruby
var secret = (1..100).rand    # random number between 1 and 100
var guesses = 0

say "I'm thinking of a number between 1 and 100."
say "Can you guess it?"

loop {
    print "Your guess: "
    var guess = read(Number)
    guesses++

    if (guess < secret) {
        say "Too low! Try higher."
    } elsif (guess > secret) {
        say "Too high! Try lower."
    } else {
        say "Correct! You got it in #{guesses} guess#{(guesses == 1 ? '' : 'es')}!"
        break
    }
}
```

---

### Project 5: Simple Statistics

```ruby
func stats(data) {
    var n    = data.len
    var mean = (data.sum / n)

    var sorted   = data.sort
    var median   = (n.is_odd
        ? sorted[n / 2]
        : ((sorted[(n/2) - 1] + sorted[n/2]) / 2)
    )

    var variance = (data.map { |x| ((x - mean)**2) }.sum / n)
    var std_dev  = variance.sqrt

    Hash(
        count   => n,
        sum     => data.sum,
        mean    => mean.round(4),
        median  => median,
        min     => data.min,
        max     => data.max,
        std_dev => std_dev.round(4),
    )
}

var data = [4, 8, 15, 16, 23, 42]
var s    = stats(data)

say "Count:   #{s{:count}}"
say "Sum:     #{s{:sum}}"
say "Mean:    #{s{:mean}}"
say "Median:  #{s{:median}}"
say "Min:     #{s{:min}}"
say "Max:     #{s{:max}}"
say "Std Dev: #{s{:std_dev}}"
```

---

### Project 6: Fibonacci Sequence

```ruby
# Method 1: Simple recursive with caching
func fib(n) is cached {
    return n if (n <= 1)
    (fib((n - 1)) + fib((n - 2)))
}

say "First 15 Fibonacci numbers:"
say (0..14).map { |n| fib(n) }

# Method 2: Iterative
func fib_sequence(count) {
    var result = [0, 1]
    while (result.len < count) {
        result.push((result[-1] + result[-2]))
    }
    result.first(count)
}

say fib_sequence(20)
```

---

### Project 7: Prime Explorer

```ruby
say "=== Prime Number Explorer ==="
say ""

# First 20 primes
say "First 20 primes:"
say 20.primes
say ""

# Check if numbers are prime
[2, 7, 13, 25, 97, 100, 101].each { |n|
    var status = n.is_prime ? "prime" : "not prime"
    say "#{n} is #{status}"
}
say ""

# Factorize some numbers
[12, 60, 100, 360, 2310].each { |n|
    say "#{n} = #{factor(n).join(' × ')}"
}
say ""

# Twin primes (pairs that differ by 2)
say "Twin prime pairs up to 100:"
var prev = 2
primes(3, 100).each { |p|
    say "(#{prev}, #{p})" if ((p - prev) == 2)
    prev = p
}
```

---

### Project 8: Word Frequency Counter

```ruby
# Count and display word frequencies from a string

var text = <<'END'
To be or not to be that is the question
Whether tis nobler in the mind to suffer
The slings and arrows of outrageous fortune
Or to take arms against a sea of troubles
END

var words = text.lc.split(/\W+/).grep { .len > 0 }
var freq  = Hash()

words.each { |w|
    freq{w} := 0
    freq{w}++
}

say "Word frequencies (sorted by count, descending):"
say "=" * 35

freq.keys
    .sort_by { |k| -freq{k} }
    .first(10)
    .each { |word|
        var count = freq{word}
        var bar   = "█" * count
        say "#{ '%-12s' % word } #{bar} (#{count})"
    }
```

---

### Project 9: Sierpinski Triangle

This draws a famous fractal pattern using simple string operations:

```ruby
func sierpinski(n) {
    var rows = ["*"]
    n.times { |i|
        var sp   = (" " * (2**i))
        rows = (rows.map { |r| (sp + r + sp) } +
                rows.map { |r| (r + " " + r) })
    }
    rows.join("\n")
}

say sierpinski(4)
```

---

## 24. Where to Learn More

You've covered the fundamentals! Here's where to go next.

### Official Documentation

| Resource | Description |
|----------|-------------|
| 📘 [Sidef GitBook](https://trizen.gitbook.io/sidef-lang/) | The complete language reference — covers everything |
| 📄 [PDF Book](https://github.com/trizen/sidef/releases/download/26.01/sidef-book.pdf) | The full book in PDF format for offline reading |
| 📝 [Advanced Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/SIDEF_ADVANCED_GUIDE.md) | An advanced tutorial covering the full language |
| 🔢 [Number Theory Tutorial](https://codeberg.org/trizen/sidef/src/branch/master/NUMBER_THEORY_TUTORIAL.md) | Deep dive into Sidef's mathematical superpowers |

### Example Code

| Resource | Description |
|----------|-------------|
| 📂 [sidef-scripts](https://github.com/trizen/sidef-scripts) | Hundreds of real Sidef programs — the best way to learn by reading |
| 🌹 [RosettaCode — Sidef](https://rosettacode.org/wiki/Sidef) | Classic programming tasks solved in Sidef, side-by-side with other languages |

### Community

| Resource | Description |
|----------|-------------|
| 💬 [GitHub Discussions](https://github.com/trizen/sidef/discussions) | Ask questions, share ideas, get help |
| 🐛 [GitHub Issues](https://github.com/trizen/sidef/issues) | Bug reports and feature requests |
| 📦 [MetaCPAN](https://metacpan.org/pod/Sidef) | CPAN package page with additional documentation |

### Try Without Installing

**[https://tio.run/#sidef](https://tio.run/#sidef)** — Run Sidef code instantly in your browser.

### What to explore next

Once you're comfortable with the basics here, the natural next steps are:

1. **Object-oriented programming** — classes, inheritance, methods
2. **Modules and namespaces** — organizing larger programs
3. **Lazy evaluation** — working with infinite sequences efficiently
4. **Number theory** — Sidef's extraordinary built-in math functions
5. **Perl module integration** — using any CPAN library from Sidef

All of these are covered in detail in the **Sidef Advanced Guide** and the official book.

---

<div align="center">

**You're ready to start coding! Happy hacking with Sidef. 🚀**

*Start with small programs, experiment freely in the REPL, and don't be afraid to break things — that's how you learn.*

</div>
