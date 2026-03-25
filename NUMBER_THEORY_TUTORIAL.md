# Computational Number Theory with Sidef

> **Sidef** is a high-level, multi-paradigm programming language with deep, built-in support for number theory. Its `Number` class provides arbitrary-precision integers, rationals, floats, and complex numbers, together with over 1,000 number-theoretic functions — ranging from basic divisibility tests to advanced primality algorithms, integer factorization, multiplicative functions, and analytic number theory tools. Performance is comparable to PARI/GP and Mathematica, backed by the [GMP](https://gmplib.org/), [MPFR](https://www.mpfr.org/), and [MPC](https://www.multiprecision.org/) C libraries.

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

---

## Table of Contents

1. [Notation and Conventions](#1-notation-and-conventions)
2. [Getting Started](#2-getting-started)
3. [The Number System](#3-the-number-system)
4. [Precision and Configuration](#4-precision-and-configuration)
5. [Arithmetic Operators](#5-arithmetic-operators)
6. [Number-Theoretic Function Reference](#6-number-theoretic-function-reference)
7. [Generating Sequences](#7-generating-sequences)
8. [User-Defined Functions](#8-user-defined-functions)
9. [Built-in Classes](#9-built-in-classes)
10. [Primality Testing](#10-primality-testing)
11. [Prime Numbers and Prime Counting](#11-prime-numbers-and-prime-counting)
12. [Integer Factorization](#12-integer-factorization)
13. [Divisors and Divisor Functions](#13-divisors-and-divisor-functions)
14. [Modular Arithmetic](#14-modular-arithmetic)
15. [Euler's Totient and Related Functions](#15-eulers-totient-and-related-functions)
16. [Multiplicative Functions](#16-multiplicative-functions)
17. [Special Number Classes](#17-special-number-classes)
18. [Sequences and Combinatorics](#18-sequences-and-combinatorics)
19. [Continued Fractions and Rational Approximation](#19-continued-fractions-and-rational-approximation)
20. [Quadratic Forms and Sum of Squares](#20-quadratic-forms-and-sum-of-squares)
21. [Lucas Sequences](#21-lucas-sequences)
22. [Analytic and Arithmetic Functions](#22-analytic-and-arithmetic-functions)
23. [Working with Large Numbers](#23-working-with-large-numbers)
24. [Computing OEIS Sequences](#24-computing-oeis-sequences)
25. [Non-trivial OEIS Sequences](#25-non-trivial-oeis-sequences)
26. [Where Sidef Excels](#26-where-sidef-excels)
27. [Making Sidef Faster](#27-making-sidef-faster)
28. [Tips, Tricks, and Common Pitfalls](#28-tips-tricks-and-common-pitfalls)
29. [Worked Problems](#29-worked-problems)
30. [Quick-Reference Cheat Sheet](#30-quick-reference-cheat-sheet)
31. [Sieve Algorithms](#31-sieve-algorithms)
32. [Primality Testing — Algorithm Deep Dives](#32-primality-testing--algorithm-deep-dives)
33. [Factorization Algorithm Deep Dives](#33-factorization-algorithm-deep-dives)
34. [Discrete Logarithms and Related Problems](#34-discrete-logarithms-and-related-problems)
35. [Chinese Remainder Theorem — Extended Applications](#35-chinese-remainder-theorem--extended-applications)
36. [Quadratic Reciprocity and Residue Theory](#36-quadratic-reciprocity-and-residue-theory)
37. [The Prime Number Theorem and Analytic Methods](#37-the-prime-number-theorem-and-analytic-methods)
38. [Smooth Numbers, Factor Bases, and Subexponential Factorization](#38-smooth-numbers-factor-bases-and-subexponential-factorization)
39. [p-Adic Arithmetic and Valuations](#39-p-adic-arithmetic-and-valuations)
40. [Dirichlet Series and Multiplicative Structure](#40-dirichlet-series-and-multiplicative-structure)
41. [Elliptic Curves in Number Theory](#41-elliptic-curves-in-number-theory)
42. [Algebraic Number Theory Constructs](#42-algebraic-number-theory-constructs)
43. [Cryptographic Applications](#43-cryptographic-applications)
44. [Number-Theoretic Transforms and Convolutions](#44-number-theoretic-transforms-and-convolutions)
45. [Computational Complexity in Number Theory](#45-computational-complexity-in-number-theory)
46. [Advanced OEIS Techniques and Sequence Acceleration](#46-advanced-oeis-techniques-and-sequence-acceleration)
- [Appendix A: Common Recipes](#appendix-a-common-recipes)
- [Appendix B: Performance Benchmarks](#appendix-b-performance-benchmarks)
- [Appendix C: Further Reading and Resources](#appendix-c-further-reading-and-resources)

---

## 1. Notation and Conventions

| Notation | Meaning |
|---|---|
| `φ(n)` | Euler's totient function |
| `μ(n)` | Möbius function |
| `τ(n)` | Number of divisors |
| `σ_k(n)` | Sum of k-th powers of divisors |
| `ω(n)` | Number of distinct prime factors |
| `Ω(n)` | Number of prime factors counted with multiplicity |
| `λ(n)` | Carmichael's lambda function |
| `ψ(n)` | Dedekind psi function |

Reading conventions used throughout this document:

- `say` prints a value followed by a newline.
- `var` introduces a variable.
- `func` defines a function.
- `local` temporarily changes a global setting inside a function or block.
- Most functions appear in both standalone form (`is_prime(n)`) and method-call form (`n.is_prime`) — both are equivalent.

---

## 2. Getting Started

For installation instructions and basic language features, refer to the [beginner's tutorial](https://codeberg.org/trizen/sidef/src/branch/master/SIDEF_BEGINNER_GUIDE.md) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf)).

### Starting the REPL

After installing Sidef, launch the interactive environment with the `sidef` command:

```console
$ sidef
Sidef 26.01, running on Linux, using Perl v5.42.0.
Type "help", "copyright" or "license" for more information.
>
```

### Running Scripts

Create a file `script.sf` and execute it as:

```console
sidef script.sf
```

### Quick Examples

```ruby
25.by { .is_prime }         # First 25 prime numbers
30.of { .esigma }           # First 30 exponential sigma values
factor(2**128 + 1)          # Prime factorization of the 7th Fermat number
```

### Basic Syntax

Numbers are first-class objects, and most number-theoretic functions can be called either as standalone functions or as method calls:

```ruby
say euler_phi(100)       #=> 40
say 100.euler_phi        #=> 40  (equivalent method-call form)
```

```ruby
var x = 42              # Variable declaration
var y = x**3            # Exponentiation
say (x + y)             # Output result

# Methods chain naturally
120.factor.sum          # Sum the prime factors of 120
```

The following four statements are all equivalent:

```ruby
say 10.by { .is_composite }
say 10.by { is_composite(_) }
say 10.by {|n| n.is_composite }
say 10.by {|n| is_composite(n) }
```

Key things to know:

- Every integer, rational, float, and complex number is a `Number` object.
- Ranges are written `a..b` (inclusive) and `a..^b` (exclusive of `b`).
- Blocks are written `{ ... }` and receive arguments via `|param|`.
- `n.of { block }` generates an array of `n` values by calling the block with indices 0, 1, …, n−1.
- `n.by { block }` generates the first `n` non-negative integers for which the block returns true.

```ruby
# Generate the first 10 Fibonacci numbers
say 10.of { .fib }      #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

# Sum of primes up to 100
say prime_sum(100)       #=> 1060

# First prime larger than 10^18
say next_prime(10**18)
```

---

## 3. The Number System

Sidef's numbers are arbitrarily precise — there is no practical size limit.

### Integer Literals and Bases

```ruby
var a = 42               # Decimal integer
var b = 0b1101           # Binary  (= 13)
var c = 0x1F4            # Hex     (= 500)
var d = 0777             # Octal   (= 511)

# Construct a number from a string in any base
var e = Number("101010", 2)   # Binary "101010" = 42
var f = Number("ff",    16)   # Hex    "ff"     = 255
```

### Rationals

Sidef performs exact rational arithmetic automatically. Use `as_frac` or `as_rat` to inspect the rational representation:

```ruby
say (1/3 + 1/6)           #=> 1/2
say as_frac(355/113)       #=> 355/113
say (22/7 - Num.pi)        # Small floating-point difference
```

### Floating-Point

Use `Num!PREC` to control precision in bits (default is 192 bits ≈ 57 significant decimal digits):

```ruby
local Num!PREC = 512       # Set 512-bit precision locally
say sqrt(2)                # Very high-precision sqrt(2)
```

### Complex Numbers

```ruby
var z = 3:4               # Complex 3 + 4i  (using : operator)
say z                     #=> 3+4i
say Complex(3, 4).abs     #=> 5   (magnitude)
say 42.i                  #=> 42i (multiply by imaginary unit)
```

### Gaussian Integers

```ruby
var g = Gauss(3, 4)
say g**100
say g.powmod(1234, 56789)
```

### Quadratic Integers

```ruby
var q = Quadratic(3, 4, 5)   # 3 + 4*sqrt(5)
say q**100
say q.powmod(98765, 43210)
```

---

## 4. Precision and Configuration

Global class variables on `Num` control runtime behavior:

| Variable | Default | Description |
|---|---|---|
| `Num!PREC` | 192 | Floating-point precision in bits |
| `Num!ROUND` | 0 | Rounding mode (0 = nearest) |
| `Num!VERBOSE` | false | Enable debug output |
| `Num!USE_YAFU` | false | Use YAFU for large factorizations |
| `Num!USE_PFGW` | false | Use PFGW64 for primality pretesting |
| `Num!USE_PARI_GP` | false | Use PARI/GP in selected methods |
| `Num!USE_FACTORDB` | false | Use factordb.com for factoring |
| `Num!USE_PRIMECOUNT` | false | Use Kim Walisch's primecount binary |
| `Num!USE_PRIMESUM` | false | Use Kim Walisch's primesum binary |
| `Num!USE_CONJECTURES` | false | Enable conjectured (faster) methods |

Use `local` to restrict changes to a function scope:

```ruby
func high_precision_pi {
    local Num!PREC = 4096
    say Num.pi         # Pi to ~1200 decimal places
}
high_precision_pi()
say Num.pi             # Back to default 192-bit precision
```

**Rounding modes** for `Num!ROUND`:

| Value | Mode |
|---|---|
| 0 | Round to nearest (default) |
| 1 | Round towards zero (truncate) |
| 2 | Round towards +∞ (ceiling) |
| 3 | Round towards −∞ (floor) |

---

## 5. Arithmetic Operators

| Operator / Method | Meaning | Example |
|---|---|---|
| `+`, `add` | Addition | `3 + 4` → `7` |
| `-`, `sub` | Subtraction | `10 - 3` → `7` |
| `*`, `mul` | Multiplication | `6 * 7` → `42` |
| `/`, `div` | Division (exact/rational) | `10 / 3` → `10/3` |
| `//`, `idiv` | Integer floor division | `17 // 5` → `3` |
| `%`, `mod` | Remainder | `17 % 5` → `2` |
| `**`, `pow` | Exponentiation | `2**10` → `1024` |
| `%%`, `is_div` | Divisibility test | `12 %% 4` → `true` |
| `&`, `and` | Bitwise AND | `0b1100 & 0b1010` → `8` |
| `\|`, `or` | Bitwise OR | `0b1100 \| 0b1010` → `14` |
| `^`, `xor` | Bitwise XOR | `0b1100 ^ 0b1010` → `6` |
| `~`, `not` | Bitwise NOT | `~0b1010` → `-11` |
| `<<`, `shift_left` | Left shift | `5 << 3` → `40` |
| `>>`, `shift_right` | Right shift | `40 >> 3` → `5` |
| `n!` / `factorial` | Factorial | `10!` → `3628800` |
| `n!!` / `double_factorial` | Double factorial | `9!!` → `945` |
| `++`, `inc` | Increment | `++x` |
| `--`, `dec` | Decrement | `--x` |

---

## 6. Number-Theoretic Function Reference

Below is a broad reference of functions used in computational number theory. For the full documentation, see: [Sidef Number Class](https://metacpan.org/pod/Sidef::Types::Number::Number) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-number-class-documentation.pdf)).

### Primality and Compositeness

```ruby
is_prime(n)                 # true if n is a probable prime (BPSW test)
is_prov_prime(n)            # true if n is a provable prime
is_composite(n)             # true if n is a composite number
is_squarefree(n)            # true if n is squarefree
is_power(n, k)              # true if n = b^k for some b >= 1
is_power_of(n, b)           # true if n = b^k for some k >= 1
is_perfect_power(n)         # true if n is a perfect power (k >= 2)
is_gaussian_prime(a, b)     # true if a+b*i is a Gaussian prime
```

### Divisors

```ruby
factor(n)                   # array with the prime factors of n
divisors(n)                 # array with the positive divisors of n
udivisors(n)                # array with the unitary divisors of n
edivisors(n)                # array with the exponential divisors of n
idivisors(n)                # array with the infinitary divisors of n
bdivisors(n)                # array with the bi-unitary divisors of n

omega_prime_divisors(n, k)  # divisors of n with omega(d) = k
almost_prime_divisors(n, k) # divisors of n with Omega(d) = k
prime_power_divisors(n)     # prime power divisors of n
square_divisors(n)          # square divisors of n
squarefree_divisors(n)      # squarefree divisors of n

k.smooth_divisors(n)        # k-smooth divisors of n
k.rough_divisors(n)         # k-rough divisors of n
k.power_divisors(n)         # k-th power divisors of n
k.powerfree_divisors(n)     # k-powerfree divisors of n
```

### Counting and Sum Functions

```ruby
omega(n, k=0)               # omega function: number of distinct primes of n
Omega(n, k=0)               # Omega function: prime factors with multiplicity
tau(n)                      # count of divisors of n
sigma(n, k=1)               # sigma_k(n): sum of k-th powers of divisors
psi(n, k=1)                 # Dedekind's Psi function
phi(n)                      # Euler's totient function
jordan_totient(n, k=1)      # Jordan's totient function: J_k(n)
lambda(n)                   # Carmichael lambda function
znorder(a, n)               # multiplicative order of a mod n
mu(n)                       # Moebius function
mertens(n)                  # Mertens function: partial sums of mu(n)
liouville(n)                # Liouville function: (-1)^Omega(n)

esigma(n)                   # exponential sigma function
usigma(n, k=1)              # unitary sigma function
isigma(n)                   # infinitary sigma function
bsigma(n)                   # bi-unitary sigma function
uphi(n)                     # unitary totient function
iphi(n)                     # infinitary totient function
```

### Integer Division and Roots

```ruby
idiv(a, b)                  # integer floor division: floor(a/b)
idiv_round(a, b)            # integer round division: round(a/b)
idiv_ceil(a, b)             # integer ceil division: ceil(a/b)
idiv_trunc(a, b)            # integer truncated division: trunc(a/b)

iroot(n, k)                 # integer k-th root of n
ilog(n, k)                  # integer logarithm of n in base k
valuation(n, k)             # number of times n is divisible by k

gcd(...)                    # greatest common divisor of a list of integers
gcud(...)                   # greatest common unitary divisor
lcm(...)                    # least common multiple of a list of integers
```

### Factorials and Binomials

```ruby
factorial(n)                # n-th factorial (n!)
mfactorial(n, k)            # k-multi-factorial of n
falling_factorial(n, k)     # falling factorial
rising_factorial(n, k)      # rising factorial
binomial(n, k)              # the binomial coefficient: n!/((n-k)! * k!)
binomialmod(n, k, m)        # binomial(n,k) modulo m
factorialmod(n, m)          # factorial(n) modulo m
```

### Primes and Composites

```ruby
pi(n)                       # count of primes <= n
pi(a, b)                    # count of primes in the range a..b
prime(n)                    # n-th prime number
primes(a, b)                # array of primes in the range a..b
prime_sum(a, b, k=1)        # sum of k-th powers of primes in [a,b]

composite(n)                # n-th composite number
composites(a, b)            # array of composites in the range a..b
composite_count(n)          # count of composites <= n
composite_sum(a, b, k=1)    # sum of k-th powers of composites in [a,b]

squarefree_count(n)         # count of squarefree numbers <= n
prime_power_count(n)        # count of prime powers <= n
perfect_power_count(n)      # count of perfect powers <= n

lpf(n)                      # least prime factor of n, with lpf(1) = 1
gpf(n)                      # greatest prime factor of n, with gpf(1) = 1
```

### Modular Arithmetic

```ruby
sqrtmod(a, n)               # find a solution x to x^2 == a (mod n)
sqrtmod_all(a, n)           # find all solutions x to x^2 == a (mod n)
invmod(a, m)                # modular inverse: a^(-1) (mod m)
powmod(n, k, m)             # modular exponentiation: n^k (mod m)
chinese(Mod(a,m), Mod(b,n)) # Chinese Remainder Theorem
legendre(a, p)              # Legendre symbol (a|p)
jacobi(a, n)                # Jacobi symbol (a|n)
kronecker(a, n)             # Kronecker symbol (a|n)
znlog(a, g, m)              # discrete log: find k with g^k ≡ a (mod m)
znprimroot(n)               # smallest primitive root mod n
linear_congruence(n, r, m)  # solve n*x ≡ r (mod m)
```

### Special Sequences

```ruby
harmonic(n, k=1)            # n-th Harmonic number of k-th order
bernoulli(n)                # n-th Bernoulli number
bernoulli(n, x)             # n-th Bernoulli polynomial evaluated at x
euler(n)                    # n-th Euler number
euler(n, x)                 # n-th Euler polynomial evaluated at x

fib(n, k=2)                 # n-th Fibonacci number (k-th order)
fibmod(n, m)                # n-th Fibonacci modulo m
lucas(n)                    # n-th Lucas number
lucasU(P, Q, n)             # Lucas sequence U_n(P, Q)
lucasV(P, Q, n)             # Lucas sequence V_n(P, Q)
lucasUmod(P, Q, n, m)       # Lucas U_n(P, Q) mod m
lucasVmod(P, Q, n, m)       # Lucas V_n(P, Q) mod m

geometric_sum(n, r)         # closed-form: Sum_{j=0..n} r^j
faulhaber_sum(n, k)         # Faulhaber's formula: Sum_{j=1..n} j^k
```

### Continued Fractions and Pell

```ruby
sqrt_cfrac(n)               # continued fraction expansion of sqrt(n)
sqrt_cfrac_period_len(n)    # length of the continued fraction period
convergents(n)              # continued fraction convergents of n
rat_approx(n)               # rational approximation of n
var(x,y) = solve_pell(n)    # smallest solution to Pell's equation x^2 - n*y^2 = 1
```

### Digits and Representation

```ruby
digits(n, base=10)          # array with digits of n in a given base
digits_sum(n, base=10)      # sum of digits of n in a given base
flip(n, b=10)               # digit reversal in base b
digital_root(n)             # digital root of n
```

### Sum of Squares and Forms

```ruby
sum_of_squares(n)           # array of [x,y] solutions for n = x^2 + y^2
diff_of_squares(n)          # array of [x,y] solutions for n = x^2 - y^2
cyclotomic(n)               # n-th cyclotomic polynomial (as a Polynomial)
cyclotomic(n, x)            # n-th cyclotomic polynomial evaluated at x
cyclotomicmod(n, x, m)      # n-th cyclotomic polynomial evaluated at x mod m
```

### Inverse Multiplicative Functions

Based on methods by [Max Alekseyev](https://cs.uwaterloo.ca/journals/JIS/VOL19/Alekseyev/alek5.html):

```ruby
inverse_phi(n)              # all x where phi(x) = n
inverse_psi(n)              # all x where psi(x) = n
inverse_sigma(n)            # all x where sigma(x) = n
inverse_uphi(n)             # all x where uphi(x) = n
inverse_usigma(n)           # all x where usigma(x) = n

inverse_sigma_len(n)        # number of solutions to sigma(x) = n
inverse_sigma_min(n)        # minimum solution
inverse_sigma_max(n)        # maximum solution
inverse_phi_len(n)          # number of solutions to phi(x) = n
inverse_phi_min(n)          # minimum solution
inverse_phi_max(n)          # maximum solution
inverse_psi_len(n)          # number of solutions to psi(x) = n
inverse_psi_min(n)          # minimum solution
inverse_psi_max(n)          # maximum solution
```

### Pseudoprimes

```ruby
is_carmichael(n)            # true if n is a Carmichael number
is_lucas_carmichael(n)      # true if n is a Lucas-Carmichael number
is_psp(n, B=2)              # true if n is a Fermat pseudoprime to base B
is_strong_psp(n, B=2)       # true if n is a strong pseudoprime to base B
is_super_psp(n, B=2)        # true if n is a superpseudoprime to base B
is_over_psp(n, B=2)         # true if n is an overpseudoprime to base B
is_chebyshev_psp(n)         # true if n is a Chebyshev pseudoprime
is_euler_psp(n, B=2)        # true if n is an Euler pseudoprime to base B
is_pell_psp(n)              # true if n is a Pell pseudoprime
is_lucasU_psp(n, P=1, Q=-1) # Lucas U pseudoprime
is_lucasV_psp(n, P=1, Q=-1) # Lucas V pseudoprime

k.fermat_psp(B, a, b)       # k-factor Fermat pseudoprimes to base B in [a,b]
k.strong_fermat_psp(B, a, b)# strong Fermat pseudoprimes in [a,b]
k.carmichael(a, b)          # Carmichael numbers with k prime factors in [a,b]
k.lucas_carmichael(a, b)    # Lucas-Carmichael numbers in [a,b]
```

### k-Property Numbers

```ruby
n.is_almost_prime(k)        # true if Omega(n) = k
n.is_omega_prime(k)         # true if omega(n) = k
n.is_powerful(k)            # true if n is k-powerful
n.is_powerfree(k)           # true if n is k-powerfree
n.is_squarefree_almost_prime(k) # true if omega(n) = k and n is squarefree

k.omega_primes(a, b)        # generate k-omega primes in [a,b]
k.almost_primes(a, b)       # generate k-almost primes in [a,b]
k.omega_prime_count(a, b)   # count of k-omega primes in [a,b]
k.almost_prime_count(a, b)  # count of k-almost primes in [a,b]

k.powerfree(a, b)           # generate k-powerfree numbers in [a,b]
k.powerful(a, b)            # generate k-powerful numbers in [a,b]
k.powerfree_count(a, b)     # count of k-powerfree numbers in [a,b]
k.powerful_count(a, b)      # count of k-powerful numbers in [a,b]

k.omega_prime_sum(a, b)     # sum of k-omega primes in [a,b]
k.almost_prime_sum(a, b)    # sum of k-almost primes in [a,b]
k.powerful_sum(a, b)        # sum of k-powerful numbers in [a,b]
k.powerfree_sum(a, b)       # sum of k-powerfree numbers in [a,b]

k.smooth_count(n)           # count of k-smooth numbers <= n
k.rough_count(n)            # count of k-rough numbers <= n
```

---

## 7. Generating Sequences

The first $n$ terms of a sequence can be generated with:

```ruby
n.by {|k| ... }         # first n non-negative integers for which block is true
n.of {|k| ... }         # call block with first n integers (0..n-1), collect results
map(a..b, {|k| ... })   # map function over range, return array
{|k| ... }.map(a..b)    # same as above
```

### Examples

```ruby
# First 10 composite numbers
say 10.by { .is_composite }         #=> [4, 6, 8, 9, 10, 12, 14, 15, 16, 18]

# Values of phi(x) for 0..9
say 10.of { .phi }                  #=> [0, 1, 1, 2, 2, 4, 2, 6, 4, 6]

# Values of phi(x) for 20..30
say map(20..30, { .phi })           #=> [8, 12, 10, 22, 8, 20, 12, 18, 12, 28, 8]
```

### Infinite Lazy Sequences

The `Math.seq()` function constructs an infinite lazy sequence:

```ruby
say Math.seq(2, {|a| a[-1].next_prime }).first(30)                   # prime numbers
say Math.seq(0, 1, {|a| a.last(2).sum }).first(30)                   # Fibonacci
say Math.seq(1, 1, {|a,n| a[-1] + n*subfactorial(n-1) }).first(10)  # OEIS: A177265
say Math.seq(1, {|a| a[-1].next_omega_prime(2) }).first(20)          # OEIS: A007774
```

---

## 8. User-Defined Functions

Functions are defined with the `func` keyword:

```ruby
func function_name(a, b, c, ...) {
    # function body
}
```

A user-defined function name can be passed as a block argument to built-in methods:

```ruby
func my_condition(n) { n.is_composite && n.is_squarefree }
say 10.by(my_condition)   # first 10 squarefree composite numbers
```

### Multiplicative Functions

Multiplicative functions are concisely implemented using `factor_prod`:

```ruby
func exponential_sigma(n, k=1) {
    n.factor_prod {|p, e|
        e.divisors.sum {|d| p**(d*k) }
    }
}

say map(1..20, {|n| exponential_sigma(n, 1) })
say map(1..20, {|n| exponential_sigma(n, 2) })
```

### Summation and Product Syntax

```ruby
func harmonic(n) {
    sum(1..n, {|k| 1/k })
}
say 8.of(harmonic)         #=> [0, 1, 3/2, 11/6, 25/12, 137/60, 49/20, 363/140]

func superfactorial(n) {
    prod(1..n, {|k| k! })
}
say 8.of(superfactorial)   #=> [1, 1, 2, 12, 288, 34560, 24883200, 125411328000]
```

### Cached Recursive Functions

The `is cached` trait automatically memoizes function results:

```ruby
func a(n) is cached {
    return 1 if (n == 0)
    -sum(^n, {|k| a(k) * binomial(n+1, k)**2 }) / (n+1)**2
}

for n in (0..30) {
    printf("(B^S)_1(%2d) = %45s / %s\n", n, a(n) / n! -> nude)
}
```

---

## 9. Built-in Classes

### Mod Class

The `Mod(a, m)` class constructs a modular object, similar to PARI/GP's `Mod`:

```ruby
var a = Mod(13, 97)

say a**42    # Mod(85, 97)
say 42*a     # Mod(61, 97)

say chinese(Mod(43, 19), Mod(13, 41))   # Chinese Remainder Theorem
```

### Polynomial Class

```ruby
say Poly(5)                   # monomial: x^5
say Poly([1,2,3,4])           # x^3 + 2*x^2 + 3*x + 4
say Poly(5 => 3, 2 => 10)     # 3*x^5 + 10*x^2
```

### PolyMod Class

Represents a polynomial modulo m:

```ruby
var a = PolyMod([13,4,51], 43)
var b = PolyMod([5,0,-11], 43)

say a*b         #=> 22*x^4 + 20*x^3 + 26*x^2 + 42*x + 41 (mod 43)
say a-b         #=> 8*x^2 + 4*x + 19 (mod 43)
say a+b         #=> 18*x^2 + 4*x + 40 (mod 43)

say [a.divmod(b)].join(' and ')   #=> 37 (mod 43) and 4*x + 28 (mod 43)
```

### Gauss Class

Represents a Gaussian integer $a + bi$:

```ruby
say Gauss(3, 4)**100
say Mod(Gauss(3, 4), 1000001)**100   #=> Mod(Gauss(826585, 77265), 1000001)

var a = Gauss(17, 19)
var b = Gauss(43, 97)

say (a + b)     #=> Gauss(60, 116)
say (a - b)     #=> Gauss(-26, -78)
say (a * b)     #=> Gauss(-1112, 2466)
say (a / b)     #=> Gauss(99/433, -32/433)
```

### Quadratic Class

Represents a quadratic integer $a + b\sqrt{w}$:

```ruby
var x = Quadratic(3, 4, 5)      # 3 + 4*sqrt(5)
var y = Quadratic(6, 1, 2)      # 6 + sqrt(2)

say x**10               #=> Quadratic(29578174649, 13203129720, 5)
say y**10               #=> Quadratic(253025888, 176008128, 2)

say x.powmod(100, 97)   #=> Quadratic(83, 42, 5)
say y.powmod(100, 97)   #=> Quadratic(83, 39, 2)
```

### Quaternion Class

Represents a quaternion $a + bi + cj + dk$:

```ruby
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)

say (a + b)         #=> Quaternion(6, 8, 10, 12)
say (a * b)         #=> Quaternion(-60, 12, 30, 24)
say (b * a)         #=> Quaternion(-60, 20, 14, 32)

say a**5                #=> Quaternion(3916, 1112, 1668, 2224)
say a.powmod(43, 97)    #=> Quaternion(61, 38, 57, 76)
say a.powmod(-5, 43)    #=> Quaternion(11, 22, 33, 1)
```

### Matrix Class

```ruby
var A = Matrix(
    [2, -3,  1],
    [1, -2, -2],
    [3, -4,  1],
)

say (A + B)         # matrix addition
say (A - B)         # matrix subtraction
say (A * B)         # matrix multiplication
say (A * 42)        # matrix-scalar multiplication

say A**20               # matrix exponentiation
say A**-1               # matrix inverse: A^(-1)
say A.powmod(43, 97)    # modular matrix exponentiation

say A.det             # matrix determinant
say A.solve([1,2,3])  # solve a system of linear equations
```

---

## 10. Primality Testing

Sidef provides a comprehensive suite of primality tests, from quick probabilistic checks to rigorous deterministic proofs.

### Quick Primality Check

```ruby
say 97.is_prime           #=> true
say 100.is_prime          #=> false
say is_prime(2**127 - 1)  #=> true  (Mersenne prime M_127)
```

`is_prime` uses a combination of trial division, Miller-Rabin, and Lucas tests (Baillie-PSW), which has no known counterexamples and is deterministic for n < 2^64.

### Full Primality Test Hierarchy

```ruby
# Trial division pretest (fast composite detection)
say n.primality_pretest

# Individual probabilistic tests
say n.is_fermat_psp(2)             # Fermat pseudoprime to base 2
say n.is_euler_psp(2)              # Euler pseudoprime to base 2
say n.is_strong_psp(2)             # Strong (Miller-Rabin) pseudoprime to base 2
say n.miller_rabin_random(20)      # Miller-Rabin with 20 random bases

# Lucas-based tests
say n.is_lucas_psp                 # Lucas pseudoprime (standard)
say n.is_strong_lucas_psp          # Strong Lucas pseudoprime
say n.is_extra_strong_lucas_psp    # Extra-strong Lucas pseudoprime

# Combined/provable tests
say n.is_bpsw_prime                # Full Baillie-PSW test
say n.is_provable_prime            # Rigorous certificate (slow for large n)
say n.is_aks_prime                 # AKS deterministic test (very slow)
```

### Special Prime Forms

```ruby
say n.is_mersenne_prime          # Is n = 2^p - 1 prime?
say n.is_prime_power             # Is n = p^k for some prime p?

say prime_power(43**5)           #=> 5   (the exponent k)
say prime_root(43**5)            #=> 43  (the prime base p)
```

### Pseudoprimes and Carmichael Numbers

```ruby
# All 3-factor Carmichael numbers up to 10^4
say 3.carmichael(1e4)

# Fermat pseudoprimes to base 2 with 3 prime factors up to 10^6
say 3.fermat_psp(2, 1e6)

# Carmichael lambda: smallest m with a^m ≡ 1 (mod n) for all gcd(a,n)=1
say lambda(561)    # 561 = first Carmichael number
```

> **Korselt's Criterion:** A squarefree composite $n$ is a Carmichael number if and only if for every prime $p \mid n$, we have $(p-1) \mid (n-1)$.

```ruby
func is_carmichael_korselt(n) {
    n.is_composite &&
    n.is_squarefree &&
    n.prime_divisors.all {|p| (n - 1) %% (p - 1) }
}

say is_carmichael_korselt(561)    #=> true
say is_carmichael_korselt(1105)   #=> true
say is_carmichael_korselt(100)    #=> false
```

### Testing Multiple Numbers at Once

When several numbers need simultaneous primality verification, `all_prime(...)` is faster than individual `is_prime(n)` calls. If one term has small prime factors, it returns early without running expensive tests on the others:

```ruby
all_prime(a, b)      # faster than: (is_prime(a) && is_prime(b))
```

---

## 11. Prime Numbers and Prime Counting

### Generating and Navigating Primes

```ruby
say prime(1)              #=> 2       (1st prime)
say prime(100)            #=> 541     (100th prime)

say primes(50)            # all primes up to 50
say primes(50, 100)       # primes in [50, 100]

say 97.next_prime         #=> 101
say 100.prev_prime        #=> 97

say 5.next_primes(100)    # 5 primes after 100: [101, 103, 107, 109, 113]
say 5.prev_primes(100)    # 5 primes before 100
```

### Prime Counting Function π(n)

```ruby
say primepi(100)           #=> 25    (25 primes ≤ 100)
say primepi(50, 100)       #=> 10    (primes in [50, 100])
say pi(10**12)             #=> 37607912018

# Closed-form bounds (no computation needed)
say 1000.prime_lower       # Lower bound for 1000th prime
say 1000.prime_upper       # Upper bound for 1000th prime
say primepi_lower(1e12)    # Lower bound for π(10^12)
say primepi_upper(1e12)    # Upper bound for π(10^12)
```

> For very large arguments, set `Num!USE_PRIMECOUNT = true` to delegate to Kim Walisch's highly optimized `primecount` binary.

### Prime Sums

```ruby
say prime_sum(100)          # Sum of all primes ≤ 100  (#=> 1060)
say prime_sum(50, 100)      # Sum of primes in [50, 100]
say prime_sum(1, 100, 2)    # Sum of squares of primes ≤ 100

say prime_power_sum(100)    # Sum of prime powers ≤ 100
say prime_power_count(100)  # Count of prime powers ≤ 100
```

### Special Prime Families

```ruby
# Twin primes: (p, p+2) both prime
say prime_cluster(1, 1000, 2)

# Cousin primes: (p, p+4)
say prime_cluster(1, 1000, 4)

# Sexy primes: (p, p+6)
say prime_cluster(1, 1000, 6)

# Prime triplets: (p, p+2, p+6)
say prime_cluster(1, 1000, 2, 6)

# Primorial: product of all primes ≤ n
say primorial(10)            #=> 210  (= 2*3*5*7)

# Product of first n primes
say 5.pn_primorial           #=> 2310 (= 2*3*5*7*11)
```

### Smooth Numbers

A number is *B-smooth* if its largest prime factor ≤ B:

```ruby
say gpf(5040)              #=> 7     (greatest prime factor)
say lpf(5040)              #=> 2     (least prime factor)

say 13.smooth_count(10**6) # 13-smooth numbers ≤ 10^6
say 11.rough_count(1000)   # 11-rough numbers ≤ 1000
```

---

## 12. Integer Factorization

### Basic Factorization

```ruby
say 5040.factor              #=> [2, 2, 2, 2, 3, 3, 5, 7]
say 5040.factor_exp          #=> [[2,4], [3,2], [5,1], [7,1]]
say 5040.prime_divisors      #=> [2, 3, 5, 7]

# Reconstruct n from factorization
say 5040.factor_exp.map_2d {|p,e| p**e }.prod   #=> 5040

# Factor formatting
say 5040.factor_map {|p,e| "#{p}^#{e}" }.join(" * ")
#=> "2^4 * 3^2 * 5^1 * 7^1"
```

### Special-Purpose Factorization

Sidef includes many specialized factorization methods combined under one function:

```ruby
special_factor(n, effort=1)     # auto-selects multiple methods
```

The `special_factor` function tries (among others): trial division, Fermat, HOLF, Sophie Germain, Pell, Phi-finder, Difference of Powers, Congruence of Powers, Miller, Lucas, Fibonacci, FLT, Pollard's p−1, Pollard's rho, Williams' p+1, Chebyshev, Cyclotomic, and Lenstra's ECM.

Individual methods are also available:

| Method | Best for |
|---|---|
| `n.trial_factor(limit)` | Small factors quickly |
| `n.pm1_factor(B)` | p where p−1 is B-smooth |
| `n.pp1_factor(B)` | p where p+1 is B-smooth |
| `n.ecm_factor(B1, curves)` | Elliptic Curve Method — general |
| `n.squfof_factor(tries)` | Medium-sized numbers (Shanks SQUFOF) |
| `n.holf_factor(tries)` | Factors near √n |
| `n.cyclotomic_factor(bases...)` | Numbers of the form a^k ± 1 |
| `n.flt_factor(base, tries)` | Factors with small multiplicative order |
| `n.miller_factor(tries)` | Carmichael numbers, Fermat pseudoprimes |
| `n.lucas_factor(j, tries)` | Lucas-Carmichael numbers |
| `n.cop_factor(tries)` | Algebraic (congruence of powers) |
| `n.prho_factor(tries)` | Pollard's rho |
| `n.pbrent_factor(tries)` | Pollard-Brent |
| `n.qs_factor` | Quadratic sieve |
| `n.special_factor(effort)` | Auto-selects multiple methods |

```ruby
# Examples where special_factor excels
say special_factor(lucas(480))                   # 0.01s
say special_factor(fibonacci(480))               # 0.01s
say special_factor(fibonacci(361)**2 + 1)        # 0.05s
say special_factor(2**512 - 1)                   # finds 12 factors, 1.5s
say special_factor(10**122 - 15**44)             # 0.1s
say special_factor((3**120 + 1) * (5**240 - 1)) # 0.1s
```

### GCD, LCM, and Extended GCD

```ruby
say gcd(48, 36)             #=> 12
say lcm(48, 36)             #=> 144

# Extended Euclidean: returns (u, v, d) where u*a + v*b = d
var (u, v, d) = gcdext(35, 15)
say [u, v, d]   # u*35 + v*15 = gcd(35,15) = 5

say consecutive_lcm(10)     #=> 2520  (lcm of 1..10)
say gcud(12, 18)             # greatest common unitary divisor
```

### Finding Closed Forms and Linear Recurrences

Given a sequence, Sidef can discover its closed form or linear recurrence:

```ruby
# Polynomial interpolation
say [0, 1, 4, 9, 16, 25, 36, 49, 64, 81].solve_seq     # x^2
say [0, 1, 33, 276, 1300, 4425, 12201].solve_seq        # 1/6*x^6 + ...

# Linear recurrence detection
say [0, 0, 1, 1, 2, 4, 7, 13, 24, 44, 81, 149].solve_rec_seq   # [1, 1, 1]
say [0, 1, 9, 36, 100, 225, 441, 784, 1296, 2025].solve_rec_seq # [5,-10,10,-5,1]

# Compute terms efficiently from a known recurrence
say Math.linear_rec([1, 1, 1], [0, 0, 1], 0, 20)    # terms 0..20
say Math.linear_rec([1, 1, 1], [0, 0, 1], 1000)     # only the 1000th term

# Modular computation
say Math.linear_recmod([5, -10, 10, -5, 1], [0, 1, 9, 36, 100], 2**128, 10**10)
```

---

## 13. Divisors and Divisor Functions

### Listing Divisors

```ruby
say 12.divisors           #=> [1, 2, 3, 4, 6, 12]
say 12.proper_divisors    #=> [1, 2, 3, 4, 6]     (excludes n)

# Unitary divisors: d | n and gcd(n/d, d) = 1
say 120.udivisors         #=> [1, 3, 5, 8, 15, 24, 40, 120]

# Square, prime power, and squarefree divisors
say 5040.square_divisors
say 5040.prime_power_divisors
say squarefree_divisors(120)

# Infinitary divisors
say 96.idivisors
```

### Divisor Count: τ(n)

```ruby
say tau(120)              #=> 16   (number of divisors)
say 120.sigma(0)          #=> 16   (sigma_0 = count of divisors)
```

### Divisor Sum: σ_k(n)

```ruby
say sigma(12)             #=> 28   (sum of divisors)
say sigma(12, 2)          #=> 210  (sum of squares of divisors)

say usigma(5040)          # sum of unitary divisors
say squarefree_sigma(5040)
say prime_sigma(100!)     # sum over distinct prime divisors
```

### Divisor Iteration

For performance, prefer `divisor_sum` and `divisor_prod` over generating the full list:

```ruby
# Preferred for performance
n.divisor_sum {|d| process(d) }    # if summing results
n.divisor_prod {|d| process(d) }   # if multiplying results

# Generate all divisors only when you need them all
n.divisors.each {|d| process(d) }
```

### Inverse Functions

These solve $f(x) = n$ for the given arithmetic function $f$:

```ruby
var n = 252
say inverse_phi(n)          #=> [301, 381, 387, 441, 508, 602, 762, 774, 882]
say inverse_psi(n)          #=> [130, 164, 166, 205, 221, 251]
say inverse_sigma(n)        #=> [96, 130, 166, 205, 221, 251]
say inverse_uphi(n)         #=> [296, 301, 320, 381, 456, 516, 602, 762]
say inverse_usigma(n)       #=> [130, 166, 205, 216, 221, 251]

# Efficient queries (no need to generate all solutions)
var m = 15!
say inverse_sigma_len(m)    #=> 910254
say inverse_sigma_min(m)    #=> 264370186080
say inverse_sigma_max(m)    #=> 1307672080867

say inverse_phi_len(m)      #=> 2852886
say inverse_phi_min(m)      #=> 1307676655073
say inverse_phi_max(m)      #=> 7959363061650
```

---

## 14. Modular Arithmetic

### Basic Operations

```ruby
say powmod(2, 1000, 1000000007)   # 2^1000 mod (10^9 + 7)
say invmod(17, 1000000007)        # 17^(-1) mod (10^9 + 7)

say addmod(43, 97, 127)           # (43 + 97) mod 127
say submod(43, 97, 127)           # (43 - 97) mod 127
say mulmod(43, 97, 127)           # (43 * 97) mod 127
```

### Compound Operations

```ruby
addmulmod(a, b, c, m)    # (a + b*c) mod m
submulmod(a, b, c, m)    # (a - b*c) mod m
muladdmod(a, b, c, m)    # (a*b + c) mod m
mulsubmod(a, b, c, m)    # (a*b - c) mod m
muladdmulmod(a,b,c,d,m)  # (a*b + c*d) mod m
mulsubmulmod(a,b,c,d,m)  # (a*b - c*d) mod m
```

### Linear Congruences

```ruby
# Solve n*x ≡ r (mod m)
say linear_congruence(3, 12, 15)    #=> [4, 9, 14]

# Modular square roots: solve x^2 ≡ a (mod m)
say sqrtmod(544, 800)                #=> 288
say sqrtmod_all(4095, 8469)          # all solutions
```

### Discrete Logarithm and Primitive Roots

```ruby
# Discrete log: find k such that a ≡ g^k (mod m)
say znlog(5, 2, 13)        # 2^k ≡ 5 (mod 13)

# Multiplicative order: smallest k with a^k ≡ 1 (mod m)
say znorder(2, 13)         # ord_13(2)

# Primitive root modulo n (smallest generator of (Z/nZ)*)
say znprimroot(13)         #=> 2
say znprimroot(17)         #=> 3
```

### Legendre, Jacobi, and Kronecker Symbols

```ruby
say legendre(7, 13)        # Legendre symbol (7|13)
say jacobi(10, 21)         # Jacobi symbol (10|21)
say kronecker(5, 8)        # Kronecker symbol (5|8)

# List all quadratic residues mod 13
say (1..12 -> grep {|a| legendre(a, 13) == 1 })
#=> [1, 3, 4, 9, 10, 12]
```

> **Euler's Criterion:** $a^{(p-1)/2} \equiv \left(\frac{a}{p}\right) \pmod{p}$, where $\left(\frac{a}{p}\right)$ is the Legendre symbol.

### p-Adic Valuation

```ruby
# How many times does p divide n?
say valuation(2**32, 4)    #=> 16  (2^32 = 4^16)
say valuation(5040, 2)     #=> 4
say valuation(5040, 3)     #=> 2
```

### Pitfall: Modular Division

```ruby
# WRONG: integer division then modulo may be incorrect
var wrong = ((powmod(2, 100, 1000) / 3) % 1000)

# RIGHT: use modular inverse
var right = (powmod(2, 100, 1000) * invmod(3, 1000) % 1000)

# Or use Mod objects (cleanest approach)
var m = Mod(2, 1000)**100
say m/3
```

---

## 15. Euler's Totient and Related Functions

### Euler's Totient φ(n)

φ(n) counts integers in [1, n] coprime to n — it is the order of the multiplicative group (Z/nZ)*:

```ruby
say euler_phi(12)           #=> 4   (1, 5, 7, 11 are coprime to 12)
say phi(100)                #=> 40

# Jordan's generalization J_k(n)
say phi(n, 2)               # Jordan totient J_2(n)
say jordan_totient(n, 3)    # J_3(n)

# Totient sum: Sum_{j=1..n} phi(j)
say totient_sum(100)        #=> 3044

# Batch computation over a range
say totient_range(7, 17)

# Unitary totient
say uphi(n)
```

> **Property:** For prime $p$, $\phi(p) = p - 1$. For prime power $p^k$, $\phi(p^k) = p^{k-1}(p-1)$. Multiplicativity: if $\gcd(m,n) = 1$, then $\phi(mn) = \phi(m)\phi(n)$.

### Carmichael's Lambda λ(n)

λ(n) is the exponent of (Z/nZ)* — the smallest $m$ such that $a^m \equiv 1 \pmod{n}$ for all $a$ coprime to $n$:

```ruby
say lambda(12)              #=> 2
say lambda(1000)            #=> 100
```

---

## 16. Multiplicative Functions

### Möbius Function μ(n)

$\mu(n) = 0$ if $n$ has a squared prime factor; $(-1)^k$ if $n$ is a product of $k$ distinct primes:

```ruby
say mu(1)     #=> 1
say mu(6)     #=> 1    (6 = 2*3)
say mu(4)     #=> 0    (4 = 2^2)
say mu(30)    #=> -1   (30 = 2*3*5)

# Mertens function M(n) = Sum_{k=1..n} mu(k)
say mertens(10**9)    #=> -25216
```

> **Möbius Inversion:** If $g(n) = \sum_{d|n} f(d)$, then $f(n) = \sum_{d|n} \mu(n/d)\, g(d)$. This is a central tool in analytic number theory.

### Liouville Function and Omega Counts

```ruby
say bigomega(12)           #=> 3   (12 = 2^2 * 3)
say omega(12)              #=> 2   (primes 2 and 3)
say liouville(12)          #=> -1  (Omega(12) = 3)
```

### Dedekind Psi Function

$\psi(n) = n \cdot \prod_{p \mid n} (1 + 1/p)$:

```ruby
say psi(n)                # Dedekind psi function
say inverse_psi(120)      #=> [75, 76, 87, 95]
```

### Sum of Prime Factors

```ruby
say sopfr(12)             #=> 7   (2+2+3, with repetition)
say sopf(12)              #=> 5   (2+3, distinct primes only)
```

### Dirichlet Convolution

```ruby
# Identity: sigma = phi * 1
say 30.of {|n| n.dirichlet_convolution({.phi}, {1}) }

# Custom convolutions
say 30.of { .dirichlet_convolution({.mu}, {_}) }
say 30.of { .dirichlet_convolution({.sigma}, {.phi}) }
```

---

## 17. Special Number Classes

### Perfect, Abundant, and Deficient Numbers

$\sigma(n) - n$ is the sum of proper divisors. A number is **perfect** if $\sigma(n) = 2n$, **abundant** if $\sigma(n) > 2n$, **deficient** if $\sigma(n) < 2n$:

```ruby
say 6.is_perfect           #=> true  (6 = 1+2+3)
say 12.is_abundant         #=> true  (sigma(12) = 28 > 24)
say 8.is_deficient         #=> true

say is_amicable(220, 284)  #=> true   (220 and 284 are amicable)

# Aliquot sum: sigma(n) - n
say aliquot(12)            #=> 16
```

### Squarefree and Powerful Numbers

```ruby
say n.is_squarefree          # No prime appears twice
say n.is_powerful(2)         # Every prime factor appears ≥ 2 times

say squarefree(100)          # All squarefree numbers ≤ 100
say 2.powerful(100)          # Powerful numbers ≤ 100
say squarefree_count(1e12)   # Count of squarefree numbers ≤ 10^12

say core(12)                 #=> 3   (squarefree part of 12)
```

### Almost Primes and Omega Primes

A *k-almost prime* has exactly $k$ prime factors counted with multiplicity ($\Omega(n) = k$). A *k-omega prime* has exactly $k$ distinct prime factors ($\omega(n) = k$):

```ruby
say n.is_almost_prime(2)         # Is n a semiprime?
say n.is_omega_prime(2)          # Are there exactly 2 distinct primes?

say 2.almost_primes(100)         # Semiprimes ≤ 100
say 2.almost_prime_count(100)    # Count of semiprimes ≤ 100
say squarefree_semiprime_count(1e10)
```

### Perfect Powers

```ruby
say n.is_perfect_power           # n = a^k, k ≥ 2?
say n.is_perfect_square          # n = a^2?
say n.is_prime_power             # n = p^k for some prime p?

say next_perfect_power(1e6)      #=> 1002001
```

### Palindromes

```ruby
say n.is_palindrome              # Palindrome in base 10?
say n.is_palindrome(2)           # Palindrome in base 2?
say n.next_palindrome            # Next base-10 palindrome > n

# Iterate over all base-10 palindromes up to 10^6
for (var n = 0; n < 1e6; n = n.next_palindrome) {
    say n
}
```

---

## 18. Sequences and Combinatorics

### Factorials and Variants

```ruby
say 10!                           #=> 3628800
say 9!!                           #=> 945         (double factorial: 9*7*5*3*1)
say mfac(9, 3)                    # triple factorial: 9*6*3
say subfactorial(5)               #=> 44           (derangements of 5 elements)
say hyperfactorial(5)             # 1^1 * 2^2 * 3^3 * 4^4 * 5^5
say superfactorial(4)             # 1! * 2! * 3! * 4!
say superprimorial(4)             # product of first 4 primorials
```

### Fibonacci, Lucas, and Generalizations

```ruby
say fib(10)                  #=> 55
say fib(20, 3)               # Tribonacci (3rd order Fibonacci)
say fibmod(10**9, 10**9+7)   # fib(10^9) mod (10^9+7)

say lucas(10)                #=> 123
say 25.of{|n| lucasU(1,-1,n) }   # Fibonacci via Lucas U sequence
say 25.of{|n| lucasU(2,-1,n) }   # Pell numbers
say 25.of{|n| lucasU(1,-2,n) }   # Jacobsthal numbers
say 25.of{|n| lucasV(1,-1,n) }   # Lucas numbers
say 25.of{|n| lucasV(2,-1,n) }   # Pell-Lucas numbers
```

### Bernoulli and Euler Numbers

```ruby
say bernoulli(10)            # 10th Bernoulli number (exact rational)
say euler_number(10)         # 10th Euler number
say tangent_number(5)        # 5th tangent number
```

### Bell, Catalan, and Motzkin Numbers

```ruby
say catalan(10)              #=> 16796
say motzkin(10)              # 10th Motzkin number
say bell(10)                 # 10th Bell number
say fubini(5)                # 5th Fubini (ordered Bell) number
```

### Stirling Numbers

```ruby
say stirling(5, 2)           # Stirling numbers of the first kind
say stirling2(5, 2)          # Stirling numbers of the second kind
```

### Polygonal and Pyramidal Numbers

```ruby
say polygonal(10, 3)          # 10th triangular number = 55
say polygonal(10, 5)          # 10th pentagonal number = 145
say polygonal(-10, 5)         # 10th second pentagonal number

say 55.is_polygonal(3)        #=> true

say centered_polygonal(6, 6)  # 6th centered hexagonal number
say pyramidal(10, 3)          # 10th tetrahedral number
```

---

## 19. Continued Fractions and Rational Approximation

Continued fractions are a powerful tool for Diophantine approximation and solving Pell's equation.

```ruby
# Continued fraction expansion of sqrt(12)
say sqrt(12).cfrac(8)           #=> [3, 2, 6, 2, 6, 2, 6, 2]

# Period of sqrt(n)'s continued fraction
say 28.sqrt_cfrac_period_len    # Length of the period
say sqrt_cfrac(61)              # Full period terms

# Convergents: best rational approximations p_k/q_k
say Num.pi.convergents(5)       #=> [3, 22/7, 333/106, 355/113, 103993/33102]

# Fraction <-> CF conversion
say as_cfrac(43/97)
say [0, 2, 3, 1, 10].cfrac2num.as_frac  #=> "43/97"

# Rational approximation
say rat_approx(0.4432989690721649484536082474f).as_frac  #=> "43/97"
```

### Pell's Equation

Pell's equation $x^2 - D \cdot y^2 = 1$ has its fundamental solution encoded in the continued fraction expansion of $\sqrt{D}$:

```ruby
# Built-in solver
var (x, y) = solve_pell(61)
say "x = #{x}, y = #{y}"

# Manual implementation using the CF period
func pell_fundamental(D) {
    var cfrac = D.sqrt_cfrac_period
    var terms = ([D.isqrt] + cfrac*2)
    var (p, q) = (1, 0)
    var (pp, qq) = (0, 1)
    for a in (terms) {
        (p, pp) = (a*p + pp, p)
        (q, qq) = (a*q + qq, q)
        return (p, q) if (p*p - D*q*q == 1)
    }
}
```

---

## 20. Quadratic Forms and Sum of Squares

### Representations as Sums of Squares

The function `squares_r(n, k)` counts the number of ways to write $n$ as a sum of $k$ squares:

```ruby
say 30.of { .squares_r(2) }     # OEIS: A004018
say 30.of { .squares_r(3) }     # OEIS: A005875
say 30.of { .squares_r(4) }     # OEIS: A000118

# Explicit solutions to n = a^2 + b^2
say sum_of_squares(50)           #=> [[1, 7], [5, 5]]

# Fast algorithms for k = {2, 4, 6, 8, 10}
say squares_r(2**128 + 1, 2)    # 0.49s
say squares_r(2**128 - 1, 4)    # 0.01s
say squares_r(2**128 - 1, 6)    # 0.01s
say squares_r(2**128 - 1, 10)   # 0.01s
```

### Gaussian Integer Factorization

```ruby
say is_gaussian_prime(3, 0)     # 3 is a Gaussian prime
say is_gaussian_prime(5, 0)     # 5 is not Gaussian prime (= (2+i)(2-i))
say is_gaussian_prime(2, 1)     # 2+i is a Gaussian prime

var g = Gauss(3, 4)
say g.norm                      # 25 = 3^2 + 4^2
say g.conj                      # Gauss(3, -4)
```

### Cyclotomic Polynomials

```ruby
say cyclotomic(12)               # Φ₁₂(x) = x^4 - x^2 + 1
say cyclotomic(12, 10)           #=> 9901

for n in (1..10) {
    say "Φ_#{n}(x) = #{cyclotomic(n)}"
}

say cyclotomicmod(100, 3, 1000)  # Φ₁₀₀(3) mod 1000
```

---

## 21. Lucas Sequences

Lucas sequences $U_n(P, Q)$ and $V_n(P, Q)$ generalize Fibonacci and Lucas numbers, and are fundamental to primality testing and factorization:

```ruby
# U_n(P, Q) sequences
say 20.of {|n| lucasU(1, -1, n) }    # Fibonacci
say 20.of {|n| lucasU(2, -1, n) }    # Pell numbers
say 20.of {|n| lucasU(1, -2, n) }    # Jacobsthal numbers

# V_n(P, Q) sequences
say 20.of {|n| lucasV(1, -1, n) }    # Lucas numbers
say 20.of {|n| lucasV(2, -1, n) }    # Pell-Lucas numbers
say 20.of {|n| lucasV(1, -2, n) }    # Jacobsthal-Lucas numbers

# Efficient modular computation
say lucasUmod(1, -1, 10**9, 10**9+7)    # fib(10^9) mod (10^9+7)
say lucasVmod(1, -1, 10**9, 10**9+7)    # lucas(10^9) mod (10^9+7)

# Chebyshev polynomials via Lucas V
say chebyshevT(5, 3)                 # T_5(3)
say chebyshevU(5, 3)                 # U_5(3)
```

---

## 22. Analytic and Arithmetic Functions

### Zeta and Related Functions

```ruby
say zeta(2)             # ζ(2) = π²/6 ≈ 1.6449...
say zeta(4)             # ζ(4) = π⁴/90
say eta(1)              # Dirichlet eta η(1) = ln 2
say zeta(0.5 + 14.1i)   # Riemann zeta at a complex point

say exp_mangoldt(8)     # p if 8 = p^k, else 1
say mangoldt(8)         # log(p) if 8 = p^k, else 0
```

### Asymptotic Functions

```ruby
say li(1e10)                 # Logarithmic integral Li(x)
say legendre_phi(1000, 4)    # Count of n ≤ 1000 not divisible by first 4 primes
say sum_remainders(100, 100) # Sum_{k=1..100} (100 mod k)
```

### Special Constants

```ruby
say Num.pi                   # π = 3.14159265...
say Num.phi                  # Golden ratio φ = 1.61803...
say Num.EulerGamma           # Euler-Mascheroni γ = 0.57721...
say Num.C                    # Catalan constant G = 0.91596...
say Num.ln2                  # ln(2) = 0.69314...
```

---

## 23. Working with Large Numbers

### Integer Roots and Logarithms

```ruby
say isqrt(2**200)            # Exact integer square root
say iroot(1000, 3)           #=> 10   (integer cube root)
say ilog(1000, 10)           #=> 3    (floor(log_10(1000)))
say ilog2(1024)              #=> 10
```

### Bit Manipulation

```ruby
say n.popcount               # Number of 1-bits in n
say n.msb                    # Index of most significant bit
say n.lsb                    # Index of least significant bit
say hamdist(a, b)            # Hamming distance between a and b
```

### Number Representation

```ruby
say 255.as_bin               # Binary: "11111111"
say 255.as_hex               # Hex: "ff"
say 1000000.commify          #=> "1,000,000"
say n.len                    # Number of decimal digits
say n.len(2)                 # Number of binary digits
```

### Arbitrary-Precision Patterns

```ruby
# Factorial digit count
say 1000!.len                # Number of decimal digits

# Last digits of a large Fibonacci
say fibmod(10**18, 10**9)

# Mersenne prime exponents
say (2..100 -> grep { .is_mersenne_prime })
#=> [2, 3, 5, 7, 13, 17, 19, 31, 61, 89]
```

---

## 24. Computing OEIS Sequences

Sidef is particularly useful for generating sequences for the [OEIS](https://oeis.org):

```ruby
say map(1..50, { .mu })
say map(1..50, { .mertens })
say map(1..50, { .tau })
say map(1..50, { .pi })
say map(1..50, { .liouville })
say map(1..50, { .sopfr })
say map(1..50, { .gpf })
say map(1..50, { .lpf })
say map(1..50, { .rad })
say map(1..50, { .phi })
say map(1..50, { .sigma })
say map(1..50, { .psi })
say map(1..50, { .esigma })
say map(1..50, { .usigma })
say map(1..50, { .isigma })

say 30.by { .is_abundant }
say 30.by { .is_odd && .is_abundant }
say 30.by { .is_semiprime }
say 30.by { .is_cyclic }
say 30.by { .is_fundamental }
say 30.by { .is_safe_prime }
say 30.by { .is_palindrome }
say 30.by { .is_palindrome(2) }

say 30.of { .fib }
say 30.of { .lucas }
say 20.of { .bell }
say 20.of { .factorial }
say 25.of { .primorial }

say map(1..30, { .ramanujan_tau })
say map(1..15, { .secant_number })
say map(1..15, { .tangent_number })

say 50.of { .squares_r(2) }
say 50.of { .squares_r(4) }

say 50.of {|n| polygonal(n, 3) }   # triangular numbers
say 50.of {|n| polygonal(n, 5) }   # pentagonal numbers
say 50.of {|n| polygonal(-n, 5) }  # second pentagonal numbers

say 8.of {|n| nth_prime(10**n) }
say 8.of {|n| nth_semiprime(10**n) }
say 8.of {|n| nth_squarefree(10**n) }
say 8.of {|n| prime_sum(10**n) }
```

### OEIS Autoload

[OEIS autoload](https://github.com/trizen/oeis-autoload) allows using OEIS sequence IDs directly as functions. Download `OEIS.sm` and `oeis.sf` from the repository, then:

```console
sidef oeis.sf 'A060881(n)' 0 9              # first 10 terms of A060881
sidef oeis.sf 'A033676(n)^2 + A033677(n)^2' 5 20
sidef oeis.sf 'sum(1..n, {|k| A000330(k) })'
```

Or include the library in a script:

```ruby
include OEIS
say map(1..10, {|k| A000330(k) })
```

---

## 25. Non-trivial OEIS Sequences

This section presents selected examples of non-trivial OEIS computations in Sidef.

### Generation of Pseudoprimes

**[A007011](https://oeis.org/A007011)**: Smallest pseudoprime to base 2 with $n$ prime factors.

```ruby
func A007011(n) {
    return nil if (n < 2)
    var x = pn_primorial(n)
    var y = 2*x
    loop {
        var arr = n.fermat_psp(2, x, y)
        return arr[0] if arr
        x = y+1
        y = 2*x
    }
}

for n in (2..100) { print(A007011(n), ", ") }
```

**[A180065](https://oeis.org/A180065)**: Smallest strong pseudoprime to base 2 with $n$ prime factors.

```ruby
func A180065(n) {
    return nil if (n < 2)
    var x = pn_primorial(n)
    var y = 2*x
    loop {
        var arr = n.strong_fermat_psp(2, x, y)
        return arr[0] if arr
        x = y+1
        y = 2*x
    }
}

for n in (2..100) { print(A180065(n), ", ") }
```

**[A006931](https://oeis.org/A006931)**: Least Carmichael number with $n$ prime factors.

```ruby
func A006931(n) {
    return nil if (n < 3)
    var x = pn_primorial(n+1)/2
    var y = 3*x
    loop {
        var arr = n.carmichael(x, y)
        return arr[0] if arr
        x = y+1
        y = 3*x
    }
}

for n in (3..100) { print(A006931(n), ", ") }
```

**[A356866](https://oeis.org/A356866)**: Smallest Carmichael number with $n$ prime factors that is also a strong pseudoprime to base 2.

```ruby
func A356866(n) {
    return nil if (n < 3)
    var x = pn_primorial(n+1)/2
    var y = 3*x
    loop {
        var arr = n.strong_fermat_carmichael(2, x, y)
        return arr[0] if arr
        x = y+1
        y = 3*x
    }
}

for n in (3..100) { print(A356866(n), ", ") }
```

### Numbers with n Prime Factors

**[A219018](https://oeis.org/A219018)**: Smallest $k > 1$ such that $k^n + 1$ has exactly $n$ distinct prime factors.

```ruby
func A219018(n) {
    for k in (1..Inf) {
        (k**n + 1).is_omega_prime(n) || next
        return k
    }
}

for n in (1..100) { print(A219018(n), ", ") }
```

**[A281940](https://oeis.org/A281940)**: Least $k$ such that $k^n + 1$ is the product of $n$ distinct primes.

```ruby
func A281940(n) {
    for k in (1..Inf) {
        (k**n + 1).is_squarefree_almost_prime(n) || next
        return k
    }
}

for n in (1..100) { print(A281940(n), ", ") }
```

**[A358863](https://oeis.org/A358863)**: Smallest $n$-gonal number with exactly $n$ prime factors (counted with multiplicity).

```ruby
func A358863(n) {
    for k in (1..Inf) {
        var v = polygonal(k, n)
        v.is_almost_prime(n) || next
        return v
    }
}

for n in (3..100) { print(A358863(n), ", ") }
```

### Inverse of Multiplicative Functions

**[A329660](https://oeis.org/A329660)**: Numbers $m$ such that $\sigma(m)$ is a Lucas number.

```ruby
for k in (1..1000) {
    var arr = k.lucas.inverse_sigma
    print(arr.join(", "), ", ") if arr
}
```

**[A291487](https://oeis.org/A291487)**: Smallest $k$ such that $\psi(k) = n!$, or 0 if no such $k$ exists.

```ruby
for k in (1..100) {
    print(k!.inverse_psi_min || 0, ", ")
}
```

### Misc Sequences

**[A323697](https://oeis.org/A323697)**: Primes $p$ such that the norm of the quadratic-field analog of $M_{p,\alpha}$, with $\alpha = 2 + \sqrt{2}$, is a rational prime.

```ruby
var alpha = (2 + sqrtQ(2))

each_prime(2, 1e6, {|p|
    var k = norm((alpha**p - 1) / (alpha-1))
    print(p, ", ") if k.is_prime
})
```

**[A037274](https://oeis.org/A037274)**: Home primes — start with $n$, concatenate prime factors, repeat until prime.

```ruby
func A037274(n) {
    return n if (n < 2)
    loop {
        n = Num(n.factor.join)
        break if n.is_prime
    }
    return n
}

for n in (1..100) { print(A037274(n), ", ") }
```

**[A139822](https://oeis.org/A139822)**: Denominator of BernoulliB($10^n$) via Von Staudt-Clausen theorem.

```ruby
func bernoulli_denominator(n) {
    return 1 if (n == 0)
    return 2 if (n == 1)
    return 1 if n.is_odd

    n.divisors.grep {|d| is_prime(d+1) }.prod {|d| d+1 }
}

for n in (0..10) { print(bernoulli_denominator(10**n), ", ") }
```

**[A323137](https://oeis.org/A323137)**: Largest prime that is both left-truncatable and right-truncatable in base $n$.

```ruby
func is_left_truncatable_prime(n, base) {
    for (var r = base; r < n; r *= base) {
        is_prime(n - r*idiv(n, r)) || return false
    }
    return true
}

func generate_from_prefix(p, base, digits) {
    var seq = [p]
    digits.each {|d|
        var n = (p*base + d)
        n.is_prime || next
        seq += __FUNC__(n, base, digits).grep {|k| is_left_truncatable_prime(k, base) }
    }
    return seq
}

func both_truncatable_primes(base) {
    primes(base-1).map {|p|
        generate_from_prefix(p, base, @(1 ..^ base))
    }.flat.sort
}

for base in (3..100) { print(both_truncatable_primes(base).max, ", ") }
```

---

## 26. Where Sidef Excels

### Identification of k-Almost Primes

The functions `is_almost_prime(k)`, `is_omega_prime(k)`, and `is_squarefree_almost_prime(k)` use efficient primorial-based trial division to quickly disprove that $n$ has a given number of prime factors. For $n$ to have at least $k$ prime factors without any factor ≤ B, we need $n > B^k$:

```ruby
n.is_almost_prime(k)                # true if Omega(n) == k
n.is_omega_prime(k)                 # true if omega(n) == k
n.is_squarefree_almost_prime(k)     # true if omega(n) == k and n is squarefree
```

The function internally calls `special_factor(n)` and terminates early if the composite part is too small to have the required number of factors. Enabling `Num!USE_CONJECTURES = true` makes this approximately 5x faster by using Pollard's rho to conjecture a larger factor bound.

### Factorization of Integers of Special Form

```ruby
var p = (primorial(557)*144 + 1)
var q = (primorial(557)*288 + 1)

assert(p.is_prov_prime)
assert(q.is_prov_prime)

say factor(p * q)        # takes 0.01s
say is_carmichael(p * q) # false (also takes 0.01s)
say phi(p * q)           # this also takes 0.01s
```

### Modular Binomial

```ruby
say binomialmod(1e20, 1e13, 20!)                        # 0.01s
say binomialmod(2**60 - 99, 1e5, next_prime(2**64))     # 0.15s
say binomialmod(4294967291 + 1, 1e5, 4294967291**2)     # 0.08s
say binomialmod(1e10, 1e4, (2**128 - 1)**2)             # 0.01s
say binomialmod(1e10, 1e5, 2**127 - 1)                  # 0.08s
```

---

## 27. Making Sidef Faster

### External Tool Integration

Enable these flags to delegate to highly optimized external tools:

```ruby
Num!USE_YAFU       = false      # true to use YAFU for factoring large integers
Num!USE_PFGW       = false      # true to use PFGW64 as a primality pretest
Num!USE_PARI_GP    = false      # true to use PARI/GP in several functions
Num!USE_FACTORDB   = false      # true to use factordb.com for factoring
Num!USE_PRIMESUM   = false      # true to use Kim Walisch's primesum
Num!USE_PRIMECOUNT = false      # true to use Kim Walisch's primecount
Num!USE_CONJECTURES = false     # true to enable conjectured (faster) bounds
Num!VERBOSE = true              # true to enable verbose/debug mode
```

These can also be set from the command line:

```console
sidef -N "VERBOSE=1; USE_FACTORDB=1;" script.sf
```

Example using FactorDB to retrieve a factorization:

```ruby
Num!VERBOSE = true
Num!USE_FACTORDB = true
say factor(43**97 + 1)
```

### Installing Math::Prime::Util

For maximum performance, install the GitHub version of Dana Jacobsen's Perl modules:

```console
cpanm --sudo -nv https://github.com/danaj/Math-Prime-Util-GMP/archive/refs/heads/master.zip
cpanm --sudo -nv https://github.com/danaj/Math-Prime-Util/archive/refs/heads/master.zip
```

---

## 28. Tips, Tricks, and Common Pitfalls

### Faster Primality Tests for Multiple Numbers

When multiple numbers need simultaneous primality verification, `all_prime(...)` is faster than individual `is_prime(n)` calls:

```ruby
all_prime(a, b)      # faster than: (is_prime(a) && is_prime(b))
```

If one term contains small prime factors, `all_prime(...)` returns immediately. It also performs a simultaneous strong Fermat test, terminating early on failure.

### Probabilistic Squarefree Checking

When full factorization is unnecessary, `is_prob_squarefree(n, B)` checks only for square factors $p^2$ with $p \leq B$:

```ruby
say is_prob_squarefree(2**512 - 1, 1e6)     # true  (probably squarefree)
say is_prob_squarefree(10**136 + 1, 1e3)    # false (definitely not squarefree)
```

If $n < B^3$ and the function returns `true`, then $n$ is definitely squarefree.

### Caching Factorizations

When reusing factorizations in hot loops:

```ruby
var cache = Hash()

func cached_factor(n) {
    cache{n} := n.factor
}

# Use factor_prod for multiplicative functions
func my_multiplicative_function(n) {
    n.factor_prod {|p, e|
        compute_for_prime_power(p, e)
    }
}
```

### Integer Overflow — There Isn't Any

Sidef handles arbitrary precision automatically:

```ruby
var n = 2**1000
say n.is_prime      # Checks primality of a 1000-bit number — no overflow
```

### Choosing the Right Function

```ruby
# For counting primes in range:
pi(a, b)            # Not: primes(a, b).len

# For compositeness:
is_composite(n)     # Not: !is_prime(n)

# For n-th prime:
nth_prime(n)        # Not: n.by {.is_prime}[-1]

# For divisor sums:
n.divisor_sum {|d| f(d) }   # Not: n.divisors.sum {|d| f(d) }
```

### Debugging Number Theory Code

```ruby
Num!VERBOSE = true

var n = (2**128 + 1)
say "Factoring: #{n}"
say factor(n)

var start = Time.now
var result = compute_something()
say "Computed in #{Time.now - start}s"
```

### Optimizing OEIS Submissions

```ruby
func generate_sequence(limit) {
    var results = []
    for n in (1..limit) {
        var value = compute_term(n)
        results.push(value)
        break if (value > threshold)    # early termination
    }
    return results
}

func format_for_oeis(seq, terms_per_line=10) {
    seq.each_slice(terms_per_line, {|slice|
        say slice.join(', ')
    })
}
```

---

## 29. Worked Problems

### Problem 1 — Primes in Arithmetic Progressions

**Problem:** Find all primes of the form $4k + 3$ up to 200.

```ruby
say primes(200).grep { _ % 4 == 3 }

# Alternative, using linear_forms_primes:
say linear_forms_primes(0, 50, [4, 3])
```

### Problem 2 — Goldbach's Conjecture

**Problem:** Verify that every even $n > 2$ up to 1000 is a sum of two primes.

```ruby
func goldbach(n) {
    primes(n/2).find {|p| (n - p).is_prime }
}

for n in (4..1000 `by` 2) {
    var p = goldbach(n)
    say p ? "#{n} = #{p} + #{n-p}" : "Goldbach fails at #{n}!"
}
```

### Problem 3 — Euler Product for ζ(2)

**Problem:** Numerically verify that $\prod_{p \text{ prime}} \frac{1}{1-p^{-2}} = \frac{\pi^2}{6}$.

```ruby
var product = primes(1e6).prod {|p| (1f / (1 - 1/p**2)) }
say product
say (Num.pi**2 / 6)    # Should be very close
```

### Problem 4 — Primitive Roots

**Problem:** Find all primitive roots modulo $p = 17$.

```ruby
var p = 17
var phi_p = (p - 1)

var primitive_roots = (^p).grep {|g| znorder(g, p) == phi_p }
say primitive_roots

say znprimroot(p)    #=> 3  (smallest primitive root)
```

### Problem 5 — Smooth Number Factorization

**Problem:** Factor $n = 2^{64} + 1$.

```ruby
var n = (2**64 + 1)
say n.pm1_factor(10000)
say flt_factor(n, 3, 1e6)
# Result includes 274177 and 67280421310721
```

### Problem 6 — Quadratic Congruences

**Problem:** Find all $x$ such that $x^2 \equiv 7 \pmod{55}$.

```ruby
say sqrtmod_all(7, 55)
say jacobi(7, 55)     # Check quadratic residuosity first
```

### Problem 7 — Aliquot Sequences (Amicable Chains)

**Problem:** Compute the aliquot sequence starting at 12496 and verify it is a 5-cycle.

```ruby
func aliquot_sequence(start, steps) {
    var seq = [start]
    var n = start
    steps.times {
        n = aliquot(n)
        seq.append(n)
        break if ((n == 0) || (n == seq[0]))
    }
    seq
}

say aliquot_sequence(12496, 10)
# Should return [12496, 14288, 15472, 14536, 14264, 12496]
```

### Problem 8 — Counting Squarefree Numbers

**Problem:** Count squarefree numbers ≤ $10^9$ and verify via the Möbius formula.

```ruby
say squarefree_count(10**9)

# Exact formula: Sum_{k=1..sqrt(n)} mu(k) * floor(n/k^2)
func squarefree_count_manual(n) {
    (1..isqrt(n)).sum {|k| mu(k) * (n // k**2) }
}

say squarefree_count_manual(10**6)
say squarefree_count(10**6)       # Should match
```

### Problem 9 — Large Prime Factorization

**Problem:** Factor a product of two 50-bit primes.

```ruby
func random_prime(bits) {
    loop {
        var n = irand(2**(bits-1), 2**bits - 1)
        return n if n.is_prime
    }
}

var p1 = random_prime(50)
var p2 = random_prime(50)
var n  = (p1 * p2)
say "n = #{n}"

say n.ecm_factor(50000)
say n.special_factor(2)
```

### Problem 10 — Verifying a Factorization

```ruby
func verify_factorization(n) {
    n.factor_exp.map_2d {|p, e| p**e }.prod == n
}

say verify_factorization(5040)      #=> true
```

---

## 30. Quick-Reference Cheat Sheet

### Primality

| Function | Description |
|---|---|
| `n.is_prime` | Baillie-PSW primality test |
| `n.is_prov_prime` | Rigorous provable primality |
| `n.is_strong_psp(b)` | Miller-Rabin to base b |
| `n.is_bpsw_prime` | Full Baillie-PSW |
| `n.is_mersenne_prime` | Mersenne prime test |
| `all_prime(a, b, ...)` | Batch primality test |
| `n.primality_pretest` | Fast small-factor detection |

### Primes

| Function | Description |
|---|---|
| `prime(n)` | n-th prime |
| `primes(a, b)` | Primes in [a, b] |
| `pi(n)` | Prime counting function π(n) |
| `prime_sum(n)` | Sum of primes ≤ n |
| `n.next_prime` | Next prime after n |
| `n.prev_prime` | Previous prime before n |
| `primorial(n)` | Product of primes ≤ n |
| `gpf(n)` | Greatest prime factor |
| `lpf(n)` | Least prime factor |

### Factorization

| Function | Description |
|---|---|
| `n.factor` | Full prime factorization |
| `n.factor_exp` | Factorization as [p,e] pairs |
| `n.prime_divisors` | Unique prime factors |
| `n.pm1_factor(B)` | Pollard p−1 |
| `n.pp1_factor(B)` | Williams p+1 |
| `n.ecm_factor(B)` | Elliptic curve method |
| `n.special_factor` | Auto multi-method |
| `gcd(a, b)` | Greatest common divisor |
| `gcdext(a, b)` | Extended GCD → (u, v, d) |
| `lcm(a, b)` | Least common multiple |

### Multiplicative Functions

| Function | Description |
|---|---|
| `phi(n)` / `euler_phi(n)` | Euler totient φ(n) |
| `sigma(n)` | Sum of divisors σ(n) |
| `sigma(n, k)` | Sum of k-th powers of divisors |
| `tau(n)` | Number of divisors τ(n) |
| `mu(n)` | Möbius function μ(n) |
| `omega(n)` | Distinct prime factors ω(n) |
| `bigomega(n)` | Prime factors with multiplicity Ω(n) |
| `liouville(n)` | Liouville function (−1)^Ω(n) |
| `psi(n)` | Dedekind psi ψ(n) |
| `sopfr(n)` | Sum of prime factors (with repetition) |
| `mertens(n)` | Mertens function M(n) |
| `lambda(n)` | Carmichael lambda λ(n) |

### Divisors

| Function | Description |
|---|---|
| `n.divisors` | All positive divisors |
| `n.udivisors` | Unitary divisors |
| `n.proper_divisors` | Divisors less than n |
| `n.prime_power_divisors` | Prime power divisors |
| `n.squarefree_divisors` | Squarefree divisors |
| `inverse_sigma(n)` | Solve σ(x) = n |
| `inverse_phi(n)` | Solve φ(x) = n |

### Modular Arithmetic

| Function | Description |
|---|---|
| `powmod(a, n, m)` | a^n mod m |
| `invmod(a, m)` | a⁻¹ mod m |
| `sqrtmod(a, m)` | √a mod m |
| `znorder(a, m)` | Multiplicative order of a mod m |
| `znlog(a, g, m)` | Discrete log: g^k ≡ a (mod m) |
| `znprimroot(n)` | Smallest primitive root mod n |
| `legendre(a, p)` | Legendre symbol (a\|p) |
| `kronecker(a, n)` | Kronecker symbol (a\|n) |
| `linear_congruence(n,r,m)` | Solve n*x ≡ r (mod m) |

### Sequences and Special Numbers

| Function | Description |
|---|---|
| `fib(n)` | n-th Fibonacci number |
| `lucas(n)` | n-th Lucas number |
| `bernoulli(n)` | n-th Bernoulli number |
| `catalan(n)` | n-th Catalan number |
| `bell(n)` | n-th Bell number |
| `polygonal(n, k)` | n-th k-gonal number |
| `squares_r(n, k)` | r_k(n): representations as k squares |
| `factorial(n)` | n! |
| `binomial(n, k)` | C(n,k) |

### Number Classification Predicates

| Predicate | True when |
|---|---|
| `n.is_prime` | n is prime |
| `n.is_composite` | n is composite |
| `n.is_squarefree` | No squared prime factor |
| `n.is_perfect` | σ(n) = 2n |
| `n.is_abundant` | σ(n) > 2n |
| `n.is_deficient` | σ(n) < 2n |
| `n.is_almost_prime(k)` | Ω(n) = k |
| `n.is_powerful(k)` | Every prime factor appears ≥ k times |
| `n.is_perfect_power` | n = a^k, k ≥ 2 |
| `n.is_palindrome(b)` | Palindrome in base b |
| `n.is_omega_prime(k)` | ω(n) = k |

### Sequence Generation — Memory Aid

- **`.by`** → filter (returns first n matching items)
- **`.of`** → map (returns first n transformed items)
- **`factor_prod`** → for multiplicative functions
- **`divisor_sum`** → for divisor-based sums
- **`is_*`** → boolean tests (return true/false)
- **`nth_*`** → find n-th element
- **`*_count`** → count elements
- **`*_sum`** → sum elements

---

## Appendix A: Common Recipes

### Sanity-Check a Factorization

```ruby
func verify_factorization(n) {
    n.factor_exp.map_2d {|p, e| p**e }.prod == n
}

say verify_factorization(5040)      #=> true
```

### Fast Primality Triage

```ruby
func triage(n) {
    return "not prime"              if (n < 2)
    return "prime"                  if (n.is_prime)
    return "perfect power, not prime" if (n.is_perfect_power)
    return "composite"
}

say triage(2**127 - 1)
```

### Modular Accumulation Loop

```ruby
var m = 1_000_000_007
var a = 2
var s = 0

for n in (1..1000) {
    s = addmod(s, powmod(a, n, m), m)
}
say s
```

### Find a Nearby Prime

```ruby
func next_prime_at_least(n) {
    n.is_prime ? n : n.next_prime
}

say next_prime_at_least(10**12)
```

### Möbius Inversion

```ruby
func moebius_invert(g, n) {
    n.divisors.sum {|d| mu(n/d) * g(d) }
}

say moebius_invert({|d| sigma(d) }, 12)   # Should be 12
```

### Generating Abundant Numbers Efficiently

```ruby
say 30.by { .is_abundant }          # first 30 abundant numbers
say 30.by { .is_odd && .is_abundant } # first 30 odd abundant numbers
```

---

## Appendix B: Performance Benchmarks

### Comparison with Other Systems

Selected benchmarks (approximate, hardware-dependent):

| Operation | Sidef | PARI/GP | Mathematica |
|---|---|---|---|
| factor(2^128+1) | 0.5s | 0.5s | 0.6s |
| pi(10^10) | 0.2s | 0.2s | 0.3s |
| binomialmod(10^10, 10^5, 2^127-1) | 0.08s | N/A | 0.15s |
| is_prime(2^1000+1) | 0.01s | 0.01s | 0.02s |

### Scaling Behavior

```ruby
# Prime counting scales well
pi(10**6)       # < 0.01s
pi(10**9)       # ~0.2s
pi(10**12)      # ~5s (with primecount)

# Factorization depends on number structure
factor(2**128 - 1)           # 0.01s (special form)
factor(nextprime(2**64)**2)  # 0.01s (small factors)

# k-Almost prime tests: ~10^6 per second for 100-digit n
n.is_almost_prime(3)
n.is_omega_prime(3)
```

---

## Appendix C: Further Reading and Resources

### Official Documentation

- **Sidef book**: [trizen.gitbook.io/sidef-lang](https://trizen.gitbook.io/sidef-lang/) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-book.pdf))
- **Advanced tutorial**: [SIDEF_ADVANCED_TUTORIAL.md](https://codeberg.org/trizen/sidef/src/branch/master/SIDEF_ADVANCED_GUIDE.md) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf))
- **Full Number class documentation**: [Sidef::Types::Number::Number](https://metacpan.org/pod/Sidef::Types::Number::Number) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-number-class-documentation.pdf))
- **Source code**: [codeberg.org/trizen/sidef](https://codeberg.org/trizen/sidef/src/master/lib/Sidef/Types/Number/Number.pm)

### Code Examples

- **Sidef scripts repository**: [github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)
- **OEIS autoload**: [github.com/trizen/oeis-autoload](https://github.com/trizen/oeis-autoload)
- **Special-purpose factorization**: [trizenx.blogspot.com](https://trizenx.blogspot.com/2019/08/special-purpose-factorization-algorithms.html)

### Mathematical References

- **OEIS**: [oeis.org](https://oeis.org) — Online Encyclopedia of Integer Sequences
- **Math::Prime::Util**: [github.com/danaj/Math-Prime-Util](https://github.com/danaj/Math-Prime-Util)
- **Max Alekseyev's papers**: [Inverse of multiplicative functions](https://cs.uwaterloo.ca/journals/JIS/VOL19/Alekseyev/alek5.html)

### Community

- **Questions and discussions**: [GitHub Discussions](https://github.com/trizen/sidef/discussions/categories/q-a)
- **Issue tracker**: [GitHub Issues](https://github.com/trizen/sidef/issues)

---

---

## 31. Sieve Algorithms

Sieves are among the oldest and most important tools in computational number theory. They systematically eliminate composite numbers to identify primes or compute arithmetic functions over entire ranges in bulk.

### Sieve of Eratosthenes

The classical sieve runs in $O(n \log \log n)$ time and $O(n)$ space. Sidef's `primes(n)` is backed by an optimized implementation, but the manual logic is instructive:

```ruby
func sieve_of_eratosthenes(n) {
    var composite = n.of { false }
    composite[0] = composite[1] = true

    for p in (2 .. isqrt(n)) {
        next if composite[p]
        var k = p*p
        while (k <= n) {
            composite[k] = true
            k += p
        }
    }

    (2..n).grep {|k| !composite[k] }
}

say sieve_of_eratosthenes(100)
say primes(10**7).len       # 664579 — Sidef's built-in is much faster
```

### Segmented Sieve

A segmented sieve reduces memory to $O(\sqrt{n})$ while sieving any range $[L, R]$, enabling prime generation near $10^{18}$:

```ruby
func segmented_sieve(L, R) {
    var small = primes(isqrt(R))
    var size  = (R - L + 1)
    var sieve = size.of { true }

    sieve[0] = false if (L <= 1)

    for p in (small) {
        var start = max(p*p, idiv_ceil(L, p) * p)
        var k = start - L
        while (k < size) {
            sieve[k] = false
            k += p
        }
    }

    (0 ..^ size).grep {|i| sieve[i] }.map {|i| L + i }
}

say segmented_sieve(10**15, 10**15 + 1000)   # primes near 10^15
```

### Linear Sieve (Sieve of Euler)

The linear sieve runs in strict $O(n)$ time by ensuring each composite is crossed out exactly once. It simultaneously builds a least prime factor (LPF) table, enabling $O(\log n)$ factorization for any integer up to $n$:

```ruby
func linear_sieve(n) {
    var lpf    = (n+1).of { 0 }
    var primes = []

    for i in (2..n) {
        if (lpf[i] == 0) {
            lpf[i] = i
            primes.push(i)
        }
        for p in (primes) {
            break if (p > lpf[i] || i*p > n)
            lpf[i*p] = p
        }
    }

    (primes, lpf)
}

var (ps, lpf) = linear_sieve(100)
say ps     # all primes up to 100

func fast_factor(n, lpf) {
    var factors = []
    while (n > 1) {
        factors.push(lpf[n])
        n //= lpf[n]
    }
    factors
}

say fast_factor(60, lpf)    #=> [2, 2, 3, 5]
```

### Sieve for Arithmetic Functions

Once the LPF table is built, any multiplicative function can be evaluated in bulk in $O(n)$:

```ruby
# Euler's totient via sieve
func sieve_phi(n) {
    var phi = (n+1).irange
    for i in (2..n) {
        next if (phi[i] != i)    # i is composite — already adjusted
        for j in (i .. n `by` i) {
            phi[j] -= phi[j] / i
        }
    }
    phi
}

say sieve_phi(50)[1..50]

# Divisor sum sigma(n) via sieve
func sieve_sigma(n) {
    var sigma = (n+1).of { 0 }
    for d in (1..n) {
        for k in (d .. n `by` d) {
            sigma[k] += d
        }
    }
    sigma
}

say sieve_sigma(50)[1..50]

# Count Omega(k) for all k in 1..n
func big_omega_sieve(n) {
    var om = (n+1).of { 0 }
    for p in (primes(n)) {
        var pk = p
        while (pk <= n) {
            for k in (pk .. n `by` pk) { om[k]++ }
            pk *= p
        }
    }
    om
}

var om = big_omega_sieve(100)
say (2..100).grep {|k| om[k] == 2 }    # semiprimes up to 100
```

### Lucy Hedgehog / Meissel-Lehmer Prime Counter

Counts $\pi(x)$ without enumerating primes, in $O(x^{3/4})$ time and $O(x^{1/2})$ space:

```ruby
func prime_counting_sieve(n) {
    var vals = []
    for k in (1 .. isqrt(n)) {
        vals.push(k)
        vals.push(n // k)
    }
    vals = vals.uniq.sort

    var S = Hash()
    vals.each {|v| S{v} = v - 1 }

    for p in (2 .. isqrt(n)) {
        next if (S{p} == S{p-1})    # p is composite
        var p2 = p*p
        vals.each {|v|
            break if (v < p2)
            S{v} -= (S{v // p} - S{p-1})
        }
    }

    S{n}
}

say prime_counting_sieve(10**6)    #=> 78498
say prime_counting_sieve(10**9)    #=> 50847534
say pi(10**9)                      # Sidef's built-in (uses same idea)
```

### Squarefree and k-Almost Prime Sieves

```ruby
# Sieve for squarefree numbers
func squarefree_sieve(n) {
    var is_sf = (n+1).of { true }
    for p in (primes(isqrt(n))) {
        var p2 = p*p; var k = p2
        while (k <= n) { is_sf[k] = false; k += p2 }
    }
    (1..n).grep {|k| is_sf[k] }
}

say squarefree_sieve(50).len    # count of squarefree numbers ≤ 50
say squarefree_count(50)        # Sidef's fast built-in

# Smallest prime factor sieve → immediate factorization
# After linear_sieve(N), factor any n ≤ N in O(log n):
var (_, LPF) = linear_sieve(10**6)
say fast_factor(831600, LPF)    # [2, 2, 2, 2, 3, 3, 5, 5, 7, 11] — instant
```

---

## 32. Primality Testing — Algorithm Deep Dives

### Trial Division with Wheel Factorization

A wheel of circumference $W = 2 \cdot 3 \cdot 5 = 30$ skips 22 out of every 30 candidates, testing only those coprime to $\{2, 3, 5\}$:

```ruby
func wheel30_factor(n) {
    for p in ([2, 3, 5]) {
        return [p] + __FUNC__(n // p) if (n %% p)
    }
    var increments = [4,2,4,2,4,6,2,6]
    var k = 7; var idx = 0
    while (k*k <= n) {
        if (n %% k) { return [k] + __FUNC__(n // k) }
        k += increments[idx]
        idx = (idx + 1) % 8
    }
    [n]
}

say wheel30_factor(5040)    #=> [2, 2, 2, 2, 3, 3, 5, 7]
```

### Fermat's Primality Test

Fermat's Little Theorem: if $n$ is prime, $a^{n-1} \equiv 1 \pmod{n}$ for all $\gcd(a,n)=1$. Composite numbers that pass for every base are Carmichael numbers:

```ruby
func fermat_test(n, a = 2) {
    return false if (n < 2 || n %% 2)
    powmod(a, n-1, n) == 1
}

say fermat_test(561)          #=> true  (561 = 3·11·17 is NOT prime!)
say is_carmichael(561)        #=> true
```

### Miller-Rabin Strong Pseudoprime Test

Write $n - 1 = 2^s \cdot d$ with $d$ odd. Then $n$ is a *strong pseudoprime* to base $a$ if $a^d \equiv 1$ or $a^{2^r d} \equiv -1 \pmod{n}$ for some $0 \leq r < s$:

```ruby
func miller_rabin(n, a) {
    return false if (n < 2)
    return true  if (n == 2 || n == 3)
    return false if (n %% 2)

    var d = n - 1; var s = 0
    while (d %% 2) { d //= 2; ++s }

    var x = powmod(a, d, n)
    return true if (x == 1 || x == n-1)

    (s - 1).times {
        x = mulmod(x, x, n)
        return true if (x == n-1)
    }
    false
}

# Deterministic for n < 3,215,031,751 using bases {2, 3, 5, 7}:
func miller_rabin_det(n) {
    [2, 3, 5, 7].all {|a| miller_rabin(n, a) }
}

say miller_rabin_det(999999937)     #=> true  (prime)
say miller_rabin_det(3215031751)    #=> false (composite)

# Sidef runs 20 random bases and BPSW for certainty:
say n.miller_rabin_random(20)
```

For $n < 3{,}317{,}044{,}064{,}679{,}887{,}385{,}961{,}981$, testing bases $\{2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37\}$ is deterministically sufficient.

### Baillie-PSW Primality Test (BPSW)

BPSW combines Miller-Rabin base 2 with a strong Lucas pseudoprime test. No composite is known to pass both. Sidef's `is_prime(n)` is exactly this test:

```ruby
func bpsw(n) {
    return false if (n < 2)
    return true  if (n == 2)
    return false if (n %% 2)
    return false if !n.primality_pretest

    return false if !n.is_strong_psp(2)      # Miller-Rabin base 2
    return n.is_strong_lucas_psp             # Strong Lucas (Selfridge params)
}

say bpsw(561)           #=> false  (Carmichael fails strong-base-2)
say bpsw(2**127 - 1)    #=> true   (Mersenne prime)
```

**Selfridge parameter selection:** Find the first $D$ in $\{5, -7, 9, -11, \ldots\}$ with Jacobi symbol $(D|n) = -1$. Set $P = 1$, $Q = (1 - D)/4$.

### AKS Primality Test

The 2002 Agrawal-Kayal-Saxena test is the first deterministic polynomial-time algorithm, running in $\tilde{O}(\log^6 n)$. Core idea: $n$ is prime iff $(x+a)^n \equiv x^n + a \pmod{x^r - 1, n}$ for sufficiently many $a$:

```ruby
# AKS condition check for small r and a (illustration only — full AKS needs more)
func aks_condition(n, r, a) {
    var lhs = PolyMod([a, 1], n)**n
    var rhs_c = n.of { 0 }
    rhs_c[0] = a % n
    rhs_c[n % r] = (rhs_c[n % r] + 1) % n
    lhs == PolyMod(rhs_c.reverse, n)
}

say aks_condition(7, 6, 1)    #=> true  (7 is prime)
say aks_condition(9, 8, 1)    #=> false (9 = 3^2)

# Sidef's built-in (very slow for large n):
say n.is_aks_prime
```

### ECPP — Elliptic Curve Primality Proving

Sidef's `is_prov_prime(n)` uses ECPP, producing a Primo-compatible certificate. Much faster than AKS in practice, handles hundreds of digits:

```ruby
say is_prov_prime(2**521 - 1)            # M_521 — provably prime
say is_prov_prime(next_prime(10**50))    # proves a 51-digit prime

var p = do {
    var n = irand(10**99, 10**100 - 1) | 1
    while (!n.is_prov_prime) { n += 2 }
    n
}
say p.is_prov_prime    #=> true
```

### Lucas Primality Test ($n-1$ Factorization)

If $n - 1$ is completely factored, then $n$ is prime iff there exists $a$ such that $a^{n-1} \equiv 1$ and $a^{(n-1)/q} \not\equiv 1 \pmod{n}$ for every prime $q \mid n-1$:

```ruby
func lucas_primality_test(n) {
    return false if (n < 2)
    return true  if (n == 2)
    return false if (n %% 2)

    var factors = (n - 1).factor.uniq
    for a in (2..n-1) {
        next if (powmod(a, n-1, n) != 1)
        if (factors.all {|q| powmod(a, (n-1)/q, n) != 1 }) {
            return true
        }
    }
    false
}

say lucas_primality_test(97)    #=> true
```

### Verifying Korselt's Criterion for Carmichael Numbers

A squarefree composite $n$ is Carmichael iff $(p-1) \mid (n-1)$ for every prime $p \mid n$:

```ruby
func is_carmichael_korselt(n) {
    n.is_composite &&
    n.is_squarefree &&
    n.prime_divisors.all {|p| (n - 1) %% (p - 1) }
}

say is_carmichael_korselt(561)     #=> true   (first Carmichael number)
say is_carmichael_korselt(1105)    #=> true
say is_carmichael_korselt(100)     #=> false
```

---

## 33. Factorization Algorithm Deep Dives

### Pollard's Rho Algorithm

Pollard's rho exploits the birthday paradox. It finds a factor of $n$ in expected $O(n^{1/4})$ time using a pseudo-random sequence $x_{i+1} = x_i^2 + c \pmod{n}$ and Floyd's cycle detection:

```ruby
func pollard_rho(n, c = 1) {
    return n if (n %% 2)
    var x = 2; var y = 2; var d = 1
    func f(x) { (mulmod(x, x, n) + c) % n }
    while (d == 1) {
        x = f(x); y = f(f(y))
        d = gcd((x - y).abs, n)
    }
    (d == n) ? nil : d
}

func rho_factor(n) {
    return [n] if n.is_prime
    var d; var c = 1
    while (!d) { d = pollard_rho(n, c); c++ }
    rho_factor(d) + rho_factor(n // d)
}

say rho_factor(8051)         #=> [83, 97]
say rho_factor(2**64 + 1)

# Sidef's Pollard-Brent (faster variant with batch GCD):
say (2**64 + 1).pbrent_factor(1000)
```

**Brent's improvement** accumulates products of GCDs in batches of size $m$, reducing GCD overhead by ~50×.

### Pollard's p−1 Method

Effective when $p - 1$ is $B$-smooth. Runs in $O(B \log B \log^2 n)$:

```ruby
func pollard_p1(n, B = 10000) {
    var a = 2
    for p in (primes(B)) {
        var pk = p
        while (pk * p <= B) { pk *= p }
        a = powmod(a, pk, n)
        var g = gcd(a - 1, n)
        return g if (g > 1 && g < n)
    }
    gcd(a - 1, n)
}

# n = 167 * 673; 673 - 1 = 672 = 2^5 * 3 * 7 (7-smooth)
say pollard_p1(112391, 100)    #=> 673

# Sidef's built-in:
say 112391.pm1_factor(100)
```

### Williams' p+1 Method

Analogous to p−1 but uses Lucas sequences; effective when $p + 1$ is smooth:

```ruby
# The key identity: V_{p+1}(P, 1) ≡ P (mod p) for prime p
func williams_pp1(n, B = 10000) {
    for P in ([2, 3, 5, 7]) {
        var v = P
        for p in (primes(B)) {
            var pk = p
            while (pk * p <= B) { pk *= p }
            v = lucasVmod(P, 1, pk, n)
            var g = gcd(v - P, n)
            return g if (g > 1 && g < n)
        }
    }
    1
}

say n.pp1_factor(10000)    # Sidef's built-in
```

### Lenstra's Elliptic Curve Method (ECM)

ECM generalizes p−1 to elliptic curves. For each curve the group order plays the role of $p - 1$; if it is $B_1$-smooth the factor is found. Expected time to find a factor $p$: $O(\exp(\sqrt{2 \ln p \ln \ln p}))$. This is the method of choice for factors up to ~60 digits:

```ruby
say n.ecm_factor(2000)            # Stage-1 bound B1 = 2000
say n.ecm_factor(50000)           # Larger bound
say n.ecm_factor(1_000_000, 100)  # B1=10^6, 100 random curves

say special_factor(2**256 - 1)    # ECM used automatically for large cofactors
```

### Fermat's Factorization Method

Exploits $n = a^2 - b^2 = (a-b)(a+b)$; effective when factors are close to $\sqrt{n}$:

```ruby
func fermat_factor(n) {
    var a = isqrt(n); a++ if (a*a < n)
    loop {
        var b2 = a*a - n
        var b  = isqrt(b2)
        return [a - b, a + b] if (b*b == b2)
        a++
    }
}

say fermat_factor(8633)      #=> [89, 97]  (factors near sqrt(8633) ≈ 92.9)
say 8633.fermat_factor(500)  # Sidef's built-in
```

### SQUFOF — Shanks' Square Forms Factorization

Operates on the principal form class group of $\mathbb{Q}(\sqrt{kn})$; runs in $O(n^{1/4})$ time with $O(1)$ storage — ideal for 15–25-digit semiprimes:

```ruby
say n.squfof_factor(10000)    # Sidef's built-in

var p = next_prime(10**9); var q = next_prime(p)
say (p * q).squfof_factor(100000)
```

### Cyclotomic Factorization

Algebraic identities from cyclotomic polynomials give explicit factors of $a^k \pm b^k$:

```ruby
# a^12 - 1 = Phi_1(a)*Phi_2(a)*Phi_3(a)*Phi_4(a)*Phi_6(a)*Phi_12(a)
func cyclo_factor(a, k) {
    k.divisors.map {|d| cyclotomic(d, a) }.grep {|v| v > 1 }
}

say cyclo_factor(2, 12)           # factors of 2^12 - 1 = 4095
say cyclotomic_factor(2**120 + 1) # Sidef's built-in
say special_factor(2**120 + 1)    # also uses cyclotomic internally
```

### Quadratic Sieve — Core Sieving Phase

The Quadratic Sieve finds $x, y$ with $x^2 \equiv y^2 \pmod{n}$, $x \not\equiv \pm y$, then $\gcd(x - y, n)$ is a factor. Complexity: $L[1/2, 1]$ — subexponential:

```ruby
# Sieve for B-smooth values of Q(x) = (x + floor(sqrt(n)))^2 - n
func qs_sieve(n, B, sieve_len = 10000) {
    var sq       = isqrt(n)
    var log_vals = sieve_len.of { 0.0 }

    for i in (0 ..^ sieve_len) {
        var qx = (sq + i)**2 - n
        log_vals[i] = log(qx.abs) if (qx != 0)
    }

    for p in (primes(B)) {
        sqrtmod_all(n, p).each {|r|
            var start = ((r - sq) % p + p) % p
            while (start < sieve_len) {
                log_vals[start] -= log(p)
                start += p
            }
        }
    }

    # Collect smooth candidates (log residual ≈ 0)
    (0 ..^ sieve_len).grep {|i| log_vals[i].abs < 5 }
                     .map   {|i| [sq + i, (sq + i)**2 - n] }
}

var cands = qs_sieve(90283, 30, 1000)
say "Smooth candidates: #{cands.len}"
cands.first(3).each {|x, qx| say "Q(#{x}) = #{qx}, factors: #{qx.abs.factor}" }

# Sidef's built-in quadratic sieve:
say n.qs_factor
```

### Number Field Sieve — Overview

GNFS is the fastest known algorithm for numbers > ~110 digits. Complexity: $L[1/3, (64/9)^{1/3}]$. Key phases: polynomial selection, two-sided sieving (algebraic and rational), sparse linear algebra (Lanczos/Wiedemann) over $\mathbb{F}_2$, square root in the number field:

```ruby
# Sidef delegates to YAFU which implements GNFS:
Num!USE_YAFU = true
say factor(10**100 + 267)    # delegates to YAFU's GNFS for large cofactors

# Optimal factor base size for GNFS:
func gnfs_factor_base(n) {
    var ln_n    = log(n)
    var ln_ln_n = log(ln_n)
    exp((ln_n * ln_ln_n / 3).sqrt).round
}

say gnfs_factor_base(10**100)    # ~500000 for a 100-digit number
```

---

## 34. Discrete Logarithms and Related Problems

### Baby-Step Giant-Step (BSGS)

BSGS solves $g^k \equiv h \pmod{m}$ in $O(\sqrt{m})$ time and space. Write $k = i\lceil\sqrt{m}\rceil - j$ and precompute baby steps as a hash table:

```ruby
func baby_giant(g, h, m) {
    var s  = isqrt(m).inc
    var tbl = Hash()
    var gj = 1
    for j in (0 ..^ s) { tbl{gj} = j; gj = mulmod(gj, g, m) }

    var gs_inv = invmod(powmod(g, s, m), m)
    var hk = h
    for i in (0 ..^ s) {
        return (i * s - tbl{hk}) % (m - 1) if tbl.has_key(hk)
        hk = mulmod(hk, gs_inv, m)
    }
    nil
}

say baby_giant(2, 22, 29)    #=> 7  (2^7 = 128 ≡ 22 mod 29)
say powmod(2, 7, 29)         #=> 22 ✓
say znlog(22, 2, 29)         # Sidef's built-in
```

### Pohlig-Hellman Algorithm

When the group order $q$ is smooth ($q = \prod p_i^{e_i}$), solve the DLP in each prime-power subgroup and reconstruct via CRT. Reduces an $O(\sqrt{q})$ problem to $O(\sum e_i \sqrt{p_i})$:

```ruby
# Solve DLP in subgroup of order p^e, reconstruct via CRT
func pohlig_hellman(g, h, p_mod, q) {
    var q_factors = q.factor_exp
    var residues  = []
    var moduli    = []

    for (pi, ei) in (q_factors) {
        var qi  = pi ** ei
        var gi  = powmod(g, q // qi, p_mod)
        var hi  = powmod(h, q // qi, p_mod)
        var gamma = powmod(gi, pi**(ei-1), p_mod)
        var x = 0

        for k in (0 ..^ ei) {
            var hk = mulmod(powmod(invmod(powmod(gi, x, p_mod), p_mod), 1, p_mod), hi, p_mod)
            hk = powmod(hk, pi**(ei-1-k), p_mod)
            var dk = baby_giant(gamma, hk, p_mod)
            x += dk * pi**k
        }

        residues.push(x % qi); moduli.push(qi)
    }

    chinese(*zip(residues, moduli).map {|r,m| Mod(r, m) }).lift
}

var p_val = 999999937
var g_val = znprimroot(p_val)
var k_val = 123456789
var h_val = powmod(g_val, k_val, p_val)
say znlog(h_val, g_val, p_val)    #=> 123456789
```

### Tonelli-Shanks: Square Roots Modulo Primes

Finds $x$ such that $x^2 \equiv a \pmod{p}$ when $(a|p) = 1$:

```ruby
func tonelli_shanks(a, p) {
    return 0 if (a % p == 0)
    return nil if (jacobi(a, p) != 1)

    var Q = p - 1; var S = 0
    while (Q %% 2) { Q //= 2; S++ }

    return powmod(a, (p+1)//4, p) if (S == 1)

    var z = 2; z++ while (jacobi(z, p) != -1)

    var M = S; var c = powmod(z, Q, p)
    var t = powmod(a, Q, p); var R = powmod(a, (Q+1)//2, p)

    loop {
        return R if (t == 1)
        var i = 1; var tmp = mulmod(t, t, p)
        while (tmp != 1) { tmp = mulmod(tmp, tmp, p); i++ }
        var b = powmod(c, powmod(2, M-i-1, p-1), p)
        M = i; c = mulmod(b, b, p); t = mulmod(t, c, p); R = mulmod(R, b, p)
    }
}

say tonelli_shanks(10, 13)    #=> 6
var x = sqrtmod(10, 13)
say powmod(x, 2, 13)          #=> 10 ✓  (Sidef's built-in)
```

### Hensel's Lemma: Lifting Modular Solutions

Lifts a solution $f(r) \equiv 0 \pmod{p}$ to a solution modulo $p^k$:

```ruby
func hensel_lift(f, df, r, p, k) {
    var pk = p; var x = r % p
    for _ in (1..k-1) {
        x = (x - f(x) * invmod(df(x) % pk, pk)) % (pk * p)
        pk *= p
    }
    x % pk
}

# x^2 ≡ 2 (mod 7) lifted to mod 7^5
var r0 = sqrtmod(2, 7)
say "mod 7:   #{r0}"
say "mod 7^5: #{hensel_lift({|x| x*x - 2}, {|x| 2*x}, r0, 7, 5)}"
```

---

## 35. Chinese Remainder Theorem — Extended Applications

### Basic CRT and Garner's Algorithm

```ruby
# Sidef's Mod-based CRT
say chinese(Mod(2, 3), Mod(3, 5), Mod(2, 7))
# x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7)  →  x ≡ 23 (mod 105)

# Garner's algorithm (numerically stable for large moduli)
func garner(residues, moduli) {
    var x = residues[0]; var M = moduli[0]
    for i in (1 ..^ residues.len) {
        var mi  = moduli[i]; var ai = residues[i]
        var inv = invmod(M % mi, mi)
        var t   = ((ai - x % mi) * inv) % mi
        x += t * M; M *= mi; x %= M
    }
    x
}

say garner([2, 3, 2], [3, 5, 7])    #=> 23
```

### CRT for Polynomial Evaluation and Multi-Modular Arithmetic

Computing a quantity modulo several primes and then reconstructing avoids expensive big-integer arithmetic in inner loops:

```ruby
# Multi-modular GCD: compute gcd(a, b) mod many small primes, then reconstruct
func poly_eval_mod(coeffs, x, m) {
    var result = 0; var xi = 1
    for c in (coeffs) {
        result = (result + c * xi) % m
        xi = (xi * x) % m
    }
    result
}

# Rational reconstruction: recover p/q from n ≡ p*q^(-1) (mod M)
func rational_reconstruct(n, M) {
    # Extended Euclidean on n and M; return first (r, s) with |r| < sqrt(M/2)
    var (r0, r1) = (M, n)
    var (s0, s1) = (0, 1)
    while (r1 * r1 * 2 > M) {
        var q = r0 // r1
        (r0, r1) = (r1, r0 - q * r1)
        (s0, s1) = (s1, s0 - q * s1)
    }
    as_frac(r1 / s1)
}
```

### CRT-Based RSA Acceleration (Garner Decryption)

CRT speeds up RSA private-key operations by a factor of ~4:

```ruby
func rsa_crt_decrypt(c, d, p, q) {
    var dp = d % (p - 1); var dq = d % (q - 1)
    var qp = invmod(q % p, p)    # q^(-1) mod p
    var mp = powmod(c % p, dp, p)
    var mq = powmod(c % q, dq, q)
    var h  = (qp * ((mp - mq) % p)) % p
    mq + h * q
}
```

---

## 36. Quadratic Reciprocity and Residue Theory

### Quadratic Reciprocity Law

For distinct odd primes $p$ and $q$:

$$\left(\frac{p}{q}\right)\left(\frac{q}{p}\right) = (-1)^{\frac{p-1}{2}\cdot\frac{q-1}{2}}$$

```ruby
# Verify for all prime pairs up to 100
var violations = 0
each_prime(3, 100, {|p|
    each_prime(p+2, 100, {|q|
        var lhs = legendre(p, q) * legendre(q, p)
        var exp = ((p-1)//2) * ((q-1)//2)
        var rhs = (exp %% 2) ? 1 : -1
        violations++ if (lhs != rhs)
    })
})
say "QR violations: #{violations}"    # 0

# Supplements:
# (−1|p) = (−1)^((p−1)/2)  →  −1 is a QR mod p iff p ≡ 1 (mod 4)
# ( 2|p) = (−1)^((p^2−1)/8) →  2 is a QR mod p iff p ≡ ±1 (mod 8)
say (primes(50).grep { legendre(-1, _) == 1 })    # primes ≡ 1 (mod 4)
say (primes(50).grep { legendre( 2, _) == 1 })    # primes ≡ ±1 (mod 8)
```

### Jacobi Symbol via Reciprocity

The Jacobi symbol $\left(\frac{a}{n}\right)$ generalizes Legendre to composite $n$ and can be computed in $O(\log^2 n)$ without factoring $n$:

```ruby
func jacobi_manual(a, n) {
    return 0 if (gcd(a, n) > 1)
    var result = 1; a %= n
    loop {
        while (a %% 2) {
            a //= 2
            result = -result if ((n % 8).is_any_of(3, 5))
        }
        (a, n) = (n, a)
        result = -result if (a % 4 == 3 && n % 4 == 3)
        a %= n
        break if (a == 0)
    }
    (n == 1) ? result : 0
}

say jacobi_manual(286, 559)    #=> 1  (but 559 = 13*43, so this doesn't mean 286 is QR)
say jacobi(286, 559)           # Sidef's built-in
```

### Euler's Factorization Method via Sum of Squares

If $n = a^2 + b^2 = c^2 + d^2$ in two distinct ways, then $n$ is composite:

```ruby
func euler_factorization(n) {
    var reps = sum_of_squares(n)
    return nil if (reps.len < 2)
    var (a, b) = reps[0]; var (c, d) = reps[1]
    [gcd(a+c, n), gcd(a-c, n), gcd(a+d, n), gcd(a-d, n)]
        .grep {|g| g > 1 && g < n }.uniq
}

say euler_factorization(221)    #=> [13, 17]  (221 = 5^2+14^2 = 10^2+11^2)
```

### Distribution of Quadratic Residues

```ruby
var p = 10007
var qr_count = (1..p-1).count {|a| legendre(a, p) == 1 }
say qr_count    #=> 5003 = (p-1)/2  (exactly half are QRs)

# Paley graph: connect i--j iff i-j is a QR mod p
# This gives a strongly regular graph with interesting properties
func paley_adjacency(p, i, j) {
    legendre((i - j) % p, p) == 1
}
```

---

## 37. The Prime Number Theorem and Analytic Methods

### The Prime Number Theorem

$\pi(x) \sim \frac{x}{\ln x}$ as $x \to \infty$; more precisely $\pi(x) \sim \text{Li}(x) = \int_2^x \frac{dt}{\ln t}$:

```ruby
for k in (1..10) {
    var x    = 10**k
    var pi_x = pi(x)
    var est1 = (x / log(x)).round
    var li_x = li(x).round
    say "pi(10^#{k}) = #{pi_x},  x/ln(x) ≈ #{est1},  Li(x) ≈ #{li_x}"
}
```

### Mertens' Theorems

```ruby
# Mertens 1: Sum_{p<=n} 1/p ≈ ln(ln(n)) + M_0  (M_0 ≈ 0.2615)
say primes(10000).sum {|p| 1.0/p }
say log(log(10000)) + 0.2615

# Mertens 3: Product_{p<=n} (1 - 1/p) ≈ e^(-gamma) / ln(n)
say primes(10000).prod {|p| 1 - 1.0/p }
say (exp(-Num.EulerGamma) / log(10000))
```

### Chebyshev Functions

```ruby
# theta(x) = Sum_{p<=x} ln(p)  ~  x
func chebyshev_theta(x) { primes(x).sum { log(_) } }

# psi(x)   = Sum_{p^k<=x} ln(p)  ~  x  (von Mangoldt sum)
func chebyshev_psi(x)   { (1..x).sum { exp_mangoldt(_).log } }

for k in (1..7) {
    var x = 10**k
    say "theta(10^#{k}) / 10^#{k} = #{chebyshev_theta(x) / x}"
}
```

### Riemann's Zeta Function

```ruby
local Num!PREC = 256
say zeta(2)                   # pi^2/6 ≈ 1.6449340668482264364...
say zeta(3)                   # Apery's constant
say zeta(0.5 + 14.134725i)    # Near first non-trivial zero

# Functional equation: zeta(s) = 2^s * pi^(s-1) * sin(pi*s/2) * Gamma(1-s) * zeta(1-s)
```

### Dirichlet's Theorem — Primes in Progressions

For $\gcd(a, q) = 1$, primes $p \equiv a \pmod{q}$ have density $1/\phi(q)$:

```ruby
func primes_by_residue(q, N = 10**6) {
    var counts = Hash()
    for a in (1..q-1) { counts{a} = 0 if (gcd(a,q) == 1) }
    primes(N).each {|p| var r = p % q; counts{r}++ if (counts.has_key(r)) }
    counts
}

primes_by_residue(10).each_kv {|r, c|
    say "#{c} primes ≡ #{r} (mod 10)"
}
# Each residue in {1,3,7,9} gets roughly 1/4 of all primes up to 10^6
```

### Legendre's Formula for π(x)

```ruby
# phi(x, a) = count of integers <= x not divisible by first a primes
func phi(x, a) {
    return x if (a == 0)
    phi(x, a-1) - phi(x // prime(a), a-1)
}

say phi(100, 4)         # not divisible by 2,3,5,7
say legendre_phi(100, 4)    # Sidef's built-in
```

### Hardy-Ramanujan: Distribution of Prime Factors

The number of distinct prime factors $\omega(n)$ is normally distributed around $\log \log n$:

```ruby
var x = 10**6
var sample = ((x-1000) .. (x+1000)).map { omega(_) }
say "Mean omega near 10^6:     #{sample.sum.to_f / sample.len}"
say "Expected log(log(10^6)):  #{log(log(x))}"
```

---

## 38. Smooth Numbers, Factor Bases, and Subexponential Factorization

### B-Smooth Numbers and the Dickman Function

A number is $B$-smooth if all prime factors are $\leq B$. The fraction of $B$-smooth numbers near $x$ is $\rho(u)$ where $u = \log x / \log B$ (Dickman's function, $\rho(u) \approx u^{-u}$ for large $u$):

```ruby
for B in ([7, 13, 23, 37, 53]) {
    say "#{B}-smooth numbers ≤ 10^6: #{B.smooth_count(10**6)}"
}

# 7-smooth (Hamming/regular) numbers: only prime factors in {2,3,5,7}
func hamming_numbers(n) {
    var h = [1]; var i = 0
    loop {
        break if (h[-1] > n)
        var nxt = [h[i]*2, h[i]*3, h[i]*5, h[i]*7].min
        h.push(nxt) if (nxt <= n && nxt != h[-1])
        i++
    }
    h.sort.grep { _ <= n }
}

say hamming_numbers(200)
```

### Optimal Factor Base Size

```ruby
func optimal_B(n) {
    var ln_n = log(n); var ln_ln_n = log(ln_n)
    exp(sqrt(ln_n * ln_ln_n) / 2).round
}

say optimal_B(10**50)     # ~1500 for QS on 50-digit number
say optimal_B(10**100)    # ~100000 for QS on 100-digit number

say primes(optimal_B(10**50)).len    # number of primes in the factor base
```

### Smooth Number Generation via Sieves

```ruby
# Find all (x, Q(x)) where Q(x) = (x + isqrt(n))^2 - n is B-smooth
func smooth_relations(n, B = 200, len = 5000) {
    var sq = isqrt(n)
    (0 ..^ len).map {|i|
        var x  = sq + i
        var qx = x*x - n
        var v  = qx.abs
        # trial-divide by factor base
        for p in (primes(B)) {
            while (v %% p) { v //= p }
        }
        v == 1 ? [x, qx] : nil
    }.grep { _ }
}

var rels = smooth_relations(90283, 30)
say "Found #{rels.len} smooth relations for n=90283 with B=30"
rels.each {|x, qx| say "  Q(#{x}) = #{qx} = #{qx.abs.factor}" }
```

---

## 39. p-Adic Arithmetic and Valuations

### p-Adic Valuation and the Ultrametric Inequality

$v_p(n)$ is the largest $k$ with $p^k \mid n$. The ultrametric property: $v_p(m + n) \geq \min(v_p(m), v_p(n))$:

```ruby
say valuation(360, 2)     #=> 3  (360 = 2^3 · 3^2 · 5)
say valuation(360, 3)     #=> 2
say valuation(360, 5)     #=> 1

# p-adic absolute value: |x|_p = p^(-v_p(x))
func p_adic_abs(x, p) { p**(-valuation(x, p)) }
say p_adic_abs(360, 2)    #=> 1/8

# Legendre's formula: v_p(n!) = Sum_{k>=1} floor(n/p^k)
func v_factorial(n, p) {
    var result = 0; var pk = p
    while (pk <= n) { result += n // pk; pk *= p }
    result
}

say v_factorial(100, 2)      #=> 97
say valuation(100!, 2)       # same
```

### Lifting the Exponent Lemma (LTE)

For odd prime $p$ with $p \mid a - b$, $p \nmid a$, $p \nmid b$:
$v_p(a^n - b^n) = v_p(a - b) + v_p(n)$

```ruby
func verify_lte(a, b, n, p) {
    var lhs = valuation(a**n - b**n, p)
    var rhs = valuation(a - b, p) + valuation(n, p)
    say "LTE: v_#{p}(#{a}^#{n}-#{b}^#{n}) = #{lhs}, formula = #{rhs}, match = #{lhs==rhs}"
}

verify_lte(5, 2, 12, 3)    # 3 | 5-2=3
verify_lte(7, 2,  8, 5)    # 5 | 7-2=5
```

### Kummer's Theorem — Valuation of Binomial Coefficients

$v_p\binom{m+n}{m}$ equals the number of carries when adding $m$ and $n$ in base $p$:

```ruby
func kummer_carries(m, n, p) {
    var carry = 0; var count = 0
    var dm = m.digits(p).reverse; var dn = n.digits(p).reverse
    for i in (0 .. max(dm.len, dn.len) - 1) {
        var s = (dm[i] // 0) + (dn[i] // 0) + carry
        carry = s // p; count += carry
    }
    count
}

var m = 10; var n = 15; var p = 2
say kummer_carries(m, n, p)
say valuation(binomial(m+n, m), p)    # same result
```

### Hensel's Lemma

Lifts a simple root of $f(x) \equiv 0 \pmod{p}$ to a root mod $p^k$:

```ruby
func hensel_lift(f, df, r, p, k) {
    var pk = p; var x = r % p
    for _ in (1..k-1) {
        x = (x - f(x) * invmod(df(x) % pk, pk)) % (pk * p)
        pk *= p
    }
    x % pk
}

func f(x)  { x*x - 2 }
func df(x) { 2*x }
var r0 = sqrtmod(2, 7)
say "x^2≡2 (mod 7^1): #{r0}"
say "x^2≡2 (mod 7^5): #{hensel_lift(f, df, r0, 7, 5)}"
```

---

## 40. Dirichlet Series and Multiplicative Structure

### Dirichlet Convolution Ring

The convolution $(f * g)(n) = \sum_{d \mid n} f(d) g(n/d)$ makes arithmetic functions into a ring under pointwise addition and Dirichlet multiplication:

```ruby
func dconv(n, f, g) { n.divisors.sum {|d| f(d) * g(n/d) } }

# Key identities:
# sigma  = phi * 1  →  sigma(n) = Sum_{d|n} phi(d)
say 20.of {|n| dconv(n+1, {.phi}, {1}) }
say map(1..20, { .sigma })    # should match

# tau = 1 * 1
say 20.of {|n| dconv(n+1, {1}, {1}) }
say map(1..20, { .tau })

# mu * 1 = epsilon
say 20.of {|n| dconv(n+1, {.mu}, {1}) }    # [1, 0, 0, ...]

# Sidef's built-in Dirichlet convolution:
say 30.of { .dirichlet_convolution({.phi}, {1}) }
```

### Möbius Inversion

If $g(n) = \sum_{d \mid n} f(d)$, then $f(n) = \sum_{d \mid n} \mu(n/d)\, g(d)$:

```ruby
func mobius_invert(g, n) {
    n.divisors.sum {|d| mu(n/d) * g(d) }
}

# Recover identity from sigma: mobius_invert(sigma)(n) should equal n
say 20.of {|n| mobius_invert({|d| sigma(d)}, n+1) }    # [1, 2, 3, ...]
```

### Euler Products and Verification

Every multiplicative $f$ has $\sum f(n)/n^s = \prod_p (1 + f(p)/p^s + f(p^2)/p^{2s} + \ldots)$:

```ruby
# Product_{p<=B} 1/(1 - 1/p^2) → zeta(2) = pi^2/6
say primes(1000).prod {|p| 1.0 / (1.0 - 1.0/p**2) }
say (Num.pi**2 / 6)

# Dirichlet series coefficients of phi(n)*mu(n)/n^2
# = Product_p (1 - 2/p^2 + 1/p^3)  (not multiplicative example)
```

### Dirichlet Hyperbola Method

Efficient computation of $\sum_{n \leq x} f(n)$ for multiplicative $f$ via the identity $\sum_{n \leq x} (f * g)(n) = \sum_{a \leq \sqrt x} f(a) G(x/a) + \sum_{b \leq \sqrt x} g(b) F(x/b) - F(\sqrt x) G(\sqrt x)$:

```ruby
# Compute Sum_{n<=x} tau(n) via hyperbola method: tau = 1 * 1
func tau_sum_hyperbola(x) {
    var sq = isqrt(x)
    2 * (1..sq).sum {|d| x // d } - sq**2
}

say tau_sum_hyperbola(1000)
say map(1..1000, { .tau }).sum    # should match
```

### Lambert Series and Partition Functions

```ruby
say 30.of { .partitions }    # [1,1,2,3,5,7,11,15,22,30,...]

func partitions_k_parts(n, k) is cached {
    return 1 if (k == 1 || n == k)
    return 0 if (k > n || k <= 0)
    __FUNC__(n-k, k) + __FUNC__(n-1, k-1)
}

# Hardy-Ramanujan asymptotic: p(n) ~ (1/4n*sqrt(3)) * exp(pi*sqrt(2n/3))
func hr_approx(n) {
    (1.0 / (4 * n * sqrt(3))) * exp(Num.pi * sqrt(2*n/3))
}

for n in ([10, 50, 100, 200]) {
    say "p(#{n}) = #{n.partitions},  HR ≈ #{hr_approx(n).round}"
}
```

---

## 41. Elliptic Curves in Number Theory

### Point Arithmetic on $E: y^2 = x^3 + ax + b \pmod{p}$

```ruby
func ec_add(P, Q, a, p) {
    return Q if (P == [nil, nil]); return P if (Q == [nil, nil])
    var (x1,y1) = P; var (x2,y2) = Q
    if (x1 == x2) {
        return [nil, nil] if (y1 != y2)
        var lam = (3*x1*x1 + a) * invmod(2*y1, p) % p
        var x3  = (lam*lam - 2*x1) % p
        return [x3, (lam*(x1-x3) - y1) % p]
    }
    var lam = (y2-y1) * invmod(x2-x1, p) % p
    var x3  = (lam*lam - x1 - x2) % p
    [x3, (lam*(x1-x3) - y1) % p]
}

func ec_mul(P, k, a, p) {
    var R = [nil, nil]; var Q = P
    while (k > 0) {
        R = ec_add(R, Q, a, p) if (k %% 2)
        Q = ec_add(Q, Q, a, p); k //= 2
    }
    R
}

var P = [5, 1]; var a = 2; var p = 17    # y^2 = x^3 + 2x + 2 over F_17
say ec_mul(P, 10, a, p)
say ec_mul(P, p+1, a, p)    # likely not identity unless #E | p+1
```

### Hasse's Theorem and Group Order

Hasse's theorem: $|\#E(\mathbb{F}_p) - (p+1)| \leq 2\sqrt{p}$:

```ruby
var p_ec = 101
var a_ec = 2; var b_ec = 3
# Count points by brute force (for small p)
var order = 1    # count point at infinity
for x in (0..p_ec-1) {
    var rhs = (x**3 + a_ec*x + b_ec) % p_ec
    order += 2 if (jacobi(rhs, p_ec) == 1)
    order += 1 if (rhs == 0)
}
say "Curve order: #{order}"
say "Hasse bound: [#{p_ec+1-2*isqrt(p_ec)}, #{p_ec+1+2*isqrt(p_ec)}]"
```

### Gaussian Prime Factorization and Sums of Squares

The factorization of primes in $\mathbb{Z}[i]$ (Gaussian integers) determines their representation as sums of squares:

```ruby
for p in (primes(50)) {
    if (p == 2) {
        say "2 = -i*(1+i)^2  (ramifies)"
    } elsif (p % 4 == 3) {
        say "#{p} ≡ 3 (mod 4)  stays prime in Z[i]"
    } else {
        var (a, b) = sum_of_squares(p)[0]
        say "#{p} ≡ 1 (mod 4)  splits: #{p} = (#{a}+#{b}i)(#{a}-#{b}i)"
    }
}
```

### Cyclotomic Fields and Primitive Roots of Unity

```ruby
for n in (1..15) { say "Phi_#{n}(x) = #{cyclotomic(n)}" }

# Verification: x^n - 1 = Product_{d|n} Phi_d(x)
func verify_cyclo(n, x) {
    (x**n - 1) == n.divisors.prod {|d| cyclotomic(d, x) }
}

say verify_cyclo(12, 5)    #=> true

# Ramanujan sum
say 30.of {|n| ramanujan_sum(n, 5) }     # c_5(n) for n = 0..29

# Identity: c_q(n) = mu(q/gcd(q,n)) * phi(q) / phi(q/gcd(q,n))
func ramanujan_formula(q, n) {
    var g = gcd(q, n); var qg = q // g
    mu(qg) * phi(q) // phi(qg)
}
```

---

## 42. Algebraic Number Theory Constructs

### Norms, Traces, and Conjugates

```ruby
# Gaussian integers: N(a+bi) = a^2 + b^2
var g = Gauss(3, 4)
say g.norm    #=> 25
say g.conj    # Gauss(3, -4)

# Quadratic fields: N(a + b*sqrt(d)) = a^2 - d*b^2
var q = Quadratic(3, 4, 5)    # 3 + 4*sqrt(5)
say q.norm    # 3^2 - 5*4^2 = 9 - 80 = -71
say q.conj    # 3 - 4*sqrt(5)

# Quaternion norm: N(a+bi+cj+dk) = a^2+b^2+c^2+d^2
var quat = Quaternion(1, 2, 3, 4)
say quat.norm    # 30
```

### Hurwitz Class Numbers

```ruby
say 50.of { .hclassno.nu }    # numerators of H(n)
say 50.of { .hclassno.de }    # denominators
say 50.of { 12 * .hclassno }  # 12*H(n) is always an integer (OEIS A005765)
```

### Ideal Theory in Z[i]

A Gaussian integer $\pi = a + bi$ is a Gaussian prime iff:
- $a = 0$, $|b|$ is an ordinary prime $\equiv 3 \pmod{4}$, or
- $b = 0$, $|a|$ is an ordinary prime $\equiv 3 \pmod{4}$, or
- $a^2 + b^2$ is an ordinary prime

```ruby
# Check and display Gaussian prime factorization
for n in (primes(30)) {
    say "#{n}: is_gaussian_prime = #{is_gaussian_prime(n, 0)}"
}

# Summing Gaussian integer norms
func gaussian_sigma(a, b) {
    Gauss(a, b).norm.divisors.sum
}
```

---

## 43. Cryptographic Applications

### RSA Key Generation and Operations

```ruby
func rsa_keygen(bits = 256) {
    var gen_p = { var x = irand(2**(bits-1), 2**bits-1) | 1; while (!x.is_prov_prime) { x+=2 }; x }
    var p = gen_p(); var q = do { var r = gen_p(); while (r==p) { r = gen_p() }; r }
    var n_rsa = p * q; var phi_rsa = (p-1)*(q-1)
    var e = 65537; die if (gcd(e, phi_rsa) != 1)
    var d = invmod(e, phi_rsa)
    (n_rsa, e, d, p, q)
}

var (n_rsa, e_rsa, d_rsa, p_rsa, q_rsa) = rsa_keygen(256)
var msg = 12345
say rsa_decrypt(rsa_encrypt(msg, e_rsa, n_rsa), d_rsa, n_rsa) == msg    #=> true

func rsa_encrypt(m, e, n) { powmod(m, e, n) }
func rsa_decrypt(c, d, n) { powmod(c, d, n) }
```

### Diffie-Hellman and Safe Primes

```ruby
# Safe prime: p = 2q+1, q prime (Sophie Germain prime)
func is_safe_prime(p) { p.is_prime && ((p-1)//2).is_prime }

say 10.by { .is_safe_prime }    # first 10 safe primes (built-in)

func dh_exchange(p, g) {
    var a_priv = irand(2, p-2); var a_pub = powmod(g, a_priv, p)
    var b_priv = irand(2, p-2); var b_pub = powmod(g, b_priv, p)
    var shared_a = powmod(b_pub, a_priv, p)
    var shared_b = powmod(a_pub, b_priv, p)
    say "DH shared secret match: #{shared_a == shared_b}"
    shared_a
}

var p_dh = next_prime(2**64)    # small for demo; use ≥2048-bit in practice
var g_dh = znprimroot(p_dh)
dh_exchange(p_dh, g_dh)
```

### Primorial Sieving Attacks

```ruby
# Trial division attack: estimate how many primes you need to guarantee
# finding a factor of n via trial division up to B
# Cost: O(pi(B)) divisions; succeeds if n has a factor <= B

func trial_division_attack(n, B) {
    for p in (primes(B)) {
        return p if (n %% p)
    }
    nil
}

# Primality of numbers of the form k*primorial(m) ± 1
say (primorial(100) + 1).is_prime    # Primorial prime?
say (primorial(100) - 1).is_prime    # Primorial prime?
```

### Number-Theoretic Hash Functions

```ruby
# Rabin's fingerprinting: polynomial hash mod a prime
func rabin_fingerprint(data, p = next_prime(2**61)) {
    var b = 257    # base
    data.chars.reduce(0, {|h, c| (h * b + c.ord) % p })
}

# Verify collision resistance: two different strings should (almost surely) hash differently
say rabin_fingerprint("hello world")
say rabin_fingerprint("hello world!")
```

---

## 44. Number-Theoretic Transforms and Convolutions

### NTT-Friendly Primes

An NTT-friendly prime $p = c \cdot 2^k + 1$ supports transforms of length $2^j$ for any $j \leq k$:

```ruby
# Find NTT primes with large power-of-2 factor in p-1
func find_ntt_primes(min_bits = 28) {
    var results = []
    for c in (1..200 `by` 2) {
        for k in (min_bits..30) {
            var p = c * 2**k + 1
            next if (!p.is_prime)
            results.push([p, k, c, znprimroot(p)])
            break if (results.len >= 5)
        }
    }
    results
}

say find_ntt_primes()
# Classic choices: 998244353 = 119*2^23+1, g=3
#                  469762049 = 7*2^26+1,   g=3

func ntt_root_of_unity(p, n) {
    powmod(znprimroot(p), (p-1)//n, p)
}

say ntt_root_of_unity(998244353, 8)    # primitive 8th root of unity mod p
```

### Polynomial Multiplication via NTT

```ruby
func poly_mult_ntt(f, g, p = 998244353) {
    var n = 1; while (n < f.len + g.len) { n *= 2 }

    # Zero-pad to length n
    var ff = f + (n - f.len).of { 0 }
    var gg = g + (n - g.len).of { 0 }

    # Pointwise multiply in NTT domain
    var omega = ntt_root_of_unity(p, n)
    var roots = n.of {|k| powmod(omega, k, p) }

    func evaluate(poly, roots) {
        n.of {|k| poly.map_with_index {|c, j| c * roots[(j*k)%n] % p }.sum % p }
    }

    var F = evaluate(ff, roots)
    var G = evaluate(gg, roots)
    var H = F.map_with_index {|v, i| v * G[i] % p }

    # Inverse NTT
    var inv_omega = invmod(omega, p)
    var inv_roots = n.of {|k| powmod(inv_omega, k, p) }
    var inv_n = invmod(n, p)

    evaluate(H, inv_roots).map {|v| v * inv_n % p }[0..f.len+g.len-2]
}

say poly_mult_ntt([1, 1, 1], [1, 1])    # (1+x+x^2)(1+x) = 1+2x+2x^2+x^3
```

### Dirichlet Convolution — Bulk Computation

```ruby
# Multiply two Dirichlet series coefficient arrays
func dirichlet_mult(a, b) {
    var n = min(a.len, b.len)
    n.of {|i|
        (i+1).divisors.sum {|d|
            d <= a.len && (i+1)//d <= b.len ? a[d-1] * b[(i+1)//d - 1] : 0
        }
    }
}

var mu_coeffs  = map(1..30, { .mu })
var one_coeffs = 30.of { 1 }
say dirichlet_mult(mu_coeffs, one_coeffs)    # should be [1, 0, 0, ..., 0] = epsilon
```

### Fast Polynomial GCD and Resultant

```ruby
# Polynomial GCD via pseudo-remainder sequences
func poly_pseudo_rem(f, g) {
    # Returns pseudo-remainder of f divided by g
    var d = f.len - g.len
    var lc = g[-1]
    var result = f.map { _ * lc**(d+1) }
    while (result.len >= g.len) {
        var ratio = result[-1].to_r / g[-1]
        var deg   = result.len - g.len
        for i in (0 ..^ g.len) { result[i+deg] -= ratio * g[i] }
        while (result.len > 0 && result[-1] == 0) { result.pop }
    }
    result
}

# Resultant via repeated pseudo-remainder
func resultant(f, g) {
    return g[-1]**(f.len-1) if (f.len == 1)
    var r = poly_pseudo_rem(f, g)
    return 0 if (r.is_empty)
    (-1)**(f.len-1) * (g.len-1) * resultant(g, r)
}
```

---

## 45. Computational Complexity in Number Theory

### Complexity of Core Problems

| Problem | Best Known Algorithm | Complexity |
|---|---|---|
| Primality (deterministic) | ECPP | $\tilde{O}(\log^5 n)$ |
| Primality (AKS) | AKS | $\tilde{O}(\log^6 n)$ |
| Factoring (general) | GNFS | $L_n[1/3,\, (64/9)^{1/3}]$ |
| Factoring (special form) | Cyclotomic / ECM | $L_n[1/2,\, 1]$ |
| Discrete log (mod p) | GNFS-DL | $L_p[1/3]$ |
| Discrete log (EC) | BSGS / Rho | $O(p^{1/2})$ |
| GCD | Binary GCD / Lehmer | $O(\log^2 n)$ |
| Modular inverse | Extended GCD | $O(\log^2 n)$ |
| Integer multiplication | Schönhage-Strassen | $O(n \log n \log\log n)$ |

where $L_n[s,c] = \exp\!\big((c+o(1))(\ln n)^s(\ln\ln n)^{1-s}\big)$ — sub-exponential for $0 < s < 1$.

```ruby
# Empirical timing comparison
func timed(&blk) {
    var t = Time.now; blk(); Time.now - t
}

for bits in (64, 128, 256, 512) {
    var n = irand(2**(bits-1), 2**bits-1)
    say "is_prime(#{bits}-bit): #{timed { is_prime(n) }}s"
}
```

### Karatsuba and Sub-Quadratic Integer Multiplication

```ruby
# Karatsuba: O(n^1.585) vs naive O(n^2)
func karatsuba(a, b, B = 10**9) {
    return a * b if (a < B || b < B)
    var a1 = a//B; var a0 = a%B
    var b1 = b//B; var b0 = b%B
    var z0 = karatsuba(a0, b0)
    var z2 = karatsuba(a1, b1)
    var z1 = karatsuba(a0+a1, b0+b1) - z0 - z2
    z2*B*B + z1*B + z0
}

# GMP (used internally by Sidef) implements Toom-Cook 3-way and
# Schönhage-Strassen FFT multiplication for very large integers
say (2**1000 * 3**700).len(10)    # number of digits — computed via GMP
```

### Binary GCD (Stein's Algorithm)

Avoids expensive division; only shifts and subtractions:

```ruby
func binary_gcd(a, b) {
    return b if (a == 0); return a if (b == 0)
    return 2 * binary_gcd(a>>1, b>>1) if (a %% 2 && b %% 2)
    return binary_gcd(a>>1, b) if (a %% 2)
    return binary_gcd(a, b>>1) if (b %% 2)
    binary_gcd((a-b).abs, min(a, b))
}

say binary_gcd(252, 105)    #=> 21
say gcd(252, 105)           # Sidef's GMP-backed built-in
```

### Fast Modular Exponentiation

Left-to-right binary method with Montgomery reduction:

```ruby
func fast_powmod(base, exp, mod) {
    var result = 1; base %= mod
    while (exp > 0) {
        result = mulmod(result, base, mod) if (exp %% 2)
        exp //= 2; base = mulmod(base, base, mod)
    }
    result
}

say fast_powmod(2, 10**18, 10**9+7)
say powmod(2, 10**18, 10**9+7)    # Sidef's GMP-backed built-in
```

### Space-Time Trade-Offs in Prime Counting

```ruby
# Method 1: direct sieve — O(x) space, O(x log log x) time
say primes(10**7).len                   # uses O(x) bits of memory

# Method 2: Lucy Hedgehog — O(sqrt(x)) space, O(x^{3/4}) time
say prime_counting_sieve(10**10)        # fits in RAM even for large x

# Method 3: Sidef's pi() — Meissel-Lehmer, O(x^{2/3}) time
say pi(10**12)                          # fast and memory-efficient
```

---

## 46. Advanced OEIS Techniques and Sequence Acceleration

### Euler Transform

Converts a sequence $a(n)$ (connected structures) to $b(n)$ (all multisets):

```ruby
func euler_transform(a, N) {
    var b = (N+1).of { 0 }; b[0] = 1
    for k in (1..N) {
        for m in (1 .. N//k) {
            for j in (m*k .. N) { b[j] += a[k-1] * b[j - m*k] }
        }
    }
    b[1..N]
}

# Rooted unlabeled trees (OEIS A000081):
var trees = [1]
for n in (2..15) {
    trees.push(euler_transform(trees, n-1)[-1])
}
say trees
```

### Berlekamp-Massey Algorithm

Finds the shortest linear recurrence for a given sequence:

```ruby
func berlekamp_massey(s) {
    var C = [1]; var B = [1]; var L = 0; var m = 1; var b = 1

    for n in (0 ..^ s.len) {
        var d = s[n]
        for i in (1..L) { d += C[i] * (s[n-i] // 0) }
        if (d == 0) { m++ }
        elsif (2*L <= n) {
            var T = C.clone; var coeff = d / b
            C = C.len.max(B.len+m).irange.map {|i| (C[i] // 0) - coeff*(B[i-m] // 0) }
            L = n+1-L; B = T; b = d; m = 1
        } else {
            var coeff = d/b
            C = C.len.max(B.len+m).irange.map {|i| (C[i] // 0) - coeff*(B[i-m] // 0) }
            m++
        }
    }
    C
}

say 20.of { .fib }.solve_rec_seq        # [1, 1] — Sidef's built-in
say berlekamp_massey(20.of { .fib })    # raw BM output
```

### Sequence Acceleration — Shanks Transformation

```ruby
func shanks_transform(seq) {
    (0 .. seq.len-3).map {|i|
        var (a0, a1, a2) = (seq[i], seq[i+1], seq[i+2])
        var d = a2 - 2*a1 + a0
        d != 0 ? a2 - (a2-a1)**2 / d : a2
    }
}

# Accelerate partial sums of 4*(1 - 1/3 + 1/5 - ...) → pi
var leibniz = 50.of {|n| 4 * sum(1..n+1, {|k| (-1.0)**(k+1) / (2*k-1) }) }
var acc1 = shanks_transform(leibniz)
var acc2 = shanks_transform(acc1)
say "Raw:     #{leibniz[-1]}"
say "1x accel: #{acc1[-1]}"
say "2x accel: #{acc2[-1]}"
say "True pi:  #{Num.pi}"
```

### Matrix Exponentiation for Linear Recurrences

```ruby
# Any k-th order linear recurrence computable in O(k^3 log n) via matrix power
func tribonacci_matrix(n) {
    var M = Matrix([1,1,1], [1,0,0], [0,1,0])
    var v = Matrix([[1],[0],[0]])
    ((M**n) * v)[0][0]
}

say 20.of { tribonacci_matrix(_) }
say Math.linear_rec([1,1,1], [0,0,1], 0, 19)     # same result

# Very large index — matrix exponentiation via Sidef:
say Math.linear_recmod([1,1,1], [0,0,1], 10**18, 10**9+7)
```

### Computing Large Sequence Terms Modulo a Prime

```ruby
var P = next_prime(10**9)

func catalan_mod(n, m) {
    binomialmod(2*n, n, m) * invmod(n+1, m) % m
}

say catalan_mod(10**6, P)    # C(10^6) mod P — fast

# Bell numbers mod p via the Bell triangle / Touchard's formula:
# B(n+1) = Sum_{k=0}^{n} C(n,k) * B(k)
func bell_mod(n, m) is cached {
    return 1 if (n == 0)
    (0..n-1).sum {|k| binomialmod(n-1, k, m) * bell_mod(k, m) % m } % m
}

say bell_mod(1000, P)
```

### Automatic Recurrence and Formula Detection

```ruby
func detect_pattern(terms, extra = 5) {
    # Try linear recurrence
    var rec = terms.solve_rec_seq
    if (rec) {
        say "Recurrence: #{rec}"
        say Math.linear_rec(rec, terms.first(rec.len), 0, terms.len+extra-1)
        return
    }
    # Try polynomial fit
    var poly = terms.solve_seq
    if (poly) {
        say "Polynomial: #{poly}"
        say (0..terms.len+extra-1).map {|n| poly.call(n) }
        return
    }
    say "No simple pattern found"
}

detect_pattern([0, 1, 4, 9, 16, 25, 36])         # x^2
detect_pattern([0, 1, 1, 2, 3, 5, 8, 13, 21])    # Fibonacci
detect_pattern([1, 3, 7, 15, 31, 63, 127])        # 2^n - 1

# OEIS lookup workflow:
# 1. Generate terms with Sidef
# 2. Paste into https://oeis.org/search
# 3. Study the matched sequence for formulas and links
# 4. Contribute new terms back to OEIS
```


---

*This document covers the `Sidef::Types::Number::Number` class and the core language features relevant to computational number theory — from elementary sieves and primality proofs to elliptic curves, p-adic arithmetic, and cryptographic applications. For additional functionality related to arrays, strings, and other types, consult the full Sidef documentation at [trizen.gitbook.io/sidef-lang](https://trizen.gitbook.io/sidef-lang/).*
