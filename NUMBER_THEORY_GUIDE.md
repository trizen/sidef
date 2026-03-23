# Sidef for Computational Number Theory

*An extended reference guide for advanced users*

> **Sidef** is a high-level, multi-paradigm programming language with deep, built-in support for number theory. Its `Number` class provides arbitrary-precision integers, rationals, floats, and complex numbers, together with hundreds of number-theoretic functions ranging from basic divisibility tests to advanced primality algorithms, integer factorization methods, multiplicative functions, and analytic number theory tools.

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [The Number System](#2-the-number-system)
3. [Precision and Configuration](#3-precision-and-configuration)
4. [Arithmetic Operators — Quick Reference](#4-arithmetic-operators--quick-reference)
5. [Primality Testing](#5-primality-testing)
6. [Prime Numbers and Prime Counting](#6-prime-numbers-and-prime-counting)
7. [Integer Factorization](#7-integer-factorization)
8. [Divisors and Divisor Functions](#8-divisors-and-divisor-functions)
9. [Modular Arithmetic](#9-modular-arithmetic)
10. [Euler's Totient and Related Functions](#10-eulers-totient-and-related-functions)
11. [Multiplicative Functions](#11-multiplicative-functions)
12. [Special Number Classes](#12-special-number-classes)
13. [Sequences and Combinatorics](#13-sequences-and-combinatorics)
14. [Continued Fractions and Rational Approximation](#14-continued-fractions-and-rational-approximation)
15. [Quadratic Forms and Sum of Squares](#15-quadratic-forms-and-sum-of-squares)
16. [Lucas Sequences](#16-lucas-sequences)
17. [Analytic and Arithmetic Functions](#17-analytic-and-arithmetic-functions)
18. [Working with Large Numbers](#18-working-with-large-numbers)
19. [Worked Problems](#19-worked-problems)
20. [Function Quick-Reference Cheat Sheet](#20-function-quick-reference-cheat-sheet)

- [At a Glance](#at-a-glance)
- [Notation and Conventions](#notation-and-conventions)
- [Appendix A: Further Reading](#appendix-a-further-reading)
- [Appendix B: Common Recipes](#appendix-b-common-recipes)

---


## At a Glance

This guide is organized around the most common tasks in computational number theory:

- testing primality and navigating the prime landscape,
- factoring large integers with specialized algorithms,
- working with divisors, modular arithmetic, and multiplicative functions,
- exploring sequences, continued fractions, and classical integer sequences,
- and using Sidef’s arbitrary-precision arithmetic for large-scale experiments.

## Notation and Conventions

| Notation | Meaning |
|---|---|
| `φ(n)` | Euler’s totient function |
| `μ(n)` | Möbius function |
| `τ(n)` | Number of divisors |
| `σ_k(n)` | Sum of k-th powers of divisors |
| `ω(n)` | Number of distinct prime factors |
| `Ω(n)` | Number of prime factors counted with multiplicity |
| `λ(n)` | Carmichael’s lambda function |
| `ψ(n)` | Dedekind psi function |

A few reading conventions used throughout the guide:

- `say` prints a value and ends the line.
- `var` introduces a variable.
- `func` defines a function.
- `local` temporarily changes a setting inside a function or block.
- Most functions are shown in both standalone form and method-call form when both are natural.


## 1. Getting Started

Sidef code is written in `.sf` files and run with the `sidef` interpreter. Numbers are first-class objects, and most number-theoretic functions can be called either as standalone functions or as **method calls** on a number.

```ruby
# Both of these are equivalent:
say euler_phi(100)       #=> 40
say 100.euler_phi        #=> 40
```

**Key things to know before you start:**

- Every integer, rational, float, and complex number is a `Number` object.
- Methods chain naturally: `120.factor.sum` sums the prime factors of 120.
- The `say` function prints its argument followed by a newline.
- Ranges are written `a..b` (inclusive) and `a..^b` (exclusive of `b`).
- Blocks are written `{ ... }` and receive arguments via `|param|`.
- `n.of { block }` generates an array of `n` values by calling the block with indices 0, 1, …, n−1.

```ruby
# Generate the first 10 Fibonacci numbers
say 10.of { .fib }      #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

# Sum of primes up to 100
say prime_sum(100)       #=> 1060

# First prime larger than 10^18
say next_prime(10**18)
```

---

## 2. The Number System

Sidef's numbers are arbitrarily precise. There is no practical size limit.

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

Sidef performs exact rational arithmetic automatically. Use `as_frac` or `as_rat` to inspect the rational representation.

```ruby
say (1/3 + 1/6)           #=> 1/2
say as_frac(355/113)       #=> 355/113
say (22/7 - Num.pi)        # Small floating-point difference
```

### Floating-Point

Use `Num!PREC` to control precision in bits (default is 192 bits ≈ 57 significant decimal digits).

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

### Gaussian integers

```ruby
var g = Gauss(3, 4)
say g**100
say g.powmod(1234, 56789)
```

### Quadratic integers

```ruby
var q = Quadratic(3,4,5)   # 3 + 4*sqrt(5)
say q**100
say q.powmod(98765, 43210)
```

---

## 3. Precision and Configuration

Global class variables on `Num` control runtime behavior.

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

**Rounding modes** (for `Num!ROUND`):

| Value | Mode |
|---|---|
| 0 | Round to nearest (default) |
| 1 | Round towards zero (truncate) |
| 2 | Round towards +∞ (ceiling) |
| 3 | Round towards −∞ (floor) |

---

## 4. Arithmetic Operators — Quick Reference

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

## 5. Primality Testing

Sidef provides a comprehensive suite of primality tests, from quick probabilistic checks to rigorous deterministic proofs.

### Quick Primality Check

```ruby
say 97.is_prime           #=> true
say 100.is_prime          #=> false
say is_prime(2**127 - 1)  #=> true  (Mersenne prime M_127)
```

`is_prime` uses a combination of trial division, Miller-Rabin, and Lucas tests — it is a **Baillie-PSW** test, which has no known counterexamples.

### Primality Test Hierarchy

```ruby
# Trial division pretest
say n.primality_pretest        # Fast check for small factors

# Individual probabilistic / deterministic tests
say n.is_fermat_psp(2)         # Fermat pseudoprime to base 2
say n.is_euler_psp(2)          # Euler pseudoprime to base 2
say n.is_strong_psp(2)         # Strong (Miller-Rabin) pseudoprime to base 2
say n.miller_rabin_random(20)  # Miller-Rabin with 20 random bases

# Lucas-based tests
say n.is_lucas_psp             # Lucas pseudoprime (standard)
say n.is_strong_lucas_psp      # Strong Lucas pseudoprime
say n.is_extra_strong_lucas_psp  # Extra-strong Lucas pseudoprime
say n.is_almost_extra_strong_lucas_psp

# Combined tests
say n.is_bpsw_prime            # Full Baillie-PSW test
say n.is_provable_prime        # Rigorous certificate (slow for large n)
say n.is_aks_prime             # AKS deterministic test (very slow)
```

### Special Prime Forms

```ruby
say n.is_mersenne_prime          # Is n = 2^p - 1 prime?
say n.is_prime_power             # Is n = p^k for some prime p?
say n.is_perfect_power           # Is n = a^k for some a,k > 1?

# Working with prime powers
say prime_power(43**5)           #=> 5   (the exponent k)
say prime_root(43**5)            #=> 43  (the prime base p)
```

### Pseudoprimes and Carmichael Numbers

These are fundamental to understanding primality testing failures.

```ruby
# All 3-factor Carmichael numbers up to 10^4
say 3.carmichael(1e4)

# 3-omega Fermat pseudoprimes to base 2 up to 10^6
say 3.fermat_psp(2, 1e6)

# Strong Fermat pseudoprimes to base 2
say 3.strong_fermat_psp(2, 1e6)

# Carmichael numbers that are ALSO strong pseudoprimes to base 2
say 3.carmichael_strong_fermat(2, 1e7)

# The Carmichael lambda function: λ(n)
# = smallest m such that a^m ≡ 1 (mod n) for all gcd(a,n)=1
say lambda(561)    # 561 = first Carmichael number
```

> **Tutorial: Verifying Korselt's Criterion**
>
> A squarefree composite number *n* is a Carmichael number if and only if for every prime *p* dividing *n*, we have *(p−1) | (n−1)*.

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

---

## 6. Prime Numbers and Prime Counting

### Generating and Navigating Primes

```ruby
say prime(1)              #=> 2      (1st prime)
say prime(100)            #=> 541    (100th prime)
say prime(1_000_000)      #=> 15485863

say primes(50)            #=> all primes up to 50
say primes(50, 100)       #=> primes in [50, 100]

say 97.next_prime         #=> 101
say 100.prev_prime        #=> 97

# Navigation by count
say 5.next_primes(100)    # 5 primes starting after 100: [101,103,107,109,113]
say 5.prev_primes(100)    # 5 primes going back from 100: [97,89,83,79,73]
```

### Prime Counting Function π(n)

```ruby
say primepi(100)           #=> 25    (25 primes ≤ 100)
say primepi(50, 100)       #=> 10    (primes in [50, 100])
say pi(10**12)             #=> 37607912018

# Bounds (closed-form, no computation needed)
say 1000.prime_lower       # Lower bound for 1000th prime
say 1000.prime_upper       # Upper bound for 1000th prime
say primepi_lower(1e12)    # Lower bound for π(10^12)
say primepi_upper(1e12)    # Upper bound for π(10^12)
```

> **Note:** For very large arguments, set `Num!USE_PRIMECOUNT = true` to delegate to Kim Walisch's highly optimized `primecount` binary.

### Prime Sums and Power Sums

```ruby
say prime_sum(100)          # Sum of all primes ≤ 100
say prime_sum(50, 100)      # Sum of primes in [50, 100]
say prime_sum(1, 100, 2)    # Sum of squares of primes ≤ 100

say prime_power_sum(100)    # Sum of prime powers ≤ 100
say prime_power_count(100)  # Count of prime powers ≤ 100
```

### Special Prime Families

```ruby
# Twin primes: (p, p+2) are both prime
say prime_cluster(1, 1000, 2)            # Lesser of each twin prime pair ≤ 1000

# Sophie Germain primes: p and 2p+1 are both prime
say linear_forms_primes(1, 500, [1,0], [2,1])

# Cousin primes: (p, p+4) both prime
say prime_cluster(1, 1000, 4)

# Sexy primes: (p, p+6) both prime
say prime_cluster(1, 1000, 6)

# Prime triplets (p, p+2, p+6)
say prime_cluster(1, 1000, 2, 6)

# Primorial: product of all primes ≤ n
say primorial(10)    #=> 2*3*5*7 = 210

# Primorial of the n-th prime
say 5.pn_primorial   #=> 11# = 2310
```

### Smooth Numbers

A number is *B-smooth* if its largest prime factor ≤ B.

```ruby
# Greatest prime factor
say gpf(5040)           #=> 7
say gpf(2**128 + 1)     #=> a large prime factor

# Least prime factor
say lpf(5040)           #=> 2
say lpf(fibonacci(1234)) #=> 234461

# Rough numbers: all prime factors > B
# (B+1)-rough numbers up to N
say 11.rough_count(1000)   # count of 11-rough numbers ≤ 1000
```

---

## 7. Integer Factorization

Sidef's `factor` method returns the full prime factorization. For numbers where the structure is known, specialized algorithms run faster.

### Basic Factorization

```ruby
say 5040.factor              #=> [2, 2, 2, 2, 3, 3, 5, 7]  (with repetition)
say 5040.factor_exp          #=> [[2,4], [3,2], [5,1], [7,1]] (p^e pairs)
say 5040.prime_divisors      #=> [2, 3, 5, 7]  (unique primes only)

# Reconstruct n from factorization
say 5040.factor_exp.map_2d {|p,e| p**e }.prod   #=> 5040
```

### Factor Iteration and Transformation

```ruby
# factor_map: iterate over (p, e) pairs and build a result
say 5040.factor_map {|p,e| "#{p}^#{e}" }.join(" * ")
#=> "2^4 * 3^2 * 5^1 * 7^1"

# product of (p^e - 1) over all prime powers
say n.factor_map {|p,e| p**e - 1 }.prod
```

### Specialized Factorization Algorithms

These return partial or complete factorizations and are useful for large or structured inputs.

| Method | Best for |
|---|---|
| `trial_factor(limit)` | Small factors quickly |
| `pm1_factor(B)` | p such that p−1 is B-smooth |
| `pp1_factor(B)` | p such that p+1 is B-smooth |
| `chebyshev_factor(B, x)` | p±1 smooth factors |
| `ecm_factor(B)` | Elliptic Curve Method — general |
| `squfof_factor` | Medium-sized numbers (Shanks SQUFOF) |
| `holf_factor` | Numbers with factors near √n |
| `flt_factor(base)` | Factors with small znorder |
| `mbe_factor` | p−1 smooth, randomized |
| `miller_factor` | Carmichael numbers, Fermat psp |
| `lucas_factor` | Lucas-Carmichael, Lucas pseudoprimes |
| `cop_factor` | Algebraic (congruence of powers) |
| `cyclotomic_factor` | Numbers of the form a^k ± 1 |
| `germain_factor` | Numbers of the form x^4 + 4y^4 |
| `fib_factor` | Fibonacci-like numbers |
| `special_factor` | Auto-selects multiple methods |

```ruby
# Full general factorization
say factor(2**64 + 1)
#=> [274177, 67280421310721]

# Williams' p+1 method with smoothness bound 10000
say n.pp1_factor(10000)

# Pollard's p−1 method
say n.pm1_factor(10000)

# Elliptic curve method
say n.ecm_factor(10000)

# Cyclotomic factorization of 2^120 + 1
say cyclotomic_factor(2**120 + 1)

# Sophie Germain identity: x^4 + 4y^4
say germain_factor(5**4 + 4 * 3**4)

# Auto-select methods
say special_factor((3**120 + 1) * (5**240 - 1))
```

### GCD, LCM, and Extended GCD

```ruby
say gcd(48, 36)             #=> 12
say lcm(48, 36)             #=> 144
say gcd(1234567, 9876543)   # Arbitrary precision

# Extended Euclidean algorithm: returns (u, v, d) where u*a + v*b = d
var (u, v, d) = gcdext(35, 15)
say [u, v, d]   # u*35 + v*15 = gcd(35,15) = 5

# Consecutive integer LCM: lcm(1, 2, ..., n)
say consecutive_lcm(10)     #=> 2520

# Greatest common unitary divisor
say gcud(12, 18)
```

---

## 8. Divisors and Divisor Functions

### Listing Divisors

```ruby
say 12.divisors           #=> [1, 2, 3, 4, 6, 12]
say 12.proper_divisors    #=> [1, 2, 3, 4, 6]   (excludes n itself)

# Unitary divisors: d | n and gcd(n/d, d) = 1
say 120.udivisors         #=> [1, 3, 5, 8, 15, 24, 40, 120]

# Square divisors, cube divisors, prime power divisors
say 5040.square_divisors            #=> [1, 4, 9, 16, 36, 144]
say 10!.cube_divisors               #=> [1, 8, 27, 64, 216, 1728]
say 5040.prime_power_divisors       #=> [2, 3, 4, 5, 7, 8, 9, 16]
say 10!.prime_power_udivisors       #=> [7, 25, 81, 256]

# Squarefree, cubefree divisors
say squarefree_divisors(120)        #=> [1, 2, 3, 5, 6, 10, 15, 30]
say cubefree_divisors(120)          #=> [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]

# Infinitary divisors
say 96.idivisors                    #=> [1, 2, 3, 6, 16, 32, 48, 96]
```

### Divisor Counting: τ(n) and σ₀(n)

```ruby
say tau(120)              #=> 16   (number of divisors)
say 120.sigma(0)          #=> 16   (same: sigma_0 = count of divisors)
say usigma0(5040)         #=> 16   (count of unitary divisors)
say prime_sigma0(n)       #=> omega(n) (count of distinct prime factors)
```

### Divisor Sum: σ_k(n)

```ruby
say sigma(12)             #=> 28   (sum of divisors)
say sigma(12, 2)          #=> 210  (sum of squares of divisors)
say sigma(12, 0)          #=> 6    (count of divisors)

# Unitary sigma
say usigma(5040)          # Sum of unitary divisors
say usigma(5040, 2)       # Sum of squares of unitary divisors

# Squarefree sigma
say squarefree_sigma(5040)       #=> 576
say squarefree_sigma(5040, 2)    #=> 65000

# Prime sigma: sum over distinct prime divisors only
say prime_sigma(100!)
say prime_sigma(100!, 2)
```

### Inverse Functions

These solve *f(x) = n* for the given arithmetic function *f*.

```ruby
# Solve phi(x) = n  (Euler totient inverse)
say inverse_phi(40)           # all x with phi(x) = 40
say inverse_phi_min(40)       # smallest such x
say inverse_phi_max(40)       # largest such x
say inverse_phi_len(40)       # how many solutions

# Solve sigma(x) = n
say inverse_sigma(42)         #=> [20, 26, 41]
say inverse_sigma(22100, 2)   #=> [120, 130, 141]

# Solve psi(x) = n  (Dedekind psi inverse)
say inverse_psi(120)          #=> [75, 76, 87, 95]
```

---

## 9. Modular Arithmetic

Modular arithmetic is the backbone of much of computational number theory.

### Basic Modular Operations

```ruby
say powmod(2, 1000, 1000000007)   # 2^1000 mod (10^9 + 7)
say invmod(17, 1000000007)        # 17^(-1) mod (10^9 + 7)

say addmod(43, 97, 127)           # (43 + 97) mod 127
say submod(43, 97, 127)           # (43 - 97) mod 127
say mulmod(43, 97, 127)           # (43 * 97) mod 127
```

### Compound Modular Operations

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

### Discrete Logarithm and Multiplicative Order

```ruby
# Discrete log: find k such that a ≡ g^k (mod m)
say znlog(5, 2, 13)        # 2^k ≡ 5 (mod 13)

# Multiplicative order: smallest k with a^k ≡ 1 (mod m)
say znorder(2, 13)         # ord_13(2)
say multiplicative_order(3, 17)

# Primitive root modulo n (smallest generator of (Z/nZ)*)
say znprimroot(13)         #=> 2
say znprimroot(17)         #=> 3
```

### Jacobi, Legendre, and Kronecker Symbols

These are essential for quadratic residuosity and primality testing.

```ruby
say legendre(7, 13)        # Legendre symbol (7|13): is 7 a QR mod 13?
say jacobi(10, 21)         # Jacobi symbol (10|21)
say kronecker(5, 8)        # Kronecker symbol (5|8)
```

> **Tutorial: Quadratic Residues**
>
> The Legendre symbol (a|p) = 1 if *a* is a quadratic residue mod prime *p*, −1 if not, and 0 if p | a.

```ruby
# List all quadratic residues mod 13
say (1..12 -> grep {|a| legendre(a, 13) == 1 })
#=> [1, 3, 4, 9, 10, 12]

# Check Euler's criterion: a^((p-1)/2) ≡ (a|p) (mod p)
var p = 13
var a = 7
say powmod(a, (p-1)/2, p)      # Should equal legendre(a, p) mod p
```

### Valuations

```ruby
# p-adic valuation: how many times p divides n
say valuation(2**32, 4)    #=> 16  (2^32 = 4^16)
say valuation(5040, 2)     #=> 4
say valuation(5040, 3)     #=> 2
```

---

## 10. Euler's Totient and Related Functions

### Euler's Totient φ(n)

φ(n) counts integers in [1, n] coprime to n. This is the order of the multiplicative group (Z/nZ)*.

```ruby
say euler_phi(12)           #=> 4  (1, 5, 7, 11 are coprime to 12)
say phi(100)                #=> 40

# Jordan's generalization J_k(n): sum of k-th powers of gcd's
say phi(n, 2)               # Jordan totient J_2(n)
say jordan_totient(n, 3)    # J_3(n)

# Totient sum: Sum_{j=1..n} phi(j)
say totient_sum(100)        #=> 3044
say totient_sum(100, 2)     #=> 280608  (Jordan totient sum)

# Range version (efficient batch computation)
say totient_range(7, 17)    #=> [6, 4, 6, 4, 10, 4, 12, 6, 8, 8, 16]

# Unitary totient uphi(n)
say uphi(n)                 # OEIS: A047994
```

> **Property:** For prime p, φ(p) = p − 1. For prime power p^k, φ(p^k) = p^(k−1)(p−1). Multiplicativity: if gcd(m,n) = 1, then φ(mn) = φ(m)φ(n).

```ruby
# Verify multiplicativity
func phi_multiplicative_check(m, n) {
    (gcd(m,n) == 1) &&
    (phi(m * n) == phi(m)*phi(n))
}
say phi_multiplicative_check(12, 35)   #=> true
```

### Carmichael's Lambda λ(n)

λ(n) is the *exponent* of (Z/nZ)* — the smallest m such that a^m ≡ 1 (mod n) for all a coprime to n.

```ruby
say lambda(12)              #=> 2  (a^2 ≡ 1 (mod 12) for all gcd(a,12)=1)
say lambda(1000)            #=> 100
say carmichael_lambda(561)  # For the first Carmichael number
```

---

## 11. Multiplicative Functions

### Möbius Function μ(n)

μ(n) = 0 if n has a squared prime factor, (−1)^k if n is a product of k distinct primes.

```ruby
say mu(1)     #=> 1
say mu(6)     #=> 1   (6 = 2*3, two distinct primes)
say mu(4)     #=> 0   (4 = 2^2, has a square factor)
say mu(30)    #=> -1  (30 = 2*3*5, three distinct primes)

# Möbius values over a range
say mobius_range(1, 20)

# Mertens function M(n) = Sum_{k=1..n} mu(k)
say mertens(100000)
say mertens(10**9)    #=> -25216
```

> **Möbius inversion:** If g(n) = Σ_{d|n} f(d), then f(n) = Σ_{d|n} μ(n/d) g(d). This is a central tool in analytic number theory.

```ruby
# Compute f(n) from g(n) = sigma(n) using Möbius inversion
func moebius_invert(g, n) {
    n.divisors.sum {|d| mu(n/d) * g(d) }
}
# For g = sigma, the result should be n itself (phi(n) for g = n)
say moebius_invert({|d| sigma(d) }, 12)   # Should be 12
```

### Liouville Function and Omega Counts

```ruby
# Ω(n): total number of prime factors with multiplicity
say bigomega(12)           #=> 3   (12 = 2^2 * 3)

# ω(n): number of distinct prime factors
say omega(12)              #=> 2   (primes 2 and 3)

# Liouville: λ(n) = (-1)^Ω(n)
say liouville(12)          #=> -1  (Ω(12) = 3)
say liouville(30)          #=> -1  (Ω(30) = 3)
say liouville(4)           #=> 1   (Ω(4) = 2)

# Partial Liouville sum
say liouville_sum(10**9)   #=> -25216
```

### The Dedekind Psi Function

ψ(n) = n * Π_{p|n} (1 + 1/p) — analogous to σ(n)/n * n.

```ruby
say psi(n)                # Dedekind psi function
say inverse_psi(120)      #=> [75, 76, 87, 95]
```

### Sum of Prime Factors

```ruby
# sopfr(n): sum of prime factors with repetition (sopfr = "sum of prime factors repeated")
say sopfr(12)             #=> 7   (2+2+3)
say sopfr(30)             #=> 10  (2+3+5)

# Sum of distinct prime factors
say sopf(12)              #=> 5   (2+3)
```

---

## 12. Special Number Classes

### Perfect, Abundant, and Deficient Numbers

σ(n) − n is the sum of proper divisors. A number is **perfect** if σ(n) = 2n, **abundant** if σ(n) > 2n, **deficient** if σ(n) < 2n.

```ruby
say 6.is_perfect           #=> true  (6 = 1+2+3)
say 28.is_perfect          #=> true
say 12.is_abundant         #=> true  (sigma(12) = 28 > 24)
say 8.is_deficient         #=> true

# Abundancy index: sigma(n)/n
say abundancy(6)           #=> 2 (6 is a perfect number)

# Aliquot sum: sigma(n) - n
say aliquot(12)            #=> 16

# Amicable numbers: sigma(m)-m = n and sigma(n)-n = m
say is_amicable(220, 284)  #=> true
```

### Squarefree and Powerful Numbers

```ruby
say n.is_squarefree        # No prime appears twice in factorization
say n.is_powerful(2)       # Every prime factor appears ≥ 2 times (2-full)
say n.is_powerful(3)       # Every prime factor appears ≥ 3 times

# Lists
say squarefree(100)              # All squarefree numbers ≤ 100
say squarefree(50, 100)          # Squarefree in [50, 100]
say 2.powerful(100)              # Powerful (squareful) numbers ≤ 100
say squarefree_count(1e12)       # π_sf(10^12)

# Core: squarefree part of n
say core(12)               #=> 3   (12 = 4*3, squarefree part = 3)
say squarefree_part(72)    #=> 2   (72 = 36*2)
```

### Almost Primes (k-Almost Primes)

A k-almost prime has exactly k prime factors counted with multiplicity (Ω(n) = k). Primes are 1-almost primes; semiprimes are 2-almost primes.

```ruby
say n.is_almost_prime(2)         # Is n a semiprime?
say n.is_almost_prime(3)         # Is n a 3-almost prime?

say 2.almost_primes(100)         # Semiprimes ≤ 100
say 3.almost_primes(100)         # 3-almost primes ≤ 100

say 2.almost_prime_sum(100)      # Sum of semiprimes ≤ 100
say 2.almost_prime_count(100)    # Count of semiprimes ≤ 100

# Squarefree semiprimes (products of exactly 2 distinct primes)
say squarefree_semiprimes(100)
say squarefree_semiprime_count(1e10)
```

### Omega Primes

A k-omega prime has exactly k *distinct* prime factors (ω(n) = k).

```ruby
say n.is_omega_prime(2)          # Is ω(n) = 2?
say n.next_omega_prime(2)        # Next 2-omega prime after n
say n.prev_omega_prime(3)        # Previous 3-omega prime before n
```

### Perfect Powers and Prime Powers

```ruby
say n.is_perfect_power           # n = a^k, k ≥ 2?
say n.is_perfect_square          # n = a^2?
say n.is_perfect_cube            # n = a^3?
say n.is_power(k)                # n = a^k for some integer a?
say n.is_prime_power             # n = p^k for some prime p?

say next_perfect_power(1e6)      #=> 1002001
say prev_perfect_power(1e6)      #=> 998001
say next_perfect_power(1e6, 3)   #=> 1030301 (next perfect cube)
```

### Palindromes

```ruby
say n.is_palindrome              # Palindrome in base 10?
say n.is_palindrome(2)           # Palindrome in base 2?
say n.next_palindrome            # Next base-10 palindrome > n
say n.next_palindrome(16)        # Next base-16 palindrome > n

# Iterate over base-10 palindromes up to 10^6
for (var n = 0; n < 1e6; n = n.next_palindrome) {
    say n
}
```

---

## 13. Sequences and Combinatorics

### Factorials and Variants

```ruby
say 10!                           #=> 3628800     (factorial)
say 9!!                           #=> 945          (double factorial: 9*7*5*3*1)
say mfac(9, 3)                    #=> triple factorial: 9*6*3
say subfactorial(5)               #=> 44           (derangements of 5 elements)
say hyperfactorial(5)             #=> 1^1*2^2*3^3*4^4*5^5
say superfactorial(4)             #=> 1!*2!*3!*4!
say superprimorial(4)             #=> 2#*3#*5#*7#  (product of first 4 primorials)
```

### Fibonacci, Lucas, and Generalizations

```ruby
say fib(10)                  #=> 55    (10th Fibonacci)
say fib(100)                 # Large Fibonacci number

# Higher-order Fibonacci (k-th order)
say fib(20, 3)               # Tribonacci
say fib(20, 4)               # Tetranacci

# Modular Fibonacci (efficient)
say fibmod(10**9, 10**9+7)   # fib(10^9) mod (10^9+7)

# Lucas numbers
say lucas(10)                #=> 123
say lucas_mod(n, m)          # Efficient modular Lucas

# Fibonacci factorization
say fib_factor(480.fib)
say fib_factor(480.lucas)
```

### Bernoulli and Euler Numbers

```ruby
say bernoulli(10)            # 10th Bernoulli number (exact rational)
say bernoulli(100)           # 100th Bernoulli number
say euler_number(10)         # 10th Euler number
say tangent_number(5)        # 5th tangent (zag) number
```

### Catalan, Motzkin, Bell Numbers

```ruby
say catalan(10)              #=> 16796  (10th Catalan number)
say motzkin(10)              # 10th Motzkin number
say bell(10)                 # 10th Bell number
say fubini(5)                # 5th Fubini (ordered Bell) number
```

### Stirling Numbers

```ruby
say stirling(5, 2)           # Stirling numbers of the first kind  s(5,2)
say stirling2(5, 2)          # Stirling numbers of the second kind S(5,2)
say stirling3(5, 2)          # Stirling numbers of the third kind (Lah numbers)
```

### Binomial and Related Coefficients

```ruby
say binomial(10, 3)          #=> 120
say multinomial(1, 4, 4, 2)  #=> 34650
say catalan(5)               #=> C(10,5)/(5+1)

# Combinations and permutations
5.combinations(2, {|*a| say a })           # 2-subsets of {0..4}
5.tuples(2, {|*a| say a })                 # ordered 2-tuples
5.combinations_with_repetition(2, ...)
```

### Arithmetic-Geometric Mean and Special Functions

```ruby
say agm(1, sqrt(2))          # AGM(1, √2) — related to elliptic integrals
say fusc(20)                 # Stern's diatomic sequence
say harm(10)                 # 10th harmonic number H_10 (exact rational)
say harmreal(100)            # H_100 as floating point
```

---

## 14. Continued Fractions and Rational Approximation

Continued fractions are a powerful tool for Diophantine approximation and solving Pell's equation.

### Computing Continued Fractions

```ruby
# Continued fraction expansion of sqrt(12): [3; 2, 6, 2, 6, ...]
say sqrt(12).cfrac(8)        #=> [3, 2, 6, 2, 6, 2, 6, 2]

# Period of sqrt(n)'s continued fraction
say 28.sqrt_cfrac_period        #=> [3, 2, 3, 10]
say 28.sqrt_cfrac_period_len    # Length of the period

# Convergents: rational approximations p_k/q_k
say Num.pi.convergents(5)    #=> [3, 22/7, 333/106, 355/113, 103993/33102]
```

### Recovering a Rational from its CF

```ruby
# Compute pi from its CF coefficients
say Num.pi.cfrac(10).flip.reduce {|a, b| b + 1/a }.as_rat
#=> 4272943/1360120  (excellent rational approximation to π)
```

> **Tutorial: Pell's Equation**
>
> Pell's equation x² − D·y² = 1 has its fundamental solution encoded in the continued fraction expansion of √D. The fundamental solution is the first convergent p_k/q_k where p_k² − D·q_k² = 1.

```ruby
func pell_fundamental(D) {
    # Return (x, y) the fundamental solution to x^2 - D*y^2 = 1
    var cfrac = D.sqrt_cfrac_period
    var terms = ([D.isqrt] + cfrac*2)
    var (p, q) = (1, 0)
    var (pp, qq) = (0, 1)
    for a in (terms) {
        (p, pp) = (a*p + pp, p)
        (q, qq) = (a*q + qq, q)
        if (p*p - D*q*q == 1) {
            return (p, q)
        }
    }
}

var (x, y) = pell_fundamental(61)
say "x = #{x}, y = #{y}"
# Fundamental solution to x^2 - 61*y^2 = 1
```

---

## 15. Quadratic Forms and Sum of Squares

### Representations as Sums of Squares

```ruby
# Number of ways to write n as a sum of k squares: r_k(n)
say squares_r(5, 2)          # r_2(5) = 8  (representations of 5 as a^2+b^2)
say squares_r(5, 4)          # r_4(5)

# Explicit solutions to n = a^2 + b^2  (with a ≤ b, both positive)
say sum_of_squares(50)       #=> [[1, 7], [5, 5]]
say sum_of_squares(99025)
#=> [[41,312],[48,311],[95,300],[104,297],[183,256],[220,225]]

# Generate r_2(n) sequence
say 30.of { .squares_r(2) }  # OEIS: A004018
say 30.of { .squares_r(4) }  # OEIS: A000118
```

### Quadratic Equations over Integers

```ruby
# Integer solutions to a*x^2 + b*x + c = 0
say [iquadratic_formula(13, -42, -34)]    #=> [3, -1]

# Cubic formula (complex solutions)
say cubic_formula(1, -6, 11, -6)  # x^3 - 6x^2 + 11x - 6 = 0 → [1, 2, 3]
```

### Polygonal Numbers

```ruby
# k-gonal numbers: triangular, square, pentagonal, hexagonal, ...
say polygonal(10, 3)          # 10th triangular number = 55
say polygonal(10, 4)          # 10th square number = 100
say polygonal(10, 5)          # 10th pentagonal number = 145
say polygonal(10, 6)          # 10th hexagonal number = 190

# Is n a k-gonal number?
say 55.is_polygonal(3)        #=> true
say 100.is_polygonal(4)       #=> true

# Find all (r, k) where polygonal(r, k) = n
say polygonal_inverse(4012)   #=> [[2,4012],[4,670],[8,145],[4012,2]]

# Centered polygonal numbers
say centered_polygonal(6, 6)  # 6th centered hexagonal number
```

### Cyclotomic Polynomials

Cyclotomic polynomials are central to algebraic number theory.

```ruby
say cyclotomic(12)            # Φ₁₂(x) = x^4 - x^2 + 1
say cyclotomic(12, 10)        #=> 9901  (evaluate at x=10)

# Modular evaluation
say cyclotomicmod(30!, 5040, 2**128 + 1)
```

---

## 16. Lucas Sequences

Lucas sequences U_n(P, Q) and V_n(P, Q) generalize Fibonacci and Lucas numbers. They are fundamental in primality testing and factorization.

```ruby
# U_n(P, Q) sequences
say 20.of {|n| lucasU(1, -1, n) }    # Fibonacci: U_n(1,-1)
say 20.of {|n| lucasU(2, -1, n) }    # Pell numbers
say 20.of {|n| lucasU(1, -2, n) }    # Jacobsthal numbers

# V_n(P, Q) sequences
say 20.of {|n| lucasV(1, -1, n) }    # Lucas numbers: V_n(1,-1)
say 20.of {|n| lucasV(2, -1, n) }    # Pell-Lucas numbers
say 20.of {|n| lucasV(1, -2, n) }    # Jacobsthal-Lucas numbers

# Efficient modular computation
say lucasUmod(1, -1, 10**9, 10**9+7)    # fib(10^9) mod (10^9+7)
say lucasVmod(1, -1, 10**9, 10**9+7)    # lucas(10^9) mod (10^9+7)

# Compute both U and V simultaneously
var (u, v) = lucasUVmod(P, Q, n, m)

# Chebyshev T polynomials via Lucas V:  T_n(x) = V_n(2x, 1) / 2
say chebyshevT(5, 3)                 # T_5(3)
say chebyshevU(5, 3)                 # U_5(3)
say chebyshevTmod(n, x, m)           # T_n(x) mod m
```

---

## 17. Analytic and Arithmetic Functions

### Zeta and Related Functions

```ruby
say zeta(2)             # ζ(2) = π²/6 ≈ 1.6449...
say zeta(4)             # ζ(4) = π⁴/90
say eta(1)              # Dirichlet eta η(1) = ln 2
say zeta(0.5 + 14.1i)   # Riemann zeta at a complex point

# Log of the n-th prime using Mangoldt function
say exp_mangoldt(8)     # p if 8 = p^k, else 1
say mangoldt(8)         # log(p) if 8 = p^k, else 0
```

### Prime-Counting and Number-Theoretic Asymptotic Functions

```ruby
say li(1e10)                 # Logarithmic integral Li(x)
say li(100)                  #=> 30.12614158...

# Legendre's phi: count of n ≤ x not divisible by first k primes
say legendre_phi(1000, 4)    # Count of n ≤ 1000 not div by 2,3,5,7

# Sum of remainders
say sum_remainders(100, 100)     # Sum_{k=1..100} (100 mod k)

# Geometric sum modulo m
say geometric_summod(100, 2, 1e9+7)  # (2^0 + 2^1 + ... + 2^100) mod (10^9+7)
```

### Class Numbers and Quadratic Forms

```ruby
say hclassno(23)             # Hurwitz-Kronecker class number H(23)
say 30.of { .hclassno.nu }   # Numerators (OEIS: A058305)
```

### Special Constants

```ruby
say Num.pi                   # π = 3.14159265...
say Num.tau                  # τ = 2π = 6.28318...
say Num.phi                  # Golden ratio φ = 1.61803...
say Num.EulerGamma           # Euler-Mascheroni γ = 0.57721...
say Num.C                    # Catalan constant G = 0.91596...
say Num.ln2                  # ln(2) = 0.69314...
```

---

## 18. Working with Large Numbers

Sidef handles arbitrarily large integers natively. Here are practical tips and idioms.

### Integer Roots and Logarithms

```ruby
# Integer square root: largest k with k^2 ≤ n
say isqrt(100)               #=> 10
say isqrt(2**200)            # Exact, huge

# Integer k-th root
say iroot(1000, 3)           #=> 10   (cube root)
say irootrem(1000, 3)        # (10, 0) — root and remainder

# Integer logarithm (floor)
say ilog(1000, 10)           #=> 3    (floor(log_10(1000)))
say ilog2(1024)              #=> 10
say ilog10(999999)           #=> 5
```

### Bit Manipulation

```ruby
say n.popcount               # Number of 1-bits in n
say n.msb                    # Index of most significant bit
say n.lsb                    # Index of least significant bit
say hamdist(a, b)            # Hamming distance between a and b
say setbit(n, k)             # Set k-th bit to 1
say clearbit(n, k)           # Set k-th bit to 0
say flipbit(n, k)            # Toggle k-th bit
```

### Arbitrary-Precision Arithmetic Patterns

```ruby
# Compute factorial of 1000 and count its digits
say 1000!.len                # Number of decimal digits

# Mersenne primality test
func is_mersenne_prime(p) {
    p.is_prime && p.is_mersenne_prime
}
say (2..100 -> grep { is_mersenne_prime(_) })
#=> [2, 3, 5, 7, 13, 17, 19, 31, 61, 89]

# Last digits of large Fibonacci
say fibmod(10**18, 10**9)
```

### Number Representation

```ruby
say 255.as_bin               # Binary: "11111111"
say 255.as_hex               # Hex: "ff"
say 255.as_oct               # Octal: "377"
say 1000000.commify          #=> "1,000,000"
say n.flip                   # Digit reversal in base 10
say n.flip(2)                # Digit reversal in base 2
say n.len                    # Number of digits (base 10)
say n.len(2)                 # Number of binary digits
```

---

## 19. Worked Problems

### Problem 1 — Finding Primes in an Arithmetic Progression

**Problem:** Find all primes of the form 4k + 3 up to 200.

```ruby
say primes(200).grep { _ % 4 == 3 }
# Alternatively, using linear_forms_primes:
say linear_forms_primes(0, 50, [4, 3])  # 4k+3 prime for k=0..50
```

**Dirichlet's theorem** guarantees infinitely many primes in every arithmetic progression a + nd where gcd(a,d) = 1.

---

### Problem 2 — Testing the Goldbach Conjecture

**Problem:** Verify Goldbach's conjecture for even numbers up to 1000 — every even n > 2 is the sum of two primes.

```ruby
func goldbach(n) {
    primes(n/2).find {|p| (n - p).is_prime }
}

for n in (4..1000 `by` 2) {
    var p = goldbach(n)
    if (!p) { say "Goldbach fails at #{n}!" }
    else    { say "#{n} = #{p} + #{n-p}" }
}
```

---

### Problem 3 — Computing the Euler Product for ζ(2)

**Problem:** Numerically verify that Π_{p prime} 1/(1 − p^−2) = π²/6.

```ruby
var product = primes(1e6).prod {|p| (1f / (1 - 1/p**2)) }
say product
say (Num.pi**2 / 6)    # Should be very close
```

---

### Problem 4 — Primitive Roots Modulo a Prime

**Problem:** Find all primitive roots modulo p = 17.

```ruby
var p = 17
var phi_p = (p - 1)    # phi(17) = 16

# A primitive root g has order phi(p) = 16 modulo p
var primitive_roots = (^p).grep {|g| znorder(g, p) == phi_p }
say primitive_roots

# The smallest primitive root
say znprimroot(p)    #=> 3
```

---

### Problem 5 — Smooth Number Factorization (Pollard's p−1)

**Problem:** Factor n = 2^64 + 1 using the p−1 method.

```ruby
var n = (2**64 + 1)
say n.pm1_factor(10000)     # Williams p-1 with bound 10000
# Or use the FLT-based method:
say flt_factor(n, 3, 1e6)
# Result includes 274177 and 67280421310721
```

---

### Problem 6 — Solving a Quadratic Congruence

**Problem:** Find all x such that x² ≡ 7 (mod 55).

```ruby
say sqrtmod_all(7, 55)
# Try legendre to check QR status first
say jacobi(7, 55)
```

---

### Problem 7 — Amicable Chains (Aliquot Sequences)

**Problem:** Compute the aliquot sequence starting at 12496 and verify it is a 5-cycle.

```ruby
func aliquot_sequence(start, steps) {
    var seq = [start]
    var n = start
    steps.times {
        n = aliquot(n)   # sigma(n) - n
        seq.append(n)
        break if ((n == 0) || (n == seq[0]))
    }
    seq
}
say aliquot_sequence(12496, 10)
# Should return [12496, 14288, 15472, 14536, 14264, 12496]
```

---

### Problem 8 — Counting Squarefree Numbers

**Problem:** How many squarefree numbers are there up to 10^9? Verify using the Möbius function.

```ruby
say squarefree_count(10**9)

# The exact formula: Sum_{k=1..sqrt(n)} mu(k) * floor(n/k^2)
func squarefree_count_manual(n) {
    (1..isqrt(n)).sum {|k| mu(k) * (n // k**2) }
}
say squarefree_count_manual(10**6)
say squarefree_count(10**6)       # Should match
```

---

### Problem 9 — The Collatz Sequence

**Problem:** Find the number below 1000 with the longest Collatz sequence.

```ruby
var best = (1..999).max_by { .collatz }
say "#{best} has Collatz length #{best.collatz}"
```

---

### Problem 10 — Large Prime Factorization Strategy

**Problem:** Factor a product of two 30-digit primes (RSA-style).

```ruby
# Generate two random 30-digit primes
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

# Try factoring
say n.ecm_factor(50000)         # ECM with bound 50000
say n.special_factor(2)         # Try multiple methods
```

---

## 20. Function Quick-Reference Cheat Sheet

### Primality

| Function | Description |
|---|---|
| `n.is_prime` | Baillie-PSW primality test |
| `n.is_provable_prime` | Rigorous certificate |
| `n.is_strong_psp(b)` | Miller-Rabin to base b |
| `n.is_bpsw_prime` | Full Baillie-PSW |
| `n.is_mersenne_prime` | Mersenne prime test |
| `k.carmichael(n)` | k-factor Carmichael numbers ≤ n |
| `lambda(n)` | Carmichael lambda function |

### Primes

| Function | Description |
|---|---|
| `prime(n)` | n-th prime |
| `primes(a, b)` | Primes in [a, b] |
| `primepi(n)` | π(n) — prime counting function |
| `prime_sum(n)` | Sum of primes ≤ n |
| `n.next_prime` | Next prime after n |
| `n.prev_prime` | Previous prime before n |
| `primorial(n)` | Product of primes ≤ n |
| `gpf(n)` | Greatest prime factor |
| `lpf(n)` | Least prime factor |
| `prime_cluster(lo,hi,*d)` | Prime clusters with given gaps |

### Factorization

| Function | Description |
|---|---|
| `n.factor` | Full prime factorization |
| `n.factor_exp` | Factorization as [p,e] pairs |
| `n.prime_divisors` | Unique prime factors |
| `n.pm1_factor(B)` | Pollard p−1 |
| `n.pp1_factor(B)` | Williams p+1 |
| `n.ecm_factor(B)` | Elliptic curve method |
| `n.cyclotomic_factor` | Cyclotomic factoring |
| `n.special_factor` | Auto multi-method |
| `gcd(a, b)` | Greatest common divisor |
| `gcdext(a, b)` | Extended GCD → (u, v, d) |
| `lcm(a, b)` | Least common multiple |

### Multiplicative Functions

| Function | Description |
|---|---|
| `phi(n)` / `euler_phi(n)` | Euler totient φ(n) |
| `sigma(n)` | Sum of divisors σ(n) |
| `sigma(n, k)` | Sum of k-th powers of divisors σ_k(n) |
| `tau(n)` | Number of divisors τ(n) |
| `mu(n)` / `moebius(n)` | Möbius function μ(n) |
| `omega(n)` | ω(n) — distinct prime factors |
| `bigomega(n)` | Ω(n) — prime factors with multiplicity |
| `liouville(n)` | Liouville function (−1)^Ω(n) |
| `psi(n)` | Dedekind psi function ψ(n) |
| `sopfr(n)` | Sum of prime factors (with repetition) |
| `mertens(n)` | Mertens function M(n) |

### Divisors

| Function | Description |
|---|---|
| `n.divisors` | All positive divisors |
| `n.udivisors` | Unitary divisors |
| `n.proper_divisors` | Divisors less than n |
| `n.prime_power_divisors` | Prime power divisors |
| `n.squarefree_divisors` | Squarefree divisors |
| `n.square_divisors` | Square divisors |
| `inverse_sigma(n)` | Solve σ(x) = n |
| `inverse_phi(n)` | Solve φ(x) = n |

### Modular Arithmetic

| Function | Description |
|---|---|
| `powmod(a, n, m)` | a^n mod m |
| `invmod(a, m)` | a⁻¹ mod m |
| `sqrtmod(a, m)` | √a mod m |
| `sqrtmod_all(a, n)` | All square roots of a mod n |
| `znorder(a, m)` | Multiplicative order of a mod m |
| `znlog(a, g, m)` | Discrete log: g^k ≡ a (mod m) |
| `znprimroot(n)` | Smallest primitive root mod n |
| `legendre(a, p)` | Legendre symbol (a|p) |
| `jacobi(a, n)` | Jacobi symbol (a|n) |
| `kronecker(a, n)` | Kronecker symbol (a|n) |
| `linear_congruence(n,r,m)` | Solve n*x ≡ r (mod m) |

### Sequences and Special Numbers

| Function | Description |
|---|---|
| `fib(n)` | n-th Fibonacci number |
| `lucas(n)` | n-th Lucas number |
| `bernoulli(n)` | n-th Bernoulli number |
| `catalan(n)` | n-th Catalan number |
| `bell(n)` | n-th Bell number |
| `stirling(n, k)` | Stirling numbers 1st kind |
| `stirling2(n, k)` | Stirling numbers 2nd kind |
| `polygonal(n, k)` | n-th k-gonal number |
| `sum_of_squares(n)` | Solutions to n = a² + b² |
| `squares_r(n, k)` | r_k(n) — representations as k squares |

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
| `is_amicable(m, n)` | σ(m)−m = n and σ(n)−n = m |

---

## Appendix A: Further Reading

- **OEIS Integration:** Many Sidef sequences correspond directly to OEIS entries. In the source code, you will often see comments like `# OEIS: A000040` to cross-reference.
- **PARI/GP Compatibility:** Many function names and semantics are compatible with PARI/GP. Users familiar with PARI will find Sidef intuitive.
- **External Tools:** For very large inputs, Sidef can delegate to specialized tools: set `Num!USE_YAFU`, `Num!USE_PARI_GP`, `Num!USE_PRIMECOUNT`, or `Num!USE_FACTORDB` to `true` as needed.
- **Arbitrary Precision:** There is no fixed integer size. All integer methods work correctly on numbers with thousands of digits.

## Appendix B: Common Recipes

This short appendix collects a few patterns that are useful in practice when working with the rest of the guide.

### Sanity-check a factorization

```ruby
func verify_factorization(n) {
    n.factor_exp.map_2d {|p, e| p**e }.prod == n
}

say verify_factorization(5040)      #=> true
```

### Fast primality triage

```ruby
func triage(n) {
    if (n < 2) {
        return "not prime"
    }
    if (n.is_prime) {
        return "prime"
    }
    if (n.is_perfect_power) {
        return "perfect power, not prime"
    }
    return "composite"
}

say triage(2**127 - 1)
```

### A small modular-arithmetic loop

```ruby
var m = 1_000_000_007
var a = 2
var s = 0

for n in (1..1000) {
    s = addmod(s, powmod(a, n, m), m)
}

say s
```

### Find a nearby prime

```ruby
func next_prime_at_least(n) {
    n.is_prime ? n : n.next_prime
}

say next_prime_at_least(10**12)
```

---

*This guide covers the `Sidef::Types::Number::Number` class. For additional functionality related to arrays, strings, and other types, consult the full Sidef documentation.*
