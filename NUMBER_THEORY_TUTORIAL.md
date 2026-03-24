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

For installation instructions and basic language features, refer to the [beginner's tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf)).

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
- **Beginner's tutorial**: [TUTORIAL.md](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) ([PDF](https://github.com/trizen/sidef/releases/download/26.01/sidef-tutorial.pdf))
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

*This document covers the `Sidef::Types::Number::Number` class and the core language features relevant to computational number theory. For additional functionality related to arrays, strings, and other types, consult the full Sidef documentation at [trizen.gitbook.io/sidef-lang](https://trizen.gitbook.io/sidef-lang/).*
