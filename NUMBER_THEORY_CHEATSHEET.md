# Advanced Number Theory with Sidef

A hands-on guide for practitioners, covering Sidef's integer and number-theoretic
facilities through worked examples.

---

## Operator Precedence via Whitespace

Sidef determines operator priority from surrounding whitespace: an operator written
**without** spaces binds **tighter** than one surrounded by spaces.

```ruby
say (3+5 * 6+7)    # means: say((3+5) * (6+7))  — '+' is tight, '*' is loose
say (3 + 5*6 + 7)  # means: say(3 + (5*6) + 7)  — '*' is tight, '+' is loose
```

---

## Table of Contents

1. [Configuration and Precision](#1-configuration-and-precision)
2. [Factorization and Prime Structure](#2-factorization-and-prime-structure)
3. [Divisor Functions](#3-divisor-functions)
4. [Euler's Totient and Variants](#4-eulers-totient-and-variants)
5. [Möbius Function and Multiplicative Structure](#5-möbius-function-and-multiplicative-structure)
6. [Prime Counting and Distribution](#6-prime-counting-and-distribution)
7. [Primality Testing](#7-primality-testing)
8. [Integer Factorization Algorithms](#8-integer-factorization-algorithms)
9. [Modular Arithmetic](#9-modular-arithmetic)
10. [Quadratic Residues and Congruences](#10-quadratic-residues-and-congruences)
11. [Dirichlet Convolution](#11-dirichlet-convolution)
12. [Arithmetic Derivative](#12-arithmetic-derivative)
13. [Continued Fractions and Pell's Equation](#13-continued-fractions-and-pells-equation)
14. [Sublinear Summation](#14-sublinear-summation)
15. [Integer Classifications and Sequences](#15-integer-classifications-and-sequences)
16. [Pseudoprimes and Carmichael Numbers](#16-pseudoprimes-and-carmichael-numbers)
17. [Combinatorics and Partitions](#17-combinatorics-and-partitions)
18. [Special Arithmetic Functions](#18-special-arithmetic-functions)
19. [Quick Reference](#19-quick-reference)

---

## 1. Configuration and Precision

Global settings that govern Sidef's numerical behaviour:

```ruby
Num!PREC            = 192    # floating-point precision in bits (default)
Num!VERBOSE         = false  # verbose/debug output from several methods
Num!USE_YAFU        = false  # use YAFU for factoring large integers
Num!USE_PFGW        = false  # use PFGW64 as a primality pretest
Num!USE_PARI_GP     = false  # use PARI/GP in several methods
Num!USE_FACTORDB    = false  # query factordb.com for factorizations
Num!USE_PRIMECOUNT  = false  # use Kim Walisch's primecount binary
Num!USE_PRIMESUM    = false  # use Kim Walisch's primesum binary
Num!USE_CONJECTURES = false  # enable conjectured (faster) methods
Num!SPECIAL_FACTORS = true   # try algebraic factor forms in factor()
```

### Scoped Precision with `local`

`local` confines a change to the current function scope, including all callees:

```ruby
func high_prec_sqrt(n) {
    local Num!PREC = 1024
    say sqrt(n)   # computed at 1024-bit precision
}
high_prec_sqrt(2)
say Num!PREC   #=> 192 — restored
```

### Creating Numbers

```ruby
var a = Num("3.14159")       # from decimal string
var b = Number("1010", 2)    # from string in base 2: b = 10
var c = 42                   # integer literal
say (1/3 + 1/6)              # exact rational arithmetic: 1/2
say as_frac(1/3 + 1/6)       # "1/2" as a string
```

---

## 2. Factorization and Prime Structure

### Complete Factorization

`factor(n)` returns prime factors with repetition (sorted ascending).
`factor_exp(n)` returns `[p, e]` pairs in ascending order of `p`.

```ruby
say 1000.factor      #=> [2, 2, 2, 5, 5, 5]
say 1000.factor_exp  #=> [[2, 3], [5, 3]]

var n = (2**128 - 1)
say n.factor
#=> [3, 5, 17, 257, 641, 65537, 274177, 6700417, 67280421310721]
```

An optional block supplies a custom sub-factoring routine. The block receives a
composite sub-factor and must return an array of (not necessarily prime) factors:

```ruby
say factor(10**120 - 10**40, {|k| k.ecm_factor })
```

Iterate over `[p, e]` pairs with destructuring:

```ruby
for pair in (720.factor_exp) {
    var (p, e) = pair...
    say "#{p}^#{e}"
}
#=> 2^4
#=> 3^2
#=> 5^1
```

`factor_map`, `factor_prod`, and `factor_sum` apply a block to each `(p, e)` pair:

```ruby
say 5040.factor_map {|p, e| p**e }           #=> [16, 9, 5, 7]
say 5040.factor_prod {|p, e| (p-1) * p**(e-1) }   #=> 1152  (= φ(5040))
say 5040.factor_sum {|p, e| e }              #=> bigomega(5040) = 9
```

### Fundamental Invariants

```ruby
var n = 720   # 2^4 * 3^2 * 5

say n.omega     # ω(n) = 3  — distinct prime factors           (A001221)
say n.bigomega  # Ω(n) = 7  — prime factors with multiplicity  (A001222)
say n.lpf       # 2          — least prime factor
say n.gpf       # 5          — greatest prime factor
say n.rad       # 30         — radical: ∏_{p|n} p              (A007947)
say n.core      # 30         — squarefree part = n / largest_square_divisor(n)
                #            — aliases: squarefree_part          (A007913)
```

`rad(n)` and `core(n)` agree only when n is squarefree. In general
`core(n) = n / square_part(n)` while `rad(n) = ∏_{p | n} p`.

```ruby
say n.valuation(2)   # v_2(720) = 4
say n.valuation(3)   # v_3(720) = 2
say n.valuation(7)   # v_7(720) = 0

# valuation(n, k) generalises to composite k:
say valuation(2**32, 4)   # 16 — how many times 4 divides 2^32

# sopf and sopfr:
say 360.sopf    # A008472: sum of *distinct* prime factors = 2+3+5 = 10
say 360.sopfr   # A001414: Σ e·p over p^e || n = 3·2 + 2·3 + 1·5 = 17
```

### Prime Signature

The prime signature is the sorted tuple of exponents in descending order:

```ruby
say 720.prime_signature   #=> [4, 2, 1]  since 720 = 2^4 · 3^2 · 5^1

# All integers in [1, 10000] with the same signature shape:
say prime_signature_inverse(1, 10000, [4, 2, 1])
#=> [720, 1080, 1800, 2520, 3240, 4200, 5040, 7560, ...]

say prime_signature_inverse_len(1, 10**6, [1])   # = prime_count(10^6)
```

### Prime Power Detection

```ruby
# prime_power(n): the exponent k if n = p^k for prime p, else 1
say  8.prime_power   # 3  — 8 = 2^3
say 15.prime_power   # 1  — 15 is not a prime power

# prime_root(n): returns p if n = p^k, else n itself
say  8.prime_root    # 2
say 15.prime_root    # 15

# perfect_power(n): largest k such that n = r^k for some integer r
say 64.perfect_power   # 6  — 64 = 2^6
say 64.perfect_root    # 2  — smallest such base
```

### Primorials and Factorial Valuations

```ruby
say  7.primorial              # 2·3·5·7 = 210   (product of primes ≤ 7)
say  4.pn_primorial           # product of first 4 primes = 210
say 10.consecutive_integer_lcm  # lcm(1,2,...,10) = 2520

# p-adic valuation of n! via Legendre's formula v_p(n!) = Σ floor(n/p^k):
say 100.factorial_power(5)   # v_5(100!) = 20+4 = 24
say 100.factorial_power(2)   # v_2(100!) = 97

# Primorial inflation / deflation:
say  6.primorial_inflation    # A108951(6)
say 12.primorial_deflation    # A319626(12)/A319627(12) — inverse operation
```

### Sublinear Partial Sums of Pointwise Functions

```ruby
say lpf_sum(10**6)    # Σ_{k=1}^{10^6} lpf(k)  (A088821)
say gpf_sum(10**6)    # Σ_{k=1}^{10^6} gpf(k)  (A088822)
say sopf_sum(10**6)   # Σ_{k=1}^{10^6} sopf(k) (A024924)
say sopfr_sum(10**6)  # Σ_{k=1}^{10^6} sopfr(k)(A025281)
```

---

## 3. Divisor Functions

### σ_k and τ

```ruby
var n = 360

say n.sigma(0)   # τ(n) = 24   — divisor count
say n.sigma(1)   # σ(n) = 1170 — sum of divisors  (k=1 is the default)
say n.sigma(2)   # σ_2(n)      — sum of squares of divisors
say n.sigma(-1)  # σ_{-1}(n)  — sum of 1/d, as an exact rational

# Aliases — note: tau(n) as a *function* = σ_0(n),
# but Num.tau as a *class constant* = 2π (the circle constant).
say n.sigma0     # = tau(n) = 24
say tau(360)     # 24
say Num.tau      # 6.283185...  (2π)

# Divisor product identity ∏_{d|n} d = n^{τ(n)/2}:
say n.divisors_prod {|d| d }
say n ** (n.sigma0 / 2)

# Proper divisors and aliquot sum s(n) = σ(n) − n:
say n.proper_divisors
say n.aliquot_sum       # aliases: aliquot, proper_sigma
say n.proper_sigma0     # = τ(n) − 1 = number of proper divisors
```

### Divisor System Variants

Sidef implements σ and τ for five divisor systems beyond the standard one:

| Pair | Type | Key condition | OEIS |
|---|---|---|---|
| `sigma` / `sigma0` | Standard | all d \| n | A000203 / A000005 |
| `usigma` / `usigma0` | Unitary | gcd(d, n/d) = 1 | A034448 / A034444 |
| `bsigma` / `bsigma0` | Bi-unitary | gcud(d, n/d) = 1 | A188999 / A286324 |
| `isigma` / `isigma0` | Infinitary | d is an i-divisor | A049417 / A037445 |
| `esigma` / `esigma0` | Exponential | b_i \| e_i for all p_i | A051377 / A049419 |

```ruby
var n = 36   # 2^2 · 3^2

say n.sigma    # 91
say n.usigma   # 1+4+9+36 = 50   (unitary divisors: gcd(d, 36/d) = 1)
say n.bsigma   # bi-unitary sigma
say n.isigma   # infinitary sigma
say n.esigma   # exponential sigma: d = ∏ p^{b_i} where b_i | e_i

say n.udivisors    # unitary divisors
say n.bdivisors    # bi-unitary divisors  (alias: biudivisors)
say n.idivisors    # infinitary divisors
say n.edivisors    # exponential divisors
```

A **unitary divisor** d | n has gcd(d, n/d) = 1, forcing each prime entirely into d
or entirely into n/d. For p^a the unitary divisors are 1 and p^a.
**Exponential divisors** of n = ∏ p_i^{e_i} are ∏ p_i^{b_i} with b_i | e_i.

```ruby
# Non-divisor complements:
say 36.nusigma   # A048146: sum of non-unitary divisors
say 36.nbsigma   # A319072: sum of non-bi-unitary divisors
say 36.nesigma   # A160135: sum of non-exponential divisors
say 36.nisigma   # A348271: sum of non-infinitary divisors
```

### Divisor Subsets

```ruby
var n = 5040   # = 2^4 · 3^2 · 5 · 7

say n.squarefree_divisors     # divisors d with μ(d) ≠ 0
say n.squarefree_sigma        # A048250: sum of squarefree divisors
say n.squarefree_usigma       # sum of unitary squarefree divisors
say n.squarefree_usigma0      # count of unitary squarefree divisors

say n.cubefree_divisors
say n.cubefree_sigma          # 4368
say n.prime_power_divisors    # prime powers p^k (k ≥ 1) dividing n
say n.prime_power_sigma       # their sum
say n.prime_divisors          # = unique prime factors = [2, 3, 5, 7]
say n.square_divisors         # divisors that are perfect squares
say n.cube_divisors           # divisors that are perfect cubes

say n.smooth_divisors(5)      # 5-smooth divisors
say n.rough_divisors(5)       # divisors d with lpf(d) ≥ 5
say n.powerful_divisors       # divisors d where v_p(d) ≥ 2 for all p | d
say n.perfect_power_divisors  # divisors that are perfect powers

# k-th power divisors and their unitary counterparts:
say n.power_divisors(2)       # = square divisors
say n.power_udivisors(2)      # unitary square divisors
```

### Iterating and Reducing over Divisors

The `divisors_each`, `divisors_map`, `divisors_sum`, and `divisors_prod` methods
iterate lazily over the divisors of n:

```ruby
# Sum of φ(d)^2 over all d | 5040:
say 5040.divisors_sum {|d| d.euler_phi**2 }   #=> 2217854

# Sum of prime divisors:
say 120.divisors_sum {|d| d.is_prime ? d : 0 }   # 2+3+5 = 10
```

### Antidivisors

The **antidivisors** of n (A066272) are integers d > 1 for which
2n ≡ ±1 (mod d), but d does not divide n:

```ruby
say  14.antidivisors      # [3, 4, 9]
say  14.antidivisor_count # 3
say 128.antidivisors      # [3, 5, 15, 17, 51, 85]
say  14.antidivisor_sigma # A066417: 3+4+9 = 16
```

### Inverse Sigma Problems

```ruby
say  28.sigma_inverse          # all n with σ(n) = 28 → [12]  (σ(12)=28)
say  28.sigma_inverse_len      # count of preimages
say  28.sigma_inverse_min      # smallest: 12
say  28.sigma_inverse_max      # largest

say 120.usigma_inverse         # all n with usigma(n) = 120
say 120.psi_inverse            # all n with ψ(n) = 120

# tau_inverse: integers in [lo, hi] with exactly k divisors
say tau_inverse(1, 100, 6)     # integers ≤ 100 with τ = 6
say tau_inverse_len(1, 100, 6) # their count
say nth_tau_inverse(1, 6)      # smallest n with τ(n) = 6  → 12
```

### Perfect, Abundant, Deficient

```ruby
say  6.is_perfect             # σ(6) = 12 = 2·6  ✓
say 12.is_abundant            # σ(12) = 28 > 24   ✓
say  8.is_deficient           # σ(8)  = 15 < 16   ✓

say 12.abundancy_index        # σ(n)/n = 7/3 as exact rational

say 20.is_primitive_abundant  # abundant, every proper divisor deficient
say 12.is_practical           # every m ≤ σ(12) is a sum of distinct divisors
```

---

## 4. Euler's Totient and Variants

### φ(n) and Its Partial Sum

```ruby
say 36.euler_phi    # φ(36) = 12    (aliases: phi, totient, eulerphi)

# Multiplicativity for gcd(m, n) = 1:
var m = 9
var n = 16
say (euler_phi(m*n) == m.euler_phi * n.euler_phi)   # true

# The fundamental identity Σ_{d|n} φ(d) = n:
say 60.divisors_sum {|d| d.euler_phi }   # = 60

# Totient range: array of φ(k) for k in [a..b]:
say totient_range(7, 17)   #=> [6, 4, 6, 4, 10, 4, 12, 6, 8, 8, 16]

# Sublinear partial sum Σ_{k=1}^n φ(k) ≈ 3n²/π² (A002088):
say totient_sum(10**9)
```

### Inverse Totient

```ruby
say 24.phi_inverse        # all n with φ(n) = 24   (alias: inverse_euler_phi)
say 24.phi_inverse_len    # count of preimages
say 24.phi_inverse_min    # smallest n: 25
say 24.phi_inverse_max    # largest n

# is_totient: true iff the number is in the image of φ
say 14.is_totient   # false — 14 is a nontotient (all odd integers > 1 are nontotients)
say 12.is_totient   # true
```

### Carmichael's λ

λ(n) is the exponent of (ℤ/nℤ)* — the lcm of the element orders:

```ruby
say 12.carmichael_lambda   # λ(12) = 2
say 15.carmichael_lambda   # λ(15) = 4

# λ(n) | φ(n); equality holds iff (ℤ/nℤ)* is cyclic (n has a primitive root):
say 7.carmichael_lambda == 7.euler_phi     # true — primes are cyclic
say 12.carmichael_lambda == 12.euler_phi   # false — (ℤ/12ℤ)* ≅ ℤ/2 × ℤ/2

# For p = 2: λ(2) = 1, λ(4) = 2, λ(2^k) = 2^{k-2} for k ≥ 3:
say 8.carmichael_lambda   # 2 = 2^{3-2}

# is_cyclic: true iff n has a primitive root (n ∈ {1,2,4,p^k,2p^k}):
say 13.is_cyclic   # true   (A003277)
say 12.is_cyclic   # false
```

### Jordan's Totient J_k(n)

J_k(n) = n^k ∏_{p|n} (1 − p^{-k}). For k = 1 this is φ(n).

```ruby
say 12.jordan_totient(1)   # = φ(12) = 4
say 12.jordan_totient(2)   # J_2(12) = 96
say 12.jordan_totient(3)

# Σ_{d|n} J_k(d) = n^k:
var n = 60
say n.divisors_sum {|d| d.jordan_totient(2) } == n**2   # true

# Sublinear partial sum Σ_{m=1}^n J_k(m):
say jordan_totient_sum(10**6, 2)   # alias: totient_sum(10^6, 2)
say jordan_totient_sum(10**6, 3)
```

### Dedekind's ψ

ψ(n) = n ∏_{p|n} (1 + p^{-1}) — the multiplicative analog of φ in the unitary setting:

```ruby
say 12.dedekind_psi    # ψ(12) = 12 · 3/2 · 4/3 = 24   (alias: psi)

# Identity: ψ(n) = Σ_{d|n} |μ(d)| · d  (Dirichlet convolution of |μ| and id)
say psi_sum(10**6)   # sublinear   (alias: dedekind_psi_sum)

# Inverse:
say 24.psi_inverse        # all x with ψ(x) = 24
say 24.psi_inverse_len
say 24.psi_inverse_min
say 24.psi_inverse_max
```

### Unitary and Infinitary Totients

```ruby
say 12.uphi    # A047994: ∏_{p^a || n} (p^a − 1)    unitary totient
say 12.bphi    # A116550: bi-unitary totient
say 12.iphi    # A091732: infinitary totient
say 12.nuphi   # A254503: non-unitary totient = φ(n) − uphi(n)

say 120.uphi_inverse     # all x with uphi(x) = 120
```

---

## 5. Möbius Function and Multiplicative Structure

### μ(n) and Mertens M(n)

```ruby
say  1.moebius   #  1   (aliases: mu, mobius)
say  6.moebius   #  1  — μ(2·3) = (−1)^2
say 30.moebius   # -1  — μ(2·3·5) = (−1)^3
say  4.moebius   #  0  — not squarefree

# Batch computation over a range:
say moebius_range(7, 17)   #=> [-1, 0, 0, 1, -1, 0, -1, 1, 1, 0, -1]

# Mertens function M(n) = Σ_{k=1}^n μ(k) — O(n^{2/3}):
for e in (1..9) {
    say "M(10^#{e}) = #{(10**e).mertens}"
}

# Range form: M(b) − M(a−1):
say mertens(21, 123)
```

### Liouville's λ(n)

λ(n) = (−1)^{Ω(n)}:

```ruby
say 12.liouville   # (−1)^3 = −1   (12 = 2^2·3, Ω=3)
say 15.liouville   # (−1)^2 =  1   (15 = 3·5,   Ω=2)

# L(n) = Σ λ(k). Also: exp_bigomega_sum(n, -1):
say liouville_sum(10**9)

# Pólya's conjecture that L(n) ≤ 0 for n ≥ 2 is FALSE:
say 906180359.liouville_sum   #=> 1  (first n with L(n) > 0)
```

### Mangoldt's Λ(n)

Λ(n) = log p if n = p^k for prime p, else 0.
The integer version `exp_mangoldt(n)` = p if n = p^k, else 1:

```ruby
say  8.exp_mangoldt   # 2   — 8 = 2^3
say  9.exp_mangoldt   # 3   — 9 = 3^2
say 12.exp_mangoldt   # 1   — not a prime power
say  7.exp_mangoldt   # 7   — prime

# Integer Chebyshev ψ̃(n) = Σ_{k≤n} exp_mangoldt(k):
say 1000.exp_mangoldt_sum   # A072107
```

### Pillai's Arithmetical Function

f(n) = Σ_{k=1}^n gcd(k, n) (A018804):

```ruby
say 12.pillai   # 40

# Identity: pillai(n) = Σ_{d|n} φ(d)·(n/d)
say 12.divisors_sum {|d| d.euler_phi * (12/d) }   # 40 ✓

say 1000.pillai_sum   # Σ_{k=1}^{1000} pillai(k)
```

### Ramanujan's Sum

c_q(n) = Σ_{1≤k≤q, gcd(k,q)=1} e^{2πikn/q} — always an integer:

```ruby
say 5.ramanujan_sum(1)    # c_5(1) = μ(5) = −1
say 5.ramanujan_sum(5)    # c_5(5) = φ(5) = 4

# Identity: c_q(n) = μ(q/gcd(q,n)) · φ(q) / φ(q/gcd(q,n)):
var q = 12; var n = 8
var g = q.gcd(n)
say (moebius(q/g) * q.euler_phi / euler_phi(q/g) == q.ramanujan_sum(n))   # true
```

### Verifying Multiplicative Identities

```ruby
var n = 360

# φ = μ * id: Σ_{d|n} μ(d)·(n/d) = φ(n)
say n.divisors_sum {|d| d.moebius * (n/d) }   # = φ(360) = 96
say n.euler_phi                                 # 96 ✓

# n = Σ_{d|n} φ(d):
say n.divisors_sum {|d| d.euler_phi }   # = 360 ✓
```

---

## 6. Prime Counting and Distribution

### π(n) — Exact, Range, and Approximate

```ruby
say prime_count(10**6)     # π(10^6) = 78498 — exact, sublinear
                           # aliases: primepi, count_primes, pi (the method)

say primepi(10**12)        #=> 37607912018

# Range: π(b) − π(a−1):
say prime_count(10**6, 2 * 10**6)    # primes in (10^6, 2·10^6]
say primepi(10**6, 2*10**6)          # same

# Proven bounds: prime_count_lower ≤ π(n) ≤ prime_count_upper:
say prime_count_lower(10**9)
say prime_count_upper(10**9)
```

### nth Prime and Bounds

```ruby
say prime(1)      # 2     — 1-indexed; aliases: nth_prime, prime
say prime(100)    # 541
say prime(10**6)  # 15485863

say 100.prime_lower    # lower bound on p_{100}  (alias: nth_prime_lower)
say 100.prime_upper    # upper bound
```

### Legendre's ϕ(n, k)

Counts integers in [1, n] coprime to the product of the first k primes:

```ruby
say legendre_phi(100, 4)   # integers ≤ 100 coprime to 2·3·5·7

# Legendre's formula: π(n) = legendre_phi(n, π(√n)) + π(√n) − 1:
var sqn = 100.isqrt
say legendre_phi(100, sqn.prime_count) + sqn.prime_count - 1   # = 25
say primepi(100)   # 25 ✓
```

### Twin Primes and Prime Constellations

```ruby
# All primes p ≤ 1000 such that p+2 is also prime:
say twin_primes(1000)
say twin_primes(500, 1000)   # in range [500, 1000]

# prime_cluster(lo, hi, offsets...): primes p with p+d_i all prime:
say prime_cluster(1, 1000, 2)         # = twin primes ≤ 1000
say prime_cluster(1, 1000, 2, 6)      # p, p+2, p+6 all prime
say prime_cluster(1, 1000, 4, 6, 10)  # p, p+4, p+6, p+10 all prime
```

### Prime Sum

```ruby
say prime_sum(10**9)   # Σ_{p≤n} p — sublinear  (aliases: primes_sum, sum_primes)

# With exponent k: Σ p^k over primes p ≤ n
say primes_sum(1, 10**6, 2)   # Σ_{p≤10^6} p^2
```

### inverse_count: Inverting Monotone Counting Functions

```ruby
# Finds smallest m ≥ 0 with count_func(m) ≥ target
say inverse_count(25, { .prime_count })          # ≈ 97 (25th prime ≈ 97)
say inverse_count(100, { |n| 10.smooth_count(n) })
```

### Almost-Prime Counting π_k(n)

The receiver is the order k:

```ruby
say 1.almost_prime_count(100)       # = prime_count(100) = 25
say 2.almost_prime_count(100)       # semiprimes ≤ 100 = 34
say 2.almost_prime_count(50, 100)   # semiprimes in [50, 100]
say 3.almost_prime_count(100)
```

### Composite Numbers

`composite(n)` (alias: `nth_composite`) returns the n-th composite.
`composite_count(n)` counts composites ≤ n; `composite_sum(n)` sums them.

```ruby
say composite(10**9)              # 1053422339 — 10^9-th composite

say composite_count(100)          # composites ≤ 100 = 74
say composite_count(50, 100)      # composites in [50, 100]
say composite_count_lower(10**9)  # proven lower bound
say composite_count_upper(10**9)  # proven upper bound

say composite_sum(100)            # sum of composites ≤ 100
say composite_sum(50, 100)        # sum of composites in [50, 100]
say composite_sum(1, 100, 2)      # Σ c^2 over composites c ≤ 100

say composites(100)               # array of all composites ≤ 100
say composites(50, 100)           # array in range [50, 100]

composites_each(100, 200, {|c| say c })   # iterate over composites in [100, 200]

say 10.next_composite    # next composite after 10 = 12
say 10.prev_composite    # previous composite before 10 = 9
say 5.next_composites    # [4, 6, 8, 9, 10] — first 5 composites
```

---

## 7. Primality Testing

### Deterministic Tests

```ruby
say ((2**31 - 1).is_prime)    # true  — M_31
say ((2**67 - 1).is_prime)    # false — composite (Cole 1903)
say ((2**127 - 1).is_prime)   # true  — M_127

# BPSW: strong base-2 Fermat + extra-strong Lucas. No known composite passes:
say n.is_bpsw_prime

# Provably prime via ECPP (works for arbitrary large primes):
say n.is_ecpp_prime
say n.is_prov_prime    # alias: is_provable_prime

# AKS — unconditionally polynomial, slow in practice:
say 101.is_aks_prime

# N−1 and N+1 primality proofs (require smooth N±1):
say ((2**31 - 1).is_nminus1_prime)
say ((2**61 + 1).is_nplus1_prime)
```

### BPSW in Detail

```ruby
say n.is_strong_psp(2)                   # strong Fermat, base 2   (alias: is_strong_fermat_psp)
say n.is_strong_lucas_psp                # strong Lucas (Selfridge parameters)
say n.is_extra_strong_lucas_psp          # slightly stronger variant
say n.is_bfsw_psp                        # BFW test — also no known composites
say n.is_bpsw_prime                      # = strong_psp(2) + extra_strong_lucas_psp combined
```

### Miller-Rabin

```ruby
say n.miller_rabin_random(20)    # 20 rounds with random bases
```

### Named Prime Classes

```ruby
say 23.is_safe_prime       # p and (p-1)/2 both prime
say 11.is_sophie_germain   # p and 2p+1 both prime
say  5.is_twin_prime       # p and p+2 both prime (A001359)
say  5.is_balanced_prime   # p = (prev_prime + next_prime)/2 (A006562)
say 13.is_emirp            # prime whose digit-reversal is a different prime (A006567)
say  n.is_mersenne_prime   # Lucas-Lehmer test on 2^n − 1
say 97.is_proth_prime      # n = k·2^m + 1 with k < 2^m (Proth's theorem)
```

### The `th` Idiom

```ruby
say 100.th { .is_prime }    # 100th prime = 541
say   1.st { .is_prime }    # 2
say   2.nd { .is_prime }    # 3
```

---

## 8. Integer Factorization Algorithms

`factor(n)` dispatches automatically. The individual methods below let you target
specific algebraic structures.

### Trial Division

```ruby
say ((17 * 19 * 100003).trial_factor(200))   # finds 17 and 19
```

### Fermat and Hart

Effective when the factors are close (n = a² − b² with small a − b):

```ruby
say ((1000003 * 1000033).fermat_factor)   # fast — factors differ by 30
say n.holf_factor                        # Hart's OLF variant
say n.holf_factor(5000)                  # with explicit tries limit
```

### Pollard's Rho and Brent

```ruby
var n = 2**64 + 1
say n.rho_factor             # Pollard's rho  (alias: prho_factor)
say n.rho_brent_factor       # Brent's improvement  (alias: pbrent_factor)
say n.rho_factor(100000)     # with iteration limit
```

### p − 1 and p + 1 Methods

```ruby
say n.pm1_factor(100000)   # Pollard p−1: exploits Fermat's little theorem (alias: pminus1_factor)
say n.pp1_factor(100000)   # Williams p+1: exploits Lucas sequences (alias: pplus1_factor)
```

### Elliptic Curve Method (ECM)

Best general-purpose method for factors of 20–60 digits:

```ruby
var n = 2**128 + 1
say n.ecm_factor
say n.ecm_factor(2000, 200000)   # B1=2000, curves=200000
```

### Quadratic Sieve and SQUFOF

```ruby
say n.squfof_factor   # Shanks' SQUFOF — very fast for 20–30 digit numbers
say n.qs_factor       # Pomerance's Quadratic Sieve
```

### Algebraic and Special Factorizations

```ruby
say ((2**12 - 1).cyclotomic_factor)    # exploits Φ_d(2) for various d
say n.dop_factor                       # difference-of-powers: x^n − y^n
say n.cop_factor                       # congruence-of-powers
say n.chebyshev_factor                 # Chebyshev polynomial factoring
say n.fibonacci_factor                 # Fibonacci / Lucas numbers
say n.lucas_factor
say n.germain_factor                   # Sophie Germain identity: x^4 + 4y^4
say n.flt_factor(2, 1000000)           # FLT-based; base=2, up to 10^6 iterations
say n.mbe_factor(50)                   # Modular Binary Exponentiation; effective for smooth p−1
say n.miller_factor(200)               # Miller-Rabin composite witnesses reveal factors

# GCD-based: combine auxiliary integers to sieve out factors:
say n.gcd_factors([19*43*97, 1, 13*41*43*101])
```

### Dispatching Pipeline

```ruby
func full_factor(n) {
    n.is_prime && return [n]
    var d = (n.trial_factor(1000).first \\ n.rho_brent_factor \\ n.ecm_factor)
    d || return [n]
    return [full_factor(d)..., full_factor(n/d)...].sort
}
say full_factor(2**128 + 1)
```

---

## 9. Modular Arithmetic

### Basic Operations

```ruby
say powmod(2, 1000, 1000000007)   # 2^1000 mod 10^9+7  (alias: expmod)
say invmod(17, 100)               # 17^{-1} mod 100 = 53

# Verify 17·53 ≡ 1 (mod 100):
say 17*53 % 100   # 1

# Extended GCD: returns (g, x, y) with g = gcd(a,b) and g = xa + yb:
var (g, x, y) = (35).gcdext(15)...
say "gcd=#{g}, x=#{x}, y=#{y}"
say g == 35*x + 15*y   # true

# Fused modular helpers — exact, no overflow:
say addmod(43, 97, 127)             # (43+97) % 127
say mulmod(43, 97, 127)             # (43·97) % 127
say submod(43, 97, 127)             # (43−97) % 127
say powmod(2, 42, 43)              # 1  (Fermat)
say addmulmod(2, 3, 4, 127)        # (2 + 3·4) % 127
say muladdmod(2, 3, 4, 127)        # (2·3 + 4) % 127
say mulsubmod(2, 3, 4, 127)        # (2·3 − 4) % 127
say muladdmulmod(2, 3, 4, 5, 127)  # (2·3 + 4·5) % 127
say mulsubmulmod(2, 3, 4, 5, 127)  # (2·3 − 4·5) % 127
```

### Multiplicative Order and Primitive Roots

```ruby
say znorder(2, 13)          # ord_13(2) = 12 — 2 is a primitive root mod 13
say znorder(2, 15)          # 4
say is_primitive_root(2, 13)   # true
say 13.znprimroot          # 2 — smallest primitive root mod 13

# n has a primitive root iff n ∈ {1, 2, 4, p^k, 2p^k}:
say 13.is_cyclic    # true
say 12.is_cyclic    # false — (ℤ/12ℤ)* ≅ ℤ/2 × ℤ/2
```

### Discrete Logarithm

```ruby
# znlog(a, g, m): find k with a ≡ g^k (mod m). Returns NaN if no solution.
say znlog(3, 2, 13)     # 4  — since 2^4 ≡ 3 (mod 13)
say znlog(5, 3, 7)      # 5  — since 3^5 ≡ 5 (mod 7)

var k = znlog(3, 2, 13)
say (powmod(2, k, 13) == 3)   # true ✓
```

### Linear Congruences and CRT

ax ≡ b (mod m) is solvable iff gcd(a, m) | b:

```ruby
say linear_congruence(7, 5, 12)    # 7x ≡ 5 (mod 12) → all solutions mod 12
say linear_congruence(6, 4, 10)    # gcd(6,10)=2|4 → 2 solutions: [2, 7]

# Manual CRT from gcdext:
func crt(r1, m1, r2, m2) {
    var (g, u, v) = (m1).gcdext(m2)...
    (r2-r1) % g != 0 && return nil
    var lcm = m1 * m2 / g
    return (r1 + m1 * u * ((r2-r1)/g)) % lcm
}
say crt(2, 3, 3, 5)   # x ≡ 2 (mod 3), x ≡ 3 (mod 5)  →  8 (mod 15)
say crt(1, 4, 3, 7)   # x ≡ 1 (mod 4), x ≡ 3 (mod 7)  →  17 (mod 28)
```

### Generalised Modular Roots

```ruby
say rootmod(8, 3, 13)        # x^3 ≡ 8 (mod 13)
say rootmod_all(1, 4, 17)    # all 4th roots of unity mod 17

say sqrtmod(3, 11)           # Tonelli-Shanks: √3 mod 11 = 5
say sqrtmod_all(1, 8)        # [1, 3, 5, 7] — all square roots of 1 mod 8
say sqrtmod_all(4, 15)       # x^2 ≡ 4 (mod 15) — via CRT over prime factors

# Chebyshev polynomials mod m:
say chebyshevTmod(10, 3, 101)   # T_{10}(3) mod 101
say chebyshevUmod(10, 3, 101)   # U_{10}(3) mod 101
```

### Geometric Sums

```ruby
# Σ_{k=0}^{n-1} r^k = (r^n − 1)/(r−1):
say geometric_sum(5, 8)           # 8^0 + … + 8^5 = 37449
say geometric_summod(5, 8, 10007) # same mod 10007
```

---

## 10. Quadratic Residues and Congruences

### Symbol Functions

```ruby
say legendre(3, 11)    #  1  — QR mod 11  (Legendre symbol)
say legendre(3, 7)     # -1  — QNR mod 7

say jacobi(7, 15)      # (7/15) = (7/3)·(7/5) = 1·(−1) = −1  (Jacobi symbol)
say jacobi(2, 9)       #  1  — but 2 is NOT a QR mod 9

say kronecker(2, -1)   # Kronecker symbol extension
say kronecker(-1, 5)   # (−1)^{(5−1)/2} = 1
```

The Jacobi symbol (a/n) = 1 does **not** imply a is a QR mod n — only the Legendre
symbol at a prime guarantees that. This asymmetry underlies the Euler pseudoprime test
and the Solovay-Strassen algorithm.

### Quadratic Residuosity and Square Roots

```ruby
say 13.quadratic_nonresidue   # 2 — smallest QNR mod 13  (alias: qnr)

say sqrtmod(3, 11)            # Tonelli-Shanks: 5 (since 5^2 ≡ 3 mod 11)
say sqrtmod_all(1, 8)         # [1, 3, 5, 7]
say sqrtmod_all(4, 15)
```

### Quadratic Reciprocity in Practice

```ruby
# For p ≡ 1 (mod 4): −1 is always a QR mod p
for p in (primes(5, 50)) {
    p%4 == 1 && say "(−1/#{p}) = #{(-1).legendre(p)}"   # always 1
}

# 2 is a QR mod p iff p ≡ ±1 (mod 8):
for p in (primes(3, 50)) {
    var sym      = legendre(2, p)
    var expected = (p%8 == 1 || p%8 == 7) ? 1 : -1
    say "(2/#{p}) = #{sym}: #{sym == expected}"
}
```

### Quadratic Congruences

```ruby
# quadratic_congruence(a, b, c, m): all x with ax^2 + bx + c ≡ 0 (mod m):
say quadratic_congruence(1, 0, -3, 11)     # x^2 ≡ 3 (mod 11)  → [5, 6]
say quadratic_congruence(3, 4, 5, 124)     #=> [47, 55, 109, 117]

# Integer solutions of ax^2 + bx + c = 0 over ℤ:
say iquadratic_formula(1, -5, 6)    # x^2 − 5x + 6 = 0  →  [2, 3]
```

### Cornacchia's Algorithm

Express a prime p as x² + d·y²:

```ruby
say 29.cornacchia(1)    # [5, 2]: 5^2 + 1·2^2 = 29
say 61.cornacchia(4)    # [5, 3]: 5^2 + 4·3^2 = 61

# Representation count r_k(n):
say squares_r(325, 2)   # r_2(325): A004018   (alias: sum_of_squares_count)
say squares_r(7, 4)     # r_4(7):   A000118 — always > 0 by Lagrange

# Explicit representations as sum of two squares:
say sum_of_squares(99025)
#=> [[41, 312], [48, 311], [95, 300], [104, 297], [183, 256], [220, 225]]

say solve_quadratic_form(1, 0, 1, 5)   # x^2 + y^2 = 5
```

---

## 11. Dirichlet Convolution

(f * g)(n) = Σ_{d|n} f(d) g(n/d):

```ruby
var n = 12

# σ = id * 1:
say n.dirichlet_convolution({|d| d }, {|d| 1 })
say n.sigma   # 28 ✓

# τ = 1 * 1:
say n.dirichlet_convolution({|d| 1 }, {|d| 1 })
say n.sigma0   # 6 ✓

# φ = μ * id:
say n.dirichlet_convolution({|d| d.moebius }, {|d| d })
say n.euler_phi   # 4 ✓

# ψ = |μ| * id (Dedekind psi):
say n.dirichlet_convolution({|d| d.moebius.abs }, {|d| d })
say n.dedekind_psi   # ✓
```

### Möbius Inversion

If g = f * **1**, then f = g * **μ**:

```ruby
var n = 60

# σ = id * 1, so id = σ * μ:
say n.dirichlet_convolution({|d| d.sigma }, {|d| d.moebius })   # = 60 ✓

# τ = 1 * 1, so 1 = τ * μ:
say n.dirichlet_convolution({|d| d.tau }, {|d| d.moebius })     # = 1 ✓
```

### The Dirichlet Hyperbola Method

Computes Σ_{n≤x} (f*g)(n) in O(x^{1/2}) given partial-sum functions for f and g:

```ruby
var n = 10**6

# Σ_{k≤n} τ(k): the classical Dirichlet divisor problem
say n.dirichlet_hyperbola({|k| 1 }, {|k| 1 }, {|k| k }, {|k| k })
say n.tau_sum   # same ✓

# Σ_{k≤n} σ(k):
say n.dirichlet_hyperbola({|k| k }, {|k| 1 }, {|k| k*(k+1)/2 }, {|k| k })
say n.sigma_sum   # same ✓
```

### General Partial Sum

```ruby
say 1000.dirichlet_sum {|k| k.moebius }    # = mertens(1000)
say 1000.dirichlet_sum {|k| k.liouville }  # = liouville_sum(1000)
say 1000.dirichlet_sum {|k| k.euler_phi }  # = totient_sum(1000)
```

---

## 12. Arithmetic Derivative

The arithmetic derivative n' is uniquely determined by 1' = 0, p' = 1 for all primes,
and (ab)' = a'b + ab'. For n = ∏ p_i^{e_i}: n' = n · Σ_{p^e || n} e/p.

```ruby
say 1.arithmetic_derivative    # 0
say 2.arithmetic_derivative    # 1
say 4.arithmetic_derivative    # (2²)' = 2·2 = 4
say 6.arithmetic_derivative    # (2·3)' = 1·3 + 2·1 = 5
say 12.arithmetic_derivative   # 12·(2/2 + 1/3) = 16   (alias: derivative)

# Product rule:
for (a, b) in ([[6, 10], [12, 35], [15, 28]]) {
    var lhs = (a*b).arithmetic_derivative
    var rhs = a.arithmetic_derivative*b + a*b.arithmetic_derivative
    say "(#{a}·#{b})' = #{lhs}  rule = #{rhs}: #{lhs == rhs}"
}
```

### Logarithmic Derivative

n'/n = Σ_{p^e || n} e/p — an exact rational:

```ruby
# 360 = 2^3·3^2·5 → 360'/360 = 3/2 + 2/3 + 1/5 = 61/30
say 360.logarithmic_derivative   # 61/30
say 360.arithmetic_derivative / 360   # same ✓
```

### Fixed Points (n' = n)

n' = n iff n = p^p for some prime p:

```ruby
say 4.arithmetic_derivative == 4    # true  — 2^2
say 27.arithmetic_derivative == 27  # true  — 3^3
```

---

## 13. Continued Fractions and Pell's Equation

### Continued Fraction Expansions

```ruby
say  7.sqrt_cfrac            # partial quotients of √7
say  7.sqrt_cfrac_period     # [1, 1, 1, 4] — the periodic block
say  7.sqrt_cfrac_period_len # 4
say 61.sqrt_cfrac_period_len # 11 — the largest period for D < 100
```

`convergents(k)` returns the first k convergents as exact rationals:

```ruby
say Num.pi.convergents(5)
#=> [3, 22/7, 333/106, 355/113, 103993/33102]

say 7.sqrt.convergents(8)
#=> [2/1, 3/1, 5/2, 8/3, 11/4, 19/7, 30/11, 49/18]
# Note: 8^2 − 7·3^2 = 1 ✓ — p_3/q_3 is the fundamental Pell solution
```

### Farey Sequences and Best Approximations

```ruby
say 5.farey                    # Farey sequence F_5
say 7.farey_neighbors(3, 5)    # neighbours of 3/5 in F_7

# Best rational approximation with denominator ≤ max_den:
say Num.pi.rat_approx(1000)    # 355/113
```

### Pell's Equation x² − D·y² = 1

The fundamental solution comes from the convergents of √D:

```ruby
say solve_pell(2)    # [3, 2]:  3^2 − 2·2^2 = 1
say solve_pell(7)    # [8, 3]:  8^2 − 7·3^2 = 1
say solve_pell(61)   # [1766319049, 226153980] — famously large

var (x0, y0) = solve_pell(7)...
say x0**2 - 7*y0**2   # 1 ✓

# Optional second argument k: solve x² − D·y² = k:
say solve_pell(2, -1)    # [1, 1]: 1 − 2·1 = −1

# Generating further solutions via composition:
# (x_n + y_n√D) = (x_0 + y_0√D)^n
var (x, y) = (x0, y0)
for k in (1..5) {
    say "Solution #{k}: (#{x}, #{y}),  x²-7y²=#{x**2 - 7*y**2}"
    (x, y) = (x0*x + 7*y0*y, y0*x + x0*y)
}
```

Period length parity determines which convergent gives the fundamental solution:
even period → convergent p_{ℓ−1}/q_{ℓ−1};
odd period → convergent p_{2ℓ−1}/q_{2ℓ−1}.

### Pisano Periods

The Pisano period π(m) is the period of the Fibonacci sequence mod m:

```ruby
say 10.pisano_period   # π(10) = 60
say  7.pisano_period   # π(7)  = 16

# For prime p:
# p ≡ ±1 (mod 5) → π(p) | p−1
# p ≡ ±2 (mod 5) → π(p) | 2(p+1)
for p in (primes(3, 50)) {
    say "π(#{p}) = #{p.pisano_period},  p mod 5 = #{p%5}"
}
```

### General Lucas Sequences

U_n(P, Q) and V_n(P, Q) unify Fibonacci, Lucas, Pell, Jacobsthal, and many more:

```ruby
say 20.of {|n| lucasU(1, -1, n) }   # Fibonacci numbers  (P=1, Q=-1)
say 20.of {|n| lucasV(1, -1, n) }   # Lucas numbers
say 20.of {|n| lucasU(2, -1, n) }   # Pell numbers        (P=2, Q=-1)
say 20.of {|n| lucasV(2, -1, n) }   # Pell-Lucas numbers
say 20.of {|n| lucasU(1, -2, n) }   # Jacobsthal numbers  (P=1, Q=-2)

# Fast modular evaluation for large indices:
say lucasumod(1, -1, 10**18, 10**9 + 7)
say fibonaccimod(10**18, 10**9 + 7)
```

---

## 14. Sublinear Summation

All functions here run in O(n^{1/2}) or O(n^{2/3}) time via sieve or
hyperbola methods.

### Divisor Function Sums

```ruby
say tau_sum(10**9)     # Σ τ(k) ~ n log n + (2γ−1)n   (A006218; alias: sigma0_sum)
say sigma_sum(10**9)   # Σ σ(k) ~ π²n²/12
```

### Totient, Möbius, Liouville

```ruby
say totient_sum(10**9)       # Σ φ(k) ~ 3n²/π²          (alias: euler_phi_sum)
say mertens(10**9)           # M(n) = Σ μ(k);  also: mertens(a, b) for ranges
say liouville_sum(10**9)     # L(n) = Σ λ(k)
say psi_sum(10**6)           # Σ ψ(k)                    (alias: dedekind_psi_sum)

# Jordan totient partial sums Σ J_k(m) = totient_sum with parameter:
say jordan_totient_sum(10**6, 2)   # alias: totient_sum(10^6, 2)
say jordan_totient_sum(10**6, 3)
```

### Chebyshev ψ̃ (Integer Version)

```ruby
say 10000.exp_mangoldt_sum   # Σ_{k≤n} exp_mangoldt(k) — integer ψ̃
```

### Prime Sums

```ruby
say prime_sum(10**9)   # Σ_{p≤n} p — sublinear

# With exponent:
say primes_sum(1, 10**6, 2)   # Σ_{p≤10^6} p^2
```

### Omega Partial Sums

```ruby
say omega_sum(10**6)        # Σ ω(k) ~ n log log n
say bigomega_sum(10**6)     # Σ Ω(k)

# exp_omega_sum(n, base) and exp_bigomega_sum(n, base) — base is the accumulation factor:
say exp_omega_sum(10**5, 2)       # Σ 2^{ω(k)}
say exp_bigomega_sum(10**5, 2)    # Σ 2^{Ω(k)}
say exp_bigomega_sum(10**9, -1)   # = liouville_sum (since λ(k) = (−1)^Ω(k))
```

### Pillai and Sum of Remainders

```ruby
say pillai_sum(10**5)   # Σ_{k≤n} pillai(k)

# sum_remainders(n, v) = Σ_{k=1}^n (v mod k) in O(√v) steps:
say 20.of {|n| sum_remainders(n, n) }           # A004125
say 20.of {|n| sum_remainders(n, n.prime) }     # A099726
```

### Verifying Asymptotics

```ruby
var n = 10**8
say ((n.tau_sum / (n * n.log)).as_float)                   # → 1  (dominant term)
say ((n.totient_sum / (3*n**2 / Num.pi**2)).as_float)      # → 1
```

---

## 15. Integer Classifications and Sequences

### Smooth and Rough Numbers

```ruby
say 720.is_smooth(5)         # all prime factors ≤ 5 ✓
say 7.smooth_count(1000)     # count of 7-smooth numbers ≤ 1000
say 1000.smooth_numbers(7.primes)   # full list

say 5.smooth_part(720)        # largest 5-smooth divisor of 720
say 5.smooth_part(105)        # 105 = 3·5·7 → 15

say 100.next_smooth(5)        # next 5-smooth number after 100
say 100.prev_smooth(5)        # previous 5-smooth number before 100

say 7.rough_count(1000)       # count of 7-rough numbers ≤ 1000
say 1000.rough_numbers(7)

say 100.next_rough(7)         # next 7-rough number after 100
say 100.prev_rough(7)         # previous 7-rough number before 100
```

### Perfect Powers and Powerful Numbers

```ruby
say  72.is_powerful         # true: every prime appears to power ≥ 2
say 100.powerful_count      # powerful numbers ≤ 100

say  64.is_power            # true: 2^6 = 4^3 = 8^2
say  64.perfect_root        # 2 — smallest base
say  64.is_power_of(2)      # true

say next_perfect_power(10**6)      # 1002001 = 1001^2
say next_perfect_power(10**6, 3)   # 1030301 = 101^3
```

### Squarefree Numbers

```ruby
say 30.is_squarefree    # true
say 12.is_squarefree    # false: 4 | 12

say 1000.squarefree_count   # ≈ 6n/π² ≈ 608
say 1000.squarefree_sum
say 50.next_squarefree
say 50.prev_squarefree
say nth_squarefree(100)
```

### k-Free and k-Full Numbers

```ruby
say 100.cubefree_count
say 100.cubefull_count
say  50.next_cubefree
say  50.prev_cubefull
say 100.powerfree_count(3)      # = cubefree_count
say n.next_powerfree(4)         # next 4-powerfree number
say 100.nonpowerfree_count(2)   # non-squarefree count ≤ 100
```

### Almost Primes and ω-Primes

```ruby
# Receiver is the order k:
say 100.semiprime_count                # = 2.almost_prime_count(100)
say 2.almost_prime_count(50, 100)      # semiprimes in [50, 100]
say 50.next_semiprime
say 50.prev_semiprime
say nth_semiprime(100)
say 1000.semiprime_sum

say 100.squarefree_semiprime_count     # A072613
say 100.squarefree_semiprimes

# ω-primes: ω(n) = k
say 30.is_omega_prime(3)               # 30 = 2·3·5, ω = 3 ✓
say 100.omega_prime_count(2)
say 50.next_omega_prime(3)
```

### Sphenic Numbers

Product of exactly 3 distinct primes:

```ruby
say 30.is_sphenic    # 30 = 2·3·5 ✓
say 42.is_sphenic    # 42 = 2·3·7 ✓
say 12.is_sphenic    # false — 12 = 2^2·3

say 100.sphenic_count
say 30.next_sphenic
say 30.prev_sphenic
```

### nth-Indexed Sequences

All functions here return the n-th element of the corresponding integer sequence.

```ruby
# Smooth and rough numbers:
say nth_smooth(100, 5)              # 100th 5-smooth number
say nth_rough(1000, 7)             # 1000th 7-rough number

# Composites:
say composite(1000)                 # 1000th composite  (alias: nth_composite)

# Perfect powers:
say nth_perfect_power(1000)         # 1000th perfect power
say nth_perfect_power(1000, 2)      # 1000th perfect square

# Powers of a specific type:
say nth_prime_power(1000)           # 1000th prime power p^k (k ≥ 1)

# Squarefree and squarefull:
say nth_squarefree(1000)            # 1000th squarefree number
say nth_squarefull(100)             # 100th squarefull (2-full) number

# k-powerfree and k-powerful:
say nth_powerfree(1000, 2)          # 1000th squarefree (2-powerfree) number
say nth_powerfree(1000, 3)          # 1000th cubefree number
say nth_powerful(100, 2)            # 100th powerful (2-powerful) number
say nth_powerful(100, 3)            # 100th 3-powerful number

# Cubefree and cubefull:
say nth_cubefree(1000)              # 1000th cubefree number
say nth_cubefull(100)               # 100th cubefull (3-full) number

# Non-free variants:
say nth_nonsquarefree(1000)         # 1000th non-squarefree number
say nth_noncubefree(1000)           # 1000th non-cubefree number
say nth_nonpowerfree(1000, 2)       # 1000th non-squarefree number

# Almost primes and ω-primes:
say nth_almost_prime(1000, 2)       # 1000th semiprime
say nth_almost_prime(1000, 3)       # 1000th 3-almost prime
say nth_squarefree_almost_prime(1000, 2)   # 1000th squarefree semiprime
say nth_omega_prime(1000, 2)        # 1000th 2-omega prime (ω(n) = 2)

# Sphenic numbers (product of 3 distinct primes):
say nth_sphenic(1000)               # 1000th sphenic number

# tau-inverse (exactly k divisors):
say nth_tau_inverse(100, 6)         # 100th integer with exactly 6 divisors
```

### Practical Numbers

n is **practical** (A005153) if every m ≤ σ(n) is a sum of distinct divisors of n.
Primorials and even perfect numbers are practical:

```ruby
say 12.is_practical   # true
say  7.is_practical   # false
say 28.is_practical   # true (perfect number)
```

### Amicable Pairs

`is_amicable(m, n)` takes **two** arguments:

```ruby
say is_amicable(220, 284)   # true — s(220) = 284 and s(284) = 220

for n in (2..10000) {
    var s = n.aliquot_sum
    s > n && is_amicable(n, s) && say "(#{n}, #{s})"
}
```

### Collatz Steps

`collatz(n)` returns the **step count** to reach 1 in the 3x+1 map,
not the trajectory:

```ruby
say 27.collatz   # 111 — notorious long chain
say  1.collatz   # 0

# Record Collatz lengths up to 100:
var record = 0
for n in (1..100) {
    var c = n.collatz
    if (c > record) { record = c; say "n=#{n}: #{c} steps" }
}
```

---

## 16. Pseudoprimes and Carmichael Numbers

### Fermat Pseudoprimes

n is a Fermat psp(a) if n is composite and a^{n−1} ≡ 1 (mod n):

```ruby
say 341.is_fermat_psp(2)   # true — first psp(2)  (alias: is_fermat_pseudoprime)
say 561.is_fermat_psp(2)   # true — first Carmichael number

1000.fermat_psp_each(2, {|n| say n })
```

### Strong Pseudoprimes

Write n−1 = 2^s·d. n is a strong psp(a) if a^d ≡ 1 or a^{2^r·d} ≡ −1 for some r < s:

```ruby
say 2047.is_strong_psp(2)   # first spsp(2)  (alias: is_strong_fermat_psp, miller_rabin)

# k-factor variants: k is the receiver (number of distinct prime factors):
say 3.squarefree_strong_fermat_psp(2, 10**6)
say 4.strong_fermat_psp(2, 10**6)
```

### Carmichael Numbers

By Korselt's criterion: n is Carmichael iff n is squarefree, composite,
and (p−1) | (n−1) for all p | n. Equivalently: λ(n) | n−1.

```ruby
say 561.is_carmichael    # 561 = 3·11·17

# Korselt's criterion explicitly:
func korselt(n) {
    n.is_squarefree || return false
    for p in (n.prime_factors) {
        (n-1) % (p-1) != 0 && return false
    }
    return true
}
say korselt(561)   # true

say ((561-1) % 561.carmichael_lambda == 0)   # true — λ(n) | n−1 ✓

# Enumerate; receiver is the factor-count k:
say 3.carmichael(100000)                                    # 3-prime-factor Carmichaels ≤ 100000
say 4.carmichael(10**9)                                     # 4-prime-factor Carmichaels ≤ 10^9
carmichael_each(1, 100000, {|n| say n })                    # all Carmichaels ≤ 100000
say 3.carmichael_strong_fermat(2, 10**7)                    # strong-Fermat Carmichaels
```

### Lucas Carmichael Numbers

(p+1) | (n+1) for all p | n:

```ruby
say 399.is_lucas_carmichael   # 399 = 3·7·19: 4|400, 8|400, 20|400 ✓
lucas_carmichael_each(1, 100000, {|n| say n })
```

### Lucas and Frobenius Pseudoprimes

```ruby
say n.is_lucas_psp                         # Lucas psp (Selfridge parameters)
say n.is_strong_lucas_psp                  # strong variant
say n.is_extra_strong_lucas_psp            # even stronger
say n.is_frobenius_pseudoprime             # Frobenius test
say n.is_frobenius_khashin_pseudoprime     # Khashin's variant
say n.is_frobenius_underwood_pseudoprime   # Underwood's variant

say n.is_lucasU_pseudoprime(1, -1)         # U_n(1,-1) ≡ 0 (mod n)
say n.is_lucasV_pseudoprime(1, -1)         # V_n(1,-1) ≡ 1 (mod n)

# Perrin primality: if p prime then p | A(p):
say 271441.is_perrin_pseudoprime   # true — 271441 = 521^2 passes but is composite
```

---

## 17. Combinatorics and Partitions

### Additive Partitions

```ruby
say partitions(4)            # [[4],[3,1],[2,2],[2,1,1],[1,1,1,1]]
say partitions(4, 2)         # partitions with parts ≤ 2
say strict_partitions(6)     # all parts distinct
say strict_partitions(12, 5) # strict, parts ≤ 5

say partition_count(100)     # p(100) = 190569292  (alias: partition_number)
```

### Multiplicative Partitions

All factorisations of n into integers > 1 (A001055):

```ruby
say multiplicative_partitions(30)
#=> [[30], [2,15], [3,10], [5,6], [2,3,5]]

say multiplicative_partitions(30, 10)       # parts ≤ 10
say multiplicative_partitions(30, nil, 11)  # sum of parts ≤ 11
```

### Subsets, Tuples, Permutations

```ruby
5.subsets(2, {|*a| say a })                       # 2-subsets of {0..4}
5.combinations(2, {|*a| say a })                  # 2-combinations
5.combinations_with_repetition(2, {|*a| say a })  # with repetition
5.tuples(2, {|*a| say a })                        # ordered 2-tuples
5.circular_permutations {|*a| say a }             # circular arrangements
```

### Stirling Numbers

```ruby
say stirling(5, 2)    # S1(5,2): Stirling numbers of the first kind
say stirling2(5, 2)   # S2(5,2): Stirling numbers of the second kind
say stirling3(5, 2)   # Lah numbers
```

### Derangements and Rencontres Numbers

`subfactorial(n, k)` = number of permutations of n elements with exactly k fixed
points (D(n, k) — the rencontres numbers; A000166 for k=0):

```ruby
say 20.of { .subfactorial }        # D(n, 0): derangements  (A000166)
say 20.of { .subfactorial(2) }     # D(n, 2)                (A000387)
say subfactorial(5, 0)             # 44 — derangements of 5 elements
```

### Polygonal Numbers

```ruby
say 10.polygonal(3)          # 10th triangular = 55
say 10.polygonal(4)          # 10th square = 100
say 10.polygonal(5)          # 10th pentagonal = 145
say 55.is_polygonal(3)       # true
say ipolygonal_root(145, 5)  # 10
say 10.centered_polygonal(6) # 10th centered hexagonal = 91
say 10.pyramidal(3)          # 10th tetrahedral = 220
```

### Multinomial Coefficients

```ruby
say multinomial(1, 4, 4, 2)   # 11!/(1!4!4!2!) = 34650
```

---

## 18. Special Arithmetic Functions

### Ramanujan's τ Function

τ(n) is the coefficient of q^n in Δ(q) = q ∏_{k≥1}(1−q^k)^{24}:

```ruby
say 1.ramanujan_tau   #  1
say 2.ramanujan_tau   # -24
say 3.ramanujan_tau   #  252
say 4.ramanujan_tau   # -1472
say 5.ramanujan_tau   #  4830

# Multiplicativity for gcd(m, n) = 1:
say 2.ramanujan_tau * 3.ramanujan_tau == 6.ramanujan_tau   # true

# Deligne's theorem |τ(p)| ≤ 2p^{11/2}:
for p in (primes(2, 50)) {
    var t = p.ramanujan_tau
    say "|τ(#{p})| = #{t.abs},  bound = #{(2 * p**5.5).round}"
}
```

### Smarandache / Kempner Function

S(n) = smallest m with n | m! (alias: `kempner`):

```ruby
say 1.smarandache   # 1
say 4.smarandache   # 4  — 4 | 4! but 4 ∤ 3!
say 9.smarandache   # 6  — 9 | 6! (since v_3(6!) = 2)

for k in (1..6) {
    say "S(2^#{k}) = #{(2**k).smarandache}"
}
```

### Cyclotomic Polynomials

```ruby
say cyclotomic(12)      # Φ_{12}(x) = x^4 − x^2 + 1  (as a Polynomial object)
say cyclotomic(12, 2)   # Φ_{12}(2) = 16 − 4 + 1 = 13
say cyclotomic(6, 2)    # Φ_6(2) = 3

# Product identity x^n − 1 = ∏_{d|n} Φ_d(x):
say 12.divisors_prod {|d| cyclotomic(d, 2) }   # = 2^12 − 1 = 4095
say (2**12 - 1)   # 4095 ✓

say cyclotomicmod(12, 2, 10**9 + 7)   # Φ_{12}(2) mod 10^9+7
```

### Bernoulli Numbers

```ruby
say  2.bernfrac    # B_2  = 1/6
say  4.bernfrac    # B_4  = −1/30
say 12.bernfrac    # B_12 = −691/2730  ← the famous 691

# Von Staudt–Clausen: denominator(B_{2k}) = ∏_{(p-1)|2k} p:
say 12.bernfrac.denominator   # 2730 = 2·3·5·7·13

# Array B_0 … B_n:
say bernoulli_numbers(6)   #=> [1, -1/2, 1/6, 0, -1/30, 0, 1/42]

# Irregular primes: p | numerator(B_{p-1}) (Kummer's criterion):
var irregular = []
for p in (primes(5, 200)) {
    for k in (range(2, p-1, 2)) {
        k.bernfrac.numerator.abs % p == 0 || next
        irregular.append(p)
        break
    }
}
say irregular.first(10)   #=> [37, 59, 67, 101, 103, 131, 149, 157, 233, 257]
```

### Faulhaber's Formula

Σ_{k=1}^n k^p exactly, via Bernoulli numbers:

```ruby
say faulhaber_sum(100, 1)       # Σ k   = 5050
say faulhaber_sum(100, 2)       # Σ k^2 = 338350
say faulhaber_sum(100, 3)       # Σ k^3 = 25502500 = 5050^2 ✓

# Range sum Σ_{k=a}^b k^p:
say faulhaber_range(50, 100, 2)  # Σ_{k=50}^100 k^2
```

### Bell, Catalan, Motzkin, Fubini

```ruby
say  5.bell_number     # B_5 = 52      set partitions of a 5-element set
say 10.bell_number     # B_10 = 115975
say bellmod(100, 10**9 + 7)   # B_100 mod 10^9+7

say  5.catalan    # C_5  = 42
say 10.catalan    # C_10 = 16796

say  5.motzkin    # M_5  = 21    (A001006)
say 10.motzkin    # M_10 = 2188

say 4.fubini          # 75    ordered set partitions  (A000670)
say 5.fubini          # 541
say fubini_numbers(5) #=> [1, 1, 3, 13, 75, 541]
```

### Harmonic Numbers

```ruby
# harmonic(n): H_n = 1 + 1/2 + … + 1/n as exact rational:
say 10.harmonic      # 7381/2520

# N-th Harmonic number of k-th order:
say 10.harmonic(2)   # 55991/2520
```

### Subfactorial / Derangements

See Section 17. `subfactorial(n, k)` = D(n, k) (rencontres numbers).

### Perrin Sequence

A(0)=3, A(1)=0, A(2)=2, A(n) = A(n−2) + A(n−3). Prime test: p prime → p | A(p):

```ruby
for p in (primes(3, 50)) {
    say "A(#{p}) mod #{p} = #{perrinmod(p, p)}"   # always 0
}

# First Perrin pseudoprime: 271441 = 521^2
say 271441.is_prime           # false
say perrinmod(271441, 271441) # 0 — passes despite being composite
```

### Padovan Sequence

A(0)=1, A(1)=0, A(2)=0, A(n) = A(n−2) + A(n−3) (A000931):

```ruby
say 20.of {|n| padovan(n) }
say padovanmod(1000, 10**9 + 7)
```

### Tangent and Secant Numbers

```ruby
say 20.of {|n| tangent_number(n) }   # A000182: zig numbers
say 20.of {|n| secant_number(n) }    # A000364: zag numbers
```

### Hurwitz-Kronecker Class Number

```ruby
# hclassno(n): class number h(−n) for quadratic forms of discriminant −n (rational)
say 30.of { .hclassno.nu }     # A058305 (numerators)
say 30.of { .hclassno.de }     # A058306 (denominators)
say 30.of { 12 * .hclassno }   # A259825
```

### Hyperfactorial, Superfactorial, Superprimorial

```ruby
say 5.hyperfactorial   # 1^1 · 2^2 · 3^3 · 4^4 · 5^5 = 86400000
say 5.superfactorial   # 0!·1!·2!·3!·4!·5! = product of first n factorials (A000178)
say 5.superprimorial   # product of first n primorials (A006939)
```

### Primitive Parts

`n.primitive_part(f)` returns the primitive part of f(n) relative to f(d) for d | n:

```ruby
func f(n) { n.fibonacci }
func a(n) { n.primitive_part(f) }

say 20.of {|n| a(n) }
# Verify: f(n) = ∏_{d|n} a(d)
say (12.divisors_prod {|d| a(d) } == f(12))   # true ✓
```

---

## 19. Quick Reference

```ruby
#── Factorization ───────────────────────────────────────────────────────
n.factor              #=> [p, p, q, ...]        sorted with repetition
n.factor_exp          #=> [[p, e], [q, f], ...]
n.factor_map {|p,e|}  #=> map over (p, e) pairs
n.factor_prod {|p,e|} #=> reduce-product over (p, e) pairs
n.factor_sum {|p,e|}  #=> reduce-sum over (p, e) pairs
n.valuation(k)        #=> v_k(n)
n.omega               #=> ω(n)  — distinct prime factors
n.bigomega            #=> Ω(n)  — total prime factors
n.lpf                 #=> least prime factor
n.gpf                 #=> greatest prime factor
n.rad                 #=> ∏_{p|n} p   (radical, A007947)  alias: squarefree_kernel
n.core                #=> squarefree part (A007913)        alias: squarefree_part
n.sopf                #=> Σ_{p|n} p   (A008472)
n.sopfr               #=> Σ_{p^e||n} e·p  (A001414)
n.prime_signature     #=> exponent vector, descending order
n.prime_power         #=> k if n = p^k, else 1
n.prime_root          #=> p if n = p^k, else n
n.perfect_power       #=> largest k: n = r^k
n.perfect_root        #=> smallest base r: n = r^k

#── Divisors ────────────────────────────────────────────────────────────
n.sigma(k)            #=> σ_k(n)  (k=1 default)
n.sigma0              #=> τ(n) = divisor count  aliases: tau, d
n.divisors            #=> sorted list
n.aliquot_sum         #=> σ(n) − n    aliases: aliquot, proper_sigma
n.proper_sigma0       #=> τ(n) − 1
n.divisors_sum {|d|}  #=> Σ_{d|n} f(d)
n.divisors_prod {|d|} #=> ∏_{d|n} f(d)
n.usigma(k)           #=> unitary sigma     (A034448)
n.bsigma(k)           #=> bi-unitary sigma  (A188999)
n.isigma(k)           #=> infinitary sigma  (A049417)
n.esigma(k)           #=> exponential sigma (A051377)
n.nusigma(k)          #=> non-unitary sigma
n.nbsigma(k)          #=> non-bi-unitary sigma
n.nisigma(k)          #=> noninfinitary sigma
n.nesigma(k)          #=> nonexponential sigma
n.udivisors           #=> unitary divisors
n.bdivisors           #=> bi-unitary divisors  alias: biudivisors
n.idivisors           #=> infinitary divisors
n.edivisors           #=> exponential divisors
n.nudivisors          #=> nonunitary divisors
n.nbdivisors          #=> non-bi-unitary divisors  alias: biudivisors
n.nidivisors          #=> noninfinitary divisors
n.nedivisors          #=> nonexponential divisors
n.sigma_inverse       #=> {m : σ(m) = n}
tau_inverse(lo,hi,k)  #=> {m ∈ [lo,hi] : τ(m) = k}
nth_tau_inverse(lo,k) #=> smallest m ≥ lo with τ(m) = k

#── Totients ────────────────────────────────────────────────────────────
n.euler_phi           #=> φ(n)  aliases: phi, totient, eulerphi
n.jordan_totient(k)   #=> J_k(n)
n.carmichael_lambda   #=> λ(n) — exponent of (ℤ/nℤ)*  alias: lambda
n.dedekind_psi        #=> ψ(n) = n ∏_{p|n}(1+1/p)     alias: psi
n.uphi                #=> unitary totient   (A047994)
n.bphi                #=> bi-unitary totient(A116550)
n.iphi                #=> infinitary totient(A091732)
n.phi_inverse         #=> {m : φ(m) = n}     alias: inverse_euler_phi
n.psi_inverse         #=> {m : ψ(m) = n}

#── Multiplicative functions ────────────────────────────────────────────
n.moebius             #=> μ(n)   aliases: mu, mobius
n.liouville           #=> (−1)^Ω(n)
n.exp_mangoldt        #=> p if n=p^k, else 1
n.ramanujan_tau       #=> Ramanujan τ(n)
n.smarandache         #=> S(n): smallest m with n | m!  alias: kempner
n.pillai              #=> Σ_{k=1}^n gcd(k,n)
n.ramanujan_sum(q)    #=> c_q(n)
n.arithmetic_derivative  #=> n'   alias: derivative
n.logarithmic_derivative #=> n'/n as exact rational

#── Primality ───────────────────────────────────────────────────────────
n.is_prime
n.is_bpsw_prime
n.is_prov_prime            # alias: is_provable_prime
n.is_ecpp_prime
n.miller_rabin_random(k)
n.is_strong_psp(a)         # aliases: is_strong_fermat_psp, miller_rabin
n.is_strong_lucas_psp      # alias: is_strong_lucas_pseudoprime
n.is_mersenne_prime        # Lucas-Lehmer test on 2^n − 1
n.is_safe_prime
n.is_sophie_germain        # n and 2n+1 both prime
n.is_twin_prime            # n and n+2 both prime
n.is_balanced_prime
n.is_emirp

#── Modular arithmetic ──────────────────────────────────────────────────
powmod(a, e, m)            #=> a^e mod m   alias: expmod
invmod(a, m)               #=> a^{-1} mod m
addmod(a, b, m)            #=> (a+b) % m
mulmod(a, b, m)            #=> (a·b) % m
submod(a, b, m)            #=> (a−b) % m
n.gcdext(m)                #=> (g, x, y) with g = xn + ym
znorder(a, m)              #=> ord_m(a)   alias: multiplicative_order
znlog(a, g, m)             #=> k: a ≡ g^k (mod m)
n.znprimroot               #=> smallest primitive root mod n
n.is_primitive_root(m)     #=> true if n is a primitive root mod m
n.is_cyclic                #=> true if n has a primitive root
n.jacobi(m)                #=> Jacobi symbol (n/m)
n.legendre(p)              #=> Legendre symbol (n/p)
n.kronecker(m)             #=> Kronecker symbol (n/m)
sqrtmod(a, m)              #=> √a mod m
rootmod(a, k, m)           #=> k-th root of a mod m
sqrtmod_all(a, m)          #=> all square roots of a mod m
linear_congruence(a, b, m) #=> all x with ax ≡ b (mod m)
n.cornacchia(d)            #=> [x,y] with x^2+d·y^2=n
solve_pell(D)              #=> [x,y] fundamental solution of x^2−Dy^2=1
solve_pell(D, k)           #=> [x,y] for x^2−Dy^2=k
squares_r(n, k)            #=> r_k(n): representation count as sum of k squares

#── Sublinear sums ──────────────────────────────────────────────────────
n.prime_count              #=> π(n)  aliases: primepi, count_primes
n.prime_sum                #=> Σ_{p≤n} p  aliases: primes_sum, sum_primes
n.mertens                  #=> M(n) = Σ μ(k);  mertens(a,b) for range
n.liouville_sum            #=> L(n) = Σ λ(k)
n.phi_sum                  #=> Σ_{k≤n} φ(k)    alias: totient_sum(n)
n.jordan_totient_sum(k)    #=> Σ_{m≤n} J_k(m)  alias: totient_sum(n,k)
n.uphi_sum(k)              #=> Σ_{m≤n} uphi_k(m)
n.nuphi_sum(k)             #=> Σ_{m≤n} nuphi_k(m)
n.iphi_sum(k)              #=> Σ_{m≤n} iphi_k(m)
n.sigma_sum(k)             #=> Σ_{m≤n} σ_k(m)
n.usigma_sum(k)            #=> Σ_{m≤n} usigma_k(m)
n.tau_sum                  #=> Σ_{k≤n} τ(k)     alias: sigma0_sum
n.dedekind_psi_sum(k)      #=> Σ_{m≤n} ψ_k(m)   alias: psi_sum
n.exp_mangoldt_sum         #=> integer Chebyshev ψ̃(n)
n.pillai_sum(k)            #=> Σ_{k≤n} pillai_k(m)
n.gpf_sum                  #=> Σ gpf(k)    (A088822)
n.lpf_sum                  #=> Σ lpf(k)
n.sopf_sum                 #=> Σ sopf(k)
n.sopfr_sum                #=> Σ sopfr(k)
n.bigomega_sum             #=> Σ Ω(k)
n.omega_sum                #=> Σ ω(k)
n.exp_bigomega_sum(base)   #=> Σ base^{Ω(k)}  (base=-1 gives liouville_sum)
n.exp_omega_sum(base)      #=> Σ base^{ω(k)}
sum_remainders(n, v)       #=> Σ_{k=1}^n (v mod k),  O(√v)

#── Integer sequences — counting ────────────────────────────────────────
prime_count(n)             #=> π(n)   aliases: primepi, count_primes
composite_count(n)         #=> number of composites ≤ n
semiprime_count(n)         #=> semiprimes ≤ n  = 2.almost_prime_count(n)
k.almost_prime_count(n)    #=> k-almost primes ≤ n
squarefree_count(n)        #=> squarefree integers ≤ n
squarefull_count(n)        #=> squarefull integers ≤ n
cubefree_count(n)          #=> cubefree integers ≤ n
cubefull_count(n)          #=> cubefull integers ≤ n
k.powerfree_count(n)       #=> k-powerfree integers ≤ n
k.powerful_count(n)        #=> k-powerful integers ≤ n
perfect_power_count(n)     #=> perfect powers ≤ n
prime_power_count(n)       #=> prime powers ≤ n
sphenic_count(n)           #=> sphenic numbers ≤ n
k.omega_prime_count(n)     #=> k-omega primes ≤ n
k.smooth_count(n)          #=> k-smooth integers ≤ n
k.rough_count(n)           #=> k-rough integers ≤ n

#── Integer sequences — nth element ─────────────────────────────────────
prime(n)                   #=> n-th prime   aliases: nth_prime
composite(n)               #=> n-th composite   alias: nth_composite
nth_squarefree(n)          #=> n-th squarefree number
nth_squarefull(n)          #=> n-th squarefull number
nth_cubefree(n)            #=> n-th cubefree number
nth_cubefull(n)            #=> n-th cubefull number
nth_powerfree(n, k=2)      #=> n-th k-powerfree number
nth_powerful(n, k=2)       #=> n-th k-powerful number
nth_nonsquarefree(n)       #=> n-th non-squarefree number
nth_noncubefree(n)         #=> n-th non-cubefree number
nth_nonpowerfree(n, k)     #=> n-th k-non-powerfree number
nth_almost_prime(n, k=2)   #=> n-th k-almost prime
nth_squarefree_almost_prime(n, k=2)  #=> n-th squarefree k-almost prime
nth_omega_prime(n, k=2)    #=> n-th k-omega prime
nth_sphenic(n)             #=> n-th sphenic number
nth_prime_power(n)         #=> n-th prime power
nth_perfect_power(n)       #=> n-th perfect power
nth_smooth(n, k)           #=> n-th k-smooth number
nth_rough(n, k)            #=> n-th k-rough number
nth_tau_inverse(n, k)      #=> n-th integer with exactly k divisors

#── Integer sequences — next/prev ───────────────────────────────────────
n.next_prime               # n.prev_prime
n.next_composite           # n.prev_composite
n.next_squarefree          # n.prev_squarefree
n.next_squarefull          # n.prev_squarefull
n.next_cubefree            # n.prev_cubefree
n.next_cubefull            # n.prev_cubefull
n.next_semiprime           # n.prev_semiprime
n.next_sphenic             # n.prev_sphenic
n.next_smooth(k)           # n.prev_smooth(k)
n.next_rough(k)            # n.prev_rough(k)
n.next_prime_power         # n.prev_prime_power
n.next_perfect_power       # n.prev_perfect_power
n.next_powerfree(k)        # n.prev_powerfree(k)
n.next_powerful(k)         # n.prev_powerful(k)
n.next_omega_prime(k)      # n.prev_omega_prime(k)

#── Continued fractions ─────────────────────────────────────────────────
n.sqrt_cfrac_period
n.sqrt_cfrac_period_len
n.convergents(k)
n.pisano_period
x.rat_approx(max_den)      #=> best p/q with q ≤ max_den
solve_pell(D)
solve_pell(D, k)

#── Combinatorics ───────────────────────────────────────────────────────
partitions(n)
strict_partitions(n)
multiplicative_partitions(n)
partition_count(n)
subfactorial(n, k)         #=> D(n,k) rencontres number  (k=0: derangements)
stirling(n, k)             #=> Stirling first kind
stirling2(n, k)            #=> Stirling second kind
stirling3(n, k)            #=> Lah numbers
multinomial(...)
```
