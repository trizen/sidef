# Introduction

In this tutorial we're going to look how we can use Sidef for doing various computations in number theory.

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

To get started with Sidef and how to install it, see [beginner's tutorial](https://github.com/trizen/sidef/blob/master/TUTORIAL.md).

Over the years, Sidef incorporated more and more mathematical functions, many of them provided by Dana Jacobsen's excellent [Math::Prime::Util](https://github.com/danaj/Math-Prime-Util) and [Math::Prime::Util::GMP](https://github.com/danaj/Math-Prime-Util-GMP) Perl modules, which provide great performance in tasks involving integer factorization, primality testing and prime counting.

Currently, there are over `1,000` numerical functions built into Sidef: [see source code](https://github.com/trizen/sidef/blob/master/lib/Sidef/Types/Number/Number.pm).

Most functions are comparable in speed to PARI/GP and Mathematica, while a few of them are a little bit slower and some of them are faster.

Sidef includes support for big integers, rationals, Gaussian integers, Quaternion integers, Quadratic integers, matrices, polynomials and floating-points of arbitrary precision (both real and complex), using the [GMP](https://gmplib.org/), [MPFR](http://www.mpfr.org/) and [MPC](http://www.multiprecision.org/) C libraries.

# Basic usage

After [installing Sidef](https://github.com/trizen/sidef/blob/master/TUTORIAL.md), we can start the REPL by executing the `sidef` command in a console:

```
$ sidef
Sidef 23.08, running on Linux, using Perl v5.38.0.
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
$ sidef script.sf
```

Some basic functionality of the language:

```ruby
var x = 42      # variable declaration
var y = x**3    # compute x^3 and store the result in y
say (x + y)     # print the result of x+y
```

# Number theoretic functions

Below we have a small collection of popular functions used in computational number theory:

```ruby
is_prime(n)                 # true if n is a probable prime (B-PSW test)
is_prov_prime(n)            # true if n is a provable prime
is_composite(n)             # true if n is a composite number
is_squarefree(n)            # true if n is squarefree

factor(n)                   # array with the prime factors of n
divisors(n)                 # array with the positive divisors of n
tau(n)                      # count of divisors of n
omega(n)                    # omega function: number of distinct primes of n
Omega(n)                    # Omega function: number of primes of n counted with multiplicity
sigma(n,k=1)                # sigma_k(n) function: sum of divisors of n
psi(n,k=1)                  # Dedekind's Psi function
phi(n)                      # Euler's totient function
jordan_totient(n,k=1)       # Jordan's totient function: J_k(n)
pi(n)                       # count of primes <= n
pi(a,b)                     # count of primes in the range a..b

factorial(n)                # n-th factorial (equivalently: n!)
mfactorial(n,k)             # k-multi-factorial of n (where k=2 means n!!)
binomial(n,k)               # the binomial coefficient: n!/((n-k)! * k!)
binomialmod(n,k,m)          # binomial(n,k) modulo m
factorialmod(n,m)           # factorial(n) modulo m

prime(n)                    # n-th prime number
primes(a,b)                 # array of primes in the range a..b
prime_sum(a,b,k=1)          # sum of primes: Sum_{a <= p prime <= b} p^k

composite(n)                # n-th composite number
composites(a,b)             # array of composites in the range a..b
composite_count(n)          # count of composites <= n
composite_sum(a,b,k=1)      # sum of composites: Sum_{a <= c composite <= b} c^k

prime_power_count(n)        # count of prime powers <= n
perfect_power_count(n)      # count of perfect powers <= n

mu(n)                       # Moebius function
mertens(n)                  # Mertens function: partial sums of mu(n)

lpf(n)                      # least prime factor of n, with lpf(1) = 1
gpf(n)                      # greatest prime factor of n, with gpf(1) = 1

sqrtmod(a,n)                # find a solution x to the congruence x^2 == a (mod n)
sqrtmod_all(a,n)            # find all solutions x to the congruence x^2 == a (mod n)

sqrtQ(n)                    # square root of n as a Quadratic object
powmod(n,k,m)               # modular exponentation: n^k (mod m)
expnorm(n,B=10)             # exp(n) normalized to base B in interval [0,1)

harmonic(n,k=1)             # n-th Harmonic number of k-th order
bernoulli(n)                # n-th Bernoulli number
euler(n)                    # n-th Euler number

bernoulli(n,x)              # n-th Bernoulli polynomial evaluated at x
euler(n,x)                  # n-th Euler polynomial evaluated at x

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
is_gaussian_prime(a,b)      # true if a+b*i is a Gaussian prime
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
k.powerful_count(a,b)       # count of k-powerfree numbers in the range a..b
k.nonpowerfree_count(a,b)   # count of k-nonpowerfree numbers in the range a..b

k.omega_prime_sum(a,b)      # sum of k-omega primes in the range a..b
k.almost_prime_sum(a,b)     # sum of k-almost primes in the range a..b
k.powerful_sum(a,b)         # sum of k-powerful numbers in the range a..b
k.powerfree_sum(a,b)        # sum of k-powerfree numbers in the range a..b
k.nonpowerfree_sum(a,b)     # sum of k-nonpowerfree numbers in the range a..b

k.fermat_psp(B,a,b)         # Fermat pseudoprimes to base B with k distinct prime factors in range a..b
k.strong_fermat_psp(B,a,b)  # strong Fermat pseudoprimes to base B with k distinct prime factors in range a..b
k.carmichael(a,b)           # Carmichael numbers with k prime factors in range a..b
k.lucas_carmichael(a,b)     # Lucas-Carmichael numbers with k prime factors in range a..b
```

# Generating sequences

The first `n` terms of a sequence can be easily generated by using the following constructs:

```ruby
n.by {|k| ... }         # collect the first n integers >= 0 for which the block returns true
n.of {|k| ... }         # calls the block with the first n integers >= 0 and collects the results

n.by({|k| ... }, a..b)  # same as n.by{...}, but in a given range a..b
n.of({|k| ... }, a..b)  # same as n.of{...}, but in a given range a..b

map(a..b, {|k| ... })   # map the values in a given range to a given block, collecting the results
a..b -> map {|k| ... }  # same as above
{|k| ... }.map(a..b)    # same as above
```

It's conventational in Sidef to use an implicit method call on the block argument (`_`), without storing the argument in a named variable:

```ruby
# First 10 composite numbers
say 10.by { .is_composite }         #=> [4, 6, 8, 9, 10, 12, 14, 15, 16, 18]

# Values of phi(x) in range 0..9
say 10.of { .phi }                  #=> [0, 1, 1, 2, 2, 4, 2, 6, 4, 6]

# First 10 prime numbers >= 50
say 10.by({ .is_prime }, 50..Inf)   #=> [53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

# Value of phi(x) in range 20 .. 20+10-1
say 10.of({ .phi }, 20..Inf)        #=> [8, 12, 10, 22, 8, 20, 12, 18, 12, 28]

# Values of phi(x) in range 20..30
say map(20..30, { .phi })           #=> [8, 12, 10, 22, 8, 20, 12, 18, 12, 28, 8]
```

For example, the following four statements are all equivalent:

```ruby
say 10.by { .is_composite }
say 10.by { is_composite(_) }
say 10.by {|n| n.is_composite }
say 10.by {|n| is_composite(n) }
```

Additionally, there is also the `Math.seq()` function, that constructs an infinite lazy sequence:

```ruby
say Math.seq(2, { .last.next_prime }).first(30)                     # prime numbers
say Math.seq(1, 1, { .last(2).sum }).first(30)                      # Fibonacci numbers
say Math.seq(1, 1, {|a,n| a[-1] + n*subfactorial(n-1) }).first(10)  # OEIS: A177265
say Math.seq(1, { .last.next_omega_prime(2) }).first(20)            # OEIS: A007774
```

# User-defined functions

A function can be defined by using the `func` keyword:

```ruby
func function_name(a,b,c,...) {
    ...
}
```

Additionally, when calling a built-in method that requires a block (`{...}`), a user-defined function name can be passed as well:

```ruby
func cond(n) { n.is_composite }
say 10.by(cond)                    # first 10 composite numbers
```

In number theory, multiplicative functions are very common and can be very easily implemented using the `n.factor_prod{|p,e| ... }` method:

```ruby
func exponential_sigma(n, k=1) {
    n.factor_prod {|p,e|
        e.divisors.sum {|d| p**(d*k) }
    }
}

say map(1..20, {|n| exponential_sigma(n, 1)})
say map(1..20, {|n| exponential_sigma(n, 2)})
say map(1..20, {|n| exponential_sigma(n, 3)})
```

Alternatively, using the `is cached` trait, which also caches the results of the function:

```ruby
func exponential_sigma(p, e, k=1) is cached {
    e.divisors.sum {|d| p**(d*k) }
}

say map(1..20, {|n| n.factor_prod{|p,e| exponential_sigma(p,e) } })
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

# Computing OEIS sequences

Sidef is particularly useful in quickly generating various sequences, which can then be searched in the [OEIS](https://oeis.org) for finding more information about them:

```ruby
say map(1..50, { .mu })
say map(1..50, { .tau })
say map(1..50, { .pi })
say map(1..50, { .mertens })
say map(1..50, { .sopfr })
say map(1..50, { .sopf })
say map(1..50, { .gpf })
say map(1..50, { .lpf })
say map(1..50, { .gpf_sum })
say map(1..50, { .lpf_sum })
say map(1..50, { .core })

say map(1..50, { .composite_count })
say map(1..50, { .prime_power_count })
say map(1..50, { .perfect_power_count })

say map(1..50, { 2.omega_prime_count(_) })
say map(1..50, { 3.omega_prime_count(_) })

say map(1..50, { 2.almost_prime_count(_) })
say map(1..50, { 3.almost_prime_count(_) })

say map(1..50, { 2.squarefree_almost_prime_count(_) })
say map(1..50, { 3.squarefree_almost_prime_count(_) })

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

say 15.of { .fib }
say 15.of { .fib(3) }
say 15.of { .lucas }
say 25.of { .motzkin }
say 20.of { .fubini }
say 20.of { .bell }
say 15.of { .factorial }
say 15.of { .subfactorial }
say 15.of { .subfactorial(2) }
say 15.of { .left_factorial }
say 15.of { .primorial }

say map(1..30, { .ramanujan_tau })
say map(1..15, { .secant_number })
say map(1..15, { .tangent_number })

say 15.of {|n| 3.rough_part(n!) }
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

say 50.of { 2.powerfree_part(_) }       # squarefree part of n
say 50.of { 3.powerfree_part(_) }       # cubefree part of n

say 50.of { 2.powerfree_sigma(_) }
say 50.of { 3.powerfree_sigma(_) }

say 50.of { 2.powerfree_usigma(_) }
say 50.of { 2.powerfree_usigma(_, 2) }

say 50.of { 2.power_sigma(_) }
say 50.of { 3.power_sigma(_) }

say 20.by { .is_llr_prime(3) }     # numbers n such that 2^n * 3 - 1 is prime
say 20.by { .is_proth_prime(3) }   # numbers n such that 2^n * 3 + 1 is prime

say map(1..50, { .phi })
say map(1..50, { .uphi })
say map(1..50, { .psi })
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
say map(1..50, { .sigma(2) })
say map(1..50, { .usigma(2) })
say map(1..50, { .isigma(2) })
say map(1..50, { .esigma(2) })
say map(1..50, { .bsigma(2) })
say map(1..50, { .nusigma(2) })
say map(1..50, { .nisigma(2) })
say map(1..50, { .nesigma(2) })
say map(1..50, { .nbsigma(2) })
say map(1..50, { .jordan_totient(2) })

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

# Non-trivial OEIS sequences

Sidef was extensively used over the years in extending various [OEIS](https://oeis.org) sequences that had the keyword `more` and/or `hard`.

In this section we present several code examples that compute non-trivial [OEIS](https://oeis.org) sequences.

---

* **[A242786](https://oeis.org/A242786)**

Least prime `p` such that `p^n` and `p^n+1` have the same number of prime factors (counted with multiplicity) or `0` if no such number exists.

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

* **[A241793](https://oeis.org/A241793)**

Least number `k` such that `k^n` and `k^n-1` contain the same number of prime factors (counted with multiplicity) or `0` if no such `k` exists.

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

* **[A281940](https://oeis.org/A281940)**

Least `k` such that `k^n + 1` is the product of `n` distinct primes (`k > 0`).

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

* **[A280005](https://oeis.org/A280005)**

Least prime `p` such that `p^n + 1` is the product of `n` distinct primes.

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

* **[A358863](https://oeis.org/A358863)**

`a(n)` is the smallest `n`-gonal number with exactly `n` prime factors (counted with multiplicity).

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
func A358863(n, from = 2, upto = 2*from) {
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

* **[A358865](https://oeis.org/A358865)**

`a(n)` is the smallest `n`-gonal pyramidal number with exactly `n` prime factors (counted with multiplicity).

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

* **[A358862](https://oeis.org/A358862)**

`a(n)` is the smallest `n`-gonal number with exactly `n` distinct prime factors.

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
func A358862(n, from = 2, upto = 2*from) {
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

* **[A358864](https://oeis.org/A358864)**

`a(n)` is the smallest `n`-gonal pyramidal number with exactly `n` distinct prime factors.

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

* **[A219019](https://oeis.org/A219019)**

Smallest positive number `k` such that `k^n - 1` contains `n` distinct prime divisors.

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

*TODO*: add examples on how to compute the smallest {Carmichael,Lucas-Carmichael,Fermat,strong Fermat} number with `n` prime factors.

# Finding closed-form of sequences

*TODO*

# Advanced number theory functions

*TODO*

# Making Sidef faster

*TODO*

# State-of-the-art performance

*TODO*
