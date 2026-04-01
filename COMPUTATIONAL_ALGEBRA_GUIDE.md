# Sidef: Advanced Computational Algebra & Number Theory

Sidef is a high-level programming language with first-class support for advanced mathematical structures. This guide covers six algebraic types that make Sidef particularly powerful for number theory, cryptography, and symbolic computation: **Polynomial**, **PolynomialMod**, **Mod**, **Gauss**, **Quadratic**, and **Quaternion**.

---

## Table of Contents

1. [Mod — Modular Arithmetic](#mod)
2. [Gauss — Gaussian Integers](#gauss)
3. [Quadratic — Quadratic Integers](#quadratic)
4. [Quaternion — Quaternion Numbers](#quaternion)
5. [Polynomial — Univariate Polynomials](#polynomial)
6. [PolynomialMod — Polynomial Quotient Rings](#polynomialmod)
7. [Cross-Type Examples](#cross-type-examples)
8. [Algebraic Number Theory](#algebraic-number-theory)
   - [Rings of Integers and Algebraic Integers](#rings-of-integers-and-algebraic-integers)
   - [Quadratic Fields: Real vs Imaginary](#quadratic-fields-real-vs-imaginary-1)
   - [Norms, Traces, and the Minimal Polynomial](#norms-traces-and-the-minimal-polynomial)
   - [The Pell Equation in Depth](#the-pell-equation-in-depth)
   - [Factorization of Rational Primes in Quadratic Fields](#factorization-of-rational-primes-in-quadratic-fields)
   - [Fermat's Two-Square Theorem via Gaussian Integers](#fermats-two-square-theorem-via-gaussian-integers)
   - [Euler's Four-Square Theorem via Quaternions](#eulers-four-square-theorem-via-quaternions)
   - [Hurwitz Quaternions and Integer Factorization](#hurwitz-quaternions-and-integer-factorization)
   - [Norm Equations and Diophantine Applications](#norm-equations-and-diophantine-applications)
   - [Cyclotomic Fields via PolynomialMod](#cyclotomic-fields-via-polynomialmod-1)
   - [Algebraic Extensions and Minimal Polynomials](#algebraic-extensions-and-minimal-polynomials)
   - [The Frobenius Endomorphism in Finite Fields](#the-frobenius-endomorphism-in-finite-fields-1)
   - [Quadratic Residues and the Legendre Symbol](#quadratic-residues-and-the-legendre-symbol)
   - [Discriminants and Different](#discriminants-and-different)
   - [Lifting and the Hensel Lemma](#lifting-and-the-hensel-lemma)
   - [The Structure of Units in Quadratic Orders](#the-structure-of-units-in-quadratic-orders)
   - [Ideal Arithmetic via Quadratic Integers](#ideal-arithmetic-via-quadratic-integers)
   - [Extended GCD in Polynomial Rings](#extended-gcd-in-polynomial-rings-bézout-coefficients)

---

## Mod

`Mod(n, m)` represents the integer `n` modulo `m`. All arithmetic automatically reduces results, making this ideal for cryptographic computations, primality work, and modular sequences.

### Construction

```ruby
var a = Mod(13, 19)     # 13 mod 19
var b = Mod(-3, 7)      # becomes Mod(4, 7) — auto-reduced
var c = Mod(17, 5)      # becomes Mod(2, 5)
```

### Arithmetic

```ruby
var a = Mod(13, 19)

a += 15                 # Mod(9,  19)  — (13+15) mod 19
a *= 99                 # Mod(17, 19)  — (9*99)  mod 19
a /= 17                 # Mod(1,  19)  — 17 * 17⁻¹ mod 19
say a                   # Mod(1, 19)

say Mod(2, 1000) ** 100 # Mod(376, 1000)  — 2¹⁰⁰ mod 1000
```

### Modular Inverse & Square Root

```ruby
say Mod(3, 7).inv       # Mod(5, 7)   — because 3*5 ≡ 1 (mod 7)
say Mod(4, 13).sqrt     # Mod(2, 13)  — because 2² ≡ 4 (mod 13)
```

### Multiplicative Order

```ruby
# Smallest k such that a^k ≡ 1 (mod m)
say Mod(2, 7).znorder   # 3  — because 2³ = 8 ≡ 1 (mod 7)
say Mod(2, 15).znorder  # 4  — because 2⁴ = 16 ≡ 1 (mod 15)
```

### Chinese Remainder Theorem

```ruby
# Solve: x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7)
say chinese(Mod(2,3), Mod(3,5), Mod(2,7))  # Mod(23, 105)

# Verify
say (23 % 3)   # 2 ✓
say (23 % 5)   # 3 ✓
say (23 % 7)   # 2 ✓

# Another CRT example
say chinese(Mod(2,3), Mod(3,4), Mod(1,5))  # Mod(11, 60)
```

### Number Sequences Modulo m

```ruby
say Mod(10, 100).fib    # Mod(55, 100)  — F(10) = 55
say Mod(10, 1000).lucas # Mod(123, 1000) — L(10) = 123

# Lucas sequences (generalize Fibonacci and Lucas)
say Mod(10, 1000).lucasu(1, -1)  # equivalent to Fibonacci
say Mod(10, 1000).lucasv(1, -1)  # equivalent to Lucas numbers

# Chebyshev polynomials mod m
say Mod(2, 100).chebyshevt(5)  # T₅(2) mod 100
say Mod(2, 100).chebyshevu(5)  # U₅(2) mod 100

# Cyclotomic polynomial evaluated mod m
say Mod(2, 100).cyclotomic(5)  # Φ₅(2) mod 100
```

### Factorial Modulo m

```ruby
say Mod(5, 13)!         # Mod(3, 13)  — 5! = 120 ≡ 3 (mod 13)
```

---

## Gauss

`Gauss(a, b)` represents the Gaussian integer `a + bi`, where `a` and `b` are ordinary integers. Gaussian integers form a unique factorization domain, making them fundamental to algebraic number theory.

### Construction & Basic Arithmetic

```ruby
var a = Gauss(17, 19)   # 17+19i
var b = Gauss(43, 97)   # 43+97i

say (a + b)               # Gauss(60, 116)   — component-wise addition
say (a - b)               # Gauss(-26, -78)
say (a * b)               # Gauss(-1112, 2466)  — (pr-qs) + (ps+qr)i
say (a / b)               # rational result: 99/433 - 32i/433
```

### Norm, Conjugate & Absolute Value

```ruby
var z = Gauss(3, 4)

say z.norm              # 25   — 3² + 4² (squared magnitude)
say z.abs               # 5    — sqrt(norm)
say z.conj              # Gauss(3, -4)
say z.inv               # conj(z) / norm(z)
say (z * z.conj)        # Gauss(25, 0)   — norm as a Gaussian integer
```

### Primality & Factorization

```ruby
say Gauss(3, 2).is_prime    # true  — 3²+2² = 13, a prime ≡ 1 (mod 4)
say Gauss(5, 0).is_prime    # false — 5 = (2+i)(2-i) in Gaussian integers

# Full factorization
var g = Gauss(120, 84)
say g.factor                # array of Gaussian prime factors

# Factor with exponents
var h = Gauss(50, 0)
say h.factor_exp            # [[prime, exponent], ...]

# Divisors
say Gauss(6, 0).divisors    # all Gaussian integer divisors of 6
```

### GCD and Coprimality

```ruby
var p = Gauss(8, 4)
var q = Gauss(6, 2)

say p.gcd(q)                # GCD in the Gaussian integers
say p.gcd_norm(q)           # norm of the GCD
say p.is_coprime(q)         # true if GCD is a unit (±1 or ±i)
say p.is_div(q)             # true if q divides p exactly
```

### Modular Arithmetic on Gaussian Integers

```ruby
var z = Gauss(3, 4)

say z.powmod(5, 100)        # z⁵ mod 100
say z.invmod(97)            # modular inverse mod 97
```

### Rotation and Sign

```ruby
var z = Gauss(3, 4)
say z.i                     # multiply by i: Gauss(-4, 3)  — 90° rotation
say z.sgn                   # unit Gaussian integer (one of 1,-1,i,-i)
```

---

## Quadratic

`Quadratic(a, b, w)` represents the quadratic integer `a + b√w`, where `w` is a square-free discriminant. This is the workhorse for algebraic number theory, Pell equations, and quadratic fields.

### Construction

```ruby
var x = Quadratic(3, 4, 5)     # 3 + 4√5
var y = Quadratic(1, 1, 2)     # 1 + √2  (fundamental solution to Pell x²-2y²=1)
var z = Quadratic(3, 4, -1)    # 3 + 4i  (Gaussian integer via Quadratic)
```

### Arithmetic

```ruby
var a = Quadratic(3, 4, 5)
var b = Quadratic(1, 2, 5)     # must share same w for direct arithmetic

say (a + b)   # Quadratic(4,  6, 5)  — (3+1) + (4+2)√5
say (a - b)   # Quadratic(2,  2, 5)
say (a * b)   # (ac+bdw) + (ad+bc)√w = (3+40) + (6+4)√5 = Quadratic(43, 10, 5)
say (a / b)   # multiply by inverse
```

### Norm, Conjugate & Inverse

```ruby
var q = Quadratic(3, 4, 5)

say q.norm        # a² - b²w = 9 - 80 = -71
say q.conj        # Quadratic(3, -4, 5)  — a - b√w
say q.inv         # a/(a²-b²w) - b/(a²-b²w)√w
say (q * q.inv)   # Quadratic(1, 0, 5)  — the identity
```

### Powers and Pell Equations

```ruby
# Pell equation x² - 2y² = ±1 : solutions grow via powers of (1+√2)
var pell = Quadratic(1, 1, 2)
say pell**2     # Quadratic(3, 2, 2)  — 3² - 2·2² = 1 ✓
say pell**5     # Quadratic(29, 20, 2) — 29² - 2·20² = 841-800 = 41...
say pell**10    # Quadratic(577, 408, 2)

# Large exponents efficiently
say Quadratic(3, 4, 5)**10  # Quadratic(29578174649, 13203129720, 5)
```

### Modular Exponentiation

```ruby
var q = Quadratic(3, 4, 5)

say q.powmod(100, 97)   # Quadratic(83, 42, 5)   — q¹⁰⁰ mod 97
say q.invmod(97)        # modular inverse mod 97

# Verify inverse
var inv = q.invmod(97)
say ((q * inv) % 97)    # should equal Quadratic(1, 0, 5)
```

### Quadratic Fields: Real vs Imaginary

```ruby
# Imaginary quadratic field Q(√-1) — Gaussian integers
var gi = Quadratic(3, 4, -1)
say gi.norm     # 9 + 16 = 25  (positive, since w=-1 makes -b²w positive)

# Real quadratic field Q(√5) — includes golden ratio
var phi = Quadratic(1, 1, 5)   # 1 + √5
say phi**2                      # Quadratic(6, 2, 5)  = 6 + 2√5

# The golden ratio itself: (1+√5)/2
var golden = Quadratic(Fraction(1,2), Fraction(1,2), 5)
```

### String Representations

```ruby
var q = Quadratic(3, 4, 5)
say q.to_s      # "Quadratic(3, 4, 5)"
say q.pretty    # "3 + (4)*sqrt(5)"
```

---

## Quaternion

`Quaternion(a, b, c, d)` represents `a + bi + cj + dk`, the extension of complex numbers to four dimensions. Quaternion multiplication is **non-commutative**, which is what makes them ideal for representing 3D rotations without gimbal lock.

### Construction

```ruby
var q  = Quaternion(1, 2, 3, 4)   # 1 + 2i + 3j + 4k
var q2 = Quaternion(5)            # 5 + 0i + 0j + 0k  (scalar quaternion)
var q3 = Quaternion()             # 0 (zero quaternion)
```

### Non-Commutative Multiplication

```ruby
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)

say (a * b)     # Quaternion(-60, 12, 30, 24)
say (b * a)     # Quaternion(-60, 20, 14, 32)  ← different! order matters

# Fundamental unit relationships: i²=j²=k²=ijk=-1
var i = Quaternion(0, 1, 0, 0)
var j = Quaternion(0, 0, 1, 0)
var k = Quaternion(0, 0, 0, 1)

say (i * i)     # Quaternion(-1, 0, 0, 0)  — i² = -1
say (i * j)     # Quaternion(0,  0, 0, 1)  — ij = k
say (j * i)     # Quaternion(0,  0, 0,-1)  — ji = -k
say (j * k)     # Quaternion(0,  1, 0, 0)  — jk = i
say (k * i)     # Quaternion(0,  0, 1, 0)  — ki = j
```

### Norm, Conjugate & Inverse

```ruby
var q = Quaternion(1, 2, 3, 4)

say q.norm      # 30    — a²+b²+c²+d² = 1+4+9+16
say q.abs       # ~5.48 — √norm (magnitude)
say q.conj      # Quaternion(1, -2, -3, -4)   — negate i,j,k parts
say q.inv       # conj(q) / norm(q)
say (q * q.inv) # Quaternion(1, 0, 0, 0)      — the identity

# Norm is multiplicative: norm(a*b) = norm(a)*norm(b)
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)
say ((a * b).norm == (a.norm*b.norm))   # true
```

### Arithmetic

```ruby
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)

say (a + b)     # Quaternion(6, 8, 10, 12)
say (a - b)     # Quaternion(-4, -4, -4, -4)
say (a / b)     # Quaternion(35/87, 4/87, 0, 8/87)  — a * b.inv
say a**3        # a cubed via binary exponentiation
say a.sqr       # Quaternion(-28, 4, 6, 8)
```

### Component Access

```ruby
var q = Quaternion(1, 2, 3, 4)

say q.a         # 1  — real part (also: q.re, q.real)
say q.b         # 2  — i coefficient
say q.c         # 3  — j coefficient
say q.d         # 4  — k coefficient
say q.parts     # [1, 2, 3, 4]

var (w, x, y, z) = q.reals   # destructure all four components
```

### 3D Rotation via Unit Quaternions

```ruby
# Represent a 90° rotation around the Z-axis
# q = cos(θ/2) + sin(θ/2)·k
var angle = 90.deg2rad
var w = angle.div(2).cos
var s = angle.div(2).sin

var rotation = Quaternion(w, 0, 0, s)
say rotation.norm    # 1.0 — unit quaternion (required for rotations)
say rotation.sgn     # the versor (unit quaternion in same direction)
```

### Modular Arithmetic

```ruby
var q = Quaternion(1, 2, 3, 4)

say q.powmod(5, 100)     # q⁵ mod 100
say q.invmod(97)         # modular inverse mod 97

# Coprimality (based on norm)
say q.is_coprime(Quaternion(5, 6, 7, 8))
```

---

## Polynomial

`Polynomial` supports univariate polynomial arithmetic with arbitrary-precision coefficients. Three constructor forms let you build polynomials naturally.

### Construction

```ruby
# From coefficient array (highest degree first)
var p = Polynomial([1, -2, 1])      # x² - 2x + 1  = (x-1)²
var q = Polynomial([1, 0, -1])      # x² - 1       = (x-1)(x+1)

# Monomial: single term x^n
var m = Polynomial(5)               # x⁵

# Sparse: specify (exponent => coefficient) pairs
var s = Polynomial(5 => 3, 2 => 10) # 3x⁵ + 10x²
```

### Arithmetic

```ruby
var p = Polynomial([1, 0, -1])   # x² - 1
var q = Polynomial([1, -1])      # x - 1

say (p + q)   # x² + x - 2        — add coefficients
say (p - q)   # x² - x            — subtract
say (p * q)   # x³ - x² - x + 1   — multiply (degrees sum)
say (p / q)   # x + 1             — exact division
say (p % q)   # 0                 — remainder

# Squaring efficiently
say Polynomial([1, 1]).sqr         # x² + 2x + 1
say Polynomial([1, 1])**4          # (x+1)⁴ = x⁴ + 4x³ + 6x² + 4x + 1
```

### Evaluation

```ruby
var p = Polynomial([1, 2, 3])   # x² + 2x + 3

say p.eval(0)    # 3   — constant term
say p.eval(1)    # 6   — 1 + 2 + 3
say p.eval(5)    # 38  — 25 + 10 + 3
say p.eval(-1)   # 2   — 1 - 2 + 3
```

### Differentiation & Root Finding

```ruby
var p = Polynomial([1, 0, -3, 2])   # x³ - 3x + 2

say p.derivative                     # 3x² - 3
say p.derivative.derivative          # 6x

say p.roots                          # all zeros of p(x)
say Polynomial([1, 0, -1]).roots     # [-1, 1]

# Newton's method for a root near x₀ = 1.5
var f  = Polynomial([1, 0, -2])      # x² - 2
var df = f.derivative
say f.newton_method(1.5, df)         # approximates √2
```

### Properties & Coefficients

```ruby
var p = Polynomial([3, 0, 2, 1])     # 3x³ + 2x + 1

say p.deg                   # 3      — degree
say p.leading_coeff         # 3      — leading coefficient
say p.leading_term          # 3x³   — leading term
say p.leading_monomial      # x³    — leading monomial
say p.coeff(1)              # 2      — coefficient of x¹
say p.coeffs                # [3, 0, 2, 1]
say p.exponents             # [3, 2, 1, 0]  — only non-zero if sparse
say p.is_squarefree         # true/false
```

### GCD, LCM & Content

```ruby
var p = Polynomial([1, 0, -1])      # x² - 1
var q = Polynomial([1, -1])         # x - 1

say p.gcd(q)                        # x - 1
say p.lcm(q)                        # x² - 1

# Extended GCD: find s, t such that s*p + t*q = gcd
var (g, s, t) = p.gcdext(q)

# Content (GCD of all coefficients) and primitive part
var r = Polynomial([6, 9, 12])      # 6x² + 9x + 12
say r.cont                          # 3
say r.prim_part                     # 2x² + 3x + 4

# Square-free part (remove repeated factors)
say Polynomial([1, -2, 1]).squarefree_part  # x - 1  (from (x-1)²)
```

### Divmod

```ruby
var p = Polynomial([1, 0, -1])   # x² - 1
var q = Polynomial([1, -1])      # x - 1

var (quotient, remainder) = p.divmod(q)
say quotient    # x + 1
say remainder   # 0
```

---

## PolynomialMod

`PolynomialMod(coeffs, modulus)` represents a polynomial in the quotient ring `K[x] / (m(x))`, where all arithmetic is reduced modulo the polynomial `m(x)`. This is the algebraic engine behind finite fields and cryptographic constructions like AES and RSA variants.

### Construction

```ruby
# (1 + 2x + 3x²) mod (1 + x²)
var p = PolynomialMod([3, 2, 1], Poly([1, 0, 1]))       # 2*x - 2 (mod x^2 + 1)

# Represent 'x' in the ring Q[x]/(x²+1)
var x = PolynomialMod([1,0], Poly([1, 0, 1]))
```

### Simulating Gaussian Integers via Q[x]/(x²+1)

```ruby
# In Q[x]/(x²+1), the element x satisfies x² = -1, so x plays the role of i
var i = PolynomialMod([1, 0], Poly([1, 0, 1]))

say (i ** 2)   # -1   — because x² ≡ -1 mod (x²+1)
say (i ** 4)   # 1
say (i ** 8)   # 1

# Arithmetic in the ring
var a = PolynomialMod([0, 3], Poly([1, 0, 1]))   # 3
var b = PolynomialMod([4, 0], Poly([1, 0, 1]))   # 4i
say ((a + b)**2)   # (3+4i)² = -7+24i  (norm-preserving!)
```

### Finite Field Arithmetic GF(p^n)

```ruby
# GF(4) = GF(2)[x]/(x²+x+1) — field with 4 elements
# Elements: {0, 1, x, x+1}
var mod_poly = Poly([1, 1, 1])   # x² + x + 1 over GF(2)

var alpha = PolynomialMod([1, 0], mod_poly)   # generator element x
var one   = PolynomialMod([0, 1], mod_poly)

say (alpha ** 1)   # x
say (alpha ** 2)   # x+1  (reduced: x² ≡ x+1 mod x²+x+1)
say (alpha ** 3)   # 1    — ord(α) = 3, so α is a primitive element
```

### Exponentiation & Inverse

```ruby
var p = PolynomialMod([1, 2], Poly([1, 0, 0, 1]))   # (1+2x) mod (x³+1)

say (p ** 3)       # p³ reduced mod (x³+1)
say (p ** (-1))    # modular inverse (negative exponent)
say (p.inv)        # same as p**(-1)
say (p * p.inv)    # 1

# High-power exponentiation is efficient via binary method
say (p ** 1000)
```

### GCD and Modular Inverse via gcdext

```ruby
var f = PolynomialMod([1, 0, 1], Poly([1, 0, 0, 1]))   # x²+1 mod x³+1
var g = PolynomialMod([1, 1],    Poly([1, 0, 0, 1]))   # x+1  mod x³+1

say f.gcd(g)                  # GCD of f and g in the quotient ring
var (d, u, v) = f.gcdext(g)   # d = u*f + v*g
say (u*f + v*g == d)          # true
```

### Derivative in Quotient Rings

```ruby
# Formal derivative, computed mod the modulus polynomial
var p = PolynomialMod([1, 0, 3, 1], Poly([1, 0, 0, 0, 1]))  # mod x⁴+1
say p.derivative    # derivative reduced mod x⁴+1
```

### Lifting Back to Polynomial Ring

```ruby
var p = PolynomialMod([1, 2, 3], Poly([1, 0, 1]))

var lifted = p.lift    # returns an ordinary Polynomial object
say lifted             # 1 + 2x + 3x²  (no modulus constraint)
say p.modulus          # the modulus polynomial: x² + 1
```

---

## Cross-Type Examples

### Gaussian Integers & Quadratic Integers

`Gauss` and `Quadratic` are related: `Quadratic(a, b, -1)` is equivalent to the Gaussian integer `Gauss(a, b)`.

```ruby
# Quadratic integers with w = -1 behave as Gaussian integers
var z1 = Gauss(3, 4)
var z2 = Quadratic(3, 4, -1)

say z1.norm   # 25  (3² + 4²)
say z2.norm   # 25  (3² - 4²·(-1) = 9 + 16)

# Pell equation solutions via Quadratic
var x = Quadratic(1, 1, 2)    # 1 + √2
(1..10).each { say x**_ }     # first 10 fundamental solutions
```

### Mod and Gauss: Gaussian Integers Modulo m

```ruby
# Combine Gauss with powmod for Gaussian modular exponentiation
var g = Gauss(3, 4)
say g.powmod(100, 1009)    # (3+4i)¹⁰⁰ mod 1009
say g.invmod(1009)         # multiplicative inverse mod 1009
```

### PolynomialMod as a Generalization of Quadratic/Gauss

All three types share the same underlying idea: arithmetic in a quotient ring `R[α]/(min_poly(α))`.

```ruby
# These three computations are equivalent representations of i² = -1:

# 1. Using Gauss directly
var g = Gauss(0, 1)
say (g * g)    # Gauss(-1, 0)

# 2. Using Quadratic with w = -1
var q = Quadratic(0, 1, -1)
say (q * q)    # Quadratic(-1, 0, -1)

# 3. Using PolynomialMod in Q[x]/(x²+1)
var p = PolynomialMod([1, 0], [1, 0, 1])
say (p * p)    # -1 in the quotient ring
```

### CRT with Multiple Moduli

```ruby
# Chinese Remainder Theorem reconstructs a number from its residues
func reconstruct(n) {
    var mods = [97, 101, 103, 107].map {|m| Mod(n, m) }
    say chinese(mods...)   # should recover Mod(n, 97*101*103*107)
}
reconstruct(123456789)
```

### Quaternion Norm is Multiplicative (Euler's Four-Square Identity)

```ruby
# The quaternion norm identity encodes Euler's four-square theorem:
# (a₁²+b₁²+c₁²+d₁²)(a₂²+b₂²+c₂²+d₂²) = (product norm)

var q1 = Quaternion(1, 2, 3, 4)
var q2 = Quaternion(5, 6, 7, 8)

say (q1.norm*q2.norm == (q1 * q2).norm)   # true
say q1.norm         # 30  = 1+4+9+16
say q2.norm         # 174 = 25+36+49+64
say ((q1*q2).norm)  # 5220 = 30 * 174
```

### Polynomial GCD & Resultant Workflow

```ruby
# Factor and check relationships between polynomials
var p = Polynomial([1, 0, -5, 0, 4])    # x⁴ - 5x² + 4 = (x-1)(x+1)(x-2)(x+2)
var q = Polynomial([1, 0, -1])          # x² - 1 = (x-1)(x+1)

say p.gcd(q)                             # x² - 1
say (p / q)                              # x² - 4
say ((p / q).roots)                      # [-2, 2]
say p.is_squarefree                      # true
say p.roots                              # [-2, -1, 1, 2]
```

---

## Algebraic Number Theory

This section develops the deeper number-theoretic machinery that the six types collectively provide, organized around the classical themes of algebraic number theory: rings of integers, norms, factorization, quadratic fields, cyclotomic fields, Diophantine equations, and the interplay between rational primes and their behavior in algebraic extensions.

---

### Rings of Integers and Algebraic Integers

An **algebraic integer** is a root of a monic polynomial with integer coefficients. The ring of integers `O_K` of a number field `K = Q(√d)` consists of all algebraic integers in `K`.

For the quadratic field `Q(√d)` with `d` square-free:

- If `d ≡ 2` or `3 (mod 4)`: the ring of integers is `Z[√d]`, elements `a + b√d` with `a, b ∈ Z`
- If `d ≡ 1 (mod 4)`: the ring of integers is `Z[(1+√d)/2]`, with the **half-integer** basis

```ruby
# Z[√2]: d=2, d ≡ 2 mod 4, so integers are a + b√2
var alpha = Quadratic(1, 1, 2)    # 1 + √2  — an algebraic integer
say alpha.norm                     # 1 - 2 = -1   (norm is in Z ✓)

# Verify: alpha satisfies x² - 2x - 1 = 0
# norm(a + b√2) = a² - 2b²
say (alpha**2 - alpha*2 - Quadratic(1,0,2))   # should be 0

# Z[(1+√5)/2]: d=5, d ≡ 1 mod 4 — the golden ratio φ = (1+√5)/2 is an integer!
var phi = Quadratic(1/2, 1/2, 5)  # (1+√5)/2
say phi.norm    # (1/4) - (1/4)*5 = -1   — norm is in Z ✓
say phi**2      # φ² = φ + 1  (the defining property of the golden ratio)

# Compare: √5 itself is NOT an algebraic integer in this sense
var sqrt5 = Quadratic(0, 1, 5)
say sqrt5.norm  # -5  (also an integer, √5 satisfies x²-5=0, monic ✓)
```

---

### Quadratic Fields: Real vs Imaginary

The sign of the discriminant `d` in `Q(√d)` determines whether the field is **real** (`d > 0`) or **imaginary** (`d < 0`), and this profoundly affects its arithmetic.

#### Imaginary Quadratic Fields

In imaginary quadratic fields the norm `N(a + b√d) = a² - b²d = a² + b²|d|` is always positive, making them **norm-Euclidean** for small `|d|`.

```ruby
# Q(√-1): Gaussian integers — norm a² + b²
var z = Quadratic(3, 4, -1)
say z.norm    # 9 + 16 = 25   (always positive)

# Q(√-2): norm a² + 2b²
var w = Quadratic(1, 1, -2)
say w.norm    # 1 + 2 = 3

# Q(√-3): norm a² + 3b² — contains the Eisenstein integers
var e = Quadratic(1, 1, -3)
say e.norm    # 1 + 3 = 4

# Q(√-5): norm a² + 5b² — famous for FAILING unique factorization
# 6 = 2 * 3 = (1+√-5)(1-√-5), two distinct factorizations into "irreducibles"
var a = Quadratic(1,  1, -5)    # 1 + √-5,  norm = 6
var b = Quadratic(1, -1, -5)    # 1 - √-5,  norm = 6
say a.norm        # 6
say b.norm        # 6
say (a * b)       # Quadratic(6, 0, -5)  = 6  ✓ — product is 6
say Quadratic(2,0,-5).norm  # 4  — norm of 2
say Quadratic(3,0,-5).norm  # 9  — norm of 3
# Neither 2 nor 3 divides (1±√-5), confirming non-unique factorization
```

#### Real Quadratic Fields

Real quadratic fields `Q(√d)`, `d > 0` have a more complex unit group: units are `±εⁿ` where `ε` is the **fundamental unit**, found as the smallest solution to the Pell equation.

```ruby
# Q(√2): fundamental unit is 1+√2 (norm = -1)
var eps2 = Quadratic(1, 1, 2)
say eps2.norm           # -1  — unit of norm -1

# Q(√3): fundamental unit is 2+√3 (norm = 1)
var eps3 = Quadratic(2, 1, 3)
say eps3.norm           # 4 - 3 = 1  — unit of norm +1

# Q(√5): fundamental unit is (1+√5)/2 = φ (norm = -1)
var eps5 = Quadratic(1/2, 1/2, 5)
say eps5.norm           # 1/4 - 5/4 = -1  — unit of norm -1

# Generating all units by powering the fundamental unit
var u = Quadratic(1, 1, 2)   # fundamental unit of Q(√2)
say u**1          # Quadratic(1, 1, 2)       = 1+√2
say u**2          # Quadratic(3, 2, 2)       = 3+2√2
say u**3          # Quadratic(7, 5, 2)       = 7+5√2
say u**4          # Quadratic(17, 12, 2)     = 17+12√2
say u**(-1)       # Quadratic(-1, 1, 2)      = -1+√2
say (u * u.conj)  # norm: (1+√2)(1-√2) = 1-2 = -1  ✓
```

---

### Norms, Traces, and the Minimal Polynomial

For `α = a + b√d` in a quadratic field, the **norm** and **trace** are the two fundamental invariants:

- `N(α) = α · ᾱ = a² - b²d`
- `Tr(α) = α + ᾱ = 2a`
- Minimal polynomial: `x² - Tr(α)·x + N(α)`

```ruby
var alpha = Quadratic(3, 4, 5)   # 3 + 4√5

say alpha.norm            # 9 - 80 = -71
say alpha.conj            # Quadratic(3, -4, 5)  — conjugate ᾱ = 3 - 4√5
say (alpha + alpha.conj)  # Quadratic(6, 0, 5)   — trace = 6
say (alpha * alpha.conj)  # Quadratic(-71, 0, 5) — norm as a Quadratic = -71

# The minimal polynomial of alpha is x² - 6x - 71
# Verify: alpha² - 6*alpha - 71 = 0
var min_poly = Polynomial([1, -6, -71])    # x² - 6x - 71
say min_poly.eval(alpha.to_n)              # ≈ 0  ✓

# Norm is multiplicative: N(αβ) = N(α)·N(β)
var beta  = Quadratic(1, 2, 5)
say ((alpha * beta).norm == alpha.norm*beta.norm)   # true
```

---

### The Pell Equation in Depth

The **Pell equation** `x² - dy² = 1` (and its negative variant `x² - dy² = -1`) is one of the oldest problems in number theory. Its solutions are exactly the powers of the fundamental unit in `Q(√d)`.

```ruby
# All solutions to x² - 2y² = ±1 come from powers of (1+√2)
var u = Quadratic(1, 1, 2)

for n in (1..8) {
    var power = u**n
    var (x, y) = power.reals
    var norm   = power.norm    # alternates -1, +1, -1, +1, ...
    say "n=#{n}: x=#{x}, y=#{y}, x²-2y²=#{norm}"
}
# n=1: x=1,   y=1,   x²-2y² = -1
# n=2: x=3,   y=2,   x²-2y² =  1
# n=3: x=7,   y=5,   x²-2y² = -1
# n=4: x=17,  y=12,  x²-2y² =  1
# n=5: x=41,  y=29,  x²-2y² = -1
# n=6: x=99,  y=70,  x²-2y² =  1
# n=7: x=239, y=169, x²-2y² = -1
# n=8: x=577, y=408, x²-2y² =  1

# Solutions to x² - 5y² = ±1 and ±4 (from Q(√5))
var v = Quadratic(1, 1, 5)   # 1 + √5, norm = -4
say v**1    # norm -4 (solution to x² - 5y² = -4)
say v**2    # Quadratic(6, 2, 5),  norm = 36 - 20 = 16... hmm, not ±1
# The fundamental unit of Z[√5] is (1+√5)/2 with norm -1
var phi = Quadratic(1/2, 1/2, 5)
say phi.norm    # -1  (solution to the Pell-like equation)
say phi**2      # Quadratic(3/2, 1/2, 5), norm = 1 — first positive solution

# Pell equation x² - 13y² = 1
var u13 = Quadratic(649, 180, 13)   # fundamental solution (known)
say u13.norm   # 649² - 13·180² = 421201 - 421200 = 1  ✓
```

#### Using Pell Solutions for Rational Approximations of √d

Each solution `(xₙ, yₙ)` gives a best rational approximation `xₙ/yₙ ≈ √d`:

```ruby
var u = Quadratic(1, 1, 2)    # fundamental unit of Q(√2)

for n in (1..6) {
    var power = u**n
    var (x, y) = power.reals
    say "#{x}/#{y} ≈ √2  (error: #{(x/y - 2.sqrt).abs})"
}
# 1/1    ≈ √2  (error: 0.414...)
# 3/2    ≈ √2  (error: 0.086...)
# 7/5    ≈ √2  (error: 0.014...)
# 17/12  ≈ √2  (error: 0.002...)
# 41/29  ≈ √2  (error: 0.0003...)
# 99/70  ≈ √2  (error: 0.00005...)
```

---

### Factorization of Rational Primes in Quadratic Fields

A rational prime `p` can behave in three distinct ways when "viewed" in the ring of integers of `Q(√d)`, determined by the **Legendre symbol** `(d/p)`:

| `(d/p)` | Behavior | Example |
|---|---|---|
| `+1` | **Split**: `p = π · π̄` into two distinct conjugate primes | `5 = (2+i)(2-i)` in `Z[i]` |
| `-1` | **Inert**: `p` remains prime | `3` stays prime in `Z[i]` |
| `0` | **Ramified**: `p = u · π²` (p divides discriminant) | `2 = -i(1+i)²` in `Z[i]` |

```ruby
# Factorization in Z[i] = Q(√-1)
# A rational prime p splits iff p ≡ 1 (mod 4), is inert iff p ≡ 3 (mod 4)

say Gauss(5, 0).factor   # 5 = (2+i)(2-i) — splits (5 ≡ 1 mod 4) ✓
say Gauss(13,0).factor   # 13 = (3+2i)(3-2i) — splits (13 ≡ 1 mod 4) ✓
say Gauss(3, 0).factor   # 3 stays inert (3 ≡ 3 mod 4) ✓
say Gauss(7, 0).factor   # 7 stays inert (7 ≡ 3 mod 4) ✓
say Gauss(2, 0).factor   # 2 = -i(1+i)² — ramified (2 | disc(Z[i]))  ✓

# Verify the split: 5 = (2+i)(2-i)
var pi  = Gauss(2, 1)
var pic = Gauss(2,-1)
say (pi * pic)            # Gauss(5, 0)  ✓
say pi.is_prime           # true — 2+i is a Gaussian prime
say pic.is_prime          # true

# Norm check: a Gaussian integer π is prime iff norm(π) is a rational prime
say pi.norm   # 4 + 1 = 5  — prime ✓

# Building Gaussian primes over all split primes up to 50
[5, 13, 17, 29, 37, 41].each { |p|
    # For p ≡ 1 (mod 4), find a,b with a²+b²=p by factoring Gauss(p,0)
    say "#{p} = #{Gauss(p, 0).factor}"
}
```

#### Splitting in Real Quadratic Fields

```ruby
# In Q(√5): p splits iff (5/p) = 1, i.e. p ≡ ±1 (mod 5)
# p = 11: 11 ≡ 1 (mod 5) — should split
# We need a,b with a² - 5b² = ±11
# Try: 4² - 5·1² = 16 - 5 = 11 ✓
var pi11 = Quadratic(4, 1, 5)
var pi11c = pi11.conj    # Quadratic(4, -1, 5)
say (pi11 * pi11c)       # Quadratic(11, 0, 5) = 11  ✓
say pi11.norm            # 16 - 5 = 11  ✓

# p = 19: 19 ≡ 4 (mod 5) — should split  ((5/19): 5^9 mod 19 = 1 ✓)
var pi19 = Quadratic(9, 4, 5)    # 9² - 5·4² = 81-80 = 1... hmm
# Let's try: norms that equal 19: a²-5b²=19 → a=3,b=-2: 9-20 ≠ 19
# Use powmod to probe: compute Mod(5, 19).sqrt to find the split
say Mod(5, 19).sqrt    # if it exists, p splits

# p = 3: 3 ≡ 3 (mod 5) — inert, stays prime in Q(√5)
var p3 = Quadratic(3, 0, 5)
say p3.norm             # 9  — not prime, but Quadratic(3,0,5) represents the
                        # rational prime 3, which stays irreducible in Z[φ]
```

---

### Fermat's Two-Square Theorem via Gaussian Integers

Every prime `p ≡ 1 (mod 4)` is a sum of two squares: `p = a² + b²`. The Gaussian integer proof is algorithmic and directly computable with the `Gauss` type.

```ruby
# Theorem: p = a² + b² ⟺ p = 2 or p ≡ 1 (mod 4)
# Proof strategy: find x with x² ≡ -1 (mod p), then gcd(x+i, p) in Z[i]

func two_squares(p) {
    # Step 1: find x such that x² ≡ -1 (mod p)
    var x = Mod(-1, p).sqrt.lift

    # Step 2: compute gcd(x+i, p) in the Gaussian integers
    var g = Gauss(x, 1).gcd(Gauss(p, 0))

    var (a, b) = g.parts.map{.abs}...
    say "#{p} = #{a}² + #{b}² = #{a*a} + #{b*b}"
}

two_squares(5)    # 5  = 1² + 2² = 1 + 4
two_squares(13)   # 13 = 2² + 3² = 4 + 9
two_squares(17)   # 17 = 1² + 4² = 1 + 16
two_squares(29)   # 29 = 2² + 5² = 4 + 25
two_squares(37)   # 37 = 1² + 6² = 1 + 36
two_squares(41)   # 41 = 4² + 5² = 16 + 25
two_squares(53)   # 53 = 2² + 7² = 4 + 49
two_squares(61)   # 61 = 5² + 6² = 25 + 36
two_squares(97)   # 97 = 4² + 9² = 16 + 81
two_squares(101)  # 101 = 1² + 10² = 1 + 100
```

#### Composing Two-Square Representations (Brahmagupta–Fibonacci Identity)

```ruby
# (a²+b²)(c²+d²) = (ac-bd)² + (ad+bc)²
# This is just multiplication of Gaussian integers!

var z1 = Gauss(2, 3)   # norm = 4+9  = 13
var z2 = Gauss(1, 4)   # norm = 1+16 = 17
var z3 = (z1 * z2)

var (a, b) = z3.parts.map{.abs}...
say "13 * 17 = 221 = #{a}² + #{b}² = #{a*a} + #{b*b}"
# 221 = 10² + 11² (since (2+3i)(1+4i) = 2+8i+3i+12i² = -10+11i)

# OR use the conjugate product:
var z4 = (z1 * z2.conj)
var (c, d) = z4.parts.map{.abs}...
say "221 = #{c}² + #{d}² = #{c*c} + #{d*d}"

# Both representations of 221 as a sum of two squares appear this way
```

---

### Euler's Four-Square Theorem via Quaternions

Every positive integer is a sum of four perfect squares (Lagrange's four-square theorem). Quaternion arithmetic provides the constructive proof.

```ruby
# Quaternion norm identity (Euler):
# (a₁²+b₁²+c₁²+d₁²)(a₂²+b₂²+c₂²+d₂²) = N(q₁·q₂)

func four_squares_product(q1, q2) {
    var prod = (q1 * q2)
    var (a, b, c, d) = prod.reals
    say "N(q1)*N(q2) = #{q1.norm}*#{q2.norm} = #{prod.norm}"
    say "= #{a}² + #{b}² + #{c}² + #{d}²"
}

four_squares_product(Quaternion(1,1,1,1), Quaternion(1,2,2,1))
# 4 * 10 = 40 = (1·1 - 1·2 - 1·2 - 1·1)² + ...

# Expressing numbers as four squares
# 7 = 2² + 1² + 1² + 1²
var q7 = Quaternion(2, 1, 1, 1)
say q7.norm    # 4+1+1+1 = 7  ✓

# 15 = 3² + 2² + 1² + 1²
var q15 = Quaternion(3, 2, 1, 1)
say q15.norm   # 9+4+1+1 = 15  ✓

# The norm being multiplicative means:
# if we can write p and q as four squares, their product is also four squares
var qa = Quaternion(2, 1, 1, 1)   # norm 7
var qb = Quaternion(3, 1, 1, 0)   # norm 11
say ((qa * qb).norm)    # 77 = 7 * 11
var (a, b, c, d) = (qa * qb).reals
say "77 = #{a}²+#{b}²+#{c}²+#{d}² = #{a**2}+#{b**2}+#{c**2}+#{d**2}"
```

---

### Hurwitz Quaternions and Integer Factorization

The **Hurwitz quaternions** — quaternions `a + bi + cj + dk` where `a,b,c,d` are either all integers or all half-integers — form the maximal order in the rational quaternion algebra ramified at 2 and ∞. They have unique factorization up to units.

```ruby
# The 24 units of the Hurwitz order include the 8 standard units and 16 half-integer units.
# Standard units: ±1, ±i, ±j, ±k
[Quaternion(1,0,0,0), Quaternion(-1,0,0,0),
 Quaternion(0,1,0,0), Quaternion(0,-1,0,0),
 Quaternion(0,0,1,0), Quaternion(0,0,-1,0),
 Quaternion(0,0,0,1), Quaternion(0,0,0,-1)].each {|u|
    say "#{u.dump}  norm=#{u.norm}"   # all have norm 1
}

# Factoring a prime p as a quaternion norm (Jacobi's four-square count)
# The number of ways to write n = a²+b²+c²+d² is 8·Σ_{d|n, 4∤d} d
var p = 5
var q = Quaternion(2, 1, 0, 0)    # 2²+1²+0²+0² = 5
say q.norm        # 5  ✓
say (q * q.conj)  # Quaternion(5,0,0,0) — norm via conjugate product

# Quaternion GCD (left and right GCDs differ for non-commutative ring)
var q1 = Quaternion(2, 1, 3, 0)
var q2 = Quaternion(1, 0, 1, 1)
# Use norm to find a rational common factor
say q1.norm   # 14
say q2.norm   # 3
# gcd(14, 3) = 1 — coprime norms imply coprime quaternions
say q1.is_coprime(q2)    # true
```

---

### Norm Equations and Diophantine Applications

Many classical Diophantine equations reduce to norm equations `N(α) = n` in a suitable ring of integers.

#### Sum of Two Squares: N(a + bi) = n in Z[i]

```ruby
# Solve a² + b² = n by factoring n in Z[i]
func sum_of_two_squares(n) {
    var g = Gauss(n, 0)
    if (g.is_prime) {
        say "#{n} is a Gaussian prime — cannot be written as sum of two non-trivial squares"
    }
    else {
        say "Gaussian factorization of #{n}:"
        g.factor.each { say ("  " + _.pretty) }
    }
}

sum_of_two_squares(25)   # = (2+i)²(2-i)² — check: 3²+4²=25, 5²+0²=25
sum_of_two_squares(50)   # = 1²+7², 5²+5²
sum_of_two_squares(65)   # = 1²+8², 4²+7² (two distinct representations)

# Count representations: relates to class number
var reps_65 = 0
for a in (0..8) {
    for b in (a..8) {
        if (a*a + b*b == 65) { ++reps_65; say "65 = #{a}²+#{b}²" }
    }
}
```

#### Norm Equations in Q(√-5): Failure of Unique Factorization

```ruby
# In Z[√-5], norm N(a+b√-5) = a² + 5b²
# The ideal (2) = P·P̄  where P=(2, 1+√-5), P̄=(2, 1-√-5) are non-principal ideals

var alpha = Quadratic(1, 1, -5)    # 1 + √-5
var beta  = Quadratic(1, -1, -5)   # 1 - √-5

say alpha.norm      # 1 + 5 = 6
say beta.norm       # 1 + 5 = 6
say (alpha * beta)  # Quadratic(6, 0, -5) = 6

# Both 2 and 3 are "irreducible" in Z[√-5] but NOT prime (they don't satisfy
# the prime divisibility property π|αβ ⟹ π|α or π|β)
var two   = Quadratic(2, 0, -5)
var three = Quadratic(3, 0, -5)
say two.norm    # 4  — irreducible (no element has norm 2 in Z[√-5])
say three.norm  # 9  — irreducible (no element of norm 3 exists in Z[√-5])

# Demonstrate non-unique factorization:
# 6 = 2·3 = (1+√-5)(1-√-5)  — two genuinely different factorizations
say (two * three)   # Quadratic(6, 0, -5)  ✓
say (alpha * beta)  # Quadratic(6, 0, -5)  ✓  (same product, different factors!)
```

#### Pythagorean Triples via Gaussian Integers

```ruby
# Every primitive Pythagorean triple (a,b,c) with a²+b²=c² comes from
# a Gaussian integer z = m+ni with c = N(z) = m²+n², gcd(m,n)=1, m≢n mod 2
# then a = m²-n², b = 2mn  (or swapped)

func pythagorean_triple(m, n) {
    var z = Gauss(m, n)
    var c = z.norm
    var a = (m*m - n*n)
    var b = 2*m*n
    say "(#{a}, #{b}, #{c}): #{a}²+#{b}²=#{a**2 + b**2}, c²=#{c**2}"
}

pythagorean_triple(2, 1)    # (3, 4, 5)
pythagorean_triple(3, 2)    # (5, 12, 13)
pythagorean_triple(4, 1)    # (15, 8, 17)
pythagorean_triple(4, 3)    # (7, 24, 25)
pythagorean_triple(5, 2)    # (21, 20, 29)
pythagorean_triple(5, 4)    # (9, 40, 41)

# Gaussian product formula for combining triples:
var z1 = Gauss(2, 1)   # gives (3,4,5)
var z2 = Gauss(3, 2)   # gives (5,12,13)
var z3 = (z1 * z2)     # Gauss(4, 7)  — gives (4²-7², 2·4·7, 4²+7²)
var (re, im) = z3.parts...
say "(#{re*re - im*im}, #{2*re*im}, #{z3.norm})"  # a new triple!
```

---

### Cyclotomic Fields via PolynomialMod

The **cyclotomic field** `Q(ζₙ)` is generated by a primitive `n`-th root of unity `ζₙ`, satisfying the cyclotomic polynomial `Φₙ(x) = 0`. In Sidef, this is modeled by `PolynomialMod` with modulus `Φₙ(x)`.

```ruby
# The n-th cyclotomic polynomial Φₙ(x) can be evaluated with .cyclotomic
# Φ₁(x) = x-1,  Φ₂(x) = x+1,  Φ₃(x) = x²+x+1,  Φ₄(x) = x²+1
# Φ₅(x) = x⁴+x³+x²+x+1,  Φ₆(x) = x²-x+1

# Q(ζ₃): cube roots of unity, Φ₃(x) = x²+x+1
# ζ₃ satisfies ζ³ = 1 and ζ²+ζ+1 = 0 — these are the Eisenstein integers!
var zeta3 = PolynomialMod([1,0], [1, 1, 1])   # ζ₃ in Q[x]/(x²+x+1)

say zeta3**1   # ζ
say zeta3**2   # ζ²  (= -ζ-1 after reduction)
say zeta3**3   # 1   — ζ₃ has order 3 ✓
say zeta3**6   # 1

# Sum of all primitive 3rd roots of unity = -1 (coefficient of x in Φ₃)
say (zeta3 + zeta3**2)   # should equal -1
# ζ + ζ² = -1  (from Φ₃: ζ²+ζ+1=0 → ζ+ζ² = -1) ✓

# Q(ζ₄) = Q(i): 4th roots of unity, Φ₄(x) = x²+1
var zeta4 = PolynomialMod([1, 0], [1, 0, 1])   # i in Q[x]/(x²+1)
say zeta4**1   # i
say zeta4**2   # -1  ✓
say zeta4**4   # 1   ✓

# Q(ζ₅): 5th roots of unity, Φ₅(x) = x⁴+x³+x²+x+1 (degree 4)
var zeta5 = PolynomialMod([1, 0], [1, 1, 1, 1, 1])
say zeta5**5   # 1  ✓
say (zeta5**4 + zeta5**3 + zeta5**2 + zeta5 + PolynomialMod([1],[1,1,1,1,1]))
# = 0  (since ζ satisfies Φ₅) ✓

# Q(ζ₈): 8th roots of unity, Φ₈(x) = x⁴+1 — contains √2 and i!
var zeta8 = PolynomialMod([1, 0], [1, 0, 0, 0, 1])
say zeta8**2    # ζ₈² = ζ₄ = i  (since (e^{2πi/8})² = e^{2πi/4})
say zeta8**4    # -1  ✓
say zeta8**8    # 1   ✓
# √2 = ζ₈ + ζ₈⁷ = ζ₈ + ζ₈⁻¹ (real part of ζ₈ doubled)
say (zeta8 + zeta8**7)   # represents √2 in this ring
```

#### Galois Action on Cyclotomic Fields

```ruby
# The Galois group Gal(Q(ζₙ)/Q) ≅ (Z/nZ)* acts by ζₙ ↦ ζₙᵏ, gcd(k,n)=1

# For Q(ζ₅)/Q: Gal ≅ (Z/5Z)* = {1,2,3,4} ≅ Z/4Z — cyclic of order 4
var mod5 = [1, 1, 1, 1, 1]   # Φ₅(x)
var zeta = PolynomialMod([1, 0], mod5)

# The four Galois automorphisms σₖ: ζ ↦ ζᵏ
for k in (1, 2, 3, 4) {
    var image = zeta**k
    say "σ_#{k}(ζ) = ζ^#{k} = #{image.pretty}"
}

# The quadratic subfield of Q(ζ₅) is Q(√5) — fixed by σ₄ (complex conjugation)
# √5 = 2ζ+2ζ⁴+1  (a known algebraic identity)
var sqrt5_rep = (zeta*2 + (2 * zeta**4) + PolynomialMod([1], mod5))
say sqrt5_rep**2   # should equal 5  (the constant polynomial 5)

__END__
σ_1(ζ) = ζ^1 = x (mod x^4 + x^3 + x^2 + x + 1)
σ_2(ζ) = ζ^2 = x^2 (mod x^4 + x^3 + x^2 + x + 1)
σ_3(ζ) = ζ^3 = x^3 (mod x^4 + x^3 + x^2 + x + 1)
σ_4(ζ) = ζ^4 = -x^3 - x^2 - x - 1 (mod x^4 + x^3 + x^2 + x + 1)
```

---

### Algebraic Extensions and Minimal Polynomials

A minimal polynomial of an algebraic number `α` over `Q` is the monic polynomial of least degree with rational coefficients having `α` as a root. The `Polynomial` type lets us compute and verify these directly.

```ruby
# Minimal polynomial of √2 + √3 over Q  (degree 4)
# If α = √2 + √3, then α - √3 = √2, so (α-√3)² = 2
# α² - 2α√3 + 3 = 2, so α² + 1 = 2α√3, squaring: (α²+1)² = 12α²
# α⁴ + 2α² + 1 = 12α²  →  α⁴ - 10α² + 1 = 0

var min_poly_alpha = Polynomial([1, 0, -10, 0, 1])   # x⁴ - 10x² + 1
var alpha_val = (2.sqrt + 3.sqrt)                        # numerical value
say min_poly_alpha.eval(alpha_val)   # ≈ 0  ✓
say min_poly_alpha.roots             # ±√2±√3 (all four conjugates)
say min_poly_alpha.is_squarefree     # true — no repeated roots ✓

# Minimal polynomial of the golden ratio φ = (1+√5)/2
# φ satisfies x² - x - 1 = 0
var min_poly_phi = Polynomial([1, -1, -1])    # x² - x - 1
say min_poly_phi.roots    # [(1+√5)/2, (1-√5)/2]  ✓
say min_poly_phi.eval(1/2 + 5.sqrt/2)  # ≈ 0  ✓

# Minimal polynomial of a primitive cube root of unity ω = (-1+√-3)/2
# ω satisfies x² + x + 1 = 0  (the 3rd cyclotomic polynomial)
var min_poly_omega = Polynomial([1, 1, 1])
say min_poly_omega.roots    # [(-1+√-3)/2, (-1-√-3)/2]  ✓

# Degree of Q(α) over Q equals the degree of the minimal polynomial
say min_poly_alpha.deg    # 4 — [Q(√2+√3) : Q] = 4
say min_poly_phi.deg      # 2 — [Q(φ) : Q] = 2 = [Q(√5) : Q]
```

---

### The Frobenius Endomorphism in Finite Fields

In `GF(pⁿ) = GF(p)[x]/(f(x))`, the **Frobenius** map `φ: α ↦ αᵖ` is the fundamental automorphism. Its order equals the degree of the field extension.

```ruby
# GF(2³) = GF(2)[x]/(x³+x+1) — an irreducible cubic over GF(2)
# Elements are polynomials a+bx+cx² with a,b,c in {0,1}
# Frobenius: α ↦ α²

var f = [1, 0, 1, 1]   # x³ + x + 1  over GF(2) (coefficients mod 2)
var alpha = PolynomialMod([1, 0], f)   # generator α

say alpha**1    # α
say alpha**2    # α² (Frobenius image)
say alpha**4    # α⁴ = (α²)²  (Frobenius squared)
say alpha**8    # α⁸ = α⁸ mod (x³+x+1)

# Frobenius has order 3: α → α² → α⁴ → α⁸ = α (since α⁷=1 in GF(8)*)
# Verify: α⁷ = 1 in GF(8)* (multiplicative group has order 2³-1=7)
say alpha**7    # should be 1  ✓

# Minimal polynomial of α over GF(2) factors xⁿ-x over GF(2ⁿ)
# The Frobenius orbit of α is {α, α², α⁴}
# So min poly of α = (x-α)(x-α²)(x-α⁴) = x³+x+1  (as expected)
say "Frobenius orbit: α, α², α⁴ are the 3 roots of x³+x+1 over GF(2)"

# GF(3²) = GF(3)[x]/(x²+1) — irreducible over GF(3) since -1 is not a square mod 3
var g = [1, 0, 1]    # x² + 1 over GF(3)
var beta = PolynomialMod([1, 0], g)
say beta**3     # Frobenius image β³ in GF(9)
say beta**9     # β⁹ = β  (Frobenius has order 2) — back to start ✓
say beta**8     # 1  (|GF(9)*| = 8)  ✓
```

---

### Quadratic Residues and the Legendre Symbol

The **Legendre symbol** `(a/p)` tells whether `a` is a quadratic residue mod the prime `p`. This is the key to understanding which primes split in a given quadratic field.

```ruby
# Euler's criterion: (a/p) ≡ a^((p-1)/2) mod p
# Mod.sqrt returns a result iff (a/p) = 1

func legendre(a, p) {
    Mod(a, p) ** ((p-1)/2)
}

# Check which numbers are QRs mod 7
for a in (1..6) {
    var sym = legendre(a, 7)
    say ("#{a} is " + (sym == Mod(1,7) ? "a QR" : "a NQR") + " mod 7")
}
# QRs mod 7 are: 1 (=1²), 2 (=3²), 4 (=2²) — exactly (7-1)/2 = 3 residues ✓

# Law of Quadratic Reciprocity: (p/q)(q/p) = (-1)^{(p-1)(q-1)/4}
func qr_test(p, q) {
    var pq = legendre(p, q).to_n
    var qp = legendre(q, p).to_n
    say "(#{p}/#{q}) = #{pq == 1 ? 1 : -1},  (#{q}/#{p}) = #{qp == 1 ? 1 : -1}"
}
qr_test(3, 5)     # (3/5) = -1, (5/3) = -1, product = +1
qr_test(3, 7)     # (3/7) = -1, (7/3) = +1, product = -1
qr_test(5, 7)     # (5/7) = -1, (7/5) = -1, product = +1
qr_test(5, 11)    # (5/11) = +1, (11/5) = +1, product = +1

# Connection to splitting: p splits in Q(√d) iff (d/p) = 1
func splits_in(p, d) {
    var sym = legendre(d % p, p)
    sym.to_n == 1
}
say splits_in(5, 3)    # Does 5 split in Q(√3)? (3/5) = ?
say splits_in(7, -1)   # Does 7 split in Q(i)? No: 7 ≡ 3 mod 4
say splits_in(13, -1)  # Does 13 split in Q(i)? Yes: 13 ≡ 1 mod 4
```

---

### Modular Arithmetic in Algebraic Number Fields

The `powmod` and `invmod` methods on `Quadratic`, `Gauss`, and `Quaternion` implement modular arithmetic in their respective rings of integers, which underpins several cryptographic and number-theoretic algorithms.

```ruby
# Modular arithmetic in Z[i] mod p
# For p ≡ 1 (mod 4), Z[i]/(p) ≅ GF(p) × GF(p) (ring splits)
# For p ≡ 3 (mod 4), Z[i]/(p) ≅ GF(p²)        (ring is a field)

var z = Gauss(3, 4)
var p = 13    # 13 ≡ 1 mod 4  — Z[i]/(13) is NOT a field

say z.powmod(12, 13)    # z^12 mod 13 — should be 1 if z is a unit mod 13
say z.invmod(13)        # inverse of 3+4i mod 13

# Verify: z * z.invmod(13) ≡ 1 mod 13
var inv = z.invmod(13)
say ((z * inv) % 13)    # Gauss(1, 0)  ✓

# Quadratic field arithmetic mod p is fundamental to elliptic curve cryptography
# and the Miller-Rabin primality test over extensions
var q = Quadratic(3, 4, 5)
var large_n = 1000000007   # a prime

say q.powmod(large_n - 1, large_n)   # Fermat-like test in Q(√5)

# Computing Fibonacci numbers via Quadratic powers
func fib_via_quadratic(n) {
    var phi = (1 + sqrtQ(5))/2
    (phi**n - phi**-n) / sqrtQ(5)
}

say fib_via_quadratic(100)      #=> Quadratic(354224848179261915075, 0, 5)
```

---

### Discriminants and Different

The **discriminant** of a number field measures the ramification and is a fundamental invariant. For `Q(√d)` with `d` square-free:

- `Δ = d` if `d ≡ 1 (mod 4)`
- `Δ = 4d` if `d ≡ 2` or `3 (mod 4)`

A prime `p` ramifies in `Q(√d)` iff `p | Δ`.

```ruby
# Computing the discriminant of x² - d (the minimal polynomial of √d)
# disc(f) = (-1)^(n(n-1)/2) * Res(f, f') / lc(f)
# For f = x² - d: disc = 4d

func quadratic_disc(d) {
    var f  = Polynomial([1, 0, -d])    # x² - d
    var df = f.derivative               # 2x
    # Discriminant via resultant or directly:
    say "disc(Q(√#{d})) = #{(d % 4 == 1) ? d : 4*d}"
    say "Ramified primes divide: #{(d % 4 == 1) ? d : 4*d}"
}

quadratic_disc(2)    # disc = 8  — ramified at 2 only
quadratic_disc(3)    # disc = 12 — ramified at 2 and 3
quadratic_disc(5)    # disc = 5  — ramified at 5 only
quadratic_disc(-1)   # disc = -4 — ramified at 2 (Gaussian integers)
quadratic_disc(-3)   # disc = -3 — ramified at 3 (Eisenstein integers)
quadratic_disc(-5)   # disc = -20 — ramified at 2 and 5

# The discriminant controls which primes can ramify.
# For the cyclotomic field Q(ζₚ): discriminant = ±p^(p-2)
# All and only the prime p ramifies

# Polynomials with repeated roots have discriminant 0
var rep = Polynomial([1, -2, 1])    # (x-1)² — discriminant = 0
say rep.is_squarefree     # false  ✓
say rep.gcd(rep.derivative)   # x - 1  (the repeated factor)
```

---

### Lifting and the Hensel Lemma

**Hensel's lemma** allows lifting solutions of polynomial congruences from `mod p` to `mod pⁿ`. The interplay between `Polynomial`, `PolynomialMod`, and `Mod` makes this algorithmic.

```ruby
# Hensel lifting: if f(a) ≡ 0 (mod p) and f'(a) ≢ 0 (mod p),
# we can lift to a solution mod p²:  a₁ = a - f(a)/f'(a) mod p²
# (Newton's method over p-adic integers!)

func hensel_lift(f, a0, p, steps) {
    var a = a0
    var modulus = p
    var df = f.derivative

    for _ in (1..steps) {
        modulus *= p   # p → p² → p³ → ...
        var fa  = Mod(f.eval(a), modulus)
        var dfa = Mod(df.eval(a), modulus)
        a = (Mod(a, modulus) - fa * dfa.inv).to_n
        say "mod #{modulus}: a ≡ #{a}"
    }
    a
}

# Lift a root of x² - 2 from mod 7 to mod 7⁴
# x² ≡ 2 (mod 7): x ≡ 3 or 4 (mod 7)  [since 3²=9≡2]
var f = Polynomial([1, 0, -2])   # x² - 2
hensel_lift(f, 3, 7, 4)
# mod 49:   a ≡ ?  (lifts 3 mod 7 to a root mod 49)
# mod 343:  a ≡ ?
# mod 2401: a ≡ ?
# This computes the 7-adic expansion of √2!

# Hensel over Gaussian integers: lift a Gaussian root of f(z) ≡ 0 mod p
# (used in algorithms for factoring polynomials over number fields)
```

---

### The Structure of Units in Quadratic Orders

```ruby
# Dirichlet's unit theorem: rank of the unit group of O_K is r₁+r₂-1
# where r₁ = real embeddings, r₂ = pairs of complex embeddings
# For Q(√d) with d>0: r₁=2, r₂=0 → rank = 1  (one fundamental unit)
# For Q(√d) with d<0: r₁=0, r₂=1 → rank = 0  (only roots of unity)

# Imaginary quadratic fields: finite unit group
# Q(√-1): units = {1, -1, i, -i}  — 4 units
# Q(√-3): units = {±1, ±ω, ±ω²}  — 6 units  (where ω is a primitive cube root)
# All others: units = {1, -1}     — 2 units

# Verify units in Q(√-1) — elements of norm 1
[Quadratic(1,0,-1), Quadratic(-1,0,-1), Quadratic(0,1,-1), Quadratic(0,-1,-1)].each {|u|
    say "#{u.pretty}: norm=#{u.norm}, is_unit=#{u.norm.abs == 1}"
}

# Verify units in Q(√-3) — the Eisenstein integers
# ω = (-1+√-3)/2 has norm = 1/4 + 3/4 = 1 ✓
var omega = Quadratic(-1/2, 1/2, -3)
say omega.norm    # 1  — ω is a unit ✓
say omega**2      # ω² = (-1-√-3)/2  — another unit ✓
say omega**3      # 1  — ω has order 3 ✓
say omega**6      # 1  ✓

# Real quadratic field Q(√2): units = ±(1+√2)ⁿ for n ∈ Z
var eps = Quadratic(1, 1, 2)    # fundamental unit
say eps.norm      # -1  — unit of norm -1

# The regulator of Q(√d) is log|ε| where ε is the fundamental unit
# Larger regulator means more spread-out units
var eps5  = Quadratic(1/2, 1/2, 5)   # fundamental unit of Q(√5)
var eps13 = Quadratic(649, 180, 13)  # fundamental unit of Q(√13) — much larger!
say eps5.to_n     # ≈ 1.618  (golden ratio)
say eps13.to_n    # ≈ 649 + 180·√13 — very large regulator
```

---

### Ideal Arithmetic via Quadratic Integers

In rings where unique factorization of *elements* fails (like `Z[√-5]`), unique factorization of **ideals** is restored (Kummer, Dedekind). We can simulate ideal arithmetic using norms and the `Quadratic` type.

```ruby
# In Z[√-5], the ideal (2) = P·P̄ where:
# P  = (2, 1+√-5)  — norm(P) = 2
# P̄  = (2, 1-√-5)  — norm(P̄) = 2
# The ideal (6) = P²·P̄²·Q·Q̄ where Q=(3,1+√-5), Q̄=(3,1-√-5)

# Elements of norm p in Z[√-5] (if they exist) generate prime ideals
# N(a + b√-5) = a² + 5b²

# Searching for elements of small norm
for a in (0..6) {
    for b in (0..3) {
        var n = (a*a + 5*b*b)
        if (n <= 20) {
            say "N(#{a}+#{b}√-5) = #{n}"
        }
    }
}
# Norm 1: (1,0) — unit
# Norm 4: (2,0) — but NOT a product of elements of norm 2!
# Norm 6: (1,1) and (1,-1) — elements of norm 6, product = 6 via alpha*alpha.conj
# Norm 9: (3,0) and (2,1)
# There is NO element of norm 2 or norm 3 in Z[√-5] — ideal divisors are not principal!

# The class group of Z[√-5] has order 2 (class number h(-20) = 2)
# This means every ideal squared is principal

# (P)² is principal: P² = (2, 1+√-5)² = ?
# One generator of P² is any element of norm 4 in P
# Since 2² = 4 and N(2) = 4, we have P² = (2)  in the ideal sense? No...
# Actually in Z[√-5]: ideal arithmetic requires tracking cosets

# Practical approach: use norm arithmetic to detect ideal classes
func ideal_norm(a, b, d) { a*a - d*b*b }   # norm in Z[√d]
say ideal_norm(1, 1, -5)    # 6 — not a prime ideal generator
say ideal_norm(2, 0, -5)    # 4 = 2² — the square of the ideal (2)
```

---

### Modular Forms and Theta Series (Counting Representations)

The number of ways to write `n = a² + b²` (or as other quadratic forms) is given by a modular form. We can compute these counts directly.

```ruby
# r₂(n): number of ways to write n = a² + b² (counting signs and order)
# r₂(n) = 4(d₁(n) - d₃(n)) where d₁,d₃ count divisors ≡ 1,3 mod 4

func r2(n) {
    squares_r(n, 2)
}

for n in (1..20) {
    say "r₂(#{n}) = #{r2(n)}"
}
# r₂(1)=4, r₂(2)=4, r₂(4)=4, r₂(5)=8, r₂(10)=8, r₂(25)=12...
# This matches 4*(#div≡1 mod 4 - #div≡3 mod 4)

# Theta function identity: Σ r₂(n) qⁿ = (Σ qⁿ²)²
# The square of the theta series — connection to elliptic functions

# Similarly, r₄(n): number of ways to write n as sum of 4 squares
# r₄(n) = 8 * Σ_{d|n, 4∤d} d  (Jacobi's formula)
func r4_jacobi(n) {
    8 * n.divisors.grep{|d| d % 4 != 0}.sum
}

for n in (1..10) {
    say "r₄(#{n}) = #{r4_jacobi(n)}"
}
# r₄(1)=8 (the 8 quaternion units: ±1,±i,±j,±k  have norm 1)
# r₄(2)=24, r₄(3)=32, ...
```

---

### Extended GCD in Polynomial Rings (Bézout Coefficients)

The extended Euclidean algorithm over polynomial rings is the foundation of rational function partial fractions, the Berlekamp-Welch algorithm, and algebraic decoding.

```ruby
# gcdext(f, g) returns (d, s, t) with s*f + t*g = d
var f = Polynomial([1, 0, -1])    # x² - 1 = (x-1)(x+1)
var g = Polynomial([1, -1])       # x - 1

var (d, s, t) = f.gcdext(g)
say "gcd = #{d.pretty}"           # x - 1
say "s   = #{s.pretty}"           # 0 (coefficient polynomial)
say "t   = #{t.pretty}"           # 1
# Verify: s*(x²-1) + t*(x-1) = x-1
say ((s*f + t*g).pretty)          # should equal gcd = x-1

# Partial fraction decomposition via extended GCD
# 1/((x-1)(x+1)) = A/(x-1) + B/(x+1)
# Bézout: s*(x-1) + t*(x+1) = 1  →  s = 1/2, t = -1/2
var p1 = Polynomial([1, -1])   # x - 1
var p2 = Polynomial([1,  1])   # x + 1
var (d2, s2, t2) = p1.gcdext(p2)
say "#{s2.pretty} * (x-1) + #{t2.pretty} * (x+1) = #{d2.pretty}"
# s2 = 1/2, t2 = -1/2 → partial fractions confirmed

# In a polynomial quotient ring, extended GCD gives the modular inverse
var mod_poly = [1, 0, 0, 1]   # x³ + 1
var h = PolynomialMod([1, 1], mod_poly)   # 1 + x  mod  x³+1
var (d3, u3, v3) = h.lift.gcdext(Polynomial(mod_poly))
# u3 * (1+x) + v3 * (x³+1) = gcd = 1  →  u3 is the inverse of (1+x) mod (x³+1)
say "Inverse of (1+x) mod (x³+1): #{u3.pretty}"
say h.inv.pretty   # should match
```

---

## Quick Reference

| Type | Represents | Key Methods |
|---|---|---|
| `Mod(n, m)` | `n mod m` | `inv`, `sqrt`, `znorder`, `fib`, `chinese`, `lucasu`, `cyclotomic` |
| `Gauss(a, b)` | `a + bi` | `norm`, `conj`, `factor`, `is_prime`, `powmod`, `gcd`, `divisors` |
| `Quadratic(a, b, w)` | `a + b√w` | `norm`, `conj`, `inv`, `powmod`, `invmod`, `to_n`, `pretty` |
| `Quaternion(a,b,c,d)` | `a+bi+cj+dk` | `norm`, `conj`, `inv`, `sgn`, `powmod`, `is_coprime` |
| `Polynomial([...])` | `p(x)` | `eval`, `derivative`, `roots`, `gcd`, `gcdext`, `prim_part`, `newton_method` |
| `PolynomialMod([...], [...])` | `p(x) mod m(x)` | `inv`, `gcd`, `gcdext`, `lift`, `modulus`, `derivative` |

All six types support: `+`, `-`, `*`, `/`, `**`, `%`, `==`, `!=`, `neg`, `sqr`, `floor`, `ceil`, `round`, `float`, `is_zero`, `is_one`, `dump`, `pretty`.

### Algebraic Number Theory: Concept Map

| Concept | Sidef type(s) | Key operations |
|---|---|---|
| Ring of integers `O_K` | `Quadratic`, `Gauss` | `norm`, `conj`, `inv` |
| Unique factorization domain | `Gauss` | `factor`, `factor_exp`, `is_prime` |
| Non-UFD (class number > 1) | `Quadratic` with `w=-5` | `norm`, `gcd` |
| Pell equation `x²-dy²=±1` | `Quadratic` | `**`, `norm`, `reals` |
| Two-square theorem | `Gauss` | `factor`, `gcd`, `norm` |
| Four-square theorem | `Quaternion` | `norm`, `*` (multiplicativity) |
| Cyclotomic field `Q(ζₙ)` | `PolynomialMod` | `**`, `inv`, `gcdext` |
| Finite field `GF(pⁿ)` | `PolynomialMod` | `**`, `inv`, `gcd` |
| Frobenius endomorphism | `PolynomialMod` | `**p` (p-th power map) |
| Quadratic residues | `Mod` | `sqrt`, `**((p-1)/2)` |
| Splitting of primes | `Gauss`, `Quadratic` | `is_prime`, `norm`, `factor` |
| CRT / ideal patching | `Mod`, `PolynomialMod` | `chinese` |
| Hensel lifting | `Polynomial`, `Mod` | `eval`, `derivative`, `inv` |
| Bézout / partial fractions | `Polynomial`, `PolynomialMod` | `gcdext` |
