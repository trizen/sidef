# Advanced Number Theory with Sidef

A hands-on guide covering Sidef's integer and number-theoretic facilities through worked examples.

---

## Table of Contents

1. [Factorization and Prime Structure](#1-factorization-and-prime-structure)
2. [Divisor Functions](#2-divisor-functions)
3. [Euler's Totient and Variants](#3-eulers-totient-and-variants)
4. [Möbius Function and Multiplicative Structure](#4-möbius-function-and-multiplicative-structure)
5. [Prime Counting and Distribution](#5-prime-counting-and-distribution)
6. [Primality Testing](#6-primality-testing)
7. [Integer Factorization Algorithms](#7-integer-factorization-algorithms)
8. [Modular Arithmetic](#8-modular-arithmetic)
9. [Quadratic Residues and Congruences](#9-quadratic-residues-and-congruences)
10. [Dirichlet Convolution](#10-dirichlet-convolution)
11. [Arithmetic Derivative](#11-arithmetic-derivative)
12. [Continued Fractions and Pell's Equation](#12-continued-fractions-and-pells-equation)
13. [Sublinear Summation](#13-sublinear-summation)
14. [Integer Classifications and Sequences](#14-integer-classifications-and-sequences)
15. [Pseudoprimes and Carmichael Numbers](#15-pseudoprimes-and-carmichael-numbers)
16. [Special Arithmetic Functions](#16-special-arithmetic-functions)

---

## 1. Factorization and Prime Structure

### Complete Factorization

`factor(n)` returns the list of prime factors with repetition (sorted ascending).
`factor_exp(n)` returns `[p, e]` pairs.

```ruby
say(1000.factor())       #=> [2, 2, 2, 5, 5, 5]
say(1000.factor_exp())   #=> [[2, 3], [5, 3]]

# Large numbers work seamlessly:
var n = ((2**128) + 1)
say(n.factor())
#=> [3, 5, 17, 257, 641, 65537, 274177, 6700417, 67280421310721, ...]
```

An optional block can supply custom factorization methods. The block receives a
composite sub-factor and must return an array of (not necessarily prime) factors:

```ruby
say(factor((10**120) - (10**40), {|k| k.ecm_factor() }))
```

Iterate over `[p, e]` pairs with destructuring:

```ruby
for pair in (720.factor_exp()) {
    var (p, e) = pair...
    say("#{p}^#{e}")
}
#=> 2^4
#=> 3^2
#=> 5^1
```

`factor_map` and `factor_prod` / `factor_sum` apply a block to each `(p, e)` pair:

```ruby
say(5040.factor_map({ |p, e| p**e }))          #=> [16, 9, 5, 7]
say(5040.factor_prod({ |p, e| (p-1) * (p**(e-1)) }))  #=> 1152  (= φ(5040))
```

### Fundamental Invariants

```ruby
var n = 720   # 2^4 * 3^2 * 5

say(n.omega())       # ω(n) = 3   — number of distinct prime factors (A001221)
say(n.bigomega())    # Ω(n) = 7   — prime factors with multiplicity (A001222)
say(n.lpf())         # 2           — least prime factor
say(n.gpf())         # 5           — greatest prime factor
say(n.rad())         # 30 = 2*3*5  — radical, rad(n) = ∏_{p|n} p  (A007947)
say(n.core())        # 30          — squarefree part = n / (largest square divisor of n)  (A007913)
say(n.squarefree_part())    # same as core(n) = 30
say(n.squarefree_kernel())  # same as rad(n) = 30
```

`rad(n)` and `core(n)` coincide exactly when n is squarefree. In general:
`core(n) = n / square_part(n)` while `rad(n) = ∏_{p | n} p`.

```ruby
say(n.valuation(2))   # v_2(720) = 4
say(n.valuation(3))   # v_3(720) = 2
say(n.valuation(7))   # v_7(720) = 0

# Sopf and sopfr:
say(360.sopf())    # A008472: sum of *distinct* prime factors = 2+3+5 = 10
say(360.sopfr())   # A001414: Σ e*p over p^e || n  = 3·2 + 2·3 + 1·5 = 17

# Sublinear partial sums:
say((10**6).lpf_sum())    # Σ_{k=1}^{10^6} lpf(k)  (A088821)
say((10**6).gpf_sum())    # Σ_{k=1}^{10^6} gpf(k)  (A088822)
say((10**6).sopf_sum())   # Σ_{k=1}^{10^6} sopf(k) (A024924)
say((10**6).sopfr_sum())  # Σ_{k=1}^{10^6} sopfr(k)(A025281)
```

### Prime Signature

The prime signature is the sorted tuple of exponents `[e_1 ≥ e_2 ≥ ... ]`:

```ruby
say(720.prime_signature())           # [4, 2, 1]

# Count of integers with a given prime signature (A025487):
say(720.prime_signature_count())      # = prime_signature_inverse_len(1, ∞, [4,2,1])

# All integers in [1, 10000] sharing 720's signature shape:
say(prime_signature_inverse(1, 10000, [4, 2, 1]))
#=> [720, 1080, 1800, 2520, 3240, 4200, 5040, 7560, ...]
```

### Factorial Valuations

The p-adic valuation of n! is given by Legendre's formula
v_p(n!) = Σ_{k≥1} ⌊n/p^k⌋:

```ruby
say(100.factorial_power(5))    # v_5(100!) = ⌊100/5⌋ + ⌊100/25⌋ = 24
say(100.factorial_power(2))    # v_2(100!) = 97

# Is n! divisible by p^k?
say((50.factorial_power(3)) >= 10)   # is 3^10 | 50! ?
```

### Primorials and Consecutive LCM

```ruby
say(7.primorial())        # 2*3*5*7 = 210         (product of primes ≤ 7)
say(4.pn_primorial())     # product of first 4 primes = 2*3*5*7 = 210

# lcm(1, 2, ..., n):
say(10.consecutive_integer_lcm())   # = lcm(1..10) = 2520
```

---

## 2. Divisor Functions

### σ_k and τ

```ruby
var n = 360

say(n.sigma(0))   # τ(n) = 24   — number of divisors
say(n.sigma(1))   # σ(n) = 1170 — sum of divisors
say(n.sigma(2))   # σ_2(n) = sum of squares of divisors
say(n.sigma(-1))  # σ_{-1}(n) = sum of reciprocals (rational)

# Aliases:
say(n.sigma0())   # = tau(n) = sigma(0)
say(n.tau())      # same

# Divisor product identity: ∏_{d|n} d = n^{τ(n)/2}:
say(n.divisors_prod({ |d| d }))
say((n ** (n.tau() / 2)))

# Proper divisors and aliquot sum = σ(n) - n:
say(n.proper_divisors())
say(n.aliquot_sum())       # = proper_sigma(n) = σ(n) − n
```

### Divisor System Variants

Sidef implements σ and τ for six divisor systems:

| Functions | Type | Key property | OEIS |
|---|---|---|---|
| `sigma` / `sigma0` | Standard | all divisors | A000203 / A000005 |
| `usigma` / `usigma0` | Unitary | gcd(d, n/d) = 1 | A034448 / A034444 |
| `bsigma` / `bsigma0` | Bi-unitary | gcud(d, n/d) = 1 | A188999 / A286324 |
| `isigma` / `isigma0` | Infinitary | d is an infinitary divisor | A049417 / A037445 |
| `esigma` / `esigma0` | Exponential | d is an e-divisor | A051377 / A049419 |

```ruby
var n = 36   # 2^2 * 3^2

say(n.sigma())      # 91
say(n.usigma())     # 1 + 4 + 9 + 36 = 50  (unitary divisors: gcd(d, 36/d) = 1)
say(n.bsigma())     # bi-unitary sigma
say(n.isigma())     # infinitary sigma
say(n.esigma())     # exponential sigma: d = ∏ p^{b_i} where b_i | e_i for each p^{e_i} || n

# Corresponding divisor lists:
say(n.udivisors())
say(n.bdivisors())   # bi-unitary divisors (aliases: biudivisors, bi_unitary_divisors)
say(n.idivisors())   # infinitary divisors
say(n.edivisors())   # exponential divisors
```

A **unitary divisor** d | n has gcd(d, n/d) = 1, which forces each prime to appear
entirely in d or entirely in n/d. For a prime power p^a, the unitary divisors are 1
and p^a. The **exponential divisors** of n = ∏ p_i^{e_i} are products ∏ p_i^{b_i}
where b_i | e_i for each i.

```ruby
# Non-standard complements (what the standard misses vs each system):
say(36.nusigma())   # A048146: sum of non-unitary divisors
say(36.nbsigma())   # A319072: sum of non-bi-unitary divisors
say(36.nesigma())   # A160135: sum of non-exponential divisors
say(36.nisigma())   # A348271: sum of non-infinitary divisors
```

### Divisor Subsets

```ruby
var n = 120

say(n.squarefree_divisors())      # divisors d with μ(d) ≠ 0
say(n.cubefree_divisors())
say(n.prime_divisors())           # = unique prime factors
say(n.prime_power_divisors())     # prime-power divisors p^k (k≥1)
say(n.perfect_power_divisors())   # divisors that are perfect powers
say(n.smooth_divisors(5))         # 5-smooth divisors of 120
say(n.rough_divisors(5))          # divisors d with all prime factors ≥ 5
say(n.square_divisors())          # divisors that are perfect squares
say(n.cube_divisors())            # divisors that are perfect cubes

# Iterate and map:
var prime_div_sum = n.divisors_map({ |d| d.is_prime() ? d : 0 }).sum()
say(prime_div_sum)   # sum of prime divisors of 120 = 2+3+5 = 10
```

The `divisors_each`, `divisors_map`, `divisors_sum`, and `divisors_prod` methods
iterate lazily or reduce over the divisors of n:

```ruby
say(5040.divisors_sum({ |d| d.euler_phi()**2 }))  #=> 2217854
```

### Antidivisors

The **antidivisors** of n (A066272) are integers d > 1 for which 2n mod d ∈ {1, d−1}:

```ruby
say(14.antidivisors())       # [3, 4, 9]
say(14.antidivisor_count())  # 3
say(14.antidivisor_sigma())  # A066417: sum = 3+4+9 = 16
```

### Perfect, Abundant, Deficient

```ruby
say(6.is_perfect())      # σ(6) = 12 = 2*6  ✓
say(12.is_abundant())    # σ(12) = 28 > 24   ✓
say(8.is_deficient())    # σ(8)  = 15 < 16   ✓

say(12.abundancy_index())       # σ(n)/n = 7/3  (as an exact rational)

say(20.is_primitive_abundant()) # abundant, but no proper divisor is abundant
say(12.is_practical())          # every m ≤ σ(12) is a sum of distinct divisors of 12
```

---

## 3. Euler's Totient and Variants

### φ(n) and Its Partial Sum

```ruby
say(36.euler_phi())     # φ(36) = 12

# Multiplicativity when gcd(m,n) = 1:
var m = 9
var n = 16
say(((m * n).euler_phi() == (m.euler_phi() * n.euler_phi())))  # true

# Partial sum Σ_{k=1}^n φ(k) in O(n^{1/2}) via hyperbola (A002088):
say((10**9).totient_sum())
```

### Inverse Totient

```ruby
# All n with φ(n) = 24:
say(24.phi_inverse())            # alias: inverse_euler_phi

say(24.phi_inverse_len())        # count of preimages
say(24.phi_inverse_min())        # smallest n: = 25
say(24.phi_inverse_max())        # largest n

# Nontotient: integers not in the image of φ
# (all odd integers > 1 are nontotients; some even ones too)
say(14.phi_inverse_len() == 0)   # 14 is a nontotient  => true
say(14.is_totient())             # false
```

### Carmichael's λ

λ(n) is the exponent of (ℤ/nℤ)*, i.e., the maximum order of any element.
It equals lcm of λ(p^k) over prime power factors.

```ruby
say(12.carmichael_lambda())   # λ(12) = 2
say(15.carmichael_lambda())   # λ(15) = 4

# λ(n) | φ(n), with equality iff n has a primitive root:
say((7.carmichael_lambda() == 7.euler_phi()))    # true — primes always have primitive roots
say((12.carmichael_lambda() == 12.euler_phi()))  # false — (ℤ/12ℤ)* ≅ ℤ/2 × ℤ/2

# For a prime p, λ(p^k) = φ(p^k) = p^{k-1}(p-1)
# For p=2: λ(2) = 1, λ(4) = 2, λ(2^k) = 2^{k-2} for k ≥ 3
say((8.carmichael_lambda()))   # 2 = λ(8) = 2^{3-2}
```

### Jordan's Totient J_k(n)

J_k(n) = n^k ∏_{p|n} (1 − p^{-k}). For k=1 this is φ(n).

```ruby
say(12.jordan_totient(1))   # = φ(12) = 4
say(12.jordan_totient(2))   # J_2(12) = 12^2 * (1 - 1/4) * (1 - 1/9) = 96
say(12.jordan_totient(3))

# Sublinear partial sum Σ_{m=1}^n J_k(m):
say((10**6).jordan_totient_sum(2))

# Identities:
# Σ_{d|n} J_k(d) = n^k   and   J_1 = φ
var n = 60
say((n.divisors().map({ |d| d.jordan_totient(2) }).sum() == (n**2)))   # true
```

### Dedekind's ψ

ψ(n) = n ∏_{p|n} (1 + p^{-1}). Compare with φ(n) = n ∏_{p|n} (1 − p^{-1}).

```ruby
say(12.dedekind_psi())    # ψ(12) = 12 * (1+1/2) * (1+1/3) = 24

# Identity: ψ(n) = Σ_{d|n} |μ(d)| * d   (Dirichlet convolution of |μ| and id)
say((10**6).dedekind_psi_sum())   # Σ_{k=1}^{10^6} ψ(k) — sublinear

say(24.psi_inverse())            # all x with ψ(x) = 24
say(24.psi_inverse_len())        # count
say(24.psi_inverse_min())        # smallest solution
say(24.psi_inverse_max())        # largest solution
```

### Unitary, Bi-Unitary, and Infinitary Totients

Each divisor system has its own analog of Euler's phi:

```ruby
say(12.uphi())    # A047994: unitary totient = ∏_{p^a || n} (p^a − 1)
say(12.bphi())    # A116550: bi-unitary totient
say(12.iphi())    # A091732: infinitary totient
say(12.nuphi())   # A254503: non-unitary totient = φ(n) − uphi(n)

say(12.uphi_inverse())   # all x with uphi(x) = 12
```

---

## 4. Möbius Function and Multiplicative Structure

### μ(n) and Mertens M(n)

```ruby
say(1.moebius())    #  1  — μ(1) = 1 by convention
say(6.moebius())    #  1  — μ(2·3) = (−1)^2 = 1
say(30.moebius())   # -1  — μ(2·3·5) = (−1)^3 = −1
say(4.moebius())    #  0  — 4 = 2^2 is not squarefree

# Batch computation over a range:
say(moebius_range(7, 17))   #=> [-1, 0, 0, 1, -1, 0, -1, 1, 1, 0, -1]

# Mertens function M(n) = Σ_{k=1}^n μ(k) — O(n^{2/3}) algorithm:
for e in (1..9) {
    say("M(10^#{e}) = #{(10**e).mertens()}")
}
```

### Liouville's λ(n)

λ(n) = (−1)^{Ω(n)} where Ω(n) is the number of prime factors with multiplicity.

```ruby
say(12.liouville())   # λ(12) = λ(2^2·3) = (−1)^3 = −1
say(15.liouville())   # λ(15) = λ(3·5)   = (−1)^2 =  1

# Liouville sum L(n) = Σ λ(k) — also computable as exp_bigomega_sum(n, -1):
say((10**9).liouville_sum())

# Pólya's conjecture (that L(n) ≤ 0 for n ≥ 2) is FALSE.
# The first counterexample is n = 906180359:
say(906150257.liouville_sum())   # still negative here
say(906180359.liouville_sum())   #=> 1  (first n with L(n) > 0)
```

### Mangoldt's Λ(n)

Λ(n) = log p if n = p^k, else 0. The integer version is `exp_mangoldt(n)` = p if n = p^k, else 1.

```ruby
say(8.exp_mangoldt())    # 2   — 8 = 2^3
say(9.exp_mangoldt())    # 3   — 9 = 3^2
say(12.exp_mangoldt())   # 1   — 12 is not a prime power
say(7.exp_mangoldt())    # 7   — 7 is prime

# Integer Chebyshev ψ̃(n) = Σ_{k≤n} exp_mangoldt(k):
say((1000).exp_mangoldt_sum())    # A072107
```

### Pillai's Function

f(n) = Σ_{k=1}^n gcd(k, n) — the "Pillai sum" or "gcd sum for n":

```ruby
say(12.pillai())       # A018804(12) = 40
# Identity: pillai(n) = Σ_{d|n} φ(d)·(n/d)
var check = 12.divisors().map({ |d| (d.euler_phi() * (12/d)) }).sum()
say(check)   # = 40

say((1000).pillai_sum())  # Σ_{k=1}^{1000} pillai(k)
```

### Ramanujan's Sum

c_q(n) = Σ_{k=1, gcd(k,q)=1}^q e^{2πikn/q} — a purely integer-valued function:

```ruby
say(5.ramanujan_sum(1))   # c_5(1) = μ(5) = −1
say(5.ramanujan_sum(5))   # c_5(5) = φ(5) = 4
say(12.ramanujan_sum(4))

# Identity: c_q(n) = μ(q/gcd(q,n)) · φ(q) / φ(q/gcd(q,n))
var q = 12
var n = 8
var g = q.gcd(n)
var computed = ((q/g).moebius() * q.euler_phi()) / (q/g).euler_phi()
say((computed == q.ramanujan_sum(n)))   # true
```

### Verifying Multiplicative Identities

```ruby
# φ = μ * id  via Dirichlet convolution:
var n = 360
say(n.divisors().map({ |d| (d.moebius() * (n/d)) }).sum())   # = φ(360)
say(n.euler_phi())

# n = Σ_{d|n} φ(d):
say(n.divisors().map({ |d| d.euler_phi() }).sum())   # = 360
```

---

## 5. Prime Counting and Distribution

### π(n) — Exact and Approximate

```ruby
say((10**6).prime_count())    # π(10^6) = 78498 — exact, sublinear

# Bounds satisfying prime_count_lower ≤ π(n) ≤ prime_count_upper:
say((10**9).prime_count_lower())
say((10**9).prime_count_upper())

# Range count π(b) − π(a−1):
say((10**6).prime_count(2 * (10**6)))   # π(2×10^6) − π(10^6)

# Also exposed as primepi / count_primes:
say(primepi(10**12))    #=> 37607912018
```

### Legendre's ϕ(n, k)

`legendre_phi(n, k)` counts integers in [1, n] not divisible by any of the first k primes.
It is the core of several prime counting algorithms:

```ruby
say(100.legendre_phi(4))    # integers ≤ 100 coprime to 2·3·5·7

# Legendre's formula: π(n) = legendre_phi(n, π(√n)) + π(√n) − 1
var sqn = (100.isqrt())
say((100.legendre_phi(sqn.prime_count()) + sqn.prime_count() - 1))
say(100.prime_count())

# Equivalent: prime(k+1).rough_count(n)
say((7).rough_count(100))   # same as legendre_phi(100, 4)
```

### nth Prime and Bounds

```ruby
say(100.nth_prime())          # p_{100} = 541
say(100.nth_prime_lower())    # lower bound on p_{100}
say(100.nth_prime_upper())    # upper bound
```

### Prime Sum

Sidef computes Σ_{p ≤ n} p in sublinear time:

```ruby
say((10**9).prime_sum())

# Verify PNT via prime sum: Σ p / (n^2 / (2 log n)) → 1:
var n = (10**6)
say((n.prime_sum()) / ((n**2) / (2 * n.log())))   # approaches 1
```

### Almost-Prime Counting π_k(n)

```ruby
# k-almost primes: Ω(n) = k
say(100.almost_prime_count(1))   # = prime_count(100)
say(100.almost_prime_count(2))   # = semiprime_count(100)
say(100.almost_prime_count(3))   # 3-almost primes ≤ 100

say(100.semiprime_count())
say(100.pi_k(2))                 # alias for almost_prime_count(2)
```

### Checking Prime Distribution

```ruby
# Verify that π(2n)/π(n) → 2 (consequence of PNT):
for e in (2..7) {
    var n = (10**e)
    var ratio = ((2*n).prime_count() / n.prime_count())
    say("π(2·10^#{e})/π(10^#{e}) = #{ratio.as_float()}")
}
```

---

## 6. Primality Testing

### Deterministic Tests

```ruby
say(((2**31) - 1).is_prime())    # true — M_31, a Mersenne prime
say(((2**67) - 1).is_prime())    # false — composite (Cole 1903)
say(((2**127) - 1).is_prime())   # true — M_127

# For Mersenne numbers, the dedicated Lucas-Lehmer test is available:
say(31.is_mersenne_prime())   # true  (2^31 - 1 is prime)
say(67.is_mersenne_prime())   # false (2^67 - 1 is composite)

# BPSW — no known pseudoprimes; deterministic for n < 3.3×10^24:
say(n.is_bpsw_prime())

# Provable primality via ECPP (for arbitrary large primes):
say(n.is_ecpp_prime())
say(n.is_prov_prime())   # alias: is_provable_prime

# AKS — polynomial time, unconditional, but slower in practice:
say(101.is_aks_prime())

# N−1 and N+1 primality proofs (when factorization of N±1 is known):
say(((2**31) - 1).is_nminus1_prime())   # alias: is_nm1_prime, is_pm1_prime
say(((2**61) - 1).is_nplus1_prime())    # alias: is_np1_prime, is_pp1_prime
```

### BPSW in Detail

BPSW combines a strong Miller-Rabin test (base 2) with a strong Lucas test.
No composite is known to pass both:

```ruby
say(n.is_strong_psp(2))               # MR base 2 (alias: is_strong_fermat_pseudoprime)
say(n.is_strong_lucas_psp())           # Lucas (Selfridge parameters)
say(n.is_bpsw_prime())                 # both combined

# Extra-strong Lucas (slightly stronger, slightly faster):
say(n.is_extra_strong_lucas_psp())     # alias: is_stronger_lucas_psp

# BFW / VPSP variant:
say(n.is_bfsw_psp())                   # V_{n+1} ≡ 2Q (mod n) — no known failures
say(n.is_vpsp())                       # same test, different alias
```

### Miller-Rabin

```ruby
# k rounds with random bases:
say(n.miller_rabin_random(20))

# Specific bases — deterministically covers certain ranges:
# {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37} covers n < 3.3×10^24:
for a in ([2, 3, 5, 7, 11, 13]) {
    say(n.is_strong_psp(a))
}
```

### Special Prime Families

```ruby
# Safe prime: p and (p-1)/2 are both prime
say(23.is_safe_prime())    # (23-1)/2 = 11 is prime ✓

# Proth prime: n = k·2^m + 1 with k < 2^m and k odd
say(97.is_proth_prime(3))  # 97 = 3·2^5 + 1 ✓  (the method takes k as argument)

# Balanced prime: p is the arithmetic mean of its neighbors
say(5.is_balanced_prime())   # (3+7)/2 = 5 ✓
say(53.is_balanced_prime())  # (47+59)/2 = 53 ✓

# Sophie Germain prime: p and 2p+1 both prime
say(11.is_sophie_germain())   # 2*11+1 = 23 is prime ✓

# Twin prime: p and p+2 both prime
say(11.is_twin_prime())       # 11+2 = 13 is prime ✓

# Emirp: prime whose digit-reversal is a different prime
say(13.is_emirp())   # rev(13) = 31, also prime ✓
```

---

## 7. Integer Factorization Algorithms

Sidef exposes each algorithm individually, allowing you to choose based on the
structure of the number.

### Trial Division

Useful for extracting small factors before applying heavier methods:

```ruby
var n = (17 * 19 * 100003)
say(n.trial_factor(200))    # trial divide up to 200 → finds 17 and 19
```

### Fermat's Method

Best when the two factors are close together (n = a² − b² with a − b small):

```ruby
var n = (1000003 * 1000033)
say(n.fermat_factor())    # fast since factors differ by 30
```

### Pollard's Rho and Brent's Variant

General-purpose for factors up to ~20 digits:

```ruby
var n = ((2**64) + 1)
say(n.rho_factor())          # Pollard's rho  (alias: prho_factor)
say(n.rho_brent_factor())    # Brent's improvement — often faster (alias: pbrent_factor)

say(n.rho_factor(100000))    # explicit max iterations
```

### p − 1 and p + 1 Methods

Effective when p − 1 (or p + 1) is B-smooth for moderate B:

```ruby
# p-1 method (Pollard): exploits Fermat's little theorem
# Works when p-1 is smooth
say(n.pm1_factor(100000))   # alias: pminus1_factor

# p+1 method (Williams): exploits Lucas sequences
# Works when p+1 is smooth
say(n.pp1_factor(100000))   # alias: pplus1_factor
```

### Elliptic Curve Method (ECM)

The method of choice for finding factors of 20–60 digits:

```ruby
var n = ((2**128) + 1)
say(n.ecm_factor())
say(n.ecm_factor(2000, 200000))   # B1=2000, curves=200000
```

### Quadratic Sieve and SQUFOF

```ruby
var n = ((10**25) + 7)

say(n.squfof_factor())    # SQUFOF — very fast for 20–30 digit numbers
say(n.qs_factor())        # Full quadratic sieve for larger numbers
```

### Algebraic and Special Factorizations

```ruby
# Cyclotomic factorization — exploits algebraic structure:
say(((2**12) - 1).cyclotomic_factor())   # factors via Φ_d(2)

# Difference-of-powers and Congruence-of-powers:
say(n.dop_factor())    # x^n - y^n type
say(n.cop_factor())    # cofactor-based

# Chebyshev polynomial factoring:
say(n.chebyshev_factor())

# Fibonacci / Lucas factoring (for numbers with recurrence structure):
say(n.fibonacci_factor())
say(n.lucas_factor())

# FLT-inspired factoring (effective when znorder(base, p) is small):
say(n.flt_factor(2, 1000000))   # base=2, up to 10^6 iterations

# MBE (Modular Binary Exponentiation) factoring:
say(n.mbe_factor(10))           # effective when p-1 is smooth

# Sophie Germain identity: x^4 + 4y^4 = (x^2-2xy+2y^2)(x^2+2xy+2y^2)
say(n.germain_factor())

# GCD-based factoring given auxiliary integers:
say(n.gcd_factors([19*43*97, 1, 13*41*43*101]))
```

### Building a Factorization Pipeline

```ruby
func full_factor(n) {
    n.is_prime() && return([n])
    # Try cheap methods first:
    var d = (n.trial_factor(1000).first() \\ n.rho_brent_factor() \\ n.ecm_factor())
    d || return([n])
    return([full_factor(d)..., full_factor(n / d)...].sort())
}

say(full_factor((2**128) + 1))
```

---

## 8. Modular Arithmetic

### Basics

```ruby
say((2).powmod(1000, 1000000007))   # 2^1000 mod 10^9+7
say((17).invmod(100))               # 17^{-1} mod 100 = 53

# Verify: 17 * 53 ≡ 1 (mod 100):
say(((17 * 53) % 100))   # 1

# Extended Euclidean: returns (g, x, y) with g = gcd(a,b) = ax + by
var (g, x, y) = (35.gcdext(15))...
say("gcd = #{g},  x = #{x},  y = #{y}")
say((g == ((35 * x) + (15 * y))))   # true

# Modular arithmetic helpers:
say(addmod(43, 97, 127))        # (43+97) % 127
say(mulmod(43, 97, 127))        # (43*97) % 127
say(submod(43, 97, 127))        # (43-97) % 127
say(divmod(43, 97, 127))        # (43 * invmod(97, 127)) % 127
say(powmod(2, 42, 43))          # 1
```

### Multiplicative Order

ord_n(a) = smallest k > 0 with a^k ≡ 1 (mod n), requiring gcd(a, n) = 1:

```ruby
say((2).znorder(13))    # 12 — 2 is a primitive root mod 13
say((2).znorder(15))    # 4
say((3).znorder(7))     # 6 — ord_7(3) = 6, so 3 is a primitive root mod 7

# Primitive root (smallest):
say(13.znprimroot())   # 2
say(7.znprimroot())    # 3

# Check whether a given element is a primitive root:
say((2).is_primitive_root(13))   # true

# n has a primitive root iff n ∈ {1, 2, 4, p^k, 2p^k} for odd prime p:
say(13.is_cyclic())    # true
say(12.is_cyclic())    # false — (ℤ/12ℤ)* ≅ ℤ/2 × ℤ/2
```

### Discrete Logarithm

```ruby
# znlog(a, g, n): find k with g^k ≡ a (mod n) via baby-step giant-step
say((3).znlog(2, 13))    # 4  — since 2^4 = 16 ≡ 3 (mod 13)
say((5).znlog(3, 7))     # 5  — since 3^5 = 243 ≡ 5 (mod 7)

# Verify:
var k = (3).znlog(2, 13)
say(((2).powmod(k, 13) == 3))   # true
```

### Linear Congruences

ax ≡ b (mod m) is solvable iff gcd(a, m) | b. When solvable, there are gcd(a,m) solutions mod m:

```ruby
say(7.solve_linear_congruence(5, 12))    # 7x ≡ 5 (mod 12) — returns solutions
say(6.solve_linear_congruence(4, 10))    # 6x ≡ 4 (mod 10): gcd(6,10)=2|4 → 2 solutions

# Also exposed as solve_lcg / linear_congruence:
say(linear_congruence(3, 12, 15))    #=> [4, 9, 14]

# Manual CRT via gcdext:
func crt(r1, m1, r2, m2) {
    var (g, u, v) = (m1.gcdext(m2))...
    (((r2 - r1) % g) != 0) && return(nil)
    var lcm = ((m1 * m2) / g)
    return((r1 + (m1 * u * ((r2 - r1) / g))) % lcm)
}
say(crt(2, 3, 3, 5))   # x ≡ 2 (mod 3), x ≡ 3 (mod 5)  =>  x ≡ 8 (mod 15)
say(crt(1, 4, 3, 7))   # x ≡ 1 (mod 4), x ≡ 3 (mod 7)  =>  x ≡ 17 (mod 28)
```

### Generalized Modular Roots

```ruby
# rootmod(a, k, n): a k-th root of a modulo n
say((8).rootmod(3, 13))        # x with x^3 ≡ 8 (mod 13)
say((1).rootmod(4, 17))        # a 4th root of 1 mod 17

# All k-th roots:
say((1).rootmod_all(4, 17))    # all 4th roots of unity mod 17
say(17.roots_of_unity(4))      # complex 4th roots of 1 (floating-point)

# Chebyshev polynomial evaluation modulo m:
say((3).chebyshevTmod(10, 101))   # T_{10}(3) mod 101
say((3).chebyshevUmod(10, 101))   # U_{10}(3) mod 101
```

---

## 9. Quadratic Residues and Congruences

### Symbol Functions

```ruby
# Legendre symbol (a/p) for odd prime p:
say((3).legendre(11))    #  1  — 3 is a QR mod 11 (x^2 ≡ 3 has solutions)
say((2).legendre(7))     #  1  — 2 is a QR mod 7
say((3).legendre(7))     # -1  — 3 is a QNR mod 7

# Jacobi symbol (a/n) — generalization to odd n, not a QR criterion:
say((7).jacobi(15))      # (7/15) = (7/3)(7/5) = (1/3)(2/5) = 1·(−1) = −1
say((2).jacobi(9))       # 1  — but 2 is NOT a QR mod 9

# Kronecker symbol — further extends to even n and n < 0:
say((2).kronecker(-1))   # 1  — the Kronecker extension
say((5).kronecker(8))
say((-1).kronecker(5))   # (−1/5) = (−1)^{(5−1)/2} = 1
```

The Jacobi symbol (a/n) = 1 does **not** imply a is a QR mod n (only the Legendre
symbol at a prime guarantees that). This is exploited by the Euler pseudoprime test.

### Quadratic Residuosity

```ruby
# Smallest QNR mod p:
say(13.quadratic_nonresidue())    # 2

# Tonelli-Shanks: square root mod p
say((3).sqrtmod(11))              # x with x^2 ≡ 3 (mod 11) => 5 (since 5^2 = 25 ≡ 3)

# All square roots (including composite moduli via CRT):
say((1).sqrtmod_all(8))     # [1, 3, 5, 7] — odd squares ≡ 1 (mod 8)
say((4).sqrtmod_all(15))    # x^2 ≡ 4 (mod 15): solutions via CRT mod 3 and mod 5
```

### Quadratic Reciprocity in Practice

```ruby
# Verify QR for p ≡ 1 (mod 4): −1 is a QR
for p in (primes(5, 50)) {
    if ((p % 4) == 1) {
        say("(−1/#{p}) = #{(-1).legendre(p)}")   # always 1
    }
}

# 2 is a QR mod p iff p ≡ ±1 (mod 8):
for p in (primes(3, 50)) {
    var sym = (2).legendre(p)
    var expected = (((p % 8) == 1) || ((p % 8) == 7)) ? 1 : -1
    say("(2/#{p}) = #{sym} (expected #{expected}): #{sym == expected}")
}
```

### Quadratic Congruences

```ruby
# Solve ax^2 + bx + c ≡ 0 (mod m)  via quadratic_congruence / modular_quadratic_formula:
say(quadratic_congruence(1, 0, -3, 11))   # x^2 ≡ 3 (mod 11): solutions [5, 6]
say(quadratic_congruence(3, 4, 5, 124))   #=> [47, 55, 109, 117]

# Integer quadratic formula — integer solutions of ax^2 + bx + c = 0:
say(iquadratic_formula(1, -5, 6))    # x^2 - 5x + 6 = 0  =>  [2, 3]
```

### Cornacchia's Algorithm

Express a prime p as x^2 + d·y^2 (when the form represents p):

```ruby
say(29.cornacchia(1))    # [5, 2]: 5^2 + 1·2^2 = 29
say(13.cornacchia(1))    # [3, 2]: 3^2 + 1·2^2 = 13

# Also available as solve_quadratic_form(d, n):
say(solve_quadratic_form(1, 29))   # same — returns [[2, 5]] or [[5, 2]]

# Sum of squares representation counts r_k(n):
say(325.sum_of_squares_count(2))   # r_2(325): ways to write 325 = x^2+y^2  (alias: squares_r)
say(7.sum_of_squares_count(4))     # r_4(7): Lagrange — always > 0
say(99025.sum_of_squares())        # one explicit representation (all reps via sum_of_squares)
```

---

## 10. Dirichlet Convolution

### Definition and Built-in

(f * g)(n) = Σ_{d|n} f(d) g(n/d) for arithmetic functions f, g.
Use `n.dconv(f, g)` (alias `dirichlet_convolution`):

```ruby
var n = 12

# sigma = id * 1:
say(n.dconv({ |d| d }, { |d| 1 }))     # = sigma(12) = 28

# tau = 1 * 1:
say(n.dconv({ |d| 1 }, { |d| 1 }))     # = tau(12) = 6

# phi = mu * id  (Möbius inversion of n = Σ_{d|n} φ(d)):
say(n.dconv({ |d| d.moebius() }, { |d| d }))  # = euler_phi(12) = 4

# id = phi * 1  (the fundamental identity):
say(n.dconv({ |d| d.euler_phi() }, { |d| 1 }))  # = 12
```

### Möbius Inversion

If g = f * 1 (i.e., g(n) = Σ_{d|n} f(d)), then f = g * μ:

```ruby
var n = 60

# σ = id * 1, so id = σ * μ:
say(n.dconv({ |d| d.sigma() }, { |d| d.moebius() }))  # = 60 = n ✓

# τ = 1 * 1, so 1 = τ * μ:
say(n.dconv({ |d| d.tau() }, { |d| d.moebius() }))    # = 1 ✓

# ψ = |μ| * id  (Dedekind psi as a convolution):
say(n.dconv({ |d| d.moebius().abs() }, { |d| d }))    # = psi(n)
say(n.dedekind_psi())
```

### The Dirichlet Hyperbola Method

Computes Σ_{n≤x} (f*g)(n) in O(x^{1/2}) when partial sums of f and g are available.
Use `n.dirichlet_sum(f, g, F, G)` (alias `dirichlet_hyperbola`):

```ruby
# Σ_{k≤n} τ(k) — the Dirichlet divisor problem
var n = 10**6
say(n.dirichlet_sum({ |k| 1 }, { |k| 1 }, { |k| k }, { |k| k }))
say(n.tau_sum())   # built-in, same value

# Σ_{k≤n} σ(k):
say(n.dirichlet_sum({ |k| k }, { |k| 1 }, { |k| (k*(k+1))/2 }, { |k| k }))
say(n.sigma_sum())   # same
```

### Convolution with Built-in Functions

```ruby
# Ramanujan's identity: c_q(n) = Σ_{d | gcd(n,q)} μ(q/d) * d
var q = 12
var n_val = 8
say(q.divisors().map({ |d|
    (q.gcd(n_val) % d == 0) ? ((q/d).moebius() * d) : 0
}).sum())
say(q.ramanujan_sum(n_val))   # should match
```

---

## 11. Arithmetic Derivative

The arithmetic derivative n' is the unique map ℤ → ℤ satisfying:
- 1' = 0
- p' = 1 for all primes p
- (ab)' = a'b + ab' (Leibniz rule)

For n = ∏ p_i^{e_i}: n' = n · Σ_{p^e || n} e/p

```ruby
say(1.arithmetic_derivative())     # 0
say(2.arithmetic_derivative())     # 1
say(4.arithmetic_derivative())     # (2^2)' = 2·2^{2-1} = 4
say(6.arithmetic_derivative())     # (2·3)' = 1·3 + 2·1 = 5
say(12.arithmetic_derivative())    # 12 · (2/2 + 1/3) = 12 · (4/3) = 16

# Verify product rule:
for pair in ([[6, 10], [12, 35], [15, 28]]) {
    var (a, b) = pair...
    var lhs = (a * b).arithmetic_derivative()
    var rhs = ((a.arithmetic_derivative() * b) + (a * b.arithmetic_derivative()))
    say("(#{a}·#{b})' = #{lhs}, rule gives #{rhs}: #{lhs == rhs}")
}

# Higher iterates:
var n = 360
say(n.arithmetic_derivative())
say(n.arithmetic_derivative().arithmetic_derivative())
```

### Logarithmic Derivative

n'/n = Σ_{p^e || n} e/p — a rational number:

```ruby
say(360.logarithmic_derivative())   # 360'/360 as exact fraction
# 360 = 2^3 * 3^2 * 5, so 360'/360 = 3/2 + 2/3 + 1/5 = 61/30
say(360.arithmetic_derivative() / 360)   # same as rational
```

### Fixed Points and "Arithmetic Primes"

```ruby
# n' = n iff n = p^p for a prime p:
say(4.arithmetic_derivative() == 4)    # true (2^2: (2^2)' = 2·2 = 4)
say(27.arithmetic_derivative() == 27)  # true (3^3: (3^3)' = 3·9 = 27)

# "Arithmetic primes": n with n' = 1 are exactly the rational primes:
for n in (1..20) {
    if (n.arithmetic_derivative() == 1) {
        say("#{n}' = 1  (#{n} is prime)")
    }
}
```

---

## 12. Continued Fractions and Pell's Equation

### Continued Fraction Expansion of √D

```ruby
say(7.sqrt_cfrac())             # initial partial quotients of √7  [2, 1, 1, 1, 4, ...]
say(7.sqrt_cfrac_period())      # periodic part [1, 1, 1, 4]
say(7.sqrt_cfrac_period_len())  # period length = 4

say(61.sqrt_cfrac_period_len()) # 61 has period 11 — the largest period for D < 100

# Period length parity determines the form of Pell solutions:
# If period length is even, the fundamental solution of x^2 - Dy^2 = 1
# is the (period_len)-th convergent. If odd, it's the (2*period_len)-th.
for d in (2..20) {
    d.is_power() && next   # skip perfect squares
    say("D=#{d}: period=#{d.sqrt_cfrac_period_len()}")
}
```

### Convergents

The convergents p_k/q_k of √D satisfy |√D − p_k/q_k| < 1/q_k^2 (Dirichlet's theorem):

```ruby
say(7.convergents(8))    # first 8 convergents of √7
# [[2,1],[3,1],[5,2],[8,3],[11,4],[19,7],[30,11],[49,18]]
# Note: 8^2 - 7·3^2 = 1  ✓ (fundamental solution of x^2 - 7y^2 = 1)

# Best rational approximation to π with denominator ≤ 1000:
say(Math::PI.rat_approx(1000).as_frac())    # 355/113
```

### Pell's Equation x² − Dy² = 1

The fundamental solution comes from the convergents of √D:

```ruby
say(solve_pell(2))    # [3, 2]:  3^2 − 2·2^2 = 1
say(solve_pell(7))    # [8, 3]:  8^2 − 7·3^2 = 1
say(solve_pell(61))   # [1766319049, 226153980]

# solve_pell also accepts a second argument k for x^2 - D*y^2 = k:
say(solve_pell(953, -1))   # solution to x^2 - 953*y^2 = -1

# Verify:
var (x0, y0) = solve_pell(7)...
say(((x0**2) - (7 * (y0**2))))   # 1 ✓

# Generate further solutions via the composition law:
# (x_n + y_n√D) = (x_0 + y_0√D)^n
var (x, y) = (x0, y0)
for k in (1..5) {
    say("Solution #{k}: x=#{x}, y=#{y},  x^2-7y^2=#{((x**2)-(7*(y**2)))}")
    (x, y) = (((x0*x) + (7*(y0*y))), ((y0*x) + (x0*y)))
}
```

### Best Rational Approximations

```ruby
# Neighbors in the Farey sequence F_n:
say([farey_neighbors(5, 2/5)])    # neighbors of 2/5 in F_5

# Convergents are best rational approximations to any real number:
say(Math::PI.convergents(5))   #=> [3, 22/7, 333/106, 355/113, 103993/33102]

# Full Farey sequence of order n:
say(5.farey())   #=> [0, 1/5, 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 1]
```

### Pisano Periods and Lucas Sequences

The Pisano period π(m) is the period of F_n mod m:

```ruby
say(10.pisano_period())    # π(10) = 60
say(7.pisano_period())     # π(7) = 16

# For prime p:
# p ≡ ±1 (mod 5) => π(p) | p−1
# p ≡ ±2 (mod 5) => π(p) | 2(p+1)
for p in (primes(3, 50)) {
    say("π(#{p}) = #{p.pisano_period()},  p ≡ #{p % 5} (mod 5)")
}

# Lucas sequences U_n(P,Q) and V_n(P,Q) — the general Pell-family:
say(lucasU(1, -1, 10))   # U_{10}(1,-1) = F_{10} = 55
say(lucasV(1, -1, 10))   # V_{10}(1,-1) = L_{10} = 123

# Fast modular evaluation for large index:
say(lucasUmod(1, -1, (10**18), ((10**9) + 7)))
say(fibmod((10**18), ((10**9) + 7)))
```

---

## 13. Sublinear Summation

All functions in this section run in O(n^{1/2}) or O(n^{2/3}) time.

### Divisor Function Sums

```ruby
# Σ_{k=1}^n τ(k) — the Dirichlet divisor problem:
say((10**9).tau_sum())      # ~ n log n + (2γ-1)n   (alias: sigma0_sum)

# Σ_{k=1}^n σ(k):
say((10**9).sigma_sum())    # ~ (π^2/12) n^2

# sigma_sum also accepts k and j arguments:
say((10**6).sigma_sum(2))          # Σ σ_2(k)
say((10**6).sigma_sum(2, 3))       # Σ k^3 * σ_2(k)
```

### Totient and Möbius Sums

```ruby
# Σ_{k=1}^n φ(k) ~ 3n^2/π^2:
say((10**9).totient_sum())    # alias: euler_phi_sum, jordan_totient_sum(n,1)

# Mertens function M(n) = Σ μ(k):
for e in (1..10) {
    say("M(10^#{e}) = #{(10**e).mertens()}")
}

# Also: mertens(a, b) returns Σ_{k=a..b} μ(k)
say(mertens(21, 123))

# Liouville sum L(n) = Σ λ(k):
say((10**9).liouville_sum())
# Also: liouville_sum(a, b) for partial ranges
say(liouville_sum(10**9, 10**10))

# Dedekind psi partial sum:
say((10**6).dedekind_psi_sum())    # alias: psi_sum(n, 1)

# Jordan totient partial sums Σ J_k(m):
say((10**6).jordan_totient_sum(1))    # = totient_sum
say((10**6).jordan_totient_sum(2))
say((10**6).jordan_totient_sum(3))
```

### Chebyshev's ψ Function

ψ̃(n) = Σ_{k≤n} exp_mangoldt(k) — the integer (multiplicative) version:

```ruby
say((1000).exp_mangoldt_sum())    # A072107

# Verify PNT: prime_sum grows like n^2/(2 log n):
var n = 10**6
say(n.prime_sum() / ((n**2) / (2 * n.log())))   # → 1
```

### Prime and Prime-Power Sums

```ruby
say((10**9).prime_sum())           # Σ p ≤ 10^9  (sublinear)

# Omega and bigomega partial sums:
say((10**6).omega_sum())           # Σ_{k≤n} ω(k)  ~ n log log n
say((10**6).bigomega_sum())        # Σ_{k≤n} Ω(k)  ~ n log log n

say((10**6).exp_omega_sum(2))      # Σ_{k≤n} 2^{ω(k)}
say((10**6).exp_bigomega_sum(2))   # Σ_{k≤n} 2^{Ω(k)}
say((10**6).exp_bigomega_sum(-1))  # = liouville_sum(n)

# GPF, LPF, sopf, sopfr cumulative sums:
say((10**6).gpf_sum())
say((10**6).lpf_sum())
say((10**6).sopf_sum())
say((10**6).sopfr_sum())
```

### Pillai Cumulative Sum

```ruby
say((10**5).pillai_sum())    # Σ_{k=1}^n pillai(k)
```

### Verifying Asymptotic Formulas

```ruby
# Σ_{k≤n} τ(k) = n log n + (2γ−1)n + O(n^{1/2}):
var n = 10**8
var expected = (n * n.log() + ((2 * EulerGamma) - 1) * n)
var actual = n.tau_sum()
say(((actual - expected).abs() < n.sqrt() * 100))   # should hold

# Σ_{k≤n} φ(k) ~ 3n^2/π^2:
var phi_sum = n.totient_sum()
var asymptote = ((3 * (n**2)) / (Math::PI**2))
say((phi_sum / asymptote))   # → 1
```

---

## 14. Integer Classifications and Sequences

### Smooth and Rough Numbers

```ruby
# B-smooth: all prime factors ≤ B
say(720.is_smooth(5))           # true: 720 = 2^4·3^2·5
say(100.smooth_count(7))        # count of 7-smooth numbers up to 100

say(1000.smooth_numbers(7))     # list of 7-smooth numbers ≤ 1000 (as array)
say(105.smooth_part(5))         # 105 = 3·5·7 → 5-smooth part = 15

# B-rough: all prime factors ≥ B
say(100.rough_count(7))
say(100.rough_part(6))          # remove all factors ≤ 6 from 100

# nth and next/prev smooth/rough:
say(nth_smooth(100, 5))         # 100th 5-smooth number
say(nth_rough(100, 7))          # 100th 7-rough number
say(100.next_smooth(5))         # smallest 5-smooth > 100
say(100.prev_rough(7))          # largest 7-rough < 100
```

### Perfect Powers and Powerful Numbers

```ruby
# Powerful: v_p(n) ≥ 2 for all p | n
say(72.is_powerful())             # 72 = 2^3·3^2 ✓
say(100.powerful_count(2))        # 2-powerful numbers ≤ 100
say(100.powerful_sum(2))

# Perfect powers: n = m^k for k ≥ 2
say(64.is_power())         # 2^6, 4^3, 8^2 ✓
say(64.perfect_root())     # smallest base = 2
say(64.perfect_power())    # largest exponent k such that 64 = r^k  => 6
say(64.is_power_of(2))     # true
say(64.is_cube())          # true (4^3)
say(64.is_square())        # true (8^2)

say(1000.perfect_power_count())
say(nth_perfect_power(100))
say(next_perfect_power(1000000))
say(prev_perfect_power(1000000))
```

### Squarefree Numbers

```ruby
say(30.is_squarefree())      # true
say(12.is_squarefree())      # false (4 | 12)

say(1000.squarefree_count())  # ≈ 6n/π^2 ≈ 608
say(nth_squarefree(100))
say(50.next_squarefree())
say(1000.squarefree_sum())
```

### k-Free and k-Full Numbers

```ruby
# Cubefree: no p^3 | n
say(100.cubefree_count())
say(50.next_cubefree())
say(50.next_cubefull())     # smallest cubefull > 50 (e.g. 64 = 2^6)

# k-powerfree and k-nonpowerfree:
say(100.powerfree_count(3))    # = cubefree_count(100)
say(100.nonpowerfree_count(2)) # = count of non-squarefree ≤ 100
say(nth_powerfree(10**14, 2))  #=> 164493406685659
```

### Almost Primes

```ruby
# k-almost primes: Ω(n) = k
say(100.semiprime_count())          # = almost_prime_count(2)
say(100.almost_prime_count(3))

say(50.next_semiprime())
say(nth_semiprime(100))             # alias: semiprime(100)
say(1000.semiprime_sum())

# Squarefree semiprimes (= products of exactly 2 distinct primes):
say(30.squarefree_semiprime_count())
say(squarefree_semiprimes(30))
```

### ω-Primes

```ruby
# ω-prime with parameter k: ω(n) = k (exactly k distinct prime factors)
say(30.is_omega_prime(3))        # 30 = 2·3·5, ω = 3 ✓
say(100.omega_prime_count(2))    # integers ≤ 100 with exactly 2 distinct prime factors

say(50.next_omega_prime(3))
say(nth_omega_prime(10**7, 3))   #=> 28013887
```

### Sphenic Numbers

Sphenic = product of exactly 3 distinct primes (squarefree 3-almost primes):

```ruby
say(30.is_sphenic())    # 30 = 2·3·5 ✓
say(42.is_sphenic())    # 42 = 2·3·7 ✓
say(12.is_sphenic())    # false (12 = 2^2·3, not squarefree)

say(sphenic_count(100))
say(nth_sphenic(10**7))   #=> 48108421
say(sphenic(200))         # array of sphenic numbers ≤ 200
```

### Practical Numbers

n is **practical** if every m ≤ σ(n) is a sum of distinct divisors of n.
Every even perfect number is practical; every primorial is practical:

```ruby
say(12.is_practical())     # true
say(18.is_practical())     # true
say(14.is_practical())     # false

# Practical numbers form a multiplicative-like structure: 2 is practical,
# and if n is practical and p ≤ σ(n)+1 is prime, then n*p is practical.
```

### Amicable Pairs

```ruby
say(220.is_amicable())    # aliquot_sum(220) = 284, aliquot_sum(284) = 220 ✓
say(284.is_amicable())

# Find amicable pairs in a range:
for n in (2..1000) {
    var s = n.aliquot_sum()
    if ((s > n) && (s.aliquot_sum() == n)) {
        say("Amicable pair: (#{n}, #{s})")
    }
}
```

---

## 15. Pseudoprimes and Carmichael Numbers

### Fermat Pseudoprimes

n is a Fermat pseudoprime to base a if n is composite and a^{n−1} ≡ 1 (mod n):

```ruby
say(341.is_fermat_psp(2))    # 341 = 11·31 is the smallest psp(2)
say(561.is_fermat_psp(2))    # true — 561 is Carmichael, psp to every base

# Enumerate (k-omega Fermat pseudoprimes):
3.fermat_psp_each(2, 10000, { |n| say(n) })

# Squarefree Fermat pseudoprimes:
say(3.squarefree_fermat_psp(2, 100000))
```

### Strong Pseudoprimes (Miller-Rabin)

Write n−1 = 2^s·d with d odd. n is a strong psp(a) if:
a^d ≡ 1, or a^{2^r·d} ≡ −1 for some r < s (all mod n):

```ruby
say(2047.is_strong_psp(2))     # smallest spsp(2) = 2047

# Enumerate strong pseudoprimes (alias: is_strong_fermat_pseudoprime):
3.strong_fermat_psp_each(2, 1000000, { |n| say(n) })

# Squarefree strong pseudoprimes:
say(3.squarefree_strong_fermat_psp(2, 100000))
```

### Carmichael Numbers

By Korselt's criterion: n is Carmichael iff n is composite, squarefree,
and (p−1) | (n−1) for every prime p | n. Equivalently: λ(n) | n−1.

```ruby
say(561.is_carmichael())    # 561 = 3·11·17 ✓

# Verify Korselt's criterion explicitly:
func korselt(n) {
    n.is_squarefree() || return(false)
    for p in (n.prime_factors()) {
        (((n - 1) % (p - 1)) != 0) && return(false)
    }
    return(true)
}
say(korselt(561))
say(korselt(1105))   # 1105 = 5·13·17

# Also: λ(n) | n−1 iff n is Carmichael
say((561 - 1) % 561.carmichael_lambda())   # 0 ✓

# Generate (k-omega Carmichael numbers):
3.carmichael_each(1, 100000, { |n| say(n) })
say(3.carmichael(100000))   # returns array
```

### Lucas-Carmichael Numbers

n is Lucas-Carmichael if n is composite, squarefree, and (p+1) | (n+1) for all p | n:

```ruby
say(399.is_lucas_carmichael())
# 399 = 3·7·19: (3+1)|400, (7+1)|400, (19+1)|400 ✓

3.lucas_carmichael_each(1, 100000, { |n| say(n) })
```

### Strong Fermat Carmichael Numbers

```ruby
3.carmichael_strong_fermat_each(2, 10**7, { |n| say(n) })
```

### Lucas Pseudoprimes

The Lucas pseudoprime test uses the sequence U_n(P, Q) mod n:

```ruby
# Selfridge parameters:
say(n.is_lucas_psp())
say(n.is_strong_lucas_psp())
say(n.is_extra_strong_lucas_psp())    # alias: is_stronger_lucas_psp

# Specific parameters (U_n and V_n tests):
say(n.is_fib_psp())         # Fibonacci-based: U_n(1,-1)  (alias: is_lucasU_psp)
say(n.is_lucasv_psp())      # Companion test:  V_n(1,-1)  (alias: is_bruckman_lucas_psp)
```

### Euler and Plumb Pseudoprimes

```ruby
# Euler-Jacobi psp: a^{(n-1)/2} ≡ (a/n) (mod n)
say(n.is_euler_psp(2))
say(n.is_abs_euler_psp())    # absolute (psp to all coprime bases)

# Euler-Plumb pseudoprime (slightly stronger):
say(n.is_plumb_psp())        # alias: is_euler_plumb_psp
```

---

## 16. Special Arithmetic Functions

### Ramanujan's τ Function

τ(n) is the coefficient of q^n in Δ(q) = q ∏_{k≥1}(1−q^k)^{24}:

```ruby
say(1.ramanujan_tau())    # 1
say(2.ramanujan_tau())    # -24
say(3.ramanujan_tau())    # 252
say(4.ramanujan_tau())    # -1472
say(5.ramanujan_tau())    # 4830

# Hecke relations: τ(mn) = τ(m)τ(n) when gcd(m,n) = 1 (multiplicativity):
say((2.ramanujan_tau() * 3.ramanujan_tau()) == 6.ramanujan_tau())   # true

# At prime powers: τ(p^k) satisfies a linear recurrence:
# τ(p^k) = τ(p)·τ(p^{k-1}) − p^{11}·τ(p^{k-2})
var p = 2
say((p.ramanujan_tau() * (p**2).ramanujan_tau()) - ((p**11) * 1))
say((p**3).ramanujan_tau())

# Deligne's theorem: |τ(p)| ≤ 2p^{11/2}:
for p in (primes(2, 50)) {
    var t = p.ramanujan_tau()
    say("τ(#{p}) = #{t},  bound = #{(2 * (p**5.5)).round()}")
}
```

### Smarandache / Kempner Function

S(n) = smallest m with n | m! :

```ruby
say(1.smarandache())    # 1
say(4.smarandache())    # 4  (4 | 4! but 4 ∤ 3!)
say(9.smarandache())    # 6  (9 | 6! = 720 since v_3(6!) = 2)

# For prime p: S(p) = p. For prime powers:
for k in (1..6) {
    say("S(2^#{k}) = #{(2**k).smarandache()}")
}
```

### Cyclotomic Polynomials

```ruby
say(6.cyclotomic_polynomial())    # Φ_6(x) = x^2 − x + 1  (Polynomial object)
say(12.cyclotomic_polynomial())   # Φ_{12}(x) = x^4 − x^2 + 1

# Evaluate at a point:
say(6.cyclotomic(2))    # Φ_6(2) = 4 − 2 + 1 = 3
say(12.cyclotomic(2))   # Φ_{12}(2) = 16 − 4 + 1 = 13

# Product identity: x^n − 1 = ∏_{d|n} Φ_d(x):
var n = 12
var prod = n.divisors().map({ |d| d.cyclotomic(2) }).prod()
say(prod)                # = 2^12 − 1 = 4095
say(((2**12) - 1))       # ✓

# Cyclotomic factoring of b^n - 1 type numbers:
say(cyclotomic_factor(((2**60) - 1)))
```

### Bernoulli Numbers

```ruby
say(2.bernfrac())    # B_2 = 1/6
say(4.bernfrac())    # B_4 = -1/30
say(12.bernfrac())   # B_{12} = -691/2730  ← the famous 691

# Von Staudt–Clausen: denom(B_{2k}) = ∏_{(p-1)|2k} p
say(12.bernfrac().denominator())   # 2730 = 2·3·5·7·13

# Array of Bernoulli numbers B_0 … B_n:
say(bernoulli_numbers(6))   #=> [1, -1/2, 1/6, 0, -1/30, 0, 1/42]

# Kummer's criterion for irregular primes:
var irregular = []
for p in (primes(5, 200)) {
    for k in (range(2, p - 1, 2)) {
        if ((k.bernfrac().numerator().abs() % p) == 0) {
            irregular.append(p)
            break
        }
    }
}
say(irregular.first(10))   # [37, 59, 67, 101, 103, 131, 149, 157, 233, 257]
```

### Faulhaber's Formula

Σ_{k=1}^n k^p as a polynomial in n via Bernoulli numbers:

```ruby
say(faulhaber_sum(1, 100))    # Σ_{k=1}^100 k   = 5050
say(faulhaber_sum(2, 100))    # Σ_{k=1}^100 k^2 = 338350
say(faulhaber_sum(3, 100))    # Σ_{k=1}^100 k^3 = 25502500 = 5050^2 ✓

# Range sum:
say(faulhaber_range(50, 100, 2))   # Σ_{k=50}^100 k^2
```

### Bell, Catalan, and Motzkin Numbers

```ruby
say(5.bell_number())     # B_5 = 52   (set partitions of {1,...,5})
say(10.bell_number())    # B_{10} = 115975
say(bellmod(100, (10**9) + 7))

say(5.catalan())         # C_5 = 42
say(10.catalan())        # C_{10} = 16796
# Identity: C_n = Σ_{k=0}^{n-1} C_k · C_{n-1-k}

say(5.motzkin())         # M_5 = 21   — lattice paths A001006
say(10.motzkin())        # M_{10} = 4862
```

### Fubini Numbers (Ordered Set Partitions)

```ruby
say(3.fubini())    # 13   — ordered partitions of {1,2,3}
say(4.fubini())    # 75
say(5.fubini())    # 541
# Full array:
say(fubini_numbers(5))   #=> [1, 1, 3, 13, 75, 541]
```

### Padovan and Perrin Sequences

```ruby
# Padovan: P(n) = P(n-2) + P(n-3),  P(0)=P(1)=P(2)=1:
say(10.padovan())
say(padovanmod(1000, ((10**9) + 7)))

# Perrin: A(n) = A(n-2) + A(n-3),  A(0)=3, A(1)=0, A(2)=2:
# Perrin primality criterion: if p is prime then p | A(p)
for p in (primes(3, 50)) {
    say("A(#{p}) mod #{p} = #{perrinmod(p, p)}")   # all 0 for primes
}

# The smallest Perrin pseudoprime is 271441 = 521^2:
say(271441.is_prime())             # false
say(perrinmod(271441, 271441))     # 0 — passes the test despite being composite
```

### Genocchi Numbers

G_n = 2(1 − 2^n)B_n where B_n is the n-th Bernoulli number:

```ruby
for n in (1..10) {
    say("G_#{n} = #{n.genocchi()}")
}
#=> G_1=1, G_2=-1, G_4=1, G_6=-3, G_8=17, G_10=-155 (odd-indexed are 0)
```

### Inverse Problems for σ and τ

```ruby
# inverse_sigma: find all n with σ(n) = v
say(28.sigma_inverse())         # [12, ...]: σ(12) = 28, σ(27) = 40 (not 28), ...
say(28.sigma_inverse_len())
say(28.sigma_inverse_min())
say(28.sigma_inverse_max())

# inverse for τ: find all n with τ(n) = k
say(tau_inverse(1, 100, 4))     # all n ≤ 100 with exactly 4 divisors
say(tau_inverse_len(1, 100, 4)) # count of such n
say(nth_tau_inverse(1, 4))      # smallest n with τ(n) = 4  => 6
```

---

## Appendix: Quick Reference

```ruby
#── Factorization ──────────────────────────────────────────
n.factor()              #=> [p1, p1, p2, ...]         (sorted, with repetition)
n.factor_exp()          #=> [[p1, e1], [p2, e2], ...]
n.factor_map {|p,e|...} #=> map over (p, e) pairs
n.valuation(p)          #=> v_p(n)
n.omega()               #=> ω(n) — distinct prime factors
n.bigomega()            #=> Ω(n) — total prime factors
n.lpf()                 #=> least prime factor
n.gpf()                 #=> greatest prime factor
n.rad()                 #=> ∏_{p|n} p   (radical, A007947)  alias: squarefree_kernel
n.core()                #=> squarefree part (A007913)        alias: squarefree_part
n.sopf()                #=> Σ_{p|n} p   (A008472)
n.sopfr()               #=> Σ_{p^e||n} e·p  (A001414)
n.prime_signature()     #=> sorted exponent vector (descending)
n.perfect_root()        #=> smallest base r: n = r^k
n.perfect_power()       #=> largest exponent k: n = r^k

#── Divisors ───────────────────────────────────────────────
n.sigma(k)              #=> σ_k(n)
n.sigma0()              #=> τ(n)   aliases: tau, d
n.divisors()            #=> sorted list of divisors
n.aliquot_sum()         #=> σ(n) − n   alias: aliquot
n.usigma()              #=> unitary sigma     (A034448)
n.bsigma()              #=> bi-unitary sigma  (A188999)
n.isigma()              #=> infinitary sigma  (A049417)
n.esigma()              #=> exponential sigma (A051377)
n.udivisors()           #=> unitary divisors
n.bdivisors()           #=> bi-unitary divisors
n.idivisors()           #=> infinitary divisors
n.edivisors()           #=> exponential divisors

#── Totients ───────────────────────────────────────────────
n.euler_phi()           #=> φ(n)   aliases: totient, eulerphi
n.jordan_totient(k)     #=> J_k(n)
n.carmichael_lambda()   #=> λ(n) — exponent of (ℤ/nℤ)*   alias: lambda
n.dedekind_psi()        #=> ψ(n) = n ∏_{p|n}(1 + 1/p)   alias: psi
n.uphi()                #=> unitary totient (A047994)
n.bphi()                #=> bi-unitary totient (A116550)
n.iphi()                #=> infinitary totient (A091732)

#── Multiplicative functions ───────────────────────────────
n.moebius()             #=> μ(n)   aliases: mu, mobius
n.liouville()           #=> λ(n) = (−1)^Ω(n)
n.exp_mangoldt()        #=> p if n=p^k, else 1
n.ramanujan_tau()       #=> Ramanujan τ(n)
n.smarandache()         #=> S(n) — Smarandache/Kempner function   alias: kempner
n.pillai()              #=> Σ_{k=1}^n gcd(k,n)
n.ramanujan_sum(q)      #=> c_q(n) — Ramanujan sum
n.arithmetic_derivative()  #=> n'   alias: derivative
n.logarithmic_derivative()  #=> n'/n as rational

#── Primality ──────────────────────────────────────────────
n.is_prime()
n.is_bpsw_prime()
n.is_prov_prime()          # alias: is_provable_prime
n.is_ecpp_prime()
n.miller_rabin_random(k)
n.is_strong_psp(a)         # aliases: is_strong_fermat_psp, miller_rabin
n.is_strong_lucas_psp()    # alias: is_strong_lucas_pseudoprime
n.is_mersenne_prime()      # Lucas-Lehmer test on 2^n - 1
n.is_safe_prime()
n.is_sophie_germain()
n.is_twin_prime()
n.is_emirp()

#── Modular arithmetic ─────────────────────────────────────
powmod(a, e, m)         #=> a^e mod m   alias: expmod
invmod(a, m)            #=> a^{-1} mod m
addmod(a, b, m)         #=> (a+b) % m
mulmod(a, b, m)         #=> (a*b) % m
submod(a, b, m)         #=> (a-b) % m
n.gcdext(m)             #=> (g, x, y) with g = ax + by
n.znorder(m)            #=> ord_m(n)   alias: multiplicative_order
n.znprimroot()          #=> smallest primitive root mod n
n.is_primitive_root(m)  #=> true if n is a primitive root mod m
n.jacobi(m)             #=> Jacobi symbol (n/m)
n.legendre(p)           #=> Legendre symbol (n/p)
n.kronecker(m)          #=> Kronecker symbol (n/m)
n.sqrtmod(m)            #=> √n mod m
n.rootmod(k, m)         #=> k-th root of n mod m
n.cornacchia(d)         #=> [x, y] with x^2 + d·y^2 = n   alias: solve_quadratic_form
solve_pell(D)           #=> [x, y] fundamental solution of x^2 − D·y^2 = 1
solve_pell(D, k)        #=> [x, y] fundamental solution of x^2 − D·y^2 = k

#── Sublinear sums ─────────────────────────────────────────
n.prime_count()         #=> π(n)   aliases: primepi, count_primes
n.prime_sum()           #=> Σ_{p≤n} p   aliases: primes_sum, sum_primes
n.mertens()             #=> M(n) = Σ_{k≤n} μ(k)
n.liouville_sum()       #=> L(n) = Σ_{k≤n} λ(k)
n.totient_sum()         #=> Σ_{k≤n} φ(k)   aliases: euler_phi_sum
n.sigma_sum()           #=> Σ_{k≤n} σ(k)
n.tau_sum()             #=> Σ_{k≤n} τ(k)   alias: sigma0_sum
n.jordan_totient_sum(k) #=> Σ_{m≤n} J_k(m)
n.dedekind_psi_sum()    #=> Σ_{k≤n} ψ(k)   alias: psi_sum
n.exp_mangoldt_sum()    #=> integer Chebyshev ψ̃(n)
n.pillai_sum()          #=> Σ_{k≤n} pillai(k)
n.gpf_sum()             #=> Σ_{k≤n} gpf(k)
n.lpf_sum()             #=> Σ_{k≤n} lpf(k)
n.bigomega_sum()        #=> Σ_{k≤n} Ω(k)
n.omega_sum()           #=> Σ_{k≤n} ω(k)
n.exp_bigomega_sum(k)   #=> Σ_{k≤n} base^{Ω(k)}  (k=-1 gives liouville_sum)
n.exp_omega_sum(k)      #=> Σ_{k≤n} base^{ω(k)}

#── Continued fractions ────────────────────────────────────
n.sqrt_cfrac_period()
n.sqrt_cfrac_period_len()
n.convergents(k)
n.pisano_period()
solve_pell(D)
x.rat_approx(max_den)   #=> best rational approximation p/q, q ≤ max_den
```
