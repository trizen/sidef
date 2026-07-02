# Computational Number Theory with Sidef

> **Sidef** is a high-level, multi-paradigm programming language with deep, built-in support for number theory. Its `Number` class provides arbitrary-precision integers, rationals, floats, and complex numbers, together with over 1,000 number-theoretic functions — from basic divisibility tests to advanced primality algorithms, integer factorization, multiplicative functions, and analytic number theory tools. Performance is comparable to PARI/GP and Mathematica, backed by the [GMP](https://gmplib.org/), [MPFR](https://www.mpfr.org/), and [MPC](https://www.multiprecision.org/) C libraries.

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

1. [Notation and Conventions](#notation-and-conventions)
2. [Getting Started](#getting-started)
3. [The Number System](#the-number-system)
4. [Precision and Configuration](#precision-and-configuration)
5. [Arithmetic Operators](#arithmetic-operators)
6. [Number-Theoretic Function Reference](#number-theoretic-function-reference)
7. [Generating Sequences](#generating-sequences)
8. [User-Defined Functions](#user-defined-functions)
9. [Built-in Classes](#built-in-classes)
10. [Primality Testing](#primality-testing)
11. [Prime Numbers and Prime Counting](#prime-numbers-and-prime-counting)
12. [Integer Factorization](#integer-factorization)
13. [Divisors and Divisor Functions](#divisors-and-divisor-functions)
14. [Modular Arithmetic](#modular-arithmetic)
15. [Euler's Totient and Related Functions](#eulers-totient-and-related-functions)
16. [Multiplicative Functions](#multiplicative-functions)
17. [Special Number Classes](#special-number-classes)
18. [Sequences and Combinatorics](#sequences-and-combinatorics)
19. [Continued Fractions and Rational Approximation](#continued-fractions-and-rational-approximation)
20. [Quadratic Forms and Sum of Squares](#quadratic-forms-and-sum-of-squares)
21. [Lucas Sequences](#lucas-sequences)
22. [Analytic and Arithmetic Functions](#analytic-and-arithmetic-functions)
23. [Working with Large Numbers](#working-with-large-numbers)
24. [Computing OEIS Sequences](#computing-oeis-sequences)
25. [Making Sidef Faster](#making-sidef-faster)
26. [Tips, Tricks, and Common Pitfalls](#tips-tricks-and-common-pitfalls)
27. [Worked Problems](#worked-problems)
28. [Quick-Reference Cheat Sheet](#quick-reference-cheat-sheet)
29. [Sieve Algorithms](#sieve-algorithms)
30. [Primality Testing - Algorithm Deep Dives](#primality-testing---algorithm-deep-dives)
31. [Factorization Algorithm Deep Dives](#factorization-algorithm-deep-dives)
32. [Discrete Logarithms and Related Problems](#discrete-logarithms-and-related-problems)
33. [Chinese Remainder Theorem - Extended Applications](#chinese-remainder-theorem---extended-applications)
34. [Quadratic Reciprocity and Residue Theory](#quadratic-reciprocity-and-residue-theory)
35. [The Prime Number Theorem and Analytic Methods](#the-prime-number-theorem-and-analytic-methods)
36. [Smooth Numbers, Factor Bases, and Subexponential Factorization](#smooth-numbers-factor-bases-and-subexponential-factorization)
37. [p-Adic Arithmetic and Valuations](#p-adic-arithmetic-and-valuations)
38. [Dirichlet Series and Multiplicative Structure](#dirichlet-series-and-multiplicative-structure)
39. [Elliptic Curves in Number Theory](#elliptic-curves-in-number-theory)
40. [Algebraic Number Theory Constructs](#algebraic-number-theory-constructs)
41. [Cryptographic Applications](#cryptographic-applications)
42. [Number-Theoretic Transforms and Convolutions](#number-theoretic-transforms-and-convolutions)
43. [Computational Complexity in Number Theory](#computational-complexity-in-number-theory)
44. [Advanced OEIS Techniques and Sequence Acceleration](#advanced-oeis-techniques-and-sequence-acceleration)

- [Appendix A: Common Recipes](#appendix-a-common-recipes)
- [Appendix B: Further Reading and Resources](#appendix-b-further-reading-and-resources)

---

## Notation and Conventions

| Notation | Meaning |
|---|---|
| `φ(n)` | Euler's totient function |
| `μ(n)` | Möbius function |
| `τ(n)` | Number of divisors |
| `σ_k(n)` | Sum of k-th powers of divisors |
| `ω(n)` | Number of distinct prime factors |
| `Ω(n)` | Number of prime factors counted with multiplicity |
| `λ(n)` | Carmichael’s lambda function |
| `ψ(n)` | Dedekind psi function |

Reading conventions used throughout this document:

- `say` prints a value followed by a newline.
- `var` introduces a variable.
- `func` defines a function.
- `local` temporarily changes a global setting inside a function or block.
- Most functions appear in both standalone form (`is_prime(n)`) and method-call form (`n.is_prime`) — both are equivalent.

---

## Getting Started

For installation instructions and basic language features, refer to the [beginner's tutorial](https://github.com/trizen/sidef/blob/master/SIDEF_BEGINNER_GUIDE.md).

### Starting the REPL

After installing Sidef, launch the interactive environment with the `sidef` command:

```console
$ sidef
Sidef 26.07, running on Linux, using Perl v5.42.1.
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

**Key things to know before you start:**

- Every integer, rational, float, and complex number is a `Number` object.
- The `say` function prints its argument followed by a newline.
- Ranges are written `a..b` (inclusive) and `a..^b` (exclusive of `b`).
- Blocks are written `{ ... }` and receive arguments via `|param|`.
- `n.of { block }` generates an array of `n` values by calling the block with indices 0, 1, …, n−1.
- `n.by { block }` generates the first `n` non-negative integers for which the block returns true.

```ruby
# Generate the first 10 Fibonacci numbers
say 10.of { .fib }       #=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

# Sum of primes up to 100
say prime_sum(100)       #=> 1060

# First prime larger than 10^18
say next_prime(10**18)
```

---

## The Number System

Sidef's numbers are arbitrarily precise — there is no practical size limit.

### Integer Literals and Bases

```ruby
var a = 42               # Decimal integer
var b = 0b1101           # Binary  (= 13)
var c = 0x1F4            # Hex     (= 500)
var d = 0777             # Octal   (= 511)

# Construct a number from a string in a given base
var e = Number("101010", 2)   # Binary "101010" = 42
var f = Number("ff",    16)   # Hex    "ff"     = 255
```

### Rationals

Sidef performs exact rational arithmetic automatically. Use `as_frac` or `as_rat` to inspect the rational representation:

```ruby
say (1/3 + 1/6)            #=> 1/2
say as_frac(355/113)       #=> 355/113
say (22/7 - Num.pi)        # Small floating-point difference
```

### Floating-Point

Use `Num!PREC` to control precision in bits (default is 192 bits ≈ 57 significant decimal digits):

```ruby
local Num!PREC = 512       # Set 512-bit precision locally
say sqrt(2)                # Very high-precision sqrt(2)
```

**Rounding modes** for `Num!ROUND`:

| Value | Mode |
|---|---|
| 0 | Round to nearest (default) |
| 1 | Round towards zero (truncate) |
| 2 | Round towards +∞ (ceiling) |
| 3 | Round towards −∞ (floor) |

### Complex Numbers

```ruby
var z = 3:4               # 3 + 4i
say z                     #=> 3+4i
say Complex(3, 4).abs     #=> 5
say 42.i                  #=> 42i
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

# Eisenstein integers can be created as:
var w = Quadratic(0, 1, -1, -1)
var z = (3 + 4*w)
say z.to_n              #=> 1 + 3.46410161513775[...]i
```

---

## Precision and Configuration

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
| `Num!USE_PRIMECOUNT` | false | Use Kim Walisch's primecount |
| `Num!USE_PRIMESUM` | false | Use Kim Walisch's primesum |
| `Num!USE_CONJECTURES` | false | Enable conjectured (faster) methods |

Use `local` to restrict changes to a function scope:

```ruby
func high_precision_pi {
    local Num!PREC = 4096
    say Num.pi         # Pi to ~1200 decimal places
}
high_precision_pi()
say Num.pi             # back to default 192-bit precision
```

---

## Arithmetic Operators

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

## Number-Theoretic Function Reference

For the full documentation, see: [Sidef Number Class](https://metacpan.org/pod/Sidef::Types::Number::Number).

---

## Generating Sequences

The first $n$ terms of a sequence can be generated with:

```ruby
n.by {|k| ... }         # first n non-negative integers for which block is true
n.of {|k| ... }         # call block with first n integers (0..n-1), collect results
map(a..b, {|k| ... })   # map function over range, return array
{|k| ... }.map(a..b)    # same as above
```

### Examples

```ruby
say 10.by { .is_composite }    #=> [4, 6, 8, 9, 10, 12, 14, 15, 16, 18]
say 10.of { .phi }             #=> [0, 1, 1, 2, 2, 4, 2, 6, 4, 6]
say map(20..30, { .phi })      #=> [8, 12, 10, 22, 8, 20, 12, 18, 12, 28, 8]
```

### Infinite Lazy Sequences

The `Math.seq()` function constructs an infinite lazy sequence:

```ruby
say Math.seq(2, {|a| a[-1].next_prime }).first(30)
say Math.seq(0, 1, {|a| a.last(2).sum }).first(30)           # Fibonacci
say Math.seq(1, {|a| a[-1].next_omega_prime(2) }).first(20)
```

---

## User-Defined Functions

Functions are defined with the `func` keyword:

```ruby
func function_name(a, b, c) {
    # body
}
```

A function name can be passed as a block argument to built-in methods:

```ruby
func my_condition(n) { n.is_composite && n.is_squarefree }
say 10.by(my_condition)
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
func harmonic(n) { sum(1..n, {|k| 1/k }) }
say 8.of(harmonic)    #=> [0, 1, 3/2, 11/6, 25/12, 137/60, 49/20, 363/140]

func superfactorial(n) { prod(1..n, {|k| k! }) }
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

## Built-in Classes

### Mod Class

The `Mod(a, m)` class constructs a modular object, similar to PARI/GP's `Mod`:

```ruby
var a = Mod(13, 97)

say a**42    #=> Mod(85, 97)
say 42*a     #=> Mod(61, 97)

say chinese(Mod(43, 19), Mod(13, 41))   # Chinese Remainder Theorem
```

### Poly and PolyMod Classes

```ruby
say Poly(5)                   # monomial: x^5
say Poly([1,2,3,4])           # x^3 + 2*x^2 + 3*x + 4

var a = PolyMod([13,4,51], 43)
var b = PolyMod([5,0,-11], 43)
say a*b
say [a.divmod(b)].join(' and ')
```

### Gauss Class

Represents a Gaussian integer $a + bi$:

```ruby
var a = Gauss(17, 19)
var b = Gauss(43, 97)

say (a + b)     #=> Gauss(60, 116)
say (a * b)     #=> Gauss(-1112, 2466)
say Gauss(3, 4)**100
say Mod(Gauss(3, 4), 1000001)**100
```

### Quadratic Class

Represents a quadratic integer $a + b\sqrt{w}$:

```ruby
var x = Quadratic(3, 4, 5)      # 3 + 4*sqrt(5)
say x**10
say x.powmod(100, 97)
```

### Quaternion Class

Represents a quaternion $a + bi + cj + dk$:

```ruby
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)

say (a * b)         #=> Quaternion(-60, 12, 30, 24)
say a**5
say a.powmod(43, 97)
```

### Matrix Class

```ruby
var A = Matrix(
    [2, -3,  1],
    [1, -2, -2],
    [3, -4,  1],
)

say A**20
say A**-1
say A.powmod(43, 97)
say A.det
say A.solve([1,2,3])
```

---

## Primality Testing

Sidef provides a comprehensive suite of primality tests, from quick probabilistic checks to rigorous deterministic proofs.

### Quick Primality Check

```ruby
say 97.is_prime           #=> true
say 100.is_prime          #=> false
say is_prime(2**127 - 1)  #=> true  (Mersenne prime M_127)
```

`is_prime` uses Baillie-PSW (trial division + Miller-Rabin + Lucas), which has no known counterexamples and is deterministic for n < 2^64.

### Full Primality Test Hierarchy

```ruby
say n.primality_pretest            # fast small-factor detection

say n.is_fermat_psp(2)             # Fermat pseudoprime to base 2
say n.is_euler_psp(2)              # Euler pseudoprime to base 2
say n.is_strong_psp(2)             # Miller-Rabin to base 2
say n.miller_rabin_random(20)      # Miller-Rabin with 20 random bases

say n.is_lucas_psp                 # Lucas pseudoprime (standard)
say n.is_strong_lucas_psp          # Strong Lucas pseudoprime
say n.is_extra_strong_lucas_psp    # Extra-strong Lucas pseudoprime
say n.is_almost_extra_strong_lucas_psp

say n.is_bpsw_prime                # full Baillie-PSW test
say n.is_provable_prime            # rigorous certificate (slow for large n)
say n.is_aks_prime                 # AKS deterministic test (very slow)
```

### Special Prime Forms

```ruby
say n.is_mersenne_prime     # true if 2^n - 1 is prime
say n.is_prime_power        # true if n = p^k, for some prime p

say prime_power(43**5)           #=> 5   (the exponent k)
say prime_root(43**5)            #=> 43  (the prime base p)
```

### Pseudoprimes and Carmichael Numbers

```ruby
say 3.carmichael(1e4)            # all 3-factor Carmichael numbers up to 10^4
say 3.fermat_psp(2, 1e6)         # Fermat pseudoprimes to base 2
say lambda(561)                  # Carmichael lambda of the first Carmichael number
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

When several numbers need simultaneous primality verification, `all_prime(...)` is faster than individual `is_prime(n)` calls — if one term has small prime factors, it returns early:

```ruby
all_prime(a, b)      # faster than: (is_prime(a) && is_prime(b))
```

---

## Prime Numbers and Prime Counting

### Generating and Navigating Primes

```ruby
say prime(1)              #=> 2
say prime(100)            #=> 541

say primes(50)        # all primes up to 50
say primes(50, 100)   # primes in [50, 100]

say 97.next_prime         #=> 101
say 100.prev_prime        #=> 97

say 5.next_primes(100)    # 5 primes after 100: [101, 103, 107, 109, 113]
say 5.prev_primes(100)    # 5 primes before 100
```

### Prime Counting Function π(n)

```ruby
say primepi(100)           #=> 25
say primepi(50, 100)       #=> 10
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
prime_sum(100)          # sum of primes ≤ 100
prime_sum(50, 100)      # sum of primes in [50,100]
prime_sum(1, 100, 2)    # sum of squares of primes ≤ 100
prime_power_sum(100)    # sum of prime powers ≤ 100
prime_power_count(100)  # count of prime powers ≤ 100
```

### Special Prime Families

```ruby
prime_cluster(1, 1000, 2)         # twin primes (p, p+2)
prime_cluster(1, 1000, 2, 6)      # prime triplets (p, p+2, p+6)
primorial(10)                     # product of primes ≤ 10 → 210
5.pn_primorial                    # product of first 5 primes → 2310
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

## Integer Factorization

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

`special_factor(n)` automatically tries trial division, Fermat, HOLF, Sophie Germain, Pell, Phi-finder, Difference/Congruence of Powers, Miller, Lucas, Fibonacci, FLT, Pollard's p−1, Pollard's rho, Williams' p+1, Chebyshev, Cyclotomic, and Lenstra's ECM.

Individual methods:

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
| `n.dop_factor(tries)` | Algebraic (difference of powers) |
| `n.prho_factor(tries)` | Pollard's rho |
| `n.pbrent_factor(tries)` | Pollard-Brent |
| `n.qs_factor` | Quadratic sieve |
| `n.special_factor(effort)` | Auto-selects multiple methods |

```ruby
# Examples where special_factor excels
say special_factor(lucas(480))                   # 0.01s
say special_factor(fibonacci(480))               # 0.01s
say special_factor(2**512 - 1)                   # 0.8s, 12 factors
say special_factor((3**120 + 1) * (5**240 - 1))  # 0.1s
```

### GCD, LCM, and Extended GCD

```ruby
say gcd(48, 36)             #=> 12
say lcm(48, 36)             #=> 144

var (u, v, d) = gcdext(35, 15)    # u*35 + v*15 = gcd(35,15) = 5

say consecutive_lcm(10)     #=> 2520
say gcud(12, 18)        # greatest common unitary divisor
```

### Finding Closed Forms and Linear Recurrences

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

## Divisors and Divisor Functions

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

## Modular Arithmetic

Modular arithmetic is the backbone of much of computational number theory.

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
say sqrtmod(544, 800)                #=> 512
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

These are essential for quadratic residuosity and primality testing.

```ruby
say legendre(7, 13)        # Legendre symbol (7|13)
say jacobi(10, 21)         # Jacobi symbol (10|21)
say kronecker(5, 8)        # Kronecker symbol (5|8)

# List all quadratic residues mod 13
say (1..12 -> grep {|a| legendre(a, 13) == 1 })
#=> [1, 3, 4, 9, 10, 12]
```

> **Euler's Criterion:** $a^{(p-1)/2} \equiv \left(\frac{a}{p}\right) \pmod{p}$

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

var m = Mod(2, 1000)**100    # cleanest approach
say m/3
```

---

## Euler's Totient and Related Functions

### Euler's Totient φ(n)

φ(n) counts integers in [1, n] coprime to n — it is the order of the multiplicative group (Z/nZ)*:

```ruby
euler_phi(12)          #=> 4
phi(100)               #=> 40
jordan_totient(n, 3)   # J_3(n)
totient_sum(100)       # Sum_{j=1..n} φ(j)
totient_range(7, 17)   # batch computation
uphi(n)                # unitary totient
```

### Carmichael's Lambda λ(n)

λ(n) is the exponent of (Z/nZ)* — the smallest $m$ such that $a^m \equiv 1 \pmod{n}$ for all $a$ coprime to $n$:

```ruby
lambda(12)             #=> 2
lambda(1000)           #=> 100
```

---

## Multiplicative Functions

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

> **Möbius Inversion:** If $g(n) = \sum_{d|n} f(d)$, then $f(n) = \sum_{d|n} \mu(n/d)\, g(d)$.

### Liouville Function and Omega Counts

```ruby
bigomega(12)           #=> 3   (Ω(12))
omega(12)              #=> 2   (ω(12))
liouville(12)          #=> -1  ((-1)^Ω(12))
```

### Dedekind Psi Function

$\psi(n) = n \cdot \prod_{p \mid n} (1 + 1/p)$:

```ruby
psi(n)                 # ψ(n) = n * ∏_{p|n} (1+1/p)
inverse_psi(120)       # solutions to ψ(x)=120 → [75,76,87,95]
```

### Sum of Prime Factors

```ruby
say sopfr(12)             #=> 7   (2+2+3, with repetition)
say sopf(12)              #=> 5   (2+3, distinct primes only)
```

### Dirichlet Convolution

```ruby
n.dirichlet_convolution({.phi}, {1})   # sigma = φ * 1
n.dirichlet_convolution({.mu}, {_})    # identity
```

---

## Special Number Classes

### Perfect, Abundant, and Deficient Numbers

$\sigma(n) - n$ is the sum of proper divisors. A number is **perfect** if $\sigma(n) = 2n$, **abundant** if $\sigma(n) > 2n$, **deficient** if $\sigma(n) < 2n$:

```ruby
say 6.is_perfect           #=> true  (6 = 1+2+3)
say 12.is_abundant         #=> true
say 8.is_deficient         #=> true

say is_amicable(220, 284)  #=> true
say aliquot(12)            #=> 16   (sigma(12) - 12)

say 30.by { .is_abundant }
say 30.by { .is_odd && .is_abundant }
```

### Squarefree and Powerful Numbers

```ruby
say n.is_squarefree          # true if n has no repeated factors
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
say n.next_palindrome(16)        # Next base-16 palindrome > n

# Iterate over all base-10 palindromes up to 10^6
for (var n = 0; n < 1e6; n = n.next_palindrome) {
    say n
}
```

---

## Sequences and Combinatorics

### Factorials and Variants

```ruby
say 10!                           #=> 3628800
say 9!!                           #=> 945         (9*7*5*3*1)
say mfac(9, 3)                    # triple factorial: 9*6*3
say subfactorial(5)               #=> 44           (derangements)
say hyperfactorial(5)             # 1^1 * 2^2 * 3^3 * 4^4 * 5^5
say superfactorial(4)             # 1! * 2! * 3! * 4!
say superprimorial(4)             # product of first 4 primorials
```

### Fibonacci, Lucas, and Generalizations

```ruby
say fib(10)                  #=> 55
say fib(20, 3)               # Tribonacci
say fibmod(10**9, 10**9+7)

say lucas(10)                #=> 123
say 25.of{|n| lucasU(1,-1,n) }   # Fibonacci via Lucas U
say 25.of{|n| lucasU(2,-1,n) }   # Pell numbers
say 25.of{|n| lucasU(1,-2,n) }   # Jacobsthal numbers
say 25.of{|n| lucasV(1,-1,n) }   # Lucas numbers
say 25.of{|n| lucasV(2,-1,n) }   # Pell-Lucas numbers
```

### Bernoulli, Euler, Bell, Catalan, Motzkin, Stirling

```ruby
say bernoulli(10)            # 10th Bernoulli number (exact rational)
say euler_number(10)         # 10th Euler number
say tangent_number(5)        # 5th tangent number

say catalan(10)              #=> 16796 (10th Catalan number)
say motzkin(10)              # 10th Motzkin number
say bell(10)                 # 10th Bell number
say fubini(5)                # 5th Fubini (ordered Bell) number

say stirling(5, 2)           # Stirling numbers of the first kind  s(5,2)
say stirling2(5, 2)          # Stirling numbers of the second kind S(5,2)
say stirling3(5, 2)          # Stirling numbers of the third kind (Lah numbers)
```

### Binomial Coefficients

```ruby
say binomial(10, 3)          #=> 120
say multinomial(1, 4, 4, 2)  #=> 34650
say binomialmod(n, k, m)     # binomial(n,k) mod m
```

### Polygonal and Pyramidal Numbers

```ruby
say polygonal(10, 3)          # 10th triangular = 55
say polygonal(10, 5)          # 10th pentagonal = 145

say centered_polygonal(6, 6)  # 6th centered hexagonal number
say pyramidal(10, 3)          # 10th tetrahedral number

say 55.is_polygonal(3)        #=> true
say polygonal_inverse(4012)   #=> [[2, 4012], [4, 670], [8, 145], [4012, 2]]
```

### Special Functions

```ruby
say agm(1, sqrt(2))          # AGM(1, √2) — related to elliptic integrals
say fusc(20)                 # Stern's diatomic sequence
say harm(10)                 # 10th harmonic number H_10 (exact rational)
say harmreal(100)            # H_100 as floating point
```

---

## Continued Fractions and Rational Approximation

Continued fractions are a powerful tool for Diophantine approximation and solving Pell's equation.

```ruby
# Continued fraction expansion of sqrt(12)
say sqrt(12).cfrac(8)           #=> [3, 2, 6, 2, 6, 2, 6, 2]

say 28.sqrt_cfrac_period_len
say sqrt_cfrac(61)

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
    # Return (x, y) the fundamental solution to x^2 - D*y^2 = 1
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

var (x, y) = pell_fundamental(61)
say "x = #{x}, y = #{y}"
# Fundamental solution to x^2 - 61*y^2 = 1
```

---

## Quadratic Forms and Sum of Squares

### Representations as Sums of Squares

The function `squares_r(n, k)` counts the number of ways to write $n$ as a sum of $k$ squares:

```ruby
say 30.of { .squares_r(2) }     # OEIS: A004018
say 30.of { .squares_r(3) }     # OEIS: A005875
say 30.of { .squares_r(4) }     # OEIS: A000118

# Explicit solutions to n = a^2 + b^2
say sum_of_squares(50)           #=> [[1, 7], [5, 5]]
```

### Gaussian Integer Factorization

```ruby
say is_gaussian_prime(3, 0)     # true
say is_gaussian_prime(5, 0)     # false (= (2+i)(2-i))

say factor(Gauss(5,0))      #=> [Gauss(0, -1), Gauss(1, 2), Gauss(2, 1)]
```

### Cyclotomic Polynomials

```ruby
say cyclotomic(12)               # Φ₁₂(x) = x^4 - x^2 + 1
say cyclotomic(12, 10)           #=> 9901
cyclotomicmod(100, 3, 1000) # Φ₁₀₀(3) mod 1000

for n in (1..10) {
    say "Φ_#{n}(x) = #{cyclotomic(n)}"
}
```

### Solving Polynomial Equations

```ruby
say [quadratic_formula(13, -42, -34)]
say [iquadratic_formula(13, -42, -34)]   #=> [3, -1] (integer roots)
say [solve_pell(863)]                    #=> [18524026608, 630565199]
say modular_quadratic_formula(1, 2*162 + 1, 162**2, 10**27)
```

---

## Lucas Sequences

Lucas sequences $U_n(P, Q)$ and $V_n(P, Q)$ generalize Fibonacci and Lucas numbers, and are fundamental to primality testing and factorization:

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
say chebyshevUmod(n, x, m)           # U_n(x) mod m
```

---

## Analytic and Arithmetic Functions

### Zeta and Related Functions

```ruby
zeta(2)             # ζ(2) = π²/6 ≈ 1.6449...
eta(1)              # Dirichlet eta η(1) = ln 2
exp_mangoldt(8)     # p if 8 = p^k, else 1
mangoldt(8)         # log(p) if 8 = p^k, else 0
```

### Asymptotic Functions

```ruby
li(1e10)                   # logarithmic integral
legendre_phi(1000, 4)      # count of n ≤1000 not divisible by first 4 primes
sum_remainders(100, 100)   # Σ_{k=1..100} (100 mod k)
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

## Working with Large Numbers

Sidef handles arbitrarily large integers natively.

### Integer Roots and Logarithms

```ruby
say isqrt(2**200)            # Exact integer square root
say iroot(1000, 3)           #=> 10   (integer cube root)
say ilog(1000, 10)           #=> 3    (floor(log_10(1000)))
say ilog2(1024)              #=> 10
```

### Bit Manipulation

```ruby
say n.popcount               # number of 1-bits
say n.msb                    # index of most significant bit
say n.lsb                    # index of least significant bit
say hamdist(a, b)            # Hamming distance
```

### Number Representation

```ruby
say 255.as_bin               # "11111111"
say 255.as_hex               # "ff"
say 1000000.commify          #=> "1,000,000"
say n.len                    # decimal digits
say n.len(2)                 # binary digits
```

### Arbitrary-Precision Patterns

```ruby
say 1000!.len                # number of decimal digits in 1000!

# Last digits of a large Fibonacci
say fibmod(10**18, 10**9)

# Mersenne prime exponents
say (2..100 -> grep { .is_mersenne_prime })
#=> [2, 3, 5, 7, 13, 17, 19, 31, 61, 89]
```

---

## Computing OEIS Sequences

Sidef is particularly useful for generating sequences for the [OEIS](https://oeis.org):

```ruby
say map(1..50, { .mu })
say map(1..50, { .tau })
say map(1..50, { .phi })
say map(1..50, { .sigma })
say map(1..50, { .sopfr })

say 30.by { .is_abundant }
say 30.by { .is_semiprime }
say 30.by { .is_palindrome }
say 30.by { .is_palindrome(2) }

say 30.of { .fib }
say 30.of { .lucas }
say 20.of { .bell }
say 20.of { .factorial }

say map(1..30, { .ramanujan_tau })
say 50.of {|n| polygonal(n, 3) }
say 50.of {|n| polygonal(n, 5) }
```

### OEIS Autoload

[OEIS autoload](https://github.com/trizen/oeis-autoload) allows using OEIS sequence IDs directly as functions:

```console
sidef oeis.sf 'A060881(n)' 0 9
sidef oeis.sf 'A033676(n)^2 + A033677(n)^2' 5 20
sidef oeis.sf 'sum(1..n, {|k| A000330(k) })'
```

Or include the library in a script:

```ruby
include OEIS
say map(1..10, {|k| A000330(k) })
```

---

## Making Sidef Faster

### External Tool Integration

```ruby
Num!USE_YAFU        = true   # YAFU for factoring large integers
Num!USE_PFGW        = true   # PFGW64 as primality pretest
Num!USE_PARI_GP     = true   # PARI/GP in several functions
Num!USE_FACTORDB    = true   # factordb.com for factoring
Num!USE_PRIMESUM    = true   # Kim Walisch's primesum
Num!USE_PRIMECOUNT  = true   # Kim Walisch's primecount
Num!USE_CONJECTURES = true   # conjectured (faster) bounds
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

---

## Tips, Tricks, and Common Pitfalls

### Probabilistic Squarefree Checking

When full factorization is unnecessary, `is_prob_squarefree(n, B)` checks only for square factors $p^2$ with $p \leq B$:

```ruby
say is_prob_squarefree(2**512 - 1, 1e6)     # true  (probably squarefree)
say is_prob_squarefree(10**136 + 1, 1e3)    # false (definitely not squarefree)
```

If $n < B^3$ and the function returns `true`, then $n$ is definitely squarefree.

### Integer Overflow — There Isn't Any

```ruby
var n = 2**1000
say n.is_prime      # Checks primality of a 1000-bit number — no overflow
```

### Debugging

```ruby
Num!VERBOSE = true

var n = (2**128 + 1)
say factor(n)

var start = Time.now
var result = compute_something()
say "Computed in #{Time.now - start}s"
```

---

## Worked Problems

### Problem 1 — Primes in Arithmetic Progressions

Find all primes of the form $4k + 3$ up to 200. (By Dirichlet's theorem, there are infinitely many.)

```ruby
say primes(200).grep { _ % 4 == 3 }

# Alternative, using linear_forms_primes:
say linear_forms_primes(0, 50, [4, 3])
```

### Problem 2 — Goldbach's Conjecture

Verify that every even $n > 2$ up to 1000 is a sum of two primes.

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

Numerically verify that $\prod_{p \text{ prime}} \frac{1}{1-p^{-2}} = \frac{\pi^2}{6}$.

```ruby
var product = primes(1e6).prod {|p| (1f / (1 - 1/p**2)) }
say product
say (Num.pi**2 / 6)
```

### Problem 4 — Primitive Roots

Find all primitive roots modulo $p = 17$.

```ruby
var p = 17
var phi_p = (p - 1)

var primitive_roots = (^p).grep {|g| znorder(g, p) == phi_p }
say primitive_roots
say znprimroot(p)    #=> 3
```

### Problem 5 — Smooth Number Factorization

Factor $n = 2^{64} + 1$.

```ruby
var n = (2**64 + 1)
say n.pp1_factor(1000)
say flt_factor(n, 3, 1e6)
# Result includes 274177 and 67280421310721
```

### Problem 6 — Quadratic Congruences

Find all $x$ such that $x^2 \equiv 7 \pmod{55}$.

```ruby
say sqrtmod_all(7, 55)
```

### Problem 7 — Aliquot Sequences (Amicable Chains)

Compute the aliquot sequence starting at 12496 and verify it is a 5-cycle.

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
# [12496, 14288, 15472, 14536, 14264, 12496]
```

### Problem 8 — Counting Squarefree Numbers

Count squarefree numbers ≤ $10^9$ and verify via the Möbius formula.

```ruby
say squarefree_count(10**9)

func squarefree_count_manual(n) {
    (1..isqrt(n)).sum {|k| mu(k) * (n // k**2) }
}

say squarefree_count_manual(10**6)
say squarefree_count(10**6)       # should match
```

### Problem 9 — Large Prime Factorization

Factor a product of two 50-bit primes.

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

## Quick-Reference Cheat Sheet

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
| `prime_cluster(lo,hi,*d)` | Prime clusters with given gaps |
| `linear_forms_primes(lo,hi,*d)` | Primes in linear forms |

### Factorization

| Function | Description |
|---|---|
| `n.factor` | Full prime factorization |
| `n.factor_exp` | Factorization as [p,e] pairs |
| `n.prime_divisors` | Unique prime factors |
| `n.pm1_factor(B)` | Pollard p−1 |
| `n.pp1_factor(B)` | Williams p+1 |
| `n.ecm_factor(B)` | Elliptic curve method |
| `n.qs_factor` | Quadratic sieve |
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
| `n.factor_prod{...}` | Product over prime powers |

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
| `inverse_psi(n)` | Solve ψ(x) = n |

### Modular Arithmetic

| Function | Description |
|---|---|
| `powmod(a, n, m)` | a^n mod m |
| `invmod(a, m)` | a⁻¹ mod m |
| `sqrtmod(a, m)` | √a mod m |
| `sqrtmod_all(a, n)` | All square roots of a mod n |
| `rootmod_all(a, k, n)` | All k-th roots of a mod n |
| `znorder(a, m)` | Multiplicative order of a mod m |
| `znlog(a, g, m)` | Discrete log: g^k ≡ a (mod m) |
| `znprimroot(n)` | Smallest primitive root mod n |
| `kronecker(a, n)` | Kronecker symbol (a\|n) |
| `linear_congruence(n,r,m)` | Solve n*x ≡ r (mod m) |
| `chinese(Mod(a,m), Mod(b,n))` | Chinese Remainder Theorem |

### Sequences and Special Numbers

| Function | Description |
|---|---|
| `fib(n)` | n-th Fibonacci number |
| `fibmod(n, m)` | n-th Fibonacci mod m |
| `lucas(n)` | n-th Lucas number |
| `lucasU(P,Q,n)` | Lucas U sequence |
| `lucasV(P,Q,n)` | Lucas V sequence |
| `bernoulli(n)` | n-th Bernoulli number |
| `catalan(n)` | n-th Catalan number |
| `bell(n)` | n-th Bell number |
| `polygonal(n, k)` | n-th k-gonal number |
| `squares_r(n, k)` | r_k(n): number of representations as k squares |
| `sum_of_squares(n)` | Solutions to n = a² + b² |
| `factorial(n)` | n! |
| `binomial(n, k)` | C(n,k) |
| `binomialmod(n, k, m)` | C(n,k) mod m |

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
| `n.is_omega_prime(k)` | ω(n) = k |
| `n.is_powerful(k)` | Every prime factor appears ≥ k times |
| `n.is_perfect_power` | n = a^k, k ≥ 2 |
| `n.is_palindrome(b)` | Palindrome in base b |

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

## Sieve Algorithms

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
        var k = (start - L)
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
            break if ((p > lpf[i]) || (i*p > n))
            lpf[i*p] = p
        }
    }

    (primes, lpf)
}

var (ps, lpf) = linear_sieve(100)

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

Once an LPF table is built, any multiplicative function can be evaluated in bulk in $O(n)$:

```ruby
func sieve_phi(n) {
    var phi = (n+1).range.to_a
    for i in (2..n) {
        next if (phi[i] != i)
        for j in (i .. n `by` i) {
            phi[j] -= (phi[j] / i)
        }
    }
    phi
}

func sieve_sigma(n) {
    var sigma = (n+1).of { 0 }
    for d in (1..n) {
        for k in (d .. n `by` d) {
            sigma[k] += d
        }
    }
    sigma
}

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
    vals.each {|v| S{v} = (v - 1) }

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
```

---

## Primality Testing - Algorithm Deep Dives

### Fermat's Primality Test

If $n$ is prime, $a^{n-1} \equiv 1 \pmod{n}$ for all $\gcd(a,n)=1$. Composites that pass for every base are Carmichael numbers:

```ruby
func fermat_test(n, a = 2) {
    return false if ((n < 2) || (n %% 2))
    powmod(a, n-1, n) == 1
}

say fermat_test(561)       #=> true  (561 is NOT prime — it's a Carmichael number!)
say is_carmichael(561)     #=> true
```

### Miller-Rabin Strong Pseudoprime Test

Write $n - 1 = 2^s \cdot d$ with $d$ odd. Then $n$ is a strong pseudoprime to base $a$ if $a^d \equiv 1$ or $a^{2^r d} \equiv -1 \pmod{n}$ for some $0 \leq r < s$:

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

    return false if !n.is_strong_psp(2)
    return n.is_strong_lucas_psp
}

say bpsw(561)           #=> false
say bpsw(2**127 - 1)    #=> true
```

### ECPP — Elliptic Curve Primality Proving

Sidef's `is_prov_prime(n)` uses ECPP, producing a Primo-compatible certificate. Much faster than AKS in practice, handles hundreds of digits:

```ruby
say is_prov_prime(2**521 - 1)
say is_prov_prime(next_prime(10**50))
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

---

## Factorization Algorithm Deep Dives

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
say pbrent_factor(2**64 + 1, 1000)    # Sidef's Pollard-Brent
```

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

say pollard_p1(112391, 100)    #=> 673
say 112391.pm1_factor(100)     # Sidef's built-in
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

ECM generalizes p−1 to elliptic curves. Method of choice for factors up to ~60 digits:

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

say fermat_factor(8633)      #=> [89, 97]
```

### Cyclotomic Factorization

Algebraic identities from cyclotomic polynomials give explicit factors of $a^k \pm b^k$:

```ruby
func cyclo_factor(a, k) {
    k.divisors.map {|d| cyclotomic(d, a) }.grep {|v| v > 1 }
}

say cyclo_factor(2, 12)           # factors of 2^12 - 1 = 4095
say cyclotomic_factor(2**120 + 1)
```

---

## Discrete Logarithms and Related Problems

### Baby-Step Giant-Step (BSGS)

BSGS solves $g^k \equiv h \pmod{m}$ in $O(\sqrt{m})$ time and space. Write $k = i\lceil\sqrt{m}\rceil - j$ and precompute baby steps as a hash table:

```ruby
func baby_giant(g, h, m) {
    var s   = isqrt(m).inc
    var tbl = Hash()
    var gj  = 1
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

    var Q = p-1; var S = 0
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
say sqrtmod(10, 13)            # Sidef's built-in
```

### Hensel's Lemma: Lifting Modular Solutions

Lifts a solution $f(r) \equiv 0 \pmod{p}$ to a solution modulo $p^k$:

```ruby
func hensel_lift(f, df, r, p, k) {
    var pk = p; var x = r % p
    for _ in (1..k-1) {
        x = ((x - f(x) * invmod(df(x) % pk, pk)) % (pk * p))
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

## Chinese Remainder Theorem - Extended Applications

### Basic CRT and Garner's Algorithm

```ruby
# Sidef's Mod-based CRT
say chinese(Mod(2, 3), Mod(3, 5), Mod(2, 7))
# x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7)  →  23 (mod 105)

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

### Rational Reconstruction

Recover $p/q$ from $n \equiv p \cdot q^{-1} \pmod{M}$:

```ruby
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

## Quadratic Reciprocity and Residue Theory

### Quadratic Reciprocity Law

For distinct odd primes $p$ and $q$:

$$\left(\frac{p}{q}\right)\left(\frac{q}{p}\right) = (-1)^{\frac{p-1}{2}\cdot\frac{q-1}{2}}$$

```ruby
var violations = 0
each_prime(3, 100, {|p|
    each_prime(p+2, 100, {|q|
        var lhs = (legendre(p, q) * legendre(q, p))
        var exp = ((p-1)//2) * ((q-1)//2)
        var rhs = ((exp %% 2) ? 1 : -1)
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

say euler_factorization(221)    #=> [13, 17]
```

---

## The Prime Number Theorem and Analytic Methods

### The Prime Number Theorem

$\pi(x) \sim \text{Li}(x) = \int_2^x \frac{dt}{\ln t}$:

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
say primes(10000).sum {|p| 1.0/p }
say log(log(10000)) + 0.2615     # Mertens 1

say primes(10000).prod {|p| 1 - 1.0/p }
say (exp(-Num.EulerGamma) / log(10000))    # Mertens 3
```

### Chebyshev Functions

```ruby
func chebyshev_theta(x) { primes(x).sum { log(_) } }
func chebyshev_psi(x)   { (1..x).sum { exp_mangoldt(_).log } }

for k in (1..7) {
    var x = 10**k
    say "theta(10^#{k}) / 10^#{k} = #{chebyshev_theta(x) / x}"
}
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

## Smooth Numbers, Factor Bases, and Subexponential Factorization

### B-Smooth Numbers and the Dickman Function

A number is $B$-smooth if all prime factors are $\leq B$. The fraction of $B$-smooth numbers near $x$ is $\rho(u)$ where $u = \log x / \log B$ (Dickman's function):

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

say hamming_numbers(200)    # 7-smooth (Hamming/regular) numbers
```

### Optimal Factor Base Size

```ruby
func optimal_B(n) {
    var ln_n = log(n); var ln_ln_n = log(ln_n)
    exp(sqrt(ln_n * ln_ln_n) / 2).round
}

say optimal_B(10**50)    # ~1500 for QS on a 50-digit number
```

### Smooth Relation Generation

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

## p-Adic Arithmetic and Valuations

### p-Adic Valuation

$v_p(n)$ is the largest $k$ with $p^k \mid n$. Ultrametric property: $v_p(m + n) \geq \min(v_p(m), v_p(n))$:

```ruby
say valuation(360, 2)     #=> 3
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

For odd prime $p$ with $p \mid a - b$, $p \nmid a$, $p \nmid b$: $v_p(a^n - b^n) = v_p(a - b) + v_p(n)$

```ruby
func verify_lte(a, b, n, p) {
    var lhs = valuation(a**n - b**n, p)
    var rhs = valuation(a - b, p) + valuation(n, p)
    say "LTE: v_#{p}(#{a}^#{n}-#{b}^#{n}) = #{lhs}, formula = #{rhs}, match = #{lhs==rhs}"
}

verify_lte(5, 2, 12, 3)
verify_lte(7, 2,  8, 5)
```

### Kummer's Theorem

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

say kummer_carries(10, 15, 2)
say valuation(binomial(25, 10), 2)    # same result
```

---

## Dirichlet Series and Multiplicative Structure

### Dirichlet Convolution Ring

The convolution $(f * g)(n) = \sum_{d \mid n} f(d) g(n/d)$ makes arithmetic functions a ring under pointwise addition and Dirichlet multiplication:

```ruby
func dconv(n, f, g) { n.divisors.sum {|d| f(d) * g(n/d) } }

say 20.of {|n| dconv(n+1, {.phi}, {1}) }   # sigma = phi * 1
say 20.of {|n| dconv(n+1, {.mu}, {1}) }    # [1, 0, 0, ...] = epsilon

say 30.of { .dirichlet_convolution({.phi}, {1}) }    # Sidef's built-in
```

### Möbius Inversion

If $g(n) = \sum_{d \mid n} f(d)$, then $f(n) = \sum_{d \mid n} \mu(n/d)\, g(d)$:

```ruby
func mobius_invert(g, n) {
    n.divisors.sum {|d| mu(n/d) * g(d) }
}

say 20.of {|n| mobius_invert({|d| sigma(d)}, n+1) }    # [1, 2, 3, ...]
```

### Dirichlet Hyperbola Method

Efficient computation of $\sum_{n \leq x} \tau(n) = 2\sum_{d \leq \sqrt{x}} \lfloor x/d \rfloor - \lfloor\sqrt{x}\rfloor^2$:

```ruby
func tau_sum_hyperbola(x) {
    var sq = isqrt(x)
    2 * (1..sq).sum {|d| x // d } - sq**2
}

say tau_sum_hyperbola(10**6)
say sigma_sum(1e6, 0)          # built-in
say sum(1..10**6, { .tau })    # verification (slow)
```

---

## Elliptic Curves in Number Theory

### Point Arithmetic on E: y² = x³ + a x + b (mod p)

```ruby
func ec_add(P, Q, a, p) {
    return Q if (P == [nil, nil])
    return P if (Q == [nil, nil])
    var (x1,y1) = P...; var (x2,y2) = Q...
    if (x1 == x2) {
        return [nil, nil] if (y1 != y2)
        var lam = ((3*x1*x1 + a) * invmod(2*y1, p) % p)
        var x3  = ((lam*lam - 2*x1) % p)
        return [x3, (lam*(x1-x3) - y1) % p]
    }
    var lam = ((y2-y1) * invmod(x2-x1, p) % p)
    var x3  = ((lam*lam - x1 - x2) % p)
    [x3, (lam*(x1-x3) - y1) % p]
}

func ec_mul(P, k, a, p) {
    var R = [nil, nil]
    var Q = P
    while (k > 0) {
        R = ec_add(R, Q, a, p) if (k %% 2)
        Q = ec_add(Q, Q, a, p)
        k //= 2
    }
    return R
}

var p_ec = 17
var a_ec = 2
var P_ec = [5, 1]
say ec_mul(P_ec, 10, a_ec, p_ec)
```

### Schoof's Algorithm — Order of E(Fp)

```ruby
func ec_order_baby_giant(a, b, p) {
    var n = p + 1
    for k in (-2*isqrt(p) .. 2*isqrt(p)) {
        var t = (n + k) % p
        var bad = false
        for P in (primes(100).map {|px| [px, isqrt(px) % p] }.first(10)) {
            var (x, y) = P
            next if (y*y % p != (x**3 + a*x + b) % p)
            bad = true if (ec_mul([x, y], t, a, p) != nil)
        }
        return (n + k) unless bad
    }
}
```

### ECM-Inspired Factorization Sketch

```ruby
func ecm_sketch(n, B1 = 2000) {
    var a = irand(0, n-1)
    var P = [irand(1, n-1), irand(1, n-1)]
    var b = (P[1]**2 - P[0]**3 - a*P[0]) % n

    for p in (primes(B1)) {
        var pk = p
        while (pk * p <= B1) { pk *= p }
        P = ec_mul(P, pk, a, n)
        return nil if (P == nil)
        var g = gcd(P[1] - P[0], n)
        return g if (g > 1 && g < n)
    }
    nil
}
```

---

## Algebraic Number Theory Constructs

### Quadratic Fields — Norms and Units

```ruby
func qnorm(a, b, d) { a*a - d*b*b }    # norm of a + b*sqrt(d) in Q(sqrt(d))

say qnorm(3, 4, 5)     # norm of 3 + 4*sqrt(5) in Q(sqrt(5))
say qnorm(2, 1, -1)    # norm of 2 + i in Z[i] (Gaussian)

var alpha = Quadratic(2, 1, 2)     # 2 + sqrt(2)
say alpha**10
say alpha.norm
say alpha.conj
```

### Algebraic Integers and Minimal Polynomials

```ruby
var sqrt5 = sqrtQ(5)
var zeta5 = exp(2*Num.pi*1.i/5)

say ((sqrt5 + 1)/2)         # Golden ratio
say (zeta5 + zeta5**-1)     # 2*cos(2pi/5)
```

### Norm in Z[i] and Gaussian Primes

```ruby
func gaussian_norm(a, b) { a*a + b*b }

# A Gaussian integer a+bi is prime iff:
#   - |norm| is a rational prime ≡ 3 (mod 4)  (like 3, 7, 11, ...)
#   - norm is a power of 2 (only 1+i)
#   - norm = p^2 where p ≡ 1 (mod 4)  (splits)

say is_gaussian_prime(3, 0)    # norm = 9, not prime
say is_gaussian_prime(3, 2)    # norm = 13 ≡ 1 (mod 4) → prime
```

---

## Cryptographic Applications

### RSA Key Generation

```ruby
func gen_rsa_keys(bits = 512) {
    var p = do { var n = (irand(2**(bits-1), 2**bits - 1) | 1); n++ while !n.is_prov_prime; n }
    var q = do { var n = (irand(2**(bits-1), 2**bits - 1) | 1); n++ while !n.is_prov_prime; n }
    say p
    say q
    var N = (p * q)
    var e = 65537
    var d = invmod(e, lcm(p-1, q-1))
    return (N, e, d)
}

var (N, e, d) = gen_rsa_keys()
var m = 42
var c = powmod(m, e, N)
say powmod(c, d, N)    #=> 42
```

### Diffie-Hellman Key Exchange

```ruby
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

### Number-Theoretic Hash Functions

```ruby
# Rabin's fingerprinting: polynomial hash mod a prime
func rabin_fingerprint(data, p = next_prime(2**61)) {
    var b = 257    # base
    data.chars.reduce({|h, c| (h*b + c.ord) % p }, 0)
}

# Verify collision resistance: two different strings should (almost surely) hash differently
say rabin_fingerprint("hello world")
say rabin_fingerprint("hello world!")
```

---

## Number-Theoretic Transforms and Convolutions

### NTT-Friendly Primes

An NTT-friendly prime $p = c \cdot 2^k + 1$ supports transforms of length $2^j$ for any $j \leq k$:

```ruby
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
```

### Polynomial Multiplication via NTT

```ruby
func poly_mult_ntt(f, g, p = 998244353) {
    var n = 1; while (n < f.len + g.len) { n *= 2 }

    var ff = f + (n - f.len).of { 0 }
    var gg = g + (n - g.len).of { 0 }

    var omega = powmod(znprimroot(p), (p-1)//n, p)
    var roots = n.of {|k| powmod(omega, k, p) }

    func evaluate(poly, roots) {
        n.of {|k| poly.map_with_index {|c, j| c * roots[(j*k)%n] % p }.sum % p }
    }

    var F = evaluate(ff, roots)
    var G = evaluate(gg, roots)
    var H = F.map_with_index {|v, i| v * G[i] % p }

    var inv_omega = invmod(omega, p)
    var inv_roots = n.of {|k| powmod(inv_omega, k, p) }
    var inv_n = invmod(n, p)

    evaluate(H, inv_roots).map {|v| v * inv_n % p }[0..f.len+g.len-2]
}

say poly_mult_ntt([1, 1, 1], [1, 1])    # (1+x+x^2)(1+x) = 1+2x+2x^2+x^3
```

### Dirichlet Convolution — Bulk Computation

```ruby
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
say dirichlet_mult(mu_coeffs, one_coeffs)    # [1, 0, 0, ..., 0] = epsilon
```

---

## Computational Complexity in Number Theory

### Complexity of Core Problems

| Problem | Best Known Algorithm | Complexity |
|---------|----------------------|-------------|
| Primality (deterministic) | ECPP | $\tilde{O}(\log^5 n)$ |
| Primality (AKS) | AKS | $\tilde{O}(\log^6 n)$ |
| Factoring (general) | GNFS | $L_n[1/3,\, (64/9)^{1/3}]$ |
| Factoring (special form) | Cyclotomic / ECM | $L_n[1/2,\, 1]$ |
| Discrete log (mod p) | GNFS-DL | $L_p[1/3]$ |
| Discrete log (EC) | BSGS / Rho | $O(p^{1/2})$ |
| GCD | Binary GCD / Lehmer | $O(\log^2 n)$ |
| Integer multiplication | Schönhage-Strassen | $O(n \log n \log\log n)$ |

where $L_n[s,c] = \exp\!\big((c+o(1))(\ln n)^s(\ln\ln n)^{1-s}\big)$.

### Karatsuba Multiplication

$O(n^{1.585})$ vs naive $O(n^2)$:

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
say primes(10**7).len                    # O(x) space, O(x log log x) time
say pi(10**12)                           # Meissel-Lehmer, O(x^{2/3}) time
```

---

## Advanced OEIS Techniques and Sequence Acceleration

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

var trees = [1]
for n in (2..15) {
    trees.push(euler_transform(trees, n-1)[-1])
}
say trees    # rooted unlabeled trees (OEIS A000081)
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
say berlekamp_massey(20.of { .fib })
```

### Shanks Transformation (Sequence Acceleration)

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
say "Raw:      #{leibniz[-1]}"
say "1x accel: #{acc1[-1]}"
say "2x accel: #{acc2[-1]}"
say "True pi:  #{Num.pi}"
```

### Matrix Exponentiation for Linear Recurrences

Any $k$-th order linear recurrence is computable in $O(k^3 \log n)$ via matrix exponentiation:

```ruby
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

say catalan_mod(10**6, P)

func bell_mod(n, m) is cached {
    return 1 if (n == 0)
    (0..n-1).sum {|k| binomialmod(n-1, k, m) * bell_mod(k, m) % m } % m
}

say bell_mod(1000, P)
```

### Automatic Pattern Detection

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

detect_pattern([0, 1, 4, 9, 16, 25, 36])
detect_pattern([0, 1, 1, 2, 3, 5, 8, 13, 21])
detect_pattern([1, 3, 7, 15, 31, 63, 127])
```

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
    return "not prime"               if (n < 2)
    return "prime"                   if (n.is_prime)
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

say moebius_invert({|d| sigma(d) }, 12)   # should be 12
```

---

## Appendix B: Further Reading and Resources

### Official Documentation

- **Sidef book**: [trizen.gitbook.io/sidef-lang](https://trizen.gitbook.io/sidef-lang/) ([PDF](https://github.com/trizen/sidef/releases/download/26.07/sidef-book.pdf))
- **Advanced tutorial**: [SIDEF_ADVANCED_GUIDE.md](https://github.com/trizen/sidef/blob/master/SIDEF_ADVANCED_GUIDE.md)
- **Computational Algebra Guide**: [COMPUTATIONAL_ALGEBRA_GUIDE.md](https://github.com/trizen/sidef/blob/master/COMPUTATIONAL_ALGEBRA_GUIDE.md)
- **Function reference for number theory**: [NUMBER_THEORY_REFERENCE.md](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_REFERENCE.md)
- **Full Number class documentation**: [Sidef::Types::Number::Number](https://metacpan.org/pod/Sidef::Types::Number::Number)

### Code Examples

- **Sidef scripts repository**: [github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)
- **OEIS autoload**: [github.com/trizen/oeis-autoload](https://github.com/trizen/oeis-autoload)
- **Special-purpose factorization**: [trizenx.blogspot.com](https://trizenx.blogspot.com/2019/08/special-purpose-factorization-algorithms.html)

### Mathematical References

- **OEIS**: [oeis.org](https://oeis.org) — Online Encyclopedia of Integer Sequences
- **Math::Prime::Util**: [github.com/danaj/Math-Prime-Util](https://github.com/danaj/Math-Prime-Util)
- **Max Alekseyev's papers**: [Inverse of multiplicative functions](https://cs.uwaterloo.ca/journals/JIS/VOL19/Alekseyev/alek5.html)

### PARI/GP Compatibility

Many Sidef function names and semantics are compatible with PARI/GP. Users familiar with PARI will find Sidef intuitive. For very large inputs, Sidef can delegate to specialized tools via `Num!USE_YAFU`, `Num!USE_PARI_GP`, `Num!USE_PRIMECOUNT`, and `Num!USE_FACTORDB`.

### Community

- **Questions and discussions**: [GitHub Discussions](https://github.com/trizen/sidef/discussions/categories/q-a)
- **Issue tracker**: [GitHub Issues](https://github.com/trizen/sidef/issues)

---

*This guide covers the `Sidef::Types::Number::Number` class. For functionality related to arrays, strings, and other types, consult the full Sidef documentation.*
