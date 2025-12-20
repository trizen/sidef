# Introduction

In this tutorial we're going to look how we can use [Sidef](https://github.com/trizen/sidef) for doing various computations in number theory.

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

To initiate your journey with Sidef and installation instructions, refer to the [beginner's tutorial](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md) ([PDF](https://github.com/trizen/sidef/releases/download/25.12/sidef-tutorial.pdf)).

Over time, Sidef has integrated numerous mathematical functions, many based on Dana Jacobsen's [Math::Prime::Util](https://github.com/danaj/Math-Prime-Util) and [Math::Prime::Util::GMP](https://github.com/danaj/Math-Prime-Util-GMP) awesome Perl modules. These modules significantly enhance performance in tasks like integer factorization, primality testing, and prime counting.

Presently, Sidef encompasses more than $1000$ numerical functions; feel free to explore the [source code](https://codeberg.org/trizen/sidef/src/master/lib/Sidef/Types/Number/Number.pm).

The majority of these functions match the speed of PARI/GP and Mathematica, while a few are marginally slower or even faster.

Sidef has built-in support for big integers, rationals, Gaussian integers, Quaternion integers, Quadratic integers, matrices, polynomials, and floating-points of arbitrary precision, using the [GMP](https://gmplib.org/), [MPFR](https://www.mpfr.org/) and [MPC](https://www.multiprecision.org/) C libraries.

# Basic usage

After [installing Sidef](https://codeberg.org/trizen/sidef/src/branch/master/TUTORIAL.md), we can start the REPL by executing the `sidef` command in a console:

```
$ sidef
Sidef 25.12, running on Linux, using Perl v5.42.0.
Type "help", "copyright" or "license" for more information.
>
```

Several examples of Sidef code to try:

```ruby
25.by { .is_prime }     # first 25 primes
30.of { .esigma }       # first 30 values of the e-sigma function
factor(2**128 + 1)      # prime factorization of the 7-th Fermat number
```

Additionally, by creating a script called `script.sf`, we can execute it as:

```console
sidef script.sf
```

Some basic functionality of the language:

```ruby
var x = 42      # variable declaration
var y = x**3    # compute x^3 and store the result in y
say (x + y)     # print the result of x+y
```

In Sidef, the following $4$ statements are all equivalent:

```ruby
say 10.by { .is_composite }
say 10.by { is_composite(_) }
say 10.by {|n| n.is_composite }
say 10.by {|n| is_composite(n) }
```

# Number theoretic functions

Below we have a small collection of common functions used in computational number theory:

```ruby
is_prime(n)                 # true if n is a probable prime (B-PSW test)
is_prov_prime(n)            # true if n is a provable prime
is_composite(n)             # true if n is a composite number
is_squarefree(n)            # true if n is squarefree
is_power(n,k)               # true if n = b^k, for some b >= 1
is_power_of(n,b)            # true if n a power of b: n = b^k, for some k >= 1
is_perfect_power(n)         # true if n is a perfect power
is_gaussian_prime(a,b)      # true if a+b*i is a Gaussian prime

factor(n)                   # array with the prime factors of n
divisors(n)                 # array with the positive divisors of n
udivisors(n)                # array with the unitary divisors of n
edivisors(n)                # array with the exponential divisors of n
idivisors(n)                # array with the infinitary divisors of n
bdivisors(n)                # array with the bi-unitary divisors of n

omega(n,k=0)                # omega function: number of distinct primes of n
Omega(n,k=0)                # Omega function: number of primes of n counted with multiplicity

omega_prime_divisors(n,k)   # divisors of n with omega(n) = k
almost_prime_divisors(n,k)  # divisors of n with Omega(n) = k
prime_power_divisors(n)     # prime power divisors of n
square_divisors(n)          # square divisors of n
squarefree_divisors(n)      # squarefree divisors of n

tau(n)                      # count of divisors of n
sigma(n,k=1)                # sigma_k(n) function: sum of divisors of n
psi(n,k=1)                  # Dedekind's Psi function
znorder(a,n)                # Multiplicative order of a mod n
lambda(n)                   # Carmichael lambda function
phi(n)                      # Euler's totient function
jordan_totient(n,k=1)       # Jordan's totient function: J_k(n)

idiv(a,b)                   # integer floor division: floor(a/b)
idiv_round(a,b)             # integer round division: round(a/b)
idiv_ceil(a,b)              # integer ceil division: ceil(a/b)
idiv_trunc(a,b)             # integer truncated division: trunc(a/b)

iroot(n,k)                  # integer k-th root of n
ilog(n,k)                   # integer logarithm of n in base k
valuation(n,k)              # number of times n is divisible by k

gcd(...)                    # greatest common divisor of a list of integers
gcud(...)                   # greatest common unitary divisor of a list of integers
lcm(...)                    # least common multiple of a list of integers

factorial(n)                # n-th factorial (equivalently: n!)
mfactorial(n,k)             # k-multi-factorial of n (where k=2 means n!!)
falling_factorial(n,k)      # falling factorial
rising_factorial(n,k)       # rising factorial
binomial(n,k)               # the binomial coefficient: n!/((n-k)! * k!)
binomialmod(n,k,m)          # binomial(n,k) modulo m
factorialmod(n,m)           # factorial(n) modulo m

pi(n)                       # count of primes <= n
pi(a,b)                     # count of primes in the range a..b
prime(n)                    # n-th prime number
primes(a,b)                 # array of primes in the range a..b
prime_sum(a,b,k=1)          # sum of primes: Sum_{a <= p prime <= b} p^k

composite(n)                # n-th composite number
composites(a,b)             # array of composites in the range a..b
composite_count(n)          # count of composites <= n
composite_sum(a,b,k=1)      # sum of composites: Sum_{a <= c composite <= b} c^k

squarefree_count(n)         # count of squarefree numbers <= n
prime_power_count(n)        # count of prime powers <= n
perfect_power_count(n)      # count of perfect powers <= n

mu(n)                       # Moebius function
mertens(n)                  # Mertens function: partial sums of mu(n)

lpf(n)                      # least prime factor of n, with lpf(1) = 1
gpf(n)                      # greatest prime factor of n, with gpf(1) = 1

sqrtmod(a,n)                # find a solution x to the congruence x^2 == a (mod n)
sqrtmod_all(a,n)            # find all solutions x to the congruence x^2 == a (mod n)

sqrtQ(n)                    # square root of n as a Quadratic object
invmod(a,m)                 # modular inverse: a^(-1) (mod m)
powmod(n,k,m)               # modular exponentiation: n^k (mod m)
expnorm(n,B=10)             # exp(n) normalized to base B in interval [0,1)

harmonic(n,k=1)             # n-th Harmonic number of k-th order
bernoulli(n)                # n-th Bernoulli number
euler(n)                    # n-th Euler number

bernoulli(n,x)              # n-th Bernoulli polynomial evaluated at x
euler(n,x)                  # n-th Euler polynomial evaluated at x

sqrt_cfrac(n)               # continued fraction expansion of sqrt(n)
sqrt_cfrac_period_len(n)    # length of the continued fraction period of sqrt(n)
convergents(n)              # continued fraction convergents of n
rat_approx(n)               # rational approximation of n

var(x,y)=solve_pell(n)      # smallest solution to Pell's equation: x^2 - n*y^2 = 1

digits(n, base=10)          # array with digits of n in a given base
digits_sum(n, base=10)      # sum of digits of n in a given base

sum_of_squares(n)           # array of [x,y] solutions for representing n as: x^2 + y^2
diff_of_squares(n)          # array of [x,y] solutions for representing n as: x^2 - y^2

cyclotomic(n)               # n-th cyclotomic polynomial (as a Polynomial object)
cyclotomic(n,x)             # n-th cyclotomic polynomial evaluated at x
cyclotomicmod(n,x,m)        # n-th cyclotomic polynomial evaluated at x modulo m

lucasU(P, Q, n)             # Lucas sequence: U_n(P, Q)
lucasV(P, Q, n)             # Lucas sequence: V_n(P, Q)

lucasUmod(P, Q, n, m)       # modular Lucas sequence: U_n(P, Q) mod m
lucasVmod(P, Q, n, m)       # modular Lucas sequence: V_n(P, Q) mod m

lucas(n)                    # n-th Lucas number
fib(n, k=2)                 # n-th Fibonacci number of k-th order
fibmod(n, m)                # n-th Fibonacci number modulo m
fibmod(n, k, m)             # n-th k-th order Fibonacci number modulo m

geometric_sum(n,r)          # closed-form to the geometric sum: Sum_{j=0..n} r^j
faulhaber_sum(n,k)          # Faulhaber's formula for: Sum_{j=1..n} j^k
```

Here we have a list of functions related to pseudoprimes:

```ruby
is_carmichael(n)            # true if n is a Carmichael number
is_lucas_carmichael(n)      # true if n is a Lucas-Carmichael number
is_psp(n, B=2)              # true if n is a Fermat pseudoprime base B
is_strong_psp(n, B=2)       # true if n is a strong Fermat pseudoprime base B
is_super_psp(n, B=2)        # true if n is a superpseudoprime to base B
is_over_psp(n, B=2)         # true if n is an overpseudoprime to base B
is_chebyshev_psp(n)         # true if n is a Chebyshev pseudoprime
is_euler_psp(n, B=2)        # true if n is an Euler pseudoprime to base B
is_pell_psp(n)              # true if n is a Pell pseudoprime: U_n(2, -1) = (2|n) (mod n)
is_abs_euler_psp(n)         # true if n is an absolute Euler pseudoprime
is_lucasU_psp(n,P=1,Q=-1)   # true if Lucas sequence U_n(P,Q) = 0 (mod n)
is_lucasV_psp(n,P=1,Q=-1)   # true if Lucas sequence V_n(P,Q) = P (mod n)

k.fermat_psp(B,a,b)         # Fermat pseudoprimes to base B with k distinct prime factors in range a..b
k.strong_fermat_psp(B,a,b)  # strong Fermat pseudoprimes to base B with k distinct prime factors in range a..b
k.carmichael(a,b)           # Carmichael numbers with k prime factors in range a..b
k.lucas_carmichael(a,b)     # Lucas-Carmichael numbers with k prime factors in range a..b
```

Additionally, here's a list of functions involving various `k-property` numbers:

```ruby
k.smooth_count(n)           # count of k-smooth numbers <= n
k.rough_count(n)            # count of k-rough numbers <= n

n.is_almost_prime(k)        # true if n is k-almost prime (i.e.: Omega(n) = k)
n.is_omega_prime(k)         # true if n is k-omega prime (i.e.: omega(n) = k)
n.is_powerful(k)            # true if n is k-powerful
n.is_powerfree(k)           # true if n is k-powerfree
n.is_nonpowerfree(k)        # true if n is k-nonpowerfree

k.omega_primes(a,b)         # generate k-omega primes in the range a..b
k.almost_primes(a,b)        # generate k-almost primes in the range a..b
k.omega_prime_count(a,b)    # count of k-omega primes in the range a..b
k.almost_prime_count(a,b)   # count of k-almost primes in the range a..b

k.powerfree(a,b)            # generate k-powerfree numbers in the range a..b
k.powerful(a,b)             # generate k-powerful numbers in the range a..b
k.nonpowerfree(a,b)         # generate k-nonpowerfree numbers in the range a..b

k.powerfree_count(a,b)      # count of k-powerfree numbers in the range a..b
k.powerful_count(a,b)       # count of k-powerful numbers in the range a..b
k.nonpowerfree_count(a,b)   # count of k-nonpowerfree numbers in the range a..b

k.omega_prime_sum(a,b)      # sum of k-omega primes in the range a..b
k.almost_prime_sum(a,b)     # sum of k-almost primes in the range a..b
k.powerful_sum(a,b)         # sum of k-powerful numbers in the range a..b
k.powerfree_sum(a,b)        # sum of k-powerfree numbers in the range a..b
k.nonpowerfree_sum(a,b)     # sum of k-nonpowerfree numbers in the range a..b

k.smooth_divisors(n)        # k-smooth divisors of n
k.rough_divisors(n)         # k-rough divisors of n
k.power_divisors(n)         # k-th power divisors of n
k.power_udivisors(n)        # k-th power unitary divisors of n
k.powerfree_divisors(n)     # k-powerfree divisors of n
k.powerfree_udivisors(n)    # k-powerfree unitary divisors of n
```

For the full documentation of each function, please see: [https://metacpan.org/pod/Sidef::Types::Number::Number](https://metacpan.org/pod/Sidef::Types::Number::Number) ([PDF](https://github.com/trizen/sidef/releases/download/25.12/sidef-number-class-documentation.pdf))

# Generating sequences

The first $n$ terms of a sequence can be easily generated by using the following constructs:

```ruby
n.by {|k| ... }         # collect the first n integers >= 0 for which the block returns true
n.of {|k| ... }         # calls the block with the first n integers >= 0 and collects the results
```

And there is also the `map` method, which maps the values in a given range to a given block, collecting the results:

```ruby
map(a..b, {|k| ... })   # returns an array
{|k| ... }.map(a..b)    # same as above
```

It's conventional in Sidef to use an implicit method call on the block argument (`_`), without storing the argument in a named variable:

```ruby
# First 10 composite numbers
say 10.by { .is_composite }         #=> [4, 6, 8, 9, 10, 12, 14, 15, 16, 18]

# Values of phi(x) in range 0..9
say 10.of { .phi }                  #=> [0, 1, 1, 2, 2, 4, 2, 6, 4, 6]

# Values of phi(x) in range 20..30
say map(20..30, { .phi })           #=> [8, 12, 10, 22, 8, 20, 12, 18, 12, 28, 8]
```

Additionally, there is also the `Math.seq()` function, that constructs an infinite lazy sequence:

```ruby
say Math.seq(2, {|a| a[-1].next_prime }).first(30)                  # prime numbers
say Math.seq(0, 1, {|a| a.last(2).sum }).first(30)                  # Fibonacci numbers
say Math.seq(1, 1, {|a,n| a[-1] + n*subfactorial(n-1) }).first(10)  # OEIS: A177265
say Math.seq(1, {|a| a[-1].next_omega_prime(2) }).first(20)         # OEIS: A007774
```

# User-defined functions

A function can be defined by using the `func` keyword:

```ruby
func function_name(a,b,c,...) {
    ...
}
```

Additionally, when calling a built-in method that requires a block (`{...}`), a user-defined function name can be provided instead:

```ruby
func my_condition(n) { n.is_composite && n.is_squarefree }
say 10.by(my_condition)   # first 10 squarefree composite numbers
```

Implementation of multiplicative functions can be easily done by using the `n.factor_prod{|p,e| ... }` method:

```ruby
func exponential_sigma(n, k=1) {
    n.factor_prod {|p,e|
        e.divisors.sum {|d| p**(d*k) }
    }
}

say map(1..20, {|n| exponential_sigma(n, 1) })
say map(1..20, {|n| exponential_sigma(n, 2) })
say map(1..20, {|n| exponential_sigma(n, 3) })
```

For computing the sum over a given range, we have the `sum(a..b, {|k| ... })` syntax:

```ruby
func harmonic(n) {
    sum(1..n, {|k| 1/k })
}

say 8.of(harmonic)         #=> [0, 1, 3/2, 11/6, 25/12, 137/60, 49/20, 363/140]
```

Similarly, for computing the product over a given range, we have the `prod(a..b, {|k| ... })` syntax:

```ruby
func superfactorial(n) {
    prod(1..n, {|k| k! })
}

say 8.of(superfactorial)   #=> [1, 1, 2, 12, 288, 34560, 24883200, 125411328000]
```

For recursive functions there is also the `is cached` trait, which automatically caches the results of the function:

```ruby
func a(n) is cached {
    return 1 if (n == 0)
    -sum(^n, {|k| a(k) * binomial(n+1, k)**2 }) / (n+1)**2
}

for n in (0..30) {
    printf("(B^S)_1(%2d) = %45s / %s\n", n, a(n) / n! -> nude)
}
```

# Built-in classes

This section briefly describes the built-in classes related to computational number theory.

For the documentation of other built-in classes, please see: [https://trizen.gitbook.io/sidef-lang/](https://trizen.gitbook.io/sidef-lang/) ([PDF](https://github.com/trizen/sidef/releases/download/25.12/sidef-book.pdf)).

## Mod class

The built-in `Mod(a,m)` class is similar to PARI/GP `Mod(a,m)` class, constructing and returning a `Mod` object:

```ruby
var a = Mod(13, 97)

say a**42    # Mod(85, 97)
say 42*a     # Mod(61, 97)

say chinese(Mod(43, 19), Mod(13, 41))   # Chinese Remainder Theorem
```

## Polynomial class

The built-in `Poly()` class can be used for constructing a polynomial object:

```ruby
say Poly(5)                   # monomial: x^5
say Poly([1,2,3,4])           # x^3 + 2*x^2 + 3*x + 4
say Poly(5 => 3, 2 => 10)     # 3*x^5 + 10*x^2
```

## PolyMod class

The `PolyMod()` class represents a modular polynomial:

```ruby
var a = PolyMod([13,4,51], 43)
var b = PolyMod([5,0,-11], 43)

say a*b         #=> 22*x^4 + 20*x^3 + 26*x^2 + 42*x + 41 (mod 43)
say a-b         #=> 8*x^2 + 4*x + 19 (mod 43)
say a+b         #=> 18*x^2 + 4*x + 40 (mod 43)

# Division and remainder
say [a.divmod(b)].join(' and ')         #=> 37 (mod 43) and 4*x + 28 (mod 43)
```

## Gauss class

The `Gauss(a,b)` class represents a Gaussian integer of the form: $a + b i$.

```ruby
say Gauss(3,4)**100
say Mod(Gauss(3,4), 1000001)**100   #=> Mod(Gauss(826585, 77265), 1000001)

var a = Gauss(17,19)
var b = Gauss(43,97)

say (a + b)     #=> Gauss(60, 116)
say (a - b)     #=> Gauss(-26, -78)
say (a * b)     #=> Gauss(-1112, 2466)
say (a / b)     #=> Gauss(99/433, -32/433)
```

## Quadratic class

The `Quadratic(a,b,w)` class represents a quadratic integer of the form: $a + b \sqrt w$.

```ruby
var x = Quadratic(3, 4, 5)      # represents: 3 + 4*sqrt(5)
var y = Quadratic(6, 1, 2)      # represents: 6 + sqrt(2)

say x**10               #=> Quadratic(29578174649, 13203129720, 5)
say y**10               #=> Quadratic(253025888, 176008128, 2)

say x.powmod(100, 97)   #=> Quadratic(83, 42, 5)
say y.powmod(100, 97)   #=> Quadratic(83, 39, 2)
```

## Quaternion class

The `Quaternion(a,b,c,d)` class represents a quaternion integer of the form: $a + b i + c j + d k$.

```ruby
var a = Quaternion(1,2,3,4)
var b = Quaternion(5,6,7,8)

say (a + b)         #=> Quaternion(6, 8, 10, 12)
say (a - b)         #=> Quaternion(-4, -4, -4, -4)
say (a * b)         #=> Quaternion(-60, 12, 30, 24)
say (b * a)         #=> Quaternion(-60, 20, 14, 32)
say (a / b)         #=> Quaternion(35/87, 4/87, 0, 8/87)

say a**5                #=> Quaternion(3916, 1112, 1668, 2224)
say a.powmod(43, 97)    #=> Quaternion(61, 38, 57, 76)
say a.powmod(-5, 43)    #=> Quaternion(11, 22, 33, 1)
```

## Matrix class

The `Matrix()` class builds and returns a Matrix object, which supports various arithmetical operations:

```ruby
var A = Matrix(
    [2, -3,  1],
    [1, -2, -2],
    [3, -4,  1],
)

var B = Matrix(
    [9, -3, -2],
    [3, -1,  7],
    [2, -4, -8],
)

say (A + B)     # matrix addition
say (A - B)     # matrix subtraction
say (A * B)     # matrix multiplication
say (A / B)     # matrix division

say (A + 42)    # matrix-scalar addition
say (A - 42)    # matrix-scalar subtraction
say (A * 42)    # matrix-scalar multiplication
say (A / 42)    # matrix-scalar division

say A**20               # matrix exponentiation
say A**-1               # matrix inverse: A^-1
say A**-2               # (A^2)^-1
say A.powmod(43, 97)    # modular matrix exponentiation

say B.det             # matrix determinant
say B.solve([1,2,3])  # solve a system of linear equations
```

# Computing OEIS sequences

Sidef is particularly useful in quickly generating various sequences, which can then be searched in the [OEIS](https://oeis.org) for finding more information about them:

```ruby
say map(1..50, { .mu })
say map(1..50, { .mertens })
say map(1..50, { .tau })
say map(1..50, { .pi })
say map(1..50, { .liouville })
say map(1..50, { .liouville_sum })
say map(1..50, { .exp_mangoldt })
say map(1..50, { .sopfr })
say map(1..50, { .sopf })
say map(1..50, { .gpf })
say map(1..50, { .lpf })
say map(1..50, { .gpf_sum })
say map(1..50, { .lpf_sum })
say map(1..50, { .rad })
say map(1..50, { .core })

say map(1..50, { .composite_count })
say map(1..50, { .prime_power_count })
say map(1..50, { .perfect_power_count })

say map(1..50, {|n| 2.omega_prime_count(n) })
say map(1..50, {|n| 3.omega_prime_count(n) })

say map(1..50, {|n| 2.almost_prime_count(n) })
say map(1..50, {|n| 3.almost_prime_count(n) })

say map(1..50, {|n| 2.squarefree_almost_prime_count(n) })
say map(1..50, {|n| 3.squarefree_almost_prime_count(n) })

say 30.of { .dirichlet_convolution({.mu}, {_}) }
say 30.of { .dirichlet_convolution({.phi}, {.mu}) }
say 30.of { .dirichlet_convolution({.sigma}, {.phi}) }

say  4.by { .is_perfect }
say 30.by { .is_abundant }
say 30.by { .is_odd && .is_abundant }
say 30.by { .is_cyclic }
say 30.by { .is_fundamental }
say 30.by { .is_primitive_root(5) }
say 30.by { .is_odd_composite }
say 30.by { .is_totient }
say 30.by { .is_rough(3) }
say 30.by { .is_smooth(3) }
say 30.by { .is_safe_prime }
say 30.by { .is_semiprime }
say 30.by { .is_squarefree_semiprime }

say 30.by { .is_palindrome }
say 30.by { .is_palindrome(2) }

say map(1..30, { .nth_prime })
say map(1..30, { .nth_composite })
say map(1..30, { .nth_prime_power })
say map(1..30, { .nth_perfect_power })
say map(1..30, { .nth_composite })
say map(1..30, { .nth_squarefree })
say map(1..30, { .nth_cubefree })
say map(1..30, { .nth_cubefull })
say map(1..30, { .nth_nonsquarefree })
say map(1..30, { .nth_noncubefree })
say map(1..30, { .nth_powerful })
say map(1..30, { .nth_powerful(4) })
say map(1..30, { .nth_powerfree(2) })
say map(1..30, { .nth_powerfree(4) })
say map(1..30, { .nth_nonpowerfree(2) })
say map(1..30, { .nth_nonpowerfree(4) })
say map(1..30, { .nth_almost_prime(3) })
say map(1..30, { .nth_omega_prime(3) })
say map(1..30, { .nth_squarefree_almost_prime(3) })

say 8.of {|n| prime_sum(10**n) }
say 8.of {|n| composite_sum(10**n) }
say 8.of {|n| prime_sum(1, 10**n, 2) }
say 8.of {|n| composite_sum(1, 10**n, 2) }
say 8.of {|n| squarefree_sum(10**n) }

say 8.of {|n| nth_prime(10**n) }
say 8.of {|n| nth_composite(10**n) }
say 8.of {|n| nth_semiprime(10**n) }
say 8.of {|n| nth_squarefree(10**n) }
say 8.of {|n| nth_almost_prime(10**n, 2) }
say 8.of {|n| nth_omega_prime(10**n, 2) }
say 8.of {|n| nth_squarefree_almost_prime(10**n, 2) }

say 30.of {|n| 2.almost_prime_sum(n) }
say 30.of {|n| 2.omega_prime_sum(n) }
say 30.of {|n| 2.squarefree_almost_prime_sum(n) }

say 50.of { .hclassno.nu }
say 50.of { .hclassno.de }
say 50.of { 12 * .hclassno }
say 60.of {|q| ramanujan_sum(2, q) }

say 50.of { .squares_r(2) }
say 50.of { .squares_r(3) }
say 50.of { .squares_r(4) }

say 30.by { .is_pyramidal(5) }
say 30.by { .is_polygonal(5) }
say 30.by { .is_polygonal2(5) }
say 30.by { .is_centered_polygonal(5) }

say 30.of {|n| pyramidal(n, 3) }    # tetrahedral numbers
say 30.of {|n| pyramidal(n, 5) }    # pentagonal pyramidal numbers

say 30.of {|n| centered_polygonal(n, 3) }   # centered triangular numbers
say 30.of {|n| centered_polygonal(n, 6) }   # centered hexagonal numbers

say 30.of { .fib }
say 30.of { .fib(3) }
say 30.of { .lucas }
say 25.of { .motzkin }
say 20.of { .fubini }
say 20.of { .bell }
say 20.of { .factorial }
say 20.of { .subfactorial }
say 20.of { .subfactorial(2) }
say 20.of { .left_factorial }
say 25.of { .primorial }
say 15.of { .pn_primorial }

say map(1..30, { .ramanujan_tau })
say map(1..15, { .secant_number })
say map(1..15, { .tangent_number })

say 15.of {|n| 3.rough_part(n!) }
say 15.of {|n| 3.smooth_part(n!) }
say 10.of {|k| semiprime(10**k) }
say 20.of {|k| semiprime_count(2**k) }
say 20.of {|n| 13.smooth_count(10**n) }
say 10.of {|k| squarefree_semiprime_count(10**k) }
say 30.of {|n| sum_remainders(n, n) }
say 30.of {|n| sum_remainders(n, n.prime) }

say 50.of { .fusc }
say 50.of { .collatz }
say 50.of { .flip }
say 50.of { .flip(2) }
say 50.of { .digital_root }

say 50.of {|n| n.factor_prod {|p,e| p*e } }
say 50.of {|n| n.divisor_sum {|d| psi(d) * sigma(n/d) } }

say 25.of {|n| euler_number(n) }
say 20.of {|n| bernoulli(2*n).nu }
say 20.of {|n| bernoulli(2*n).de }

say 25.of{|n| lucasU(1, -1, n) }    # the Fibonacci numbers
say 25.of{|n| lucasU(2, -1, n) }    # the Pell numbers
say 25.of{|n| lucasU(1, -2, n) }    # the Jacobsthal numbers

say 25.of{|n| lucasV(1, -1, n) }    # the Lucas numbers
say 25.of{|n| lucasV(2, -1, n) }    # the Pell-Lucas numbers
say 25.of{|n| lucasV(1, -2, n) }    # the Jacobsthal-Lucas numbers

say 50.of {|n| polygonal( n, 3) }  # triangular numbers
say 50.of {|n| polygonal( n, 5) }  # pentagonal numbers
say 50.of {|n| polygonal(-n, 5) }  # second pentagonal numbers

say 25.of { .mfac(2) }    # double-factorials
say 25.of { .mfac(3) }    # triple-factorials

say 30.of {|n| n.primitive_part({.fib}) }
say 30.of {|n| 2.powerfree_part_sum(n) }
say 30.of {|n| 3.powerfree_part_sum(n) }

say 50.of {|n| 2.powerfree_part(n) }       # squarefree part of n
say 50.of {|n| 3.powerfree_part(n) }       # cubefree part of n

say 50.of {|n| 2.powerfree_sigma(n) }
say 50.of {|n| 3.powerfree_sigma(n) }

say 50.of {|n| 2.powerfree_usigma(n) }
say 50.of {|n| 2.powerfree_usigma(n, 2) }

say 50.of {|n| 2.power_sigma(n) }
say 50.of {|n| 3.power_sigma(n) }

say 20.by { .is_llr_prime(3) }     # numbers n such that 2^n * 3 - 1 is prime
say 20.by { .is_proth_prime(3) }   # numbers n such that 2^n * 3 + 1 is prime

say map(1..50, { .psi })
say map(1..50, { .phi })
say map(1..50, { .iphi })
say map(1..50, { .bphi })
say map(1..50, { .uphi })
say map(1..50, { .nuphi })
say map(1..50, { .sigma })
say map(1..50, { .usigma })
say map(1..50, { .isigma })
say map(1..50, { .esigma })
say map(1..50, { .bsigma })
say map(1..50, { .nusigma })
say map(1..50, { .nisigma })
say map(1..50, { .nesigma })
say map(1..50, { .nbsigma })

say map(1..50, { .psi(2) })
say map(1..50, { .phi(2) })
say map(1..50, { .sigma(2) })
say map(1..50, { .usigma(2) })
say map(1..50, { .isigma(2) })
say map(1..50, { .esigma(2) })
say map(1..50, { .bsigma(2) })
say map(1..50, { .nusigma(2) })
say map(1..50, { .nisigma(2) })
say map(1..50, { .nesigma(2) })
say map(1..50, { .nbsigma(2) })

say 10.of { .hyperfactorial }
say 10.of { .superfactorial }
say 10.of { .superprimorial }

say map(1..30, { .nth_omega_prime(2) })
say map(1..30, { .nth_omega_prime(3) })

say map(1..30, { .nth_almost_prime(2) })
say map(1..30, { .nth_almost_prime(3) })

say map(1..30, { .nth_squarefree_almost_prime(2) })
say map(1..30, { .nth_squarefree_almost_prime(3) })

say 15.by { .is_carmichael }
say 15.by { .is_lucas_carmichael }

say 15.by { .is_composite && .is_lucas_psp }
say 15.by { .is_composite && .is_strong_lucas_psp }

say 15.by { .is_composite && .is_psp }
say 15.by { .is_composite && .is_psp(3) }

say 15.by { .is_composite && .is_strong_psp }
say 15.by { .is_composite && .is_strong_psp(3) }

say 15.by { .is_composite && .is_euler_psp }
say 15.by { .is_composite && .is_euler_psp(3) }

say 15.by { .is_composite && .is_super_psp }
say 15.by { .is_composite && .is_super_psp(3) }

say 15.by { .is_composite && .is_over_psp }
say 15.by { .is_composite && .is_over_psp(3) }

say 15.by { .is_composite && .is_pell_psp }
say 15.by { .is_composite && .is_pell_lucas_psp }

say 15.by { .is_composite && .is_lucasU_psp }
say 15.by { .is_composite && .is_lucasV_psp }
```

# Finding closed-form to sequences

Given an unknown sequence of integers, we can try to find a closed-form to it, by using polynomial interpolation, which is built into Sidef as `Array.solve_seq()`:

```ruby
say [0, 1, 4, 9, 16, 25, 36, 49, 64, 81].solve_seq      # x^2
say [0, 1, 33, 276, 1300, 4425, 12201].solve_seq        # 1/6*x^6 + 1/2*x^5 + 5/12*x^4 - 1/12*x^2
```

Additionally, we can try to find a linear-recurrence to a sequence, using `Array.solve_rec_seq()`:

```ruby
say [0, 0, 1, 1, 2, 4, 7, 13, 24, 44, 81, 149].solve_rec_seq      # [1, 1, 1]
say [0, 1, 9, 36, 100, 225, 441, 784, 1296, 2025].solve_rec_seq   # [5, -10, 10, -5, 1]
```

The returned linear-recurrence signature can be passed to `Math.linear_rec(signature, initial_terms, from, to)` for efficiently computing the terms in a given range or only the n-th term of the sequence:

```ruby
say Math.linear_rec([1, 1, 1], [0, 0, 1], 0, 20)    # terms in range 0..20
say Math.linear_rec([1, 1, 1], [0, 0, 1], 1000)     # only the 1000-th term
```

If only the remainder is needed, we can use `Math.linear_recmod(signature, initial_terms, n, m)`, which efficiently computes the n-th term modulo $m$:

```ruby
say Math.linear_recmod([5, -10, 10, -5, 1], [0, 1, 9, 36, 100], 2**128, 10**10)   # (2^128)-th term modulo 10^10
```

# Inverse of multiplicative functions

Based on methods by [Max Alekseyev](https://cs.uwaterloo.ca/journals/JIS/VOL19/Alekseyev/alek5.html), Sidef implements support for computing the inverse of the following functions:

* Sum of divisors function: `sigma_k(n)`
* Euler's totient function: `phi(n)`
* Dedekind's Psi function: `psi(n)`
* Unitary totient function: `uphi(n)`
* Unitary sigma function: `usigma(n)`

Example:

```ruby
var n = 252
say inverse_phi(n)          #=> [301, 381, 387, 441, 508, 602, 762, 774, 882]
say inverse_psi(n)          #=> [130, 164, 166, 205, 221, 251]
say inverse_sigma(n)        #=> [96, 130, 166, 205, 221, 251]
say inverse_uphi(n)         #=> [296, 301, 320, 381, 456, 516, 602, 762]
say inverse_usigma(n)       #=> [130, 166, 205, 216, 221, 251]
```

Additionally, there are functions for computing only the minimum or the maximum value, as well as only the number of solutions, all of which can be computed more efficiently than generating all the solutions:

```ruby
var n = 15!

say inverse_sigma_len(n)        #=> 910254
say inverse_sigma_min(n)        #=> 264370186080
say inverse_sigma_max(n)        #=> 1307672080867

say inverse_phi_len(n)          #=> 2852886
say inverse_phi_min(n)          #=> 1307676655073
say inverse_phi_max(n)          #=> 7959363061650

say inverse_psi_len(n)          #=> 1162269
say inverse_psi_min(n)          #=> 370489869750
say inverse_psi_max(n)          #=> 1307672080867
```

# OEIS autoload

[OEIS autoload](https://github.com/trizen/oeis-autoload) is a Sidef command-line tool and a library that implements support for using [OEIS](https://oeis.org) sequences as functions.

The source-code files can be downloaded from:

* backend library: https://raw.githubusercontent.com/trizen/oeis-autoload/main/OEIS.sm
* command-line tool: https://raw.githubusercontent.com/trizen/oeis-autoload/main/oeis.sf

After downloading the above two files, we can execute:

```console
sidef oeis.sf 'A060881(n)' 0 9    # print the first 10 terms of A060881
```

Several other usage examples:

```console
sidef oeis.sf 'A033676(n)^2 + A033677(n)^2'              # first 10 terms
sidef oeis.sf 'A033676(n)^2 + A033677(n)^2' 5            # 5-th term
sidef oeis.sf 'A033676(n)^2 + A033677(n)^2' 5 20         # terms 5..20
```

The ID of a [OEIS](https://oeis.org) sequence can be called like any other function:

```console
sidef oeis.sf 'sum(1..n, {|k| A000330(k) })'
sidef oeis.sf 'sum(0..n, {|k| A048994(n, k) * A048993(n+k, n) })'
```

The `OEIS.sm` library can also be used inside Sidef scripts, by placing it in the same directory with the script:

```ruby
include OEIS
say map(1..10, {|k| A000330(k) })
```

# Non-trivial OEIS sequences

Sidef was extensively used over the years in extending various [OEIS](https://oeis.org) sequences that had the `more` and/or `hard` keywords.

In this section we present several code examples that compute non-trivial [OEIS](https://oeis.org) sequences.

## Generation of pseudoprimes

---

**[A007011](https://oeis.org/A007011)**: Smallest pseudoprime to base $2$ with $n$ prime factors.

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

**NOTE:** there is also the `n.squarefree_fermat_psp(base, x, y)` method, which is slightly faster.

---

**[A180065](https://oeis.org/A180065)**: Smallest strong pseudoprime to base $2$ with $n$ prime factors.

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

**NOTE:** there is also the `n.squarefree_strong_fermat_psp(base, x, y)` method, which is slightly faster.

---

**[A271874](https://oeis.org/A271874)**: Smallest Fermat pseudoprime to base $n$ with $n$ distinct prime factors.

```ruby
func A271874(n, k=n) {
    return nil if (n < 2)

    var x = pn_primorial(k)
    var y = 2*x

    loop {
        var arr = k.fermat_psp(n,x,y)
        return arr[0] if arr
        x = y+1
        y = 2*x
    }
}

for n in (2..100) { print(A271874(n), ", ") }
```

---

**[A271873](https://oeis.org/A271873)**: Square array $A(n, k)$ read by antidiagonals downwards: smallest Fermat pseudoprime to base $n$ with $k$ distinct prime factors for $k$, $n$ >= $2$.

```ruby
{|x| {|y| A271874(x,y) }.map(2..10) }.map(2..10).each { .say }  # takes 0.5 seconds
```

(reusing the `A271874(n,k)` function defined above)

---

**[A006931](https://oeis.org/A006931)**: Least Carmichael number with $n$ prime factors.

```ruby
func A006931(n) {
    return nil if (n < 3)

    var x = pn_primorial(n+1)/2
    var y = 3*x

    loop {
        var arr = n.carmichael(x,y)
        return arr[0] if arr
        x = y+1
        y = 3*x
    }
}

for n in (3..100) { print(A006931(n), ", ") }
```

---

**[A216928](https://oeis.org/A216928)**: Least Lucas-Carmichael number with $n$ prime factors.

```ruby
func A216928(n) {
    return nil if (n < 3)

    var x = pn_primorial(n+1)/2
    var y = 3*x

    loop {
        var arr = n.lucas_carmichael(x,y)
        return arr[0] if arr
        x = y+1
        y = 3*x
    }
}

for n in (3..100) { print(A216928(n), ", ") }
```

---

**[A356866](https://oeis.org/A356866)**: Smallest Carmichael number ([A002997](https://oeis.org/A002997)) with $n$ prime factors that is also a strong pseudoprime to base $2$ ([A001262](https://oeis.org/A001262)).

```ruby
func A356866(n) {
    return nil if (n < 3)

    var x = pn_primorial(n+1)/2
    var y = 3*x

    loop {
        var arr = n.strong_fermat_carmichael(2,x,y)
        return arr[0] if arr
        x = y+1
        y = 3*x
    }
}

for n in (3..100) { print(A356866(n), ", ") }
```

---

## Numbers with $n$ prime factors

---

**[A219018](https://oeis.org/A219018)**: Smallest $k > 1$ such that $k^n + 1$ has exactly $n$ distinct prime factors.

```ruby
func A219018(n) {
    for k in (1..Inf) {
        var v = (k**n + 1)
        v.is_omega_prime(n) || next
        return k
    }
}

for n in (1..100) { print(A219018(n), ", ") }
```

---

**[A219019](https://oeis.org/A219019)**: Smallest $k > 1$ such that $k^n - 1$ has exactly $n$ distinct prime divisors.

```ruby
func A219019(n) {
    for k in (1..Inf) {
        var v = (k**n - 1)
        v.is_omega_prime(n) || next
        return k
    }
}

for n in (1..100) { print(A219019(n), ", ") }
```

---

**[A359070](https://oeis.org/A359070)**: Smallest $k > 1$ such that $k^n - 1$ is the product of $n$ distinct primes.

```ruby
func A359070(n) {
    for k in (1..Inf) {
        is_squarefree(k-1) || next
        var v = (k**n - 1)
        v.is_squarefree_almost_prime(n) || next
        return k
    }
}

for n in (1..100) { print(A359070(n), ", ") }
```

---

**[A242786](https://oeis.org/A242786)**: Least prime $p$ such that $p^n$ and $p^n+1$ have the same number of prime factors (counted with multiplicity) or $0$ if no such number exists.

```ruby
func A242786(n) {
    for (var p = 2; true; p.next_prime!) {
        var v = (p**n + 1)
        v.is_almost_prime(n) || next
        return p
    }
}

for n in (1..100) { print(A242786(n), ", ") }
```

---

**[A241793](https://oeis.org/A241793)**: Least number $k$ such that $k^n$ and $k^n-1$ contain the same number of prime factors (counted with multiplicity) or $0$ if no such $k$ exists.

```ruby
func A241793(n) {
    for k in (1..Inf) {
        var b = bigomega(k)*n
        var v = (k**n - 1)
        is_almost_prime(v, b) || next
        return k
    }
}

for n in (1..100) { print(A241793(n), ", ") }
```

---

**[A281940](https://oeis.org/A281940)**: Least $k$ such that $k^n + 1$ is the product of $n$ distinct primes ($k > 0$).

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

---

**[A280005](https://oeis.org/A280005)**: Least prime $p$ such that $p^n + 1$ is the product of $n$ distinct primes.

```ruby
func A280005(n) {
    for(var p = 2; true; p.next_prime!) {
        var v = (p**n + 1)
        v.is_squarefree_almost_prime(n) || next
        return p
    }
}

for n in (1..100) { print(A280005(n), ", ") }
```

---

**[A358863](https://oeis.org/A358863)**: $a(n)$ is the smallest n-gonal number with exactly $n$ prime factors (counted with multiplicity).

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

Alternative solution:

```ruby
func A358863(n, from = 2**n, upto = 2*from) {
    loop {
        n.almost_primes(from, upto).each {|v|
            v.is_polygonal(n) || next
            return v
        }
        from = upto+1
        upto = idiv(3*upto, 2)
    }
}

for n in (3..100) { print(A358863(n), ", ") }
```

---

**[A358865](https://oeis.org/A358865)**: $a(n)$ is the smallest n-gonal pyramidal number with exactly $n$ prime factors (counted with multiplicity).

```ruby
func A358865(n) {
    for k in (1..Inf) {
        var v = pyramidal(k, n)
        v.is_almost_prime(n) || next
        return v
    }
}

for n in (3..100) { print(A358865(n), ", ") }
```

---

**[A358862](https://oeis.org/A358862)**: $a(n)$ is the smallest n-gonal number with exactly $n$ distinct prime factors.

```ruby
func A358862(n) {
    for k in (1..Inf) {
        var v = polygonal(k, n)
        v.is_omega_prime(n) || next
        return v
    }
}

for n in (3..100) { print(A358862(n), ", ") }
```

Alternative solution:

```ruby
func A358862(n, from = n.pn_primorial, upto = 2*from) {
    loop {
        n.omega_primes(from, upto).each {|v|
            v.is_polygonal(n) || next
            return v
        }
        from = upto+1
        upto *= 2
    }
}

for n in (3..100) { print(A358862(n), ", ") }
```

---

**[A358864](https://oeis.org/A358864)**: $a(n)$ is the smallest n-gonal pyramidal number with exactly $n$ distinct prime factors.

```ruby
func A358864(n) {
    for k in (1..Inf) {
        var v = pyramidal(k, n)
        v.is_omega_prime(n) || next
        return v
    }
}

for n in (3..100) { print(A358864(n), ", ") }
```

---

**[A127637](https://oeis.org/A127637)**: Smallest squarefree triangular number with exactly $n$ prime factors.

```ruby
func A127637(n, from = n.pn_primorial, upto = 2*from) {
    loop {
        n.squarefree_almost_primes(from, upto).each {|v|
            v.is_polygonal(3) || next
            return v
        }
        from = upto+1
        upto *= 2
    }
}

for n in (1..100) { print(A127637(n), ", ") }
```

---

**[A239696](https://oeis.org/A239696)**: Smallest number $m$ such that $m$ and `reverse(m)` each have $n$ distinct prime factors.

```ruby
func A239696(n, from = n.pn_primorial, upto = 2*from) {
    loop {
        n.omega_primes(from, upto).each {|v|
            v.reverse.is_omega_prime(n) || next
            return v
        }
        from = upto+1
        upto *= 2
    }
}

for n in (1..100) { print(A239696(n), ", ") }
```

---

**[A291138](https://oeis.org/A291138)**: $a(n)$ is the smallest $k$ such that $\psi(k)$ and $\phi(k)$ have same distinct prime factors when $k$ is the product of $n$ distinct primes, or $0$ if no such $k$ exists.

```ruby
func A291138(n, from = n.pn_primorial, upto = 2*from) {
    loop {
        n.squarefree_almost_primes_each(from, upto, {|v|
            var a = v.phi
            var b = v.psi
            a.is_smooth_over_prod(b) || next
            b.is_smooth_over_prod(a) || next
            return v
        })
        from = upto+1
        upto *= 2
    }
}

for n in (1..100) { print(A291138(n), ", ") }
```

---

## Inverse of multiplicative functions

---

**[A329660](https://oeis.org/A329660)**: Numbers $m$ such that $\sigma(m)$ is a Lucas number ([A000032](https://oeis.org/A000032)), where $\sigma(m)$ is the sum of divisors of $m$ ([A000203](https://oeis.org/A000203)).

```ruby
for k in (1..1000) {
    var arr = k.lucas.inverse_sigma
    print(arr.join(", "), ", ") if arr
}
```

---

**[A291487](https://oeis.org/A291487)**: $a(n)$ is the smallest $k$ such that $\psi(k) = n!$, or $0$ if no such $k$ exists (`psi(k) =` [A001615](https://oeis.org/A001615)(k)).

```ruby
for k in (1..100) {
    print(k!.inverse_psi_min || 0, ", ")
}
```

---

**[A291356](https://oeis.org/A291356)**: $a(n)$ is the smallest $k$ such that `usigma(k) =` [A002110](https://oeis.org/A002110)(n), or $0$ if no such $k$ exists.

```ruby
for k in (1..100) {
    print(k.pn_primorial.inverse_usigma.first || 0, ", ")
}
```

---

## Counting functions

---

**[A106629](https://oeis.org/A106629)**: Number of positive integers $<= 10^n$ that are divisible by no prime exceeding $13$.

```ruby
for n in (0..100) {
    print(13.smooth_count(10**n), ", ")
}
```

---

**[A116429](https://oeis.org/A116429)**: The number of n-almost primes less than or equal to $9^n$, starting with $a(0)=1$.

```ruby
for n in (0..100) {
    print(n.almost_prime_count(9**n), ", ")
}
```

---

**[A062761](https://oeis.org/A062761)**: Number of powerful numbers between $2^{n-1}+1$ and $2^n$.

```ruby
for n in (1..100) {
    print(2.powerful_count(2**(n-1) + 1, 2**n), ", ")
}
```

---

## Misc sequences

---

**[A323697](https://oeis.org/A323697)**: Primes $p$ such that the norm of the quadratic-field analog of Mersenne numbers $M_{p,\alpha} = (\alpha^p - 1)/(\alpha - 1)$, with $\alpha = 2 + \sqrt 2$, is a rational prime.

```ruby
var alpha = (2 + sqrtQ(2))    # creates a Quadratic integer

each_prime(2, 1e6, {|p|
    var k = norm((alpha**p - 1) / (alpha-1))
    print(p, ", ") if k.is_prime
})
```

---

**[A061682](https://oeis.org/A061682)**: Length of period of continued fraction expansion of square root of $2^{2n+1}+1$.

```ruby
for n in  (2..100) {
    print(sqrt_cfrac_period_len(2**(2*n + 1) + 1), ", ")
}
```

---

**[A139822](https://oeis.org/A139822)**: Denominator of `BernoulliB(10^n)`.

```ruby
func bernoulli_denominator(n) {   # Von Staudt-Clausen theorem

    return 1 if (n == 0)
    return 2 if (n == 1)
    return 1 if n.is_odd

    n.divisors.grep {|d| is_prime(d+1) }.prod {|d| d+1 }
}

for n in (0..10) { print(bernoulli_denominator(10**n), ", ") }
```

---

**[A071255](https://oeis.org/A071255)**: $a(1) = 2$, $a(n+1) = a(n)$-th squarefree number.

```ruby
var n = 1
var prev = n+1

for (1..100) {
    n = nth_squarefree(n+1)
    assert_eq(n.squarefree_count, prev)
    print(n, ", ")
    prev = n+1
}
```

---

**[A037274](https://oeis.org/A037274)**: Home primes: for $n >= 2$, $a(n)$ is the prime that is finally reached when you start with $n$, concatenate its prime factors ([A037276](https://oeis.org/A037276)) and repeat until a prime is reached ($a(n) = -1$ if no prime is ever reached).

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

---

**[A359492](https://oeis.org/A359492)**: $a(n)$ is the least number of the form $p^2 + q^2 - 2$ for primes $p$ and $q$ that is an odd prime times $2^n$, or $-1$ if there is no such number.

```ruby
func A359492(n) {
    var t = 2**n
    for (var p = 3; true; p.next_prime!) {
        if (sum_of_squares(t*p + 2).any {.all_prime}) {
            return (t*p)
        }
    }
}

for n in (3..100) { print(A359492(n), ", ") }
```

---

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

**[A357435](https://oeis.org/A357435)**: $a(n)$ is the least prime $p$ such that $p^2+4$ is a prime times $5^n$.

```ruby
func A357435(n, solution = Inf) {
    var m = 5**n

    for x in (modular_quadratic_formula(1, 0, 4, m)) {

        x > solution && break

        for k in (0 .. Inf) {
            var p = (m*k + x)

            p > solution && break
            p.is_prime || next

            var u = (p**2 + 4)
            u.is_power_of(5) || u.remdiv(5).is_prime || next

            var v = (u.valuation(5) - (u.is_power_of(5) ? 1 : 0))

            if (v == n) {
                solution = min(p, solution)
            }
        }
    }

    return solution
}

for n in (0..100) { print(A357435(n), ", ") }
```

---

# Integer factorization

Sidef includes many special-purpose integer factorization methods, which are combined under a single function:

```ruby
special_factor(n, effort=1)     # tries to find special factors of n
```

The `special_factor(n)` function efficiently tries to find special factors (not necessarily prime) of a large integer $n$, using various special-purpose factorization methods, such as:

* Trial division
* Fermat factorization method
* HOLF method
* S. Germain factorization method
* Pell factorization method
* Phi-finder method
* Difference of powers method
* Congruence of powers method
* Miller factorization method
* Lucas factorization method
* Fibonacci factorization method
* FLT factorization method
* Pollard's p-1 method
* Pollard's rho method
* Williams' p+1 method
* Chebyshev factorization method
* Cyclotomic factorization method
* Lenstra's Elliptic Curve Method

Some of these special-purpose factorization methods are described in [this blog post](https://trizenx.blogspot.com/2019/08/special-purpose-factorization-algorithms.html).

By providing an integer argument for `effort` greater than $1$, the function increases the amount of tries accordingly, before giving up. For example, `special_factor(n, 2)` will double the number of tries.

The method returns an array with the factors of $n$. The product of the factors will give back $n$, but some factors may be composite.

Here are some examples where `special_factor(n)` excels:

```ruby
say special_factor(lucas(480))                   # finds all prime factors, taking 0.01s
say special_factor(fibonacci(480))               # finds all prime factors, taking 0.01s
say special_factor(fibonacci(361)**2 + 1)        # finds all prime factors, taking 0.05s

say special_factor(2**512 - 1)                   # finds 12 factors, taking 1.5s
say special_factor(10**122 - 15**44)             # finds all prime factors, taking 0.1s
say special_factor(17**48 + 17**120)             # finds all prime factors, taking 0.1s
say special_factor((3**120 + 1) * (5**240 - 1))  # finds all prime factors, taking 0.1s

say special_factor(181490268975016506576033519670430436718066889008242598463521)
say special_factor(173315617708997561998574166143524347111328490824959334367069087)
say special_factor(5373477536385214579076118706681399189136056405078551802232403683)
say special_factor(57981220983721718930050466285761618141354457135475808219583649146881)
say special_factor(2425361208749736840354501506901183117777758034612345610725789878400467)
say special_factor(2828427124746190097638422773161207685721457240278848640927457308905928537636961)
say special_factor(90000000000000000000000000000000000002689807631151675321570673859864194363258374661)
say special_factor(1000000000000000000000110940350000000000000004102587086035000000000050571383025434301)
say special_factor(178558027781611975691578574219321581742259878171663349730859376950932642242171853408904221)
say special_factor(6384263073451390405968126023273631892411500902402571736234793541658288688275134678964387652)
say special_factor(1000000000000000000000000000367000000000000000000000000038559000000000000000000000001190673)
say special_factor(999999999999999999999999999977900000000000000000000000000143909999999999999999999999999752869)
```

The function `special_factor(n)` is also used internally in `factor(n)` for large enough $n$, making all the number theory functions, that depend on the factorization of $n$, very fast for special values of $n$.

Additionally, the following special-purpose factorization methods can be used individually:

```ruby
n.trial_factor(limit)               # Trial division
n.fermat_factor(k=1e4)              # Fermat factorization method
n.holf_factor(tries=1e4)            # HOLF method
n.sophie_germain_factor             # Sophie Germain factorization method
n.dop_factor(tries=n.ilog2)         # Difference of powers method
n.cop_factor(tries=n.ilog2)         # Congruence of powers method
n.cyclotomic_factor(bases...)       # Cyclotomic factorization method
n.ecm_factor(B1, curves)            # Elliptic curve method
n.fib_factor(upto = 2*n.ilog2)      # Fibonacci factorization method
n.flt_factor(base=2, tries=1e4)     # Fermat's Little Theorem method
n.miller_factor(tries=100)          # Miller factorization method
n.lucas_factor(j=1, tries=100)      # Lucas factorization method
n.mbe_factor(tries=10)              # Modular Binary Exponentiation method
n.prho_factor(tries)                # Pollard's rho factorization method
n.pbrent_factor(tries)              # Pollard-Brent factorization method
n.pell_factor(tries=1e4)            # Pell factorization method
n.phi_finder_factor(tries=1e4)      # Phi-finder method
n.pm1_factor(B)                     # Pollard's p-1 method
n.pp1_factor(B)                     # Williams' p+1 method
n.chebyshev_factor(B,x)             # Chebyshev T factorization method
n.squfof_factor(tries=1e4)          # Shanks’ square forms method
n.qs_factor                         # Quadratic sieve factorization
```

# Where Sidef excels

This section includes several examples in which Sidef does very well in terms of performance.

## Identification of k-almost primes

The following $3$ functions use efficient trial-division (based on primorials) to obtain a bound $B$, trying to disprove that $n$ has a given number of prime factors:

```ruby
n.is_almost_prime(k)                # true if Omega(n) == k
n.is_omega_prime(k)                 # true if omega(n) == k
n.is_squarefree_almost_prime(k)     # true if omega(n) == k and n is squarefree
```

For an integer $n$ to have at least $k$ prime factors, without having any prime factors less than or equal to $B$, it necessitates $n$ to be greater than $B^k$. This condition arises because all prime factors of $n$ exceed the value of $B$.

Moreover, the function internally invokes `special_factor(n)` and promptly concludes if the composite part of $n$ falls below the required threshold to attain $k-j$ prime factors.

A significant speed enhancement could be achieved by using ECM with conjectured bounds to increase $B$ much higher than what can now be achieved with trial-division. This would effectively reject numerous numbers more swiftly.

Another conjectured approach would be using Pollard's rho method to find a larger bound for $B$, which requires $O(\sqrt B)$ steps to find a prime factor less than $B$. Therefore, if we take $B = 10^{12}$, after $O(10^6)$ iterations of the Pollard rho method without success in finding a prime factor of $n$, it's very likely that $n$ has no prime factor less than $10^{12}$.

This latter approach can be enabled by setting `Num!USE_CONJECTURES = true` and is useful for computing upper bounds, being approximately 5x faster than the rigorous method.

## Factorization of integers of special form

The `factor(n)` function is very fast for integers of special form that can be factorized by the `special_factor(n)` function.

This performance is extended to all the other built-in functions that require the prime factorization of $n$:

```ruby
var p = (primorial(557)*144 + 1)
var q = (primorial(557)*288 + 1)

assert(p.is_prov_prime)
assert(q.is_prov_prime)

say factor(p * q)                   # takes 0.01s
say is_carmichael(p * q)            # false (also takes 0.01s)
say phi(p * q)                      # this also takes 0.01s
```

## Modular binomial

Another function that is very well optimized in Sidef, is `binomial(n,k,m)`:

```ruby
say binomialmod(1e20, 1e13, 20!)                        # takes 0.01s
say binomialmod(2**60 - 99, 1e5, next_prime(2**64))     # takes 0.15s
say binomialmod(4294967291 + 1, 1e5, 4294967291**2)     # takes 0.08s
say binomialmod(1e10, 1e4, (2**128 - 1)**2)             # takes 0.01s
say binomialmod(1e10, 1e10 - 1e5, 2**127 - 1)           # takes 0.11s
say binomialmod(1e10, 1e5, 2**127 - 1)                  # takes 0.08s
say binomialmod(1e10, 1e6, 2**127 - 1)                  # takes 1.28s
```

## Sum of $k$ squares function

The sum of squares function `r_k(n)` returns the number of ways of representing $n$ as a sum of $k$ squares.

```ruby
say 30.of { .squares_r(2) }     # OEIS: A004018
say 30.of { .squares_r(3) }     # OEIS: A005875
say 30.of { .squares_r(4) }     # OEIS: A000118
```

The Sidef implementation uses fast algorithms for `k = {2, 4, 6, 8, 10}` based on the prime factorization of $n$:

```ruby
say squares_r(2**128 + 1, 2)       # takes 0.49s
say squares_r(2**128 - 1, 4)       # takes 0.01s
say squares_r(2**128 - 1, 6)       # takes 0.01s
say squares_r(2**128 - 1, 10)      # takes 0.01s
```

The case $k = 3$ is also decently fast for values of $n$ up to about $2^{40}$:

```ruby
say squares_r(2**40 + 1, 3)    # 15312384 (takes 2.5s)
say squares_r(2**42 + 1, 3)    # 19943424 (takes 5.7s)
```

In general, any positive value of $k$ is supported, but only the above ones are specially optimized:

```ruby
say squares_r(5040, 15)       # 3354826635339287557503600 (takes 6.78s)
```

The other cases, like $k = 7$, recursively count the number of solutions based on the solutions for $k-1$:

```ruby
say squares_r(2**32 + 1, 7)   # 18040153467917470423562112 (takes 0.91s)
say squares_r(2**32 + 1, 11)  # 239232267533254255253533478654408687317150080 (takes 3.96s)
```

# Making Sidef faster

It's possible to make certain functions faster, by using external tools and resources, such as [FactorDB](http://factordb.com), [YAFU](https://github.com/bbuhrow/yafu), [PFGW64](https://sourceforge.net/projects/openpfgw/), [PARI/GP](http://pari.math.u-bordeaux.fr/), [primecount](https://github.com/kimwalisch/primecount) and [primesum](https://github.com/kimwalisch/primesum), which can be enabled in the following lines of code (which must be placed at the top of a program):

```ruby
Num!USE_YAFU       = false      # true to use YAFU for factoring large integers
Num!USE_PFGW       = false      # true to use PFGW64 as a primality pretest for large enough n
Num!USE_PARI_GP    = false      # true to use PARI/GP in several functions
Num!USE_FACTORDB   = false      # true to use factordb.com for factoring large integers
Num!USE_PRIMESUM   = false      # true to use Kim Walisch's primesum in prime_sum(n)
Num!USE_PRIMECOUNT = false      # true to use Kim Walisch's primecount in prime_count(n)
```

When these external tools and resources are being used, some debugging information is printed out, which can be seen by setting:

```ruby
Num!VERBOSE = true      # true to enable verbose/debug mode
```

Here's an example using [FactorDB](http://factordb.com) to retrieve the prime factorization of a large integer:

```ruby
Num!VERBOSE = true
Num!USE_FACTORDB = true
say factor(43**97 + 1)
```

Alternatively, the features can be enabled from the command-line as well, using the `-N` option:

```console
sidef -N "VERBOSE=1; USE_FACTORDB=1;" script.sf
```

It's also highly recommended to install the [Math::Prime::Util](https://metacpan.org/pod/Math::Prime::Util) Perl module, which provides great performance in many functions for native integers.

If possible, the [GitHub version](https://github.com/danaj/Math-Prime-Util) is recommended instead, which includes many new functions and optimizations not yet released on MetaCPAN:

```console
cpanm --sudo -nv https://github.com/danaj/Math-Prime-Util-GMP/archive/refs/heads/master.zip
cpanm --sudo -nv https://github.com/danaj/Math-Prime-Util/archive/refs/heads/master.zip
```

# Tips and tricks

This section provides various tips and tricks to achieve a better performance when solving specific problems.

## Primality testing

When multiple numbers necessitate simultaneous primality verification, using the `all_prime(...)` function proves faster than individually invoking `is_prime(n)` for each number.

The advantage lies in the ability to expedite processing: if one term is composite, containing small prime factors, `all_prime(...)` swiftly returns without performing primality tests, acknowledging the composite nature of at least one term.

Moreover, if no small prime factor is found for any provided term, the function does a strong Fermat test to base $2$ for each term. It attempts early termination if any term fails this test.

Lastly, the function performs an extra-strong Lucas test on each term, resulting in a BPSW test.

```ruby
all_prime(a, b)      # overall faster than: (is_prime(a) && is_prime(b))
```

Sidef also provides the very fast `primality_pretest(n)` function, which tries to find a small prime factors of $n$, returning `false` if $n$ is definitely not a prime number.

## Squarefree checking

When checking if a given number $n$ is squarefree, rather than fully factoring the number, is enough to find a square factor of $n$, which instantly proves that $n$ is not squarefree.

In this regard, Sidef provides the `is_prob_squarefree(n, B)` function, which checks if $n$ is divisible by a square $p^2$ with $p <= B$:

```ruby
say is_prob_squarefree(2**512 - 1, 1e6)     # true   (probably squarefree)
say is_prob_squarefree(10**136 + 1, 1e3)    # false  (definitely not squarefree)
```

If $n$ is less than $B^3$, and the function returns `true`, then $n$ is definitely squarefree.

If the $B$ parameter is omitted, multiple limits are tested internally, trying to find a square factor of $n$, up to $B = 10^7$.

# More examples

For more Sidef code examples, please see: [https://github.com/trizen/sidef-scripts](https://github.com/trizen/sidef-scripts)

# The end

If you have any questions related to Sidef, please ask here:

* https://github.com/trizen/sidef/discussions/categories/q-a
