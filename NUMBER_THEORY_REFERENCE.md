# Computational Number Theory in Sidef

A comprehensive guide to using Sidef for computational number theory.

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Core Concepts](#core-concepts)
4. [Function Reference](#function-reference)
5. [Advanced Topics](#advanced-topics)
6. [Performance Optimization](#performance-optimization)
7. [Practical Examples](#practical-examples)

---

## Introduction

Sidef is a powerful programming language with extensive support for computational number theory. It provides over 1,000 numerical functions with performance comparable to PARI/GP and Mathematica, backed by the GMP, MPFR, and MPC libraries for arbitrary precision arithmetic.

### What Sidef Offers

- **Arbitrary precision arithmetic**: Big integers, rationals, floating-points
- **Specialized number types**: Gaussian integers, Quaternions, Quadratic integers
- **Advanced structures**: Matrices, polynomials, modular arithmetic
- **Extensive function library**: Primality testing, factorization, divisor functions, and more

### Installation

For installation instructions and basic language features, refer to the [beginner's tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md).

---

## Getting Started

### Starting the REPL

After installing Sidef, launch the interactive environment:

```console
$ sidef
Sidef 26.01, running on Linux, using Perl v5.42.0.
Type "help", "copyright" or "license" for more information.
>
```

### Quick Examples

```ruby
25.by { .is_prime }         # First 25 primes
30.of { .esigma }           # First 30 exponential sigma values
factor(2**128 + 1)          # Factor the 7th Fermat number
```

### Running Scripts

Create a file `script.sf` and run it:

```console
sidef script.sf
```

### Basic Syntax

```ruby
var x = 42              # Variable declaration
var y = x**3            # Exponentiation
say (x + y)             # Output result

# These are equivalent:
say 10.by { .is_composite }
say 10.by { is_composite(_) }
say 10.by {|n| n.is_composite }
say 10.by {|n| is_composite(n) }
```

---

## Core Concepts

### Generating Sequences

Sidef provides intuitive methods for sequence generation:

```ruby
# First n integers satisfying a condition
n.by {|k| ... }         # Returns integers where block is true

# First n function values
n.of {|k| ... }         # Applies function to 0..(n-1)

# Map over a range
map(a..b, {|k| ... })   # Maps function over range
{|k| ... }.map(a..b)    # Alternative syntax

# Infinite lazy sequences
Math.seq(initial_values, {|previous| next_value })
```

#### Examples

```ruby
# First 10 composite numbers
say 10.by { .is_composite }         #=> [4, 6, 8, 9, 10, 12, 14, 15, 16, 18]

# Values of φ(x) for 0..9
say 10.of { .phi }                  #=> [0, 1, 1, 2, 2, 4, 2, 6, 4, 6]

# Values of φ(x) for 20..30
say map(20..30, { .phi })           #=> [8, 12, 10, 22, 8, 20, 12, 18, 12, 28, 8]

# Infinite sequences
say Math.seq(2, {|a| a[-1].next_prime }).first(30)                  # Primes
say Math.seq(0, 1, {|a| a.last(2).sum }).first(30)                  # Fibonacci
```

### User-Defined Functions

```ruby
# Basic function definition
func function_name(a, b, c, ...) {
    # Function body
}

# Example: custom predicate
func my_condition(n) {
    n.is_composite && n.is_squarefree
}
say 10.by(my_condition)     # First 10 squarefree composites

# Multiplicative functions using factor_prod
func exponential_sigma(n, k=1) {
    n.factor_prod {|p, e|
        e.divisors.sum {|d| p**(d*k) }
    }
}

# Summation syntax
func harmonic(n) {
    sum(1..n, {|k| 1/k })
}

# Product syntax
func superfactorial(n) {
    prod(1..n, {|k| k! })
}

# Cached recursive functions
func a(n) is cached {
    return 1 if (n == 0)
    -sum(^n, {|k| a(k) * binomial(n+1, k)**2 }) / (n+1)**2
}
```

---

## Function Reference

### Primality Testing

```ruby
is_prime(n)                 # Probable prime (BPSW test)
is_prov_prime(n)            # Provable prime
is_composite(n)             # Composite test
is_gaussian_prime(a,b)      # Gaussian prime: a+bi

all_prime(...)              # Faster than multiple is_prime() calls
primality_pretest(n)        # Fast composite detection
```

### Integer Properties

```ruby
# Power tests
is_squarefree(n)            # No repeated prime factors
is_power(n, k)              # n = b^k for some b ≥ 1
is_power_of(n, b)           # n = b^k for some k ≥ 1
is_perfect_power(n)         # n = b^k for b,k > 1

# Structure tests
is_almost_prime(n, k)       # Ω(n) = k
is_omega_prime(n, k)        # ω(n) = k
is_powerful(n, k)           # k-powerful
is_powerfree(n, k)          # k-powerfree
is_squarefree_almost_prime(n, k)  # ω(n) = k and squarefree
```

### Factorization

```ruby
factor(n)                   # Prime factorization
divisors(n)                 # Positive divisors
udivisors(n)                # Unitary divisors
edivisors(n)                # Exponential divisors
idivisors(n)                # Infinitary divisors
bdivisors(n)                # Bi-unitary divisors

# Specialized divisor types
omega_prime_divisors(n, k)  # Divisors with ω(d) = k
almost_prime_divisors(n, k) # Divisors with Ω(d) = k
prime_power_divisors(n)     # Prime power divisors
square_divisors(n)          # Square divisors
squarefree_divisors(n)      # Squarefree divisors

k.smooth_divisors(n)        # k-smooth divisors
k.rough_divisors(n)         # k-rough divisors
k.power_divisors(n)         # k-th power divisors
k.powerfree_divisors(n)     # k-powerfree divisors
```

### Arithmetic Functions

```ruby
# Counting functions
omega(n, k=0)               # Distinct prime factors
Omega(n, k=0)               # Prime factors with multiplicity
tau(n)                      # Number of divisors

# Sum functions
sigma(n, k=1)               # Sum of k-th powers of divisors
psi(n, k=1)                 # Dedekind's Psi function
esigma(n)                   # Exponential sigma
usigma(n, k=1)              # Unitary sigma
isigma(n)                   # Infinitary sigma
bsigma(n)                   # Bi-unitary sigma

# Totient functions
phi(n)                      # Euler's totient
uphi(n)                     # Unitary totient
iphi(n)                     # Infinitary totient
jordan_totient(n, k=1)      # Jordan's J_k(n)

# Special functions
lambda(n)                   # Carmichael lambda
znorder(a, n)               # Multiplicative order of a mod n
mu(n)                       # Moebius function
mertens(n)                  # Mertens function
liouville(n)                # Liouville lambda
```

### Modular Arithmetic

```ruby
# Basic operations
invmod(a, m)                # Modular inverse
powmod(n, k, m)             # Modular exponentiation
sqrtmod(a, n)               # Modular square root
sqrtmod_all(a, n)           # All square roots mod n

# Advanced functions
chinese(Mod(a,m), Mod(b,n)) # Chinese Remainder Theorem
binomialmod(n, k, m)        # Binomial coefficient mod m
factorialmod(n, m)          # Factorial mod m
lucasUmod(P, Q, n, m)       # Lucas sequence mod m
lucasVmod(P, Q, n, m)       # Lucas sequence mod m
cyclotomicmod(n, x, m)      # Cyclotomic polynomial mod m
```

### Prime Counting and Generation

```ruby
# Counting
pi(n)                       # Prime count ≤ n
pi(a, b)                    # Prime count in [a,b]
composite_count(n)          # Composite count ≤ n
squarefree_count(n)         # Squarefree count ≤ n
prime_power_count(n)        # Prime power count ≤ n

k.almost_prime_count(a, b)  # k-almost primes in [a,b]
k.omega_prime_count(a, b)   # k-omega primes in [a,b]
k.powerful_count(a, b)      # k-powerful in [a,b]
k.smooth_count(n)           # k-smooth count ≤ n

# Generation
prime(n)                    # n-th prime
primes(a, b)                # Primes in [a,b]
composite(n)                # n-th composite
composites(a, b)            # Composites in [a,b]

nth_prime(n)                # n-th prime
nth_composite(n)            # n-th composite
nth_squarefree(n)           # n-th squarefree
nth_powerful(n)             # n-th powerful
nth_almost_prime(n, k)      # n-th k-almost prime
nth_omega_prime(n, k)       # n-th k-omega prime

k.almost_primes(a, b)       # Generate k-almost primes
k.omega_primes(a, b)        # Generate k-omega primes
k.powerful(a, b)            # Generate k-powerful
k.powerfree(a, b)           # Generate k-powerfree
```

### Summation Functions

```ruby
# Prime sums
prime_sum(a, b, k=1)        # Σ p^k for primes in [a,b]
composite_sum(a, b, k=1)    # Σ c^k for composites in [a,b]
squarefree_sum(a, b)        # Sum of squarefree in [a,b]

k.almost_prime_sum(a, b)    # Sum of k-almost primes
k.omega_prime_sum(a, b)     # Sum of k-omega primes
k.powerful_sum(a, b)        # Sum of k-powerful
```

### Pseudoprimes

```ruby
# Testing
is_carmichael(n)            # Carmichael number
is_lucas_carmichael(n)      # Lucas-Carmichael number
is_psp(n, B=2)              # Fermat pseudoprime base B
is_strong_psp(n, B=2)       # Strong pseudoprime base B
is_euler_psp(n, B=2)        # Euler pseudoprime base B
is_super_psp(n, B=2)        # Superpseudoprime base B
is_over_psp(n, B=2)         # Overpseudoprime base B
is_lucasU_psp(n, P=1, Q=-1) # Lucas U pseudoprime
is_lucasV_psp(n, P=1, Q=-1) # Lucas V pseudoprime
is_pell_psp(n)              # Pell pseudoprime

# Generation
k.fermat_psp(B, a, b)       # Generate in range [a,b]
k.strong_fermat_psp(B, a, b)
k.carmichael(a, b)
k.lucas_carmichael(a, b)
```

### Special Number Types

```ruby
# Factorials
factorial(n)                # n!
mfactorial(n, k)            # k-multi-factorial
falling_factorial(n, k)     # Falling factorial
rising_factorial(n, k)      # Rising factorial
subfactorial(n)             # Derangements
left_factorial(n)           # Sum of factorials
superfactorial(n)           # Product of factorials
hyperfactorial(n)           # Product of powers

# Binomial
binomial(n, k)              # Binomial coefficient

# Fibonacci and Lucas
fib(n, k=2)                 # k-th order Fibonacci
lucas(n)                    # Lucas numbers
lucasU(P, Q, n)             # Lucas U sequence
lucasV(P, Q, n)             # Lucas V sequence

# Primorials
primorial(n)                # Product of primes ≤ n
pn_primorial(n)             # Product of first n primes

# Polygonal and pyramidal
polygonal(n, k)             # k-gonal number
pyramidal(n, k)             # k-gonal pyramidal
centered_polygonal(n, k)    # Centered k-gonal
```

### Advanced Functions

```ruby
# Continued fractions
sqrt_cfrac(n)               # CF expansion of √n
sqrt_cfrac_period_len(n)    # Period length
convergents(n)              # CF convergents
rat_approx(n)               # Rational approximation

# Diophantine equations
solve_pell(n)               # Pell's equation x²-ny²=1
sum_of_squares(n)           # Representations as x²+y²
diff_of_squares(n)          # Representations as x²-y²

# Special sums
harmonic(n, k=1)            # Harmonic numbers
faulhaber_sum(n, k)         # Power sum formula
geometric_sum(n, r)         # Geometric series

# Number representation
digits(n, base=10)          # Digit array
digits_sum(n, base=10)      # Digit sum
digital_root(n)             # Digital root
flip(n, b=10)               # Reverse digits

# Bernoulli and Euler
bernoulli(n)                # Bernoulli number
bernoulli(n, x)             # Bernoulli polynomial
euler(n)                    # Euler number
euler(n, x)                 # Euler polynomial

# Polynomials
cyclotomic(n)               # Cyclotomic polynomial
cyclotomic(n, x)            # Evaluated at x
```

### Inverse Functions

```ruby
# Based on Max Alekseyev's methods
inverse_phi(n)              # Values x where φ(x) = n
inverse_psi(n)              # Values x where ψ(x) = n
inverse_sigma(n)            # Values x where σ(x) = n
inverse_uphi(n)             # Values x where uphi(x) = n
inverse_usigma(n)           # Values x where usigma(x) = n

# Counting and extrema
inverse_sigma_len(n)        # Number of solutions
inverse_sigma_min(n)        # Minimum solution
inverse_sigma_max(n)        # Maximum solution
inverse_phi_len(n)          # Number of solutions
inverse_phi_min(n)          # Minimum solution
inverse_phi_max(n)          # Maximum solution
```

---

## Advanced Topics

### Built-in Classes

#### Mod Class

Modular arithmetic with automatic reduction:

```ruby
var a = Mod(13, 97)
say a**42                   # Mod(85, 97)
say 42*a                    # Mod(61, 97)
say chinese(Mod(43, 19), Mod(13, 41))  # CRT
```

#### Polynomial Class

```ruby
say Poly(5)                 # Monomial: x^5
say Poly([1,2,3,4])         # x³ + 2x² + 3x + 4
say Poly(5 => 3, 2 => 10)   # 3x^5 + 10x²
```

#### PolyMod Class

Modular polynomials:

```ruby
var a = PolyMod([13,4,51], 43)
var b = PolyMod([5,0,-11], 43)

say a*b         # 22x⁴ + 20x³ + 26x² + 42x + 41 (mod 43)
say a-b         # 8x² + 4x + 19 (mod 43)
say [a.divmod(b)].join(' and ')
```

#### Gauss Class

Gaussian integers (a + bi):

```ruby
say Gauss(3,4)**100
say Mod(Gauss(3,4), 1000001)**100

var a = Gauss(17,19)
var b = Gauss(43,97)

say (a + b)     # Gauss(60, 116)
say (a * b)     # Gauss(-1112, 2466)
say (a / b)     # Gauss(99/433, -32/433)
```

#### Quadratic Class

Quadratic integers (a + b√w):

```ruby
var x = Quadratic(3, 4, 5)      # 3 + 4√5
var y = Quadratic(6, 1, 2)      # 6 + √2

say x**10               # Quadratic(29578174649, 13203129720, 5)
say x.powmod(100, 97)   # Quadratic(83, 42, 5)
```

#### Quaternion Class

Quaternion integers (a + bi + cj + dk):

```ruby
var a = Quaternion(1,2,3,4)
var b = Quaternion(5,6,7,8)

say (a * b)         # Quaternion(-60, 12, 30, 24)
say a**5            # Quaternion(3916, 1112, 1668, 2224)
say a.powmod(43, 97)
```

#### Matrix Class

```ruby
var A = Matrix(
    [2, -3,  1],
    [1, -2, -2],
    [3, -4,  1],
)

say (A + B)             # Matrix addition
say (A * B)             # Matrix multiplication
say A**20               # Matrix exponentiation
say A**-1               # Matrix inverse
say A.powmod(43, 97)    # Modular exponentiation
say A.det               # Determinant
say A.solve([1,2,3])    # Linear system
```

### Sequence Analysis

#### Finding Closed Forms

Polynomial interpolation for sequences:

```ruby
say [0, 1, 4, 9, 16, 25, 36, 49, 64, 81].solve_seq
# x²

say [0, 1, 33, 276, 1300, 4425, 12201].solve_seq
# (x^6)/6 + (x^5)/2 + (5x^4)/12 - (x²)/12
```

#### Finding Linear Recurrences

```ruby
say [0, 0, 1, 1, 2, 4, 7, 13, 24, 44, 81, 149].solve_rec_seq
# [1, 1, 1] - Tribonacci signature

say [0, 1, 9, 36, 100, 225, 441, 784, 1296, 2025].solve_rec_seq
# [5, -10, 10, -5, 1]
```

#### Computing Recurrence Terms

```ruby
# Generate terms in a range
say Math.linear_rec([1, 1, 1], [0, 0, 1], 0, 20)

# Compute n-th term only
say Math.linear_rec([1, 1, 1], [0, 0, 1], 1000)

# Modular computation
say Math.linear_recmod([5, -10, 10, -5, 1], [0, 1, 9, 36, 100], 2**128, 10**10)
```

### Integer Factorization

Sidef includes sophisticated factorization methods:

```ruby
special_factor(n, effort=1)     # Combined special-purpose methods
```

#### Individual Methods

```ruby
n.trial_factor(limit)           # Trial division
n.fermat_factor(k=1e4)          # Fermat's method
n.holf_factor(tries=1e4)        # HOLF method
n.sophie_germain_factor         # Sophie Germain method
n.dop_factor(tries)             # Difference of powers
n.cop_factor(tries)             # Congruence of powers
n.cyclotomic_factor(bases...)   # Cyclotomic method
n.ecm_factor(B1, curves)        # Elliptic curve method
n.fib_factor(upto)              # Fibonacci method
n.flt_factor(base, tries)       # FLT method
n.miller_factor(tries)          # Miller's method
n.lucas_factor(j, tries)        # Lucas method
n.prho_factor(tries)            # Pollard's rho
n.pbrent_factor(tries)          # Pollard-Brent
n.pell_factor(tries)            # Pell method
n.pm1_factor(B)                 # Pollard's p-1
n.pp1_factor(B)                 # Williams' p+1
n.chebyshev_factor(B, x)        # Chebyshev method
n.squfof_factor(tries)          # SQUFOF
n.qs_factor                     # Quadratic sieve
```

#### Examples

```ruby
# These factor very quickly
say special_factor(lucas(480))
say special_factor(fibonacci(480))
say special_factor(2**512 - 1)
say special_factor((3**120 + 1) * (5**240 - 1))
```

### OEIS Integration

#### Computing OEIS Sequences

Sidef excels at generating sequences for OEIS:

```ruby
say map(1..50, { .mu })             # Moebius
say map(1..50, { .tau })            # Divisor count
say map(1..50, { .pi })             # Prime counting

say 30.by { .is_abundant }          # Abundant numbers
say 30.by { .is_semiprime }         # Semiprimes
say 30.by { .is_cyclic }            # Cyclic numbers

say 30.of { .fib }                  # Fibonacci
say 30.of { .lucas }                # Lucas
say 30.of { .factorial }            # Factorials
say 30.of { .primorial }            # Primorials
```

#### OEIS Autoload

The [OEIS autoload](https://github.com/trizen/oeis-autoload) tool allows using OEIS sequences as functions:

```console
# Download OEIS.sm and oeis.sf
sidef oeis.sf 'A060881(n)' 0 9
sidef oeis.sf 'A033676(n)^2 + A033677(n)^2'
sidef oeis.sf 'sum(1..n, {|k| A000330(k) })'
```

In scripts:

```ruby
include OEIS
say map(1..10, {|k| A000330(k) })
```

---

## Performance Optimization

### Configuration Flags

Enable external tools for better performance:

```ruby
Num!USE_YAFU       = false      # YAFU for factoring
Num!USE_PFGW       = false      # PFGW64 for primality
Num!USE_PARI_GP    = false      # PARI/GP integration
Num!USE_FACTORDB   = false      # FactorDB lookup
Num!USE_PRIMESUM   = false      # primesum tool
Num!USE_PRIMECOUNT = false      # primecount tool
Num!VERBOSE        = false      # Debug output
Num!USE_CONJECTURES = false     # Conjectured bounds
```

Command-line usage:

```console
sidef -N "VERBOSE=1; USE_FACTORDB=1;" script.sf
```

### Performance Tips

#### Primality Testing

```ruby
# Faster than individual tests
all_prime(a, b, c)      # vs is_prime(a) && is_prime(b) && is_prime(c)

# Fast pretest
primality_pretest(n)    # Quick composite detection
```

#### Squarefree Checking

```ruby
# Probabilistic test (fast)
is_prob_squarefree(n, B)    # Check for square factors ≤ B

# If n < B³ and returns true, n is definitely squarefree
say is_prob_squarefree(2**512 - 1, 1e6)     # true (probably)
say is_prob_squarefree(10**136 + 1, 1e3)    # false (definitely not)
```

#### Special Forms

Functions are optimized for special-form integers:

```ruby
var p = (primorial(557)*144 + 1)
var q = (primorial(557)*288 + 1)

say factor(p * q)           # Very fast
say phi(p * q)              # Very fast
```

### Where Sidef Excels

#### k-Almost Prime Identification

Efficient trial division with conjectured bounds:

```ruby
# Very fast even for large n
n.is_almost_prime(k)                # Ω(n) == k
n.is_omega_prime(k)                 # ω(n) == k
n.is_squarefree_almost_prime(k)     # Both
```

#### Modular Binomial

Highly optimized:

```ruby
say binomialmod(1e20, 1e13, 20!)                    # 0.01s
say binomialmod(2**60 - 99, 1e5, next_prime(2**64)) # 0.15s
say binomialmod(1e10, 1e5, 2**127 - 1)              # 0.08s
```

#### Sum of Squares

Fast algorithms for k = {2, 4, 6, 8, 10}:

```ruby
say squares_r(2**128 + 1, 2)       # 0.49s
say squares_r(2**128 - 1, 4)       # 0.01s
say squares_r(2**128 - 1, 6)       # 0.01s
say squares_r(2**128 - 1, 10)      # 0.01s
```

---

## Practical Examples

### Example 1: Finding Special Pseudoprimes

Smallest pseudoprime to base 2 with n prime factors:

```ruby
func smallest_pseudoprime(n) {
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

for n in (2..100) {
    print(smallest_pseudoprime(n), ", ")
}
```

### Example 2: Numbers with n Prime Factors

Smallest k where k^n + 1 has exactly n distinct prime factors:

```ruby
func A281940(n) {
    for k in (1..Inf) {
        var v = (k**n + 1)
        v.is_squarefree_almost_prime(n) || next
        return k
    }
}

for n in (1..100) { print(A281940(n), ", ") }
```

### Example 3: Home Primes

```ruby
func home_prime(n) {
    return n if (n < 2)
    loop {
        n = Num(n.factor.join)
        break if n.is_prime
    }
    return n
}

for n in (1..100) { print(home_prime(n), ", ") }
```

### Example 4: Left and Right Truncatable Primes

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
        seq += __FUNC__(n, base, digits).grep {|k|
            is_left_truncatable_prime(k, base)
        }
    }
    return seq
}

func both_truncatable_primes(base) {
    primes(base-1).map {|p|
        generate_from_prefix(p, base, @(1 ..^ base))
    }.flat.sort
}

for base in (3..20) {
    say "Base #{base}: #{both_truncatable_primes(base).max}"
}
```

### Example 5: Computing Class Numbers

```ruby
say 50.of { .hclassno.nu }      # Numerators
say 50.of { .hclassno.de }      # Denominators
say 50.of { 12 * .hclassno }    # Scaled values
```

### Example 6: Ramanujan Tau Function

```ruby
say map(1..30, { .ramanujan_tau })
```

### Example 7: Polygonal and Pyramidal Numbers

```ruby
# Triangular numbers
say 30.of {|n| polygonal(n, 3) }

# Pentagonal numbers
say 30.of {|n| polygonal(n, 5) }

# Check if number is polygonal
say 30.by { .is_polygonal(5) }      # Pentagonal numbers

# Pyramidal numbers
say 30.of {|n| pyramidal(n, 3) }    # Tetrahedral
say 30.of {|n| pyramidal(n, 5) }    # Pentagonal pyramidal

# Centered polygonal
say 30.of {|n| centered_polygonal(n, 3) }   # Centered triangular
say 30.of {|n| centered_polygonal(n, 6) }   # Centered hexagonal
```

### Example 8: Working with Large Numbers

```ruby
# Continued fractions
say sqrt_cfrac(61)                  # CF expansion of √61
say sqrt_cfrac_period_len(61)       # Period length

# Pell equation solutions
var (x, y) = solve_pell(61)
say "x² - 61y² = 1: x=#{x}, y=#{y}"

# Convergents for rational approximation
say 10.of { rat_approx(Math.pi) }
```

### Example 9: Multiplicative Function Inverses

```ruby
# Find all n where σ(n) = 252
var n = 252
say "σ⁻¹(252) = #{inverse_sigma(n)}"

# Find all n where φ(n) = 252
say "φ⁻¹(252) = #{inverse_phi(n)}"

# Find all n where ψ(n) = 252
say "ψ⁻¹(252) = #{inverse_psi(n)}"

# Efficient queries
say "Min φ⁻¹(15!) = #{inverse_phi_min(15!)}"
say "Max φ⁻¹(15!) = #{inverse_phi_max(15!)}"
say "Count φ⁻¹(15!) = #{inverse_phi_len(15!)}"
```

### Example 10: Dirichlet Convolution

```ruby
# Dirichlet convolution of two functions
func dirichlet_conv(n, f, g) {
    n.divisor_sum {|d| f(d) * g(n/d) }
}

# Identity: σ = φ * 1
say 30.of {|n|
    n.dirichlet_convolution({.phi}, {1})
}

# Identity: τ * μ = 1
say 30.of {|n|
    n.dirichlet_convolution({.tau}, {.mu})
}

# Custom convolutions
say 30.of { .dirichlet_convolution({.mu}, {_}) }
say 30.of { .dirichlet_convolution({.sigma}, {.phi}) }
```

### Example 11: Smooth and Rough Numbers

```ruby
# Count 13-smooth numbers ≤ 10^n
for n in (0..10) {
    print(13.smooth_count(10**n), ", ")
}

# Generate smooth numbers in range
say 5.smooth_divisors(720)
say 7.rough_divisors(720)

# Smooth and rough parts
say 15.of {|n| 3.smooth_part(n!) }
say 15.of {|n| 3.rough_part(n!) }
```

### Example 12: Cyclotomic Polynomials

```ruby
# Generate cyclotomic polynomials
for n in (1..10) {
    say "Φ_#{n}(x) = #{cyclotomic(n)}"
}

# Evaluate at specific points
say cyclotomic(12, 2)           # Φ₁₂(2)
say cyclotomic(30, -1)          # Φ₃₀(-1)

# Modular evaluation
say cyclotomicmod(100, 3, 1000) # Φ₁₀₀(3) mod 1000
```

### Example 13: Lucas Sequences

```ruby
# Lucas U and V sequences
say 25.of {|n| lucasU(1, -1, n) }   # Fibonacci
say 25.of {|n| lucasU(2, -1, n) }   # Pell
say 25.of {|n| lucasV(1, -1, n) }   # Lucas
say 25.of {|n| lucasV(2, -1, n) }   # Pell-Lucas

# Modular Lucas sequences
say lucasUmod(1, -1, 10**9, 1000000007)
say lucasVmod(1, -1, 10**9, 1000000007)

# Custom parameters
func jacobsthal(n) { lucasU(1, -2, n) }
say 20.of { jacobsthal(_) }
```

### Example 14: Powerful Numbers

```ruby
# Count and generate powerful numbers
say 2.powerful_count(1, 1000)
say 2.powerful(1, 100)

# k-powerful for various k
say 3.powerful_count(1, 10000)
say 4.powerful_count(1, 10000)

# Sum of powerful numbers
say 2.powerful_sum(1, 1000)

# Check if number is powerful
say 30.by { .is_powerful(2) }
say 20.by { .is_powerful(3) }
```

### Example 15: Exponential Divisors

```ruby
# Generate exponential divisors
say 720.edivisors

# Exponential sigma function
func exp_sigma(n, k=1) {
    n.edivisors.sum { _**k }
}

say map(1..20, {|n| exp_sigma(n, 1) })
say map(1..20, {|n| exp_sigma(n, 2) })

# Built-in exponential sigma
say map(1..20, { .esigma })
say map(1..20, { .esigma(2) })
```

### Example 16: Gaussian Integer Factorization

```ruby
# Check if Gaussian integer is prime
say is_gaussian_prime(3, 0)     # 3 is Gaussian prime
say is_gaussian_prime(5, 0)     # 5 is not (= (2+i)(2-i))
say is_gaussian_prime(2, 1)     # 2+i is Gaussian prime

# Work with Gaussian integers
var g = Gauss(3, 4)
say g**2                        # Gauss(-7, 24)
say g.norm                      # 25 = 3² + 4²
say g.conj                      # Gauss(3, -4)

# Factorization representations
for n in (1..20) {
    var sols = sum_of_squares(n)
    if (sols) {
        say "#{n} = #{sols[0][0]}² + #{sols[0][1]}²"
    }
}
```

### Example 17: Matrix Operations in Number Theory

```ruby
# Fibonacci via matrix exponentiation
func fib_matrix(n) {
    var M = Matrix([1, 1], [1, 0])
    (M**n)[0][1]
}

say 20.of { fib_matrix(_) }

# Linear recurrences via matrices
func linear_rec_matrix(sig, init, n) {
    var k = sig.len
    var M = Matrix(
        sig + k.of { [0] * (k-1) + [_==0 ? 1 : 0] }...
    )
    var v = Matrix([[init]]).transpose
    ((M**n) * v)[0][0]
}

# Lucas numbers via matrix
func lucas_via_matrix(n) {
    linear_rec_matrix([1, 1], [2, 1], n)
}
```

### Example 18: Partition Functions

```ruby
# Number of partitions (using built-in)
say 30.of { .partitions }

# Restricted partitions
func partitions_into_k_parts(n, k) is cached {
    return 1 if (k == 1)
    return 0 if (k > n)
    sum(1 .. n/k, {|j|
        __FUNC__(n - k*j, k-1)
    })
}

# Partitions into distinct parts
func partitions_distinct(n, k=n) is cached {
    return 1 if (n == 0)
    return 0 if (k <= 0 || n < 0)
    __FUNC__(n-k, k-1) + __FUNC__(n, k-1)
}
```

### Example 19: Carmichael Numbers Generation

```ruby
# Generate Carmichael numbers in range
func carmichael_in_range(a, b, k=3) {
    k.carmichael(a, b)
}

# Smallest Carmichael with k factors
func smallest_carmichael(k) {
    return nil if (k < 3)
    var x = pn_primorial(k+1)/2
    var y = 3*x

    loop {
        var arr = k.carmichael(x, y)
        return arr[0] if arr
        x = y+1
        y = 3*x
    }
}

for k in (3..10) {
    say "C(#{k}) = #{smallest_carmichael(k)}"
}
```

### Example 20: Quadratic Residues

```ruby
# Check quadratic residuosity
func is_quadratic_residue(a, p) {
    kronecker(a, p) == 1
}

# Find all quadratic residues mod p
func quadratic_residues(p) {
    1 .. p-1 -> grep { is_quadratic_residue(_, p) }
}

say quadratic_residues(23)

# Tonelli-Shanks for square roots
say sqrtmod(10, 13)         # x² ≡ 10 (mod 13)
say sqrtmod_all(10, 13)     # All solutions
```

---

## Tips and Tricks

### Debugging Number Theory Code

```ruby
# Enable verbose mode
Num!VERBOSE = true

# Trace factorizations
var n = (2**128 + 1)
say "Factoring: #{n}"
say factor(n)

# Profile performance
var start = Time.now
var result = compute_something()
var elapsed = (Time.now - start)
say "Computed in #{elapsed}s"
```

### Working with OEIS Sequences

Best practices for OEIS computation:

```ruby
# Generate sequences efficiently
func generate_sequence(limit) {
    var results = []
    for n in (1..limit) {
        var value = compute_term(n)
        results.push(value)

        # Early termination if pattern breaks
        break if (value > threshold)
    }
    return results
}

# Format for OEIS submission
func format_for_oeis(seq, terms_per_line=10) {
    seq.each_slice(terms_per_line, {|slice|
        say slice.join(', ')
    })
}
```

### Optimizing Factor-Based Computations

```ruby
# Cache factorizations when reusing
var cache = Hash()

func cached_factor(n) {
    cache{n} := n.factor
}

# Use factor_prod { ... } for multiplicative functions
func my_multiplicative_function(n) {
    n.factor_prod {|p, e|
        # Compute for prime power
        compute_for_prime_power(p, e)
    }
}
```

---

## Common Pitfalls

### 1. Integer Overflow in Other Languages

Sidef handles arbitrary precision automatically:

```ruby
# This works fine - no overflow
var n = 2**1000
say n.is_prime      # Checks primality of 1000-bit number
```

### 2. Primality Testing vs Proving

```ruby
# Probable prime (BPSW - very fast, deterministic < 2^64)
is_prime(n)         # Use for most purposes

# Provable prime (much slower for large n)
is_prov_prime(n)    # Use when proof is required
```

### 3. Modular Arithmetic Pitfalls

```ruby
# Wrong: integer division followed by modulo may not be always correct
var wrong = ((powmod(2, 100, 1000) / 3) % 1000)

# Right: use modular inverse
var right = (powmod(2, 100, 1000) * invmod(3, 1000) % 1000)

# Or use Mod objects
var m = Mod(powmod(2, 100, 1000), 1000)
say m/3
```

### 4. Efficient Divisor Iteration

```ruby
# Less efficient: generate all divisors
n.divisors.each {|d| process(d) }

# More efficient: use divisor_sum/divisor_prod
n.divisor_sum {|d| process(d) }     # If summing results
n.divisor_prod {|d| process(d) }    # If multiplying results
```

### 5. Choosing the Right Function

```ruby
# For counting primes in range:
pi(a, b)            # Not: primes(a, b).len

# For checking compositeness:
is_composite(n)     # Not: !is_prime(n)

# For getting n-th prime:
nth_prime(n)        # Not: n.by {.is_prime}[-1]
```

---

## Resources and Further Reading

### Documentation

- **Full Number class documentation**: [Sidef Number Class](https://metacpan.org/pod/Sidef::Types::Number::Number) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-number-class-documentation.pdf))
- **Sidef book**: [trizen.gitbook.io/sidef-lang](https://trizen.gitbook.io/sidef-lang/) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-book.pdf))
- **Beginner's tutorial**: [TUTORIAL.md](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf))

### Code Examples

- **Sidef scripts repository**: [github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)
- **OEIS autoload**: [github.com/trizen/oeis-autoload](https://github.com/trizen/oeis-autoload)
- **Number theory algorithms**: [Special-purpose factorization](https://trizenx.blogspot.com/2019/08/special-purpose-factorization-algorithms.html)

### Mathematical References

- **OEIS**: [oeis.org](https://oeis.org) - Online Encyclopedia of Integer Sequences
- **Math::Prime::Util**: [github.com/danaj/Math-Prime-Util](https://github.com/danaj/Math-Prime-Util)
- **Max Alekseyev's papers**: [Inverse of multiplicative functions](https://cs.uwaterloo.ca/journals/JIS/VOL19/Alekseyev/alek5.html)

### Community

- **Questions and discussions**: [GitHub Discussions](https://github.com/trizen/sidef/discussions/categories/q-a)
- **Issue tracker**: [GitHub Issues](https://github.com/trizen/sidef/issues)

---

## Quick Reference Card

### Most Common Operations

```ruby
# Primality
is_prime(n)                     # BPSW test
is_prov_prime(n)                # Provable prime

# Factorization
factor(n)                       # Prime factors
divisors(n)                     # All divisors

# Arithmetic functions
tau(n)                          # Count divisors: τ(n)
sigma(n)                        # Sum divisors: σ(n)
phi(n)                          # Euler's totient: φ(n)
mu(n)                           # Moebius: μ(n)
omega(n)                        # Distinct primes: ω(n)
Omega(n)                        # Prime factors: Ω(n)

# Primes
pi(n)                           # Prime count
prime(n)                        # n-th prime
primes(a, b)                    # Primes in range

# Modular
powmod(a, b, m)                 # a^b mod m
invmod(a, m)                    # a^(-1) mod m
sqrtmod(a, m)                   # √a mod m

# Special sequences
fib(n)                          # Fibonacci
lucas(n)                        # Lucas
factorial(n)                    # n!
binomial(n, k)                  # C(n,k)

# Sequence generation
n.by {|k| condition }           # First n matching
n.of {|k| function }            # First n values
map(a..b, {|k| function })      # Map over range
```

### Memory Aid

- **`.by`** = filter (returns matching items)
- **`.of`** = map (returns transformed items)
- **`factor_prod`** = for multiplicative functions
- **`divisor_sum`** = for divisor-based sums
- **`is_*`** = boolean tests (return true/false)
- **`nth_*`** = find n-th element
- **`*_count`** = count elements
- **`*_sum`** = sum elements

---

## Appendix: Performance Benchmarks

### Comparison with Other Systems

Selected benchmarks (approximate, hardware-dependent):

| Operation | Sidef | PARI/GP | Mathematica |
|-----------|-------|---------|-------------|
| factor(2^128+1) | 0.5s | 0.5s | 0.6s |
| pi(10^10) | 0.2s | 0.2s | 0.3s |
| binomialmod(10^10, 10^5, 2^127-1) | 0.08s | N/A | 0.15s |
| is_prime(2^1000+1) | 0.01s | 0.01s | 0.02s |

### Scaling Behavior

```ruby
# Prime counting scales well
pi(10**6)       # < 0.01s
pi(10**9)       # ~0.2s
pi(10**12)      # ~5s with primecount

# Factorization depends on number structure
factor(2**128 - 1)          # 0.01s (special form)
factor(nextprime(2**64)^2)  # 0.01s (small factors)
factor(random_semiprime)    # Variable (general case)

# k-almost prime tests
n.is_almost_prime(3)        # ~10^6 per second for 100-digit n
n.is_omega_prime(3)         # Similar performance
```

---

## Conclusion

Sidef provides a powerful, elegant environment for computational number theory with:

- **Extensive function library**: Over 1,000 numerical functions
- **Arbitrary precision**: No overflow worries
- **High performance**: Comparable to specialized systems
- **Clean syntax**: Intuitive and readable code
- **Active development**: Regular updates and improvements

Whether you're exploring sequences for OEIS, developing new algorithms, or solving number-theoretic problems, Sidef offers the tools and performance you need.

### Getting Help

If you have questions or need assistance:

1. Check the [documentation](https://trizen.gitbook.io/sidef-lang/)
2. Browse [code examples](https://github.com/trizen/sidef-scripts)
3. Ask in [GitHub Discussions](https://github.com/trizen/sidef/discussions)

Happy computing!
