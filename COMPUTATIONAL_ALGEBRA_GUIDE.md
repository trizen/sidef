# Sidef: Computational Algebra & Number Theory

Sidef ships with six built-in algebraic types — **Mod**, **Gauss**, **Quadratic**, **Quaternion**, **Polynomial**, and **PolynomialMod** — that turn modular arithmetic, quadratic fields, quaternions, and polynomial rings into first-class citizens of the language. This guide walks through each type and then shows how they compose to model real algebraic number theory: prime splitting, Pell equations, cyclotomic fields, finite fields, and more.

---

## Table of Contents

1. [Mod — Modular Arithmetic](#mod)
2. [Gauss — Gaussian Integers](#gauss)
3. [Quadratic — Elements of a Quadratic Ring](#quadratic)
4. [Quaternion — Quaternion Numbers](#quaternion)
5. [Polynomial — Univariate Polynomials](#polynomial)
6. [PolynomialMod — Polynomial Quotient Rings](#polynomialmod)
7. [Cross-Type Examples](#cross-type-examples)
8. [Algebraic Number Theory](#algebraic-number-theory)
   - [Rings of Integers](#rings-of-integers)
   - [Quadratic Fields: Real vs Imaginary](#quadratic-fields-real-vs-imaginary)
   - [Norms, Traces, and Minimal Polynomials](#norms-traces-and-minimal-polynomials)
   - [Pell's Equation and Fundamental Units](#pells-equation-and-fundamental-units)
   - [Splitting of Rational Primes](#splitting-of-rational-primes)
   - [Fermat's Two-Square Theorem](#fermats-two-square-theorem)
   - [Euler's Four-Square Theorem](#eulers-four-square-theorem)
   - [Cyclotomic Fields via PolynomialMod](#cyclotomic-fields-via-polynomialmod)
   - [Finite Fields and the Frobenius Endomorphism](#finite-fields-and-the-frobenius-endomorphism)
   - [Quadratic Residues and the Legendre Symbol](#quadratic-residues-and-the-legendre-symbol)
   - [Hensel Lifting](#hensel-lifting)
   - [Bézout Coefficients in Polynomial Rings](#bezout-coefficients-in-polynomial-rings)
9. [Quick Reference](#quick-reference)

---

## Mod

`Mod(n, m)` represents the integer $n$ modulo $m$. Every arithmetic operation automatically reduces the result, which makes this type a natural fit for cryptography, primality testing, and modular sequences.

### Construction & reduction

```ruby
var a = Mod(13, 19)     # 13 mod 19
var b = Mod(-3, 7)      # auto-reduced to Mod(4, 7)
var c = Mod(17, 5)      # auto-reduced to Mod(2, 5)
```

### Arithmetic

```ruby
var a = Mod(13, 19)

a += 15                  # Mod(9, 19)
a *= 99                  # Mod(17, 19)
a /= 17                  # Mod(1, 19)  -- division multiplies by the modular inverse
say a

say (Mod(2, 1000) ** 100) # 2^100 mod 1000, via binary exponentiation
```

### Inverse, square root, and order

```ruby
say Mod(3, 7).inv         # Mod(5, 7)   -- 3*5 == 1 (mod 7)
say Mod(4, 13).sqrt       # Mod(2, 13)  -- 2^2 == 4 (mod 13)
say Mod(2, 7).znorder     # 3           -- smallest k with 2^k == 1 (mod 7)
```

### Chinese Remainder Theorem

```ruby
# x == 2 (mod 3), x == 3 (mod 5), x == 2 (mod 7)
say chinese(Mod(2, 3), Mod(3, 5), Mod(2, 7))   # Mod(23, 105)

say (23 % 3)   # 2
say (23 % 5)   # 3
say (23 % 7)   # 2
```

### Sequences modulo m

```ruby
say Mod(10, 100).fib          # Mod(55, 100)   -- F(10) = 55
say Mod(10, 1000).lucas       # Mod(123, 1000) -- L(10) = 123

say Mod(10, 1000).lucasu(1, -1)   # Fibonacci, expressed as a Lucas U-sequence
say Mod(10, 1000).lucasv(1, -1)   # Lucas numbers, as a Lucas V-sequence

say Mod(2, 100).chebyshevt(5)     # T_5(2) mod 100
say Mod(2, 100).chebyshevu(5)     # U_5(2) mod 100
say Mod(2, 100).cyclotomic(5)     # Phi_5(2) mod 100
```

### Factorial modulo m

```ruby
say Mod(5, 13)!    # Mod(3, 13)  -- 5! = 120 == 3 (mod 13)
```

---

## Gauss

`Gauss(a, b)` represents the Gaussian integer $a + bi$. Gaussian integers form a unique factorization domain, which makes them a computational gateway into algebraic number theory.

### Construction & arithmetic

```ruby
var a = Gauss(17, 19)
var b = Gauss(43, 97)

say (a + b)     # component-wise addition
say (a - b)
say (a * b)     # (pr-qs) + (ps+qr)i
say (a / b)     # a rational-valued result when it doesn't divide evenly
```

### Norm, conjugate, absolute value

```ruby
var z = Gauss(3, 4)

say z.norm       # 25  -- 3^2 + 4^2, the squared magnitude
say z.abs        # 5   -- sqrt(norm)
say z.conj       # Gauss(3, -4)
say z.inv        # conj(z) / norm(z)
say (z * z.conj) # Gauss(25, 0)  -- the norm, expressed as a Gaussian integer
```

### Primality and factorization

```ruby
say Gauss(3, 2).is_prime   # true  -- 3^2+2^2 = 13, a prime == 1 (mod 4)
say Gauss(5, 0).is_prime   # false -- 5 = (2+i)(2-i) in the Gaussian integers

var g = Gauss(120, 84)
say g.factor                # array of Gaussian prime factors
say Gauss(50, 0).factor_exp # [[prime, exponent], ...]
say Gauss(6, 0).divisors    # every Gaussian integer divisor of 6
```

### GCD and coprimality

```ruby
var p = Gauss(8, 4)
var q = Gauss(6, 2)

say p.gcd(q)            # GCD in the Gaussian integers
say p.gcd_norm(q)       # norm of that GCD
say p.is_coprime(q)     # true if the GCD is a unit (+-1 or +-i)
say p.is_div(q)         # true if q divides p exactly
```

### Modular arithmetic

```ruby
var z = Gauss(3, 4)

say z.powmod(5, 100)     # z^5 mod 100
say z.invmod(97)         # modular inverse mod 97
```

### Rotation and sign

```ruby
var z = Gauss(3, 4)
say z.i      # Gauss(-4, 3)  -- multiplying by i rotates 90 degrees
say z.sgn    # the unit (one of 1, -1, i, -i) with the same argument as z
```

---

## Quadratic

`Quadratic(a, b, p, q)` represents an element $a + b t$ of the quotient ring $\Z[t] / (t^2 - q t - p)$, where $t$ satisfies $t^2 = p + q t$. Every element carries four components: the two coordinates `a`, `b`, and the two ring parameters `p`, `q`.

Two special cases cover almost everything you'll want to compute:

- **Quadratic integers** $a + b \sqrt w$: call `Quadratic(a, b, w)` — this defaults $q$ to $0$, so $t^2 = w$, i.e. $t = \sqrt w$.
- **Linear recurrences**: $t^2 = p + q t$ is exactly the recurrence relation $U(n) = q U(n-1) + p U(n-2)$, so powers of $t$ generate Fibonacci-like sequences in $O(log n)$ multiplications (see below).

### Construction

```ruby
var x = Quadratic(3, 4, 5)     # 3 + 4*sqrt(5)      (p=5, q=0)
var y = Quadratic(1, 1, 2)     # 1 + sqrt(2)         -- fundamental solution to x^2-2y^2=1
var z = Quadratic(3, 4, -1)    # 3 + 4i, via p=-1    -- a Gaussian integer in disguise
var t = Quadratic(0, 1, 1, 1)  # t itself, with t^2 = t + 1  (the golden-ratio recurrence)
```

### Arithmetic

Two elements must share the same `(p, q)` to add or multiply directly.

```ruby
var a = Quadratic(3, 4, 5)
var b = Quadratic(1, 2, 5)

say (a + b)   # Quadratic(4, 6, 5, 0)
say (a - b)   # Quadratic(2, 2, 5, 0)
say (a * b)   # (ac+bd*p) + (ad+bc+bd*q)*t = Quadratic(43, 10, 5, 0)
say (a / b)   # a * conj(b) / norm(b)
```

### Norm, trace, conjugate, inverse

For $e = a + b*t$, the conjugate uses the *other* root $t' = q - t$ of the minimal polynomial:

```ruby
var e = Quadratic(3, 4, 1, 1)   # t^2 = 1 + t

say e.norm        # a^2 + a*b*q - b^2*p = 5
say e.trace       # 2*a + b*q = 10
say e.conj        # Quadratic(7, -4, 1, 1)
say e.inv         # conj(e) / norm(e)
say (e * e.inv)   # Quadratic(1, 0, 1, 1)
```

When `q = 0` (the `Quadratic(a, b, w)` shorthand) these simplify to the familiar `norm = a^2 - b^2*w`, `trace = 2a`, and `conj = a - b*t`.

### Powers, Pell equations, and Fibonacci — for free

Raising a `Quadratic` element to a power uses binary exponentiation, so it's efficient even for huge exponents. Two classic sequences fall out immediately:

```ruby
# Pell equation x^2 - 2y^2 = +-1: solutions are the powers of (1+sqrt(2))
var pell = Quadratic(1, 1, 2)
say pell**2     # Quadratic(3, 2, 2, 0)   -- 3^2 - 2*2^2 = 1
say pell**5     # Quadratic(41, 29, 2, 0)
say pell**10    # Quadratic(3363, 2378, 2, 0)

# Fibonacci and Lucas numbers via t^2 = t + 1
func fib(n) { Quadratic(0, 1, 1, 1)**n -> b }
func luc(n) { Quadratic(0, 1, 1, 1)**n -> trace }

say fib(10)   # 55
say fib(20)   # 6765
say luc(10)   # 123
```

### Modular exponentiation

```ruby
var q = Quadratic(3, 4, 5)

say q.powmod(100, 97)     # q^100 mod 97
var inv = q.invmod(97)
say ((q * inv) % 97)      # Quadratic(1, 0, 5, 0)
```

### Rounding, division, and comparisons

```ruby
var e = Quadratic(3.7, 4.2, 1, 1)
say e.floor        # Quadratic(3, 4, 1, 1)
say e.ceil         # Quadratic(4, 5, 1, 1)
say e.round(2)     # component-wise rounding

var x = Quadratic(7, 5, 1, 1)
var y = Quadratic(2, 1, 1, 1)
var (quot, rem) = x.divmod(y)   # Euclidean division, minimizing the norm of rem
say x.idiv(y)                   # the quotient alone
```

### Primality, units, and coprimality

```ruby
var e = Quadratic(1, 1, 1, 1)
say e.is_prime      # true if |norm(e)| is a rational prime (sufficient, not necessary)
say e.is_unit       # true if |norm(e)| == 1
say e.is_int        # true if b == 0

var g = Quadratic(6, 0, 1, 1)
var h = Quadratic(4, 0, 1, 1)
say g.gcd(h)
say g.is_coprime(h)   # true if gcd(norm(g), norm(h)) == 1
```

### String representations

```ruby
var q = Quadratic(3, 4, 5)
say q.to_s      # "Quadratic(3, 4, 5, 0)"
say q.pretty    # "3 + 4*sqrt(5)"
```

---

## Quaternion

`Quaternion(a, b, c, d)` represents $a + bi + cj + dk$, the four-dimensional extension of the complex numbers. Multiplication is **non-commutative**, which is exactly what makes quaternions useful for representing 3D rotations without gimbal lock.

### Construction

```ruby
var q  = Quaternion(1, 2, 3, 4)   # 1 + 2i + 3j + 4k
var q2 = Quaternion(5)            # 5 + 0i + 0j + 0k
var q3 = Quaternion()             # the zero quaternion
```

### Non-commutative multiplication

```ruby
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)

say (a * b)     # Quaternion(-60, 12, 30, 24)
say (b * a)     # Quaternion(-60, 20, 14, 32)  -- order matters

var i = Quaternion(0, 1, 0, 0)
var j = Quaternion(0, 0, 1, 0)
var k = Quaternion(0, 0, 0, 1)

say (i * i)   # Quaternion(-1, 0, 0, 0)  -- i^2 = -1
say (i * j)   # Quaternion(0, 0, 0, 1)   -- ij = k
say (j * i)   # Quaternion(0, 0, 0, -1)  -- ji = -k
say (j * k)   # Quaternion(0, 1, 0, 0)   -- jk = i
say (k * i)   # Quaternion(0, 0, 1, 0)   -- ki = j
```

### Norm, conjugate, inverse

```ruby
var q = Quaternion(1, 2, 3, 4)

say q.norm      # 30    -- a^2+b^2+c^2+d^2
say q.abs       # sqrt(norm) ~ 5.477
say q.conj      # Quaternion(1, -2, -3, -4)
say q.inv       # conj(q) / norm(q)
say (q * q.inv) # Quaternion(1, 0, 0, 0)

var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)
say ((a * b).norm == (a.norm * b.norm))   # true -- the norm is multiplicative
```

### Arithmetic

```ruby
var a = Quaternion(1, 2, 3, 4)
var b = Quaternion(5, 6, 7, 8)

say (a + b)     # Quaternion(6, 8, 10, 12)
say (a - b)     # Quaternion(-4, -4, -4, -4)
say (a / b)     # a * b.inv
say a**3        # binary exponentiation
say a.sqr       # Quaternion(-28, 4, 6, 8)
```

### Component access

```ruby
var q = Quaternion(1, 2, 3, 4)

say q.a         # 1  -- real part (aliases: re, real)
say q.b         # 2  -- i coefficient
say q.c         # 3  -- j coefficient
say q.d         # 4  -- k coefficient
say q.parts     # [1, 2, 3, 4]

var (w, x, y, z) = q.reals    # destructure all four components
```

### Unit quaternions and rotation

A unit quaternion $q = cos(\theta/2) + k sin(\theta/2)$ represents a rotation by $\theta$ around the $z$-axis:

```ruby
var angle = 90.deg2rad
var w = angle.div(2).cos
var s = angle.div(2).sin

var rotation = Quaternion(w, 0, 0, s)
say rotation.norm    # 1.0  -- a valid rotation quaternion is always a unit quaternion
say rotation.sgn     # the versor: q / |q|
```

### Modular arithmetic and coprimality

```ruby
var q = Quaternion(1, 2, 3, 4)

say q.powmod(5, 100)                       # q^5 mod 100
say q.invmod(97)                           # modular inverse mod 97
say q.is_coprime(Quaternion(5, 6, 7, 8))   # true if gcd(norm(q), norm(other)) == 1
```

---

## Polynomial

`Polynomial` implements univariate polynomials with arbitrary-precision coefficients, stored sparsely so that high-degree, mostly-zero polynomials stay cheap.

### Construction

```ruby
# From an array, highest degree first
var p = Polynomial([1, -2, 1])       # x^2 - 2x + 1 = (x-1)^2
var q = Polynomial([1, 0, -1])       # x^2 - 1 = (x-1)(x+1)

# Monomial: a single argument n gives x^n
var m = Polynomial(5)                # x^5

# Sparse: exponent => coefficient pairs
var s = Polynomial(5 => 3, 2 => 10)  # 3x^5 + 10x^2

# From a string
var e = Polynomial("3*x^2 + 2*x + 1")
```

### Arithmetic

```ruby
var p = Polynomial([1, 0, -1])   # x^2 - 1
var q = Polynomial([1, -1])      # x - 1

say (p + q)   # x^2 + x - 2
say (p - q)   # x^2 - x
say (p * q)   # x^3 - x^2 - x + 1
say (p / q)   # x + 1     -- exact division returns a Polynomial
say (p % q)   # 0         -- remainder

say Polynomial([1, 1]).sqr     # x^2 + 2x + 1
say (Polynomial([1, 1]) ** 4)  # (x+1)^4 = x^4 + 4x^3 + 6x^2 + 4x + 1
```

Division that isn't exact returns a `Fraction` representing the rational function; use `//` (alias `idiv`) to get just the quotient, or `divmod` for both parts at once.

### Evaluation

```ruby
var p = Polynomial([1, 2, 3])   # x^2 + 2x + 3

say p.eval(0)    # 3
say p.eval(1)    # 6
say p.eval(5)    # 38
say p.eval(-1)   # 2
```

### Differentiation and root finding

```ruby
var p = Polynomial([1, 0, -3, 2])   # x^3 - 3x + 2

say p.derivative              # 3x^2 - 3
say p.derivative.derivative   # 6x

say p.roots                          # numerical roots of p
say Polynomial([1, 0, -1]).roots     # [-1, 1]
say Polynomial([1, 0, 1]).roots      # [-1i, 1i]

# Newton's method for a root near x0 = 1.5
var f  = Polynomial([1, 0, -2])      # x^2 - 2
var df = f.derivative
say f.newton_method(1.5, df)         # approximates sqrt(2)
```

`roots` starts from `deg(f)` evenly-spaced roots of unity and refines each with Newton's method, so it may miss some roots when `f` has repeated ones. For working modulo an integer, use `roots_mod`:

```ruby
say Polynomial([1, 0, -1]).roots_mod(7)    # [1, 6]  -- x^2 == 1 (mod 7)
say Polynomial([1, 0, 0, -1]).roots_mod(13) # [1, 3, 9] -- x^3 == 1 (mod 13)
```

### Properties and coefficients

```ruby
var p = Polynomial([3, 0, 2, 1])     # 3x^3 + 2x + 1

say p.degree                # 3       (alias: deg)
say p.leading_coefficient   # 3       (alias: leading_coeff)
say p.leading_term          # 3x^3
say p.leading_monomial      # x^3
say p.coeff(1)              # 2
say p.coeffs                # [[0,1], [1,2], [3,3]]  -- ascending exponent order
say p.exponents             # [0, 1, 3]
say p.height                # 3  -- largest absolute coefficient
say p.is_squarefree         # true or false
```

### GCD, LCM, content

```ruby
var p = Polynomial([1, 0, -1])      # x^2 - 1
var q = Polynomial([1, -1])         # x - 1

say p.gcd(q)     # x - 1  (normalized to monic)
say p.lcm(q)     # x^2 - 1

# Extended GCD: u*p + v*q = gcd(p, q)
var (g, u, v) = p.gcdext(q)
say (((u * p) + (v * q)) == g)   # true

var r = Polynomial([6, 9, 12])      # 6x^2 + 9x + 12
say r.content            # 3  (alias: cont)
say r.primitive_part     # 2x^2 + 3x + 4  (alias: prim_part)

say Polynomial([1, -2, 1]).squarefree_part   # x - 1, from (x-1)^2
```

### Divmod and modular exponentiation

```ruby
var p = Polynomial([1, 0, -1])   # x^2 - 1
var q = Polynomial([1, -1])      # x - 1

var (quotient, remainder) = p.divmod(q)
say quotient    # x + 1
say remainder   # 0

var base = Polynomial([1, 1])       # x + 1
var mod  = Polynomial([1, 0, 1])    # x^2 + 1
say base.powmod(100, mod)           # (x+1)^100 mod (x^2+1), computed efficiently
```

---

## PolynomialMod

`PolynomialMod(coeffs, modulus)` represents an element of the quotient ring $\R[x] / (m(x))$: every arithmetic result is automatically reduced modulo the polynomial `m(x)`. This is the algebraic engine behind finite fields, cyclotomic fields, and constructions like AES's $GF(2^8)$.

The modulus can be given as a plain coefficient array or as an existing `Polynomial`.

### Construction

```ruby
# (3x^2 + 2x + 1) mod (x^2 + 1)
var p = PolynomialMod([3, 2, 1], [1, 0, 1])

# the element x itself, in Q[x]/(x^2+1) — it behaves exactly like i
var x = PolynomialMod([1, 0], [1, 0, 1])
```

### Simulating Gaussian integers via $\Q[x]/(x²+1)$

```ruby
var i = PolynomialMod([1, 0], [1, 0, 1])   # x, reduced mod x^2+1

say (i ** 2)   # -1   -- x^2 == -1 (mod x^2+1)
say (i ** 4)   # 1

var a = PolynomialMod([2, 3], [1, 0, 1])   # 3 + 2x  ~  3 + 2i
var b = PolynomialMod([4, 1], [1, 0, 1])   # 1 + 4x  ~  1 + 4i
say ((a * b) ** 2)   # matches (3+2i)(1+4i), squared, in the ring
```

### Finite field arithmetic $GF(pⁿ)$

```ruby
# GF(4) = GF(2)[x] / (x^2+x+1) — a field with 4 elements: {0, 1, x, x+1}
var mod_poly = [1, 1, 1]   # x^2 + x + 1, over GF(2)
var alpha = PolynomialMod([1, 0], mod_poly)   # generator x

say (alpha ** 1)   # x
say (alpha ** 2)   # x + 1     (x^2 reduces to x+1)
say (alpha ** 3)   # 1         -- alpha is a primitive element: ord(alpha) = 3
```

### Exponentiation and inverse

```ruby
var p = PolynomialMod([2, 1], [1, 0, 0, 1])   # (1+2x) mod (x^3+1)

say (p ** 3)        # p^3 reduced mod (x^3+1)
say (p ** -1)       # modular inverse, via negative exponent
say p.inv           # the same, spelled out
say (p * p.inv)     # 1
say (p ** 1000)     # efficient even for large exponents
```

The inverse of $f(x)$ in $\R[x]/(m(x))$ exists exactly when $\gcd(f, m) = 1$.

### GCD and modular inverse via gcdext

```ruby
var f = PolynomialMod([1, 0, 1], [1, 0, 0, 1])   # x^2+1 mod x^3+1
var g = PolynomialMod([1, 1],    [1, 0, 0, 1])   # x+1   mod x^3+1

say f.gcd(g)
var (d, u, v) = f.gcdext(g)      # d = u*f + v*g
say (((u * f) + (v * g)) == d)   # true
```

### Chinese Remainder Theorem

Unlike `Mod`'s free-standing `chinese(...)` function, `PolynomialMod` exposes CRT as a class method, and the inputs may have different moduli:

```ruby
var a = PolynomialMod([2, 1], [1, 0, 1])   # 2x+1 mod (x^2+1)
var b = PolynomialMod([1, 3], [1, 1, 1])   # x+3  mod (x^2+x+1)
var c = PolynomialMod.chinese(a, b)
say c   # a single polynomial congruent to both a and b
```

### Derivative and lifting

```ruby
var p = PolynomialMod([1, 0, 3, 1], [1, 0, 0, 0, 1])   # mod x^4+1
say p.derivative      # the formal derivative, reduced mod x^4+1

var lifted = p.lift   # (alias: to_poly) — the residue as a plain Polynomial
say lifted
say p.modulus         # the modulus polynomial itself
```

### Factoring polynomials over $GF(p)$

```ruby
# x^4 + 1 factors over GF(5) — Cantor-Zassenhaus factorization
var f = PolynomialMod([1, 0, 0, 0, 1], 5)
say f.factor       # every irreducible factor, repeated by multiplicity
say f.factor_exp   # [[factor, exponent], ...]
```

---

## Cross-Type Examples

### Gaussian integers and Quadratic integers

`Quadratic(a, b, -1)` and `Gauss(a, b)` describe the same numbers through two different lenses:

```ruby
var z1 = Gauss(3, 4)
var z2 = Quadratic(3, 4, -1)

say z1.norm   # 25  (3^2 + 4^2)
say z2.norm   # 25  (3^2 - 4^2*(-1) = 9 + 16)

# Pell equation solutions, as a sequence of Quadratic powers
var x = Quadratic(1, 1, 2)
(1..10).each { |n| say (x**n) }
```

### Mod combined with Gauss

```ruby
var g = Gauss(3, 4)
say g.powmod(100, 1009)    # (3+4i)^100 mod 1009
say g.invmod(1009)         # multiplicative inverse mod 1009
```

### PolynomialMod as a generalization of Quadratic and Gauss

All three describe the same relation $i^2 = -1$ through different quotient rings:

```ruby
var g = Gauss(0, 1)
say (g * g)    # Gauss(-1, 0)

var q = Quadratic(0, 1, -1)
say (q * q)    # Quadratic(-1, 0, -1, 0)

var p = PolynomialMod([1, 0], [1, 0, 1])
say (p * p)    # -1, in Q[x]/(x^2+1)
```

### CRT across several moduli

```ruby
func reconstruct(n) {
    var residues = [97, 101, 103, 107].map { |m| Mod(n, m) }
    chinese(residues...)
}
say reconstruct(123456789)
```

### Euler's four-square identity

```ruby
var q1 = Quaternion(1, 2, 3, 4)
var q2 = Quaternion(5, 6, 7, 8)

say ((q1.norm * q2.norm) == (q1 * q2).norm)   # true -- the norm identity
say q1.norm           # 30  = 1+4+9+16
say q2.norm           # 174 = 25+36+49+64
say ((q1 * q2).norm)  # 5220 = 30 * 174
```

### Polynomial factoring workflow

```ruby
var p = Polynomial([1, 0, -5, 0, 4])    # x^4 - 5x^2 + 4 = (x-1)(x+1)(x-2)(x+2)
var q = Polynomial([1, 0, -1])          # x^2 - 1 = (x-1)(x+1)

say p.gcd(q)          # x^2 - 1
say (p / q)           # x^2 - 4
say ((p / q).roots)   # [-2, 2]
say p.is_squarefree   # true
say p.roots           # [-2, -1, 1, 2]
```

---

## Algebraic Number Theory

This section develops the number-theoretic machinery that these six types collectively provide, organized around the classical themes of algebraic number theory.

---

### Rings of Integers

An **algebraic integer** is a root of a monic polynomial with integer coefficients. For the quadratic field $\Q(\sqrt d)$ with $d$ square-free:

- If `d == 2` or `3 (mod 4)`: the ring of integers is $\Z[\sqrt d]$, elements $a + b \sqrt d$ with $a$, $b$ integers.
- If `d == 1 (mod 4)`: the ring of integers is $\Z[(1+\sqrt d)/2]$, using a half-integer basis.

```ruby
# Z[sqrt(2)]: d=2, d == 2 (mod 4), so integers have the form a + b*sqrt(2)
var alpha = Quadratic(1, 1, 2)    # 1 + sqrt(2)
say alpha.norm    # -1  -- an integer, as expected for an algebraic integer

# Z[(1+sqrt(5))/2]: d=5, d == 1 (mod 4) — the golden ratio is an algebraic integer!
var phi = Quadratic(1/2, 1/2, 5)   # (1+sqrt(5))/2
say phi.norm    # -1  -- still an integer, even though a and b are halves
say (phi ** 2)  # phi + 1, the defining property of the golden ratio
```

---

### Quadratic Fields: Real vs Imaginary

The sign of `d` in $\Q(\sqrt d)$ determines whether the field is **real** ($d > 0$) or **imaginary** ($d < 0$), which profoundly affects the arithmetic.

#### Imaginary quadratic fields

The norm $N(a + b \sqrt d) = a^2 - b^2 d = a^2 + b^2 |d|$ is always non-negative:

```ruby
say Quadratic(3, 4, -1).norm   # 25  -- Gaussian integers: a^2 + b^2
say Quadratic(1, 1, -2).norm   # 3   -- Q(sqrt(-2)): a^2 + 2b^2
say Quadratic(1, 1, -3).norm   # 4   -- Q(sqrt(-3)): the Eisenstein integers

# Q(sqrt(-5)) famously fails unique factorization:
# 6 = 2*3 = (1+sqrt(-5))(1-sqrt(-5)), two genuinely different factorizations
var a = Quadratic(1,  1, -5)    # norm 6
var b = Quadratic(1, -1, -5)    # norm 6
say (a * b)                     # Quadratic(6, 0, -5, 0) = 6
say Quadratic(2, 0, -5).norm    # 4  -- no element of Z[sqrt(-5)] has norm 2
say Quadratic(3, 0, -5).norm    # 9  -- and none has norm 3, either
```

#### Real quadratic fields

Real quadratic fields have infinitely many units: `+-eps^n` where `eps` is the **fundamental unit**, the smallest nontrivial solution to a Pell-like equation.

```ruby
var eps2 = Quadratic(1, 1, 2)          # fundamental unit of Q(sqrt(2))
say eps2.norm            # -1

var eps3 = Quadratic(2, 1, 3)          # fundamental unit of Q(sqrt(3))
say eps3.norm            # 1

var eps5 = Quadratic(1/2, 1/2, 5)      # fundamental unit of Q(sqrt(5)): the golden ratio
say eps5.norm            # -1

# Powering the fundamental unit generates every unit
var u = Quadratic(1, 1, 2)
say (u ** 1)    # 1 + sqrt(2)
say (u ** 2)    # 3 + 2*sqrt(2)
say (u ** 3)    # 7 + 5*sqrt(2)
say (u ** -1)   # -1 + sqrt(2)
```

---

### Norms, Traces, and Minimal Polynomials

For $\alpha = a + b \sqrt d$, the norm and trace are its two fundamental invariants, and together they give its minimal polynomial `x^2 - Tr(alpha)*x + N(alpha)`:

```ruby
var alpha = Quadratic(3, 4, 5)   # 3 + 4*sqrt(5)

say alpha.norm     # -71
say alpha.trace    # 6
say alpha.conj     # Quadratic(3, -4, 5, 0)

var min_poly = Polynomial([1, -6, -71])    # x^2 - 6x - 71
say min_poly.eval(alpha.to_n)              # ~ 0

# The norm is multiplicative: N(alpha*beta) = N(alpha)*N(beta)
var beta = Quadratic(1, 2, 5)
say ((alpha * beta).norm == (alpha.norm * beta.norm))   # true
```

The same idea extends to algebraic numbers with no `Quadratic` representation, using `Polynomial` directly:

```ruby
# alpha = sqrt(2) + sqrt(3) satisfies x^4 - 10x^2 + 1 = 0
var min_poly_alpha = Polynomial([1, 0, -10, 0, 1])
say min_poly_alpha.eval(2.sqrt + 3.sqrt)   # ~ 0
say min_poly_alpha.is_squarefree           # true -- no repeated conjugates
say min_poly_alpha.degree                  # 4 = [Q(sqrt(2)+sqrt(3)) : Q]
```

---

### Pell's Equation and Fundamental Units

The **Pell equation** $x^2 - d y^2 = +-1$ is one of the oldest problems in number theory, and its solutions are exactly the powers of the fundamental unit of $\Q(\sqrt d)$.

```ruby
var u = Quadratic(1, 1, 2)   # fundamental unit of Q(sqrt(2))

for n in (1..8) {
    var power = (u ** n)
    var (x, y) = power.reals
    say "n=#{n}: x=#{x}, y=#{y}, x^2-2y^2=#{power.norm}"
}
# n=1: x=1,   y=1,   norm=-1
# n=2: x=3,   y=2,   norm=1
# n=3: x=7,   y=5,   norm=-1
# n=4: x=17,  y=12,  norm=1
# ...alternating -1, 1, -1, 1...
```

Each solution `(x_n, y_n)` also gives a best rational approximation of $\sqrt d$:

```ruby
for n in (1..6) {
    var (x, y) = (u ** n).reals
    say "#{x}/#{y} ~ sqrt(2), error #{((x/y) - 2.sqrt).abs}"
}
# 1/1, 3/2, 7/5, 17/12, 41/29, 99/70 — converging on sqrt(2)
```

$\Q(\sqrt 5)$'s fundamental unit is the golden ratio, with norm $-1$ rather than $+1$ — a reminder that not every real quadratic field has a norm-`+1` fundamental unit:

```ruby
var phi = Quadratic(1/2, 1/2, 5)
say phi.norm           # -1
say ((phi ** 2).norm)  # 1  -- squaring a norm(-1) unit always gives norm(+1)
```

---

### Splitting of Rational Primes

A rational prime $p$ behaves in one of three ways in the ring of integers of $\Q(\sqrt d)$, determined by the Legendre symbol $(d/p)$:

| `(d/p)` | Behavior | Example in `Z[i]` |
|---|---|---|
| `+1` | **Split**: `p = pi * conj(pi)` | `5 = (2+i)(2-i)` |
| `-1` | **Inert**: `p` stays prime | `3` stays prime |
| `0`  | **Ramified**: `p = u * pi^2` | `2 = -i*(1+i)^2` |

```ruby
# In Z[i]: p splits iff p == 1 (mod 4), is inert iff p == 3 (mod 4)
say Gauss(5, 0).factor    # (2+i)(2-i) -- splits, 5 == 1 (mod 4)
say Gauss(13, 0).factor   # (3+2i)(3-2i) -- splits, 13 == 1 (mod 4)
say Gauss(3, 0).factor    # stays inert, 3 == 3 (mod 4)
say Gauss(2, 0).factor    # ramified — 2 divides the discriminant of Z[i]

var pi  = Gauss(2, 1)
var pic = Gauss(2, -1)
say (pi * pic)       # Gauss(5, 0)
say pi.is_prime      # true -- norm(pi) = 5 is a rational prime
```

Splitting in real quadratic fields works the same way, via `Quadratic`:

```ruby
# In Q(sqrt(5)): 11 splits since 4^2 - 5*1^2 = 11
var pi11 = Quadratic(4, 1, 5)
say (pi11 * pi11.conj)    # Quadratic(11, 0, 5, 0) = 11
say pi11.norm             # 11
```

---

### Fermat's Two-Square Theorem

Every prime $p \equiv 1 \pmod{4}$ is a sum of two squares. The classical proof is constructive: find $x$ with $x^2 \equiv -1 \pmod{p}$, then take $\gcd(x+i, p)$ in $\Z[i]$.

```ruby
func two_squares(p) {
    var x = Mod(-1, p).sqrt.lift
    var g = Gauss(x, 1).gcd(Gauss(p, 0))
    var (a, b) = g.parts.map { .abs }...
    say "#{p} = #{a}^2 + #{b}^2"
}

two_squares(5)     # 5  = 1^2 + 2^2
two_squares(13)    # 13 = 2^2 + 3^2
two_squares(17)    # 17 = 1^2 + 4^2
two_squares(29)    # 29 = 2^2 + 5^2
two_squares(97)    # 97 = 4^2 + 9^2
```

This composes with the **Brahmagupta–Fibonacci identity** $(a^2+b^2)(c^2+d^2) = (ac-bd)^2 + (ad+bc)^2$ — which is just multiplication of Gaussian integers:

```ruby
var z1 = Gauss(2, 3)   # norm 13
var z2 = Gauss(1, 4)   # norm 17
var z3 = (z1 * z2)

var (a, b) = z3.parts.map { .abs }...
say "13 * 17 = 221 = #{a}^2 + #{b}^2"   # 221 = 10^2 + 11^2
```

---

### Euler's Four-Square Theorem

Every positive integer is a sum of four squares (Lagrange's theorem), and quaternion arithmetic makes the proof constructive: the quaternion norm identity `N(q1)*N(q2) = N(q1*q2)` combines two four-square representations into one.

```ruby
func combine_four_squares(q1, q2) {
    var prod = (q1 * q2)
    var (a, b, c, d) = prod.reals
    say "#{q1.norm} * #{q2.norm} = #{prod.norm} = #{a}^2+#{b}^2+#{c}^2+#{d}^2"
}

combine_four_squares(Quaternion(1, 1, 1, 1), Quaternion(1, 2, 2, 1))   # 4 * 10 = 40

# 7 = 2^2 + 1^2 + 1^2 + 1^2
say Quaternion(2, 1, 1, 1).norm    # 7

# Coprime norms combine into a new four-square representation
var qa = Quaternion(2, 1, 1, 1)   # norm 7
var qb = Quaternion(3, 1, 1, 0)   # norm 11
say ((qa * qb).norm)              # 77 = 7 * 11
```

---

### Cyclotomic Fields via PolynomialMod

The **cyclotomic field** $\Q(\zeta_n)$ is generated by a primitive `n`-th root of unity, satisfying the `n`-th cyclotomic polynomial $\Phi_n(x) = 0$. In Sidef, this is exactly `PolynomialMod` with modulus $\Phi_n(x)$.

```ruby
# Q(zeta_3): cube roots of unity, Phi_3(x) = x^2+x+1 — the Eisenstein integers
var zeta3 = PolynomialMod([1, 0], [1, 1, 1])

say (zeta3 ** 1)   # zeta
say (zeta3 ** 2)   # zeta^2, reduced
say (zeta3 ** 3)   # 1 -- order 3

# zeta + zeta^2 = -1, from Phi_3: zeta^2+zeta+1 = 0
say (zeta3 + (zeta3 ** 2))

# Q(zeta_4) = Q(i)
var zeta4 = PolynomialMod([1, 0], [1, 0, 1])
say (zeta4 ** 2)   # -1
say (zeta4 ** 4)   # 1

# Q(zeta_8) contains both i and sqrt(2)
var zeta8 = PolynomialMod([1, 0], [1, 0, 0, 0, 1])
say (zeta8 ** 2)   # zeta_4 = i
say (zeta8 ** 4)   # -1
say (zeta8 + (zeta8 ** 7))   # zeta_8 + zeta_8^-1 represents sqrt(2)
```

#### Galois action

The Galois group $Gal(\Q(\zeta_n)/\Q) = (\Z/n\Z)*$ acts by `zeta -> zeta^k` for $\gcd(k, n) = 1$:

```ruby
var mod5 = [1, 1, 1, 1, 1]    # Phi_5(x)
var zeta = PolynomialMod([1, 0], mod5)

for k in (1, 2, 3, 4) {
    say "sigma_#{k}(zeta) = #{(zeta ** k).pretty}"
}
```

---

### Finite Fields and the Frobenius Endomorphism

In $GF(p^n) = GF(p)[x]/(f(x))$, the **Frobenius map** `phi: a -> a^p` is the fundamental automorphism, and its order equals the degree of the extension.

```ruby
# GF(2^3) = GF(2)[x]/(x^3+x+1), an irreducible cubic over GF(2)
var f = [1, 0, 1, 1]
var alpha = PolynomialMod([1, 0], f)

say (alpha ** 1)   # alpha
say (alpha ** 2)   # alpha^2  -- the Frobenius image
say (alpha ** 4)   # alpha^4  -- Frobenius applied twice
say (alpha ** 7)   # 1        -- |GF(8)*| = 7, so alpha^7 = 1

# GF(3^2) = GF(3)[x]/(x^2+1) — irreducible since -1 is not a square mod 3
var g = [1, 0, 1]
var beta = PolynomialMod([1, 0], g)
say (beta ** 3)   # the Frobenius image of beta in GF(9)
say (beta ** 9)   # back to beta -- Frobenius has order 2
say (beta ** 8)   # 1  -- |GF(9)*| = 8
```

`PolynomialMod` can also factor polynomials over $GF(p)$ directly, using Cantor–Zassenhaus factorization:

```ruby
var poly = PolynomialMod([1, 0, 0, 4], 5)   # x^3 + 4, over GF(5)
say poly.factor_exp
```

---

### Quadratic Residues and the Legendre Symbol

The **Legendre symbol** $(a/p)$ tells whether $a$ is a quadratic residue modulo the prime $p$, via Euler's criterion $(a/p) \equiv a^{(p-1)/2} \pmod{p}$.

```ruby
func legendre(a, p) { Mod(a, p) ** ((p-1)/2) }

for a in (1..6) {
    var sym = legendre(a, 7)
    say "#{a} is #{(sym == Mod(1, 7)) ? 'a QR' : 'a non-residue'} mod 7"
}
# QRs mod 7: 1, 2, 4 — exactly (7-1)/2 = 3 residues

# Quadratic reciprocity: (p/q)(q/p) = (-1)^((p-1)(q-1)/4)
func qr_test(p, q) {
    var pq = (legendre(p, q) == Mod(1, q)) ? 1 : -1
    var qp = (legendre(q, p) == Mod(1, p)) ? 1 : -1
    say "(#{p}/#{q})=#{pq}, (#{q}/#{p})=#{qp}, product=#{pq*qp}"
}
qr_test(3, 5)    # product = +1
qr_test(3, 7)    # product = -1
qr_test(5, 11)   # product = +1
```

This directly answers whether a prime splits in `Q(sqrt(d))`: it splits iff `(d/p) = 1`.

---

### Hensel Lifting

**Hensel's lemma** lifts a solution of `f(x) == 0 (mod p)` to a solution modulo $p^2$, $p^3$, and so on — Newton's method over the p-adic integers. `Polynomial` and `Mod` compose naturally here.

```ruby
func hensel_lift(f, a0, p, steps) {
    var a  = a0
    var m  = p
    var df = f.derivative

    for _ in (1..steps) {
        m *= p
        var fa  = Mod(f.eval(a), m)
        var dfa = Mod(df.eval(a), m)
        a = ((Mod(a, m) - (fa * dfa.inv))).to_n
        say "mod #{m}: a == #{a}"
    }
    a
}

# Lift a root of x^2 - 2 from mod 7 to mod 7^4 -- this computes the
# 7-adic expansion of sqrt(2)
var f = Polynomial([1, 0, -2])
hensel_lift(f, 3, 7, 4)
```

---

### Bézout Coefficients in Polynomial Rings

The extended Euclidean algorithm on polynomials underlies partial-fraction decomposition and gives the modular inverse in a quotient ring.

```ruby
var f = Polynomial([1, 0, -1])    # x^2 - 1 = (x-1)(x+1)
var g = Polynomial([1, -1])       # x - 1

var (d, s, t) = f.gcdext(g)
say d.pretty                       # x - 1
say (((s * f) + (t * g)) == d)     # true

# Partial fractions: 1/((x-1)(x+1)) = A/(x-1) + B/(x+1)
var p1 = Polynomial([1, -1])   # x - 1
var p2 = Polynomial([1,  1])   # x + 1
var (d2, s2, t2) = p1.gcdext(p2)
say "#{s2.pretty}*(x-1) + #{t2.pretty}*(x+1) = #{d2.pretty}"

# In a quotient ring, extended GCD gives the modular inverse directly
var modulus = [1, 0, 0, 1]                       # x^3 + 1
var h = PolynomialMod([1, 1], modulus)           # 1 + x, mod x^3+1
var (d3, u3, v3) = h.lift.gcdext(Polynomial(modulus))
say u3.pretty     # the inverse of (1+x) mod (x^3+1)
say h.inv.pretty  # should match
```

---

## Quick Reference

| Type | Represents | Key methods |
|---|---|---|
| `Mod(n, m)` | `n mod m` | `inv`, `sqrt`, `znorder`, `fib`, `chinese`, `lucasu`, `cyclotomic` |
| `Gauss(a, b)` | `a + bi` | `norm`, `conj`, `factor`, `is_prime`, `powmod`, `gcd`, `divisors` |
| `Quadratic(a, b, p, q)` | `a + b*t`, `t^2 = p + q*t` | `norm`, `trace`, `conj`, `inv`, `powmod`, `invmod`, `to_n` |
| `Quaternion(a,b,c,d)` | `a+bi+cj+dk` | `norm`, `conj`, `inv`, `sgn`, `powmod`, `is_coprime` |
| `Polynomial([...])` | `p(x)` | `eval`, `derivative`, `roots`, `roots_mod`, `gcd`, `gcdext`, `primitive_part` |
| `PolynomialMod([...], [...])` | `p(x) mod m(x)` | `inv`, `gcd`, `gcdext`, `factor`, `lift`, `modulus`, `derivative` |

All six types support: `+`, `-`, `*`, `/`, `**`, `%`, `==`, `!=`, `neg`, `sqr`, `floor`, `ceil`, `round`, `float`, `is_zero`, `is_one`, `dump`, `pretty`.

### Concept map

| Concept | Sidef type(s) | Key operations |
|---|---|---|
| Ring of integers `O_K` | `Quadratic`, `Gauss` | `norm`, `conj`, `inv` |
| Unique factorization domain | `Gauss` | `factor`, `factor_exp`, `is_prime` |
| Non-UFD (class number > 1) | `Quadratic` with `w=-5` | `norm`, `gcd` |
| Pell's equation `x^2-dy^2=+-1` | `Quadratic` | `**`, `norm`, `reals` |
| Two-square theorem | `Gauss` | `factor`, `gcd`, `norm` |
| Four-square theorem | `Quaternion` | `norm`, `*` (multiplicativity) |
| Cyclotomic field `Q(zeta_n)` | `PolynomialMod` | `**`, `inv`, `gcdext` |
| Finite field `GF(p^n)` | `PolynomialMod` | `**`, `inv`, `gcd`, `factor` |
| Frobenius endomorphism | `PolynomialMod` | `**p` (p-th power map) |
| Quadratic residues | `Mod` | `sqrt`, `**((p-1)/2)` |
| Splitting of primes | `Gauss`, `Quadratic` | `is_prime`, `norm`, `factor` |
| CRT / ideal patching | `Mod`, `PolynomialMod` | `chinese` |
| Hensel lifting | `Polynomial`, `Mod` | `eval`, `derivative`, `inv` |
| Bézout / partial fractions | `Polynomial`, `PolynomialMod` | `gcdext` |

## 📚 Documentation & Learning Resources

| Resource | Description |
|----------|-------------|
| 📘 [Sidef GitBook](https://trizen.gitbook.io/sidef-lang/) | The complete language reference — covers everything |
| 📄 [Beginner's Guide](https://github.com/trizen/sidef/blob/master/SIDEF_BEGINNER_GUIDE.md) | Start here if you're new to Sidef |
| 📝 [Advanced Guide](https://github.com/trizen/sidef/blob/master/SIDEF_ADVANCED_GUIDE.md) | Comprehensive language tutorial |
| 📕 [Full PDF Documentation](https://github.com/trizen/sidef/releases/download/26.07/sidef-documentation.pdf) | Offline PDF version of the complete language documentation |
| 📑 [Number Theory Cheatsheet](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_CHEATSHEET.md) | Quick reference for Sidef's number theory functions |
| 📚 [Number Theory Guide](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_GUIDE.md) | Deep dive into Sidef's mathematical superpowers |
| 🔢 [Number Theory Reference](https://github.com/trizen/sidef/blob/master/NUMBER_THEORY_REFERENCE.md) | Complete function reference for number theory |

### Code examples

| Resource | Description |
|----------|-------------|
| 📂 [sidef-scripts](https://github.com/trizen/sidef-scripts) | Hundreds of real Sidef programs — the best way to learn by reading |
| 🌹 [RosettaCode — Sidef](https://rosettacode.org/wiki/Sidef) | Classic programming tasks solved in Sidef, side-by-side with other languages |
