package Sidef::Optimizer {

    use utf8;
    use 5.016;
    use Scalar::Util qw(refaddr);

    use constant {
                  STRING        => 'Sidef::Types::String::String',
                  NUMBER        => 'Sidef::Types::Number::Number',
                  MOD           => 'Sidef::Types::Number::Mod',
                  GAUSS         => 'Sidef::Types::Number::Gauss',
                  FRACTION      => 'Sidef::Types::Number::Fraction',
                  QUADRATIC     => 'Sidef::Types::Number::Quadratic',
                  QUATERNION    => 'Sidef::Types::Number::Quaternion',
                  REGEX         => 'Sidef::Types::Regex::Regex',
                  BOOL          => 'Sidef::Types::Bool::Bool',
                  ARRAY         => 'Sidef::Types::Array::Array',
                  RANGENUM      => 'Sidef::Types::Range::RangeNumber',
                  RANGESTR      => 'Sidef::Types::Range::RangeString',
                  DIR_DT        => 'Sidef::DataTypes::Glob::Dir',
                  FILE_DT       => 'Sidef::DataTypes::Glob::File',
                  PIPE_DT       => 'Sidef::DataTypes::Glob::Pipe',
                  NUMBER_DT     => 'Sidef::DataTypes::Number::Number',
                  STRING_DT     => 'Sidef::DataTypes::String::String',
                  COMPLEX_DT    => 'Sidef::DataTypes::Number::Complex',
                  REGEX_DT      => 'Sidef::DataTypes::Regex::Regex',
                  GAUSS_DT      => 'Sidef::DataTypes::Number::Gauss',
                  MOD_DT        => 'Sidef::DataTypes::Number::Mod',
                  FRACTION_DT   => 'Sidef::DataTypes::Number::Fraction',
                  QUADRATIC_DT  => 'Sidef::DataTypes::Number::Quadratic',
                  QUATERNION_DT => 'Sidef::DataTypes::Number::Quaternion',
                  RANGENUM_DT   => 'Sidef::DataTypes::Range::RangeNumber',
                  RANGESTR_DT   => 'Sidef::DataTypes::Range::RangeString',
                  BACKTICK_DT   => 'Sidef::DataTypes::Glob::Backtick',
                  PERL_DT       => 'Sidef::DataTypes::Perl::Perl',
                 };

    my %dt_table = (
        qw(
          Sidef::DataTypes::Bool::Bool            Sidef::Types::Bool::Bool
          Sidef::DataTypes::Array::Array          Sidef::Types::Array::Array
          Sidef::DataTypes::Array::Pair           Sidef::Types::Array::Pair
          Sidef::DataTypes::Array::Matrix         Sidef::Types::Array::Matrix
          Sidef::DataTypes::Hash::Hash            Sidef::Types::Hash::Hash
          Sidef::DataTypes::Set::Set              Sidef::Types::Set::Set
          Sidef::DataTypes::Set::Bag              Sidef::Types::Set::Bag
          Sidef::DataTypes::Regex::Regex          Sidef::Types::Regex::Regex
          Sidef::DataTypes::String::String        Sidef::Types::String::String
          Sidef::DataTypes::Number::Number        Sidef::Types::Number::Number
          Sidef::DataTypes::Number::Complex       Sidef::Types::Number::Complex
          Sidef::DataTypes::Number::Fraction      Sidef::Types::Number::Fraction
          Sidef::DataTypes::Number::Gauss         Sidef::Types::Number::Gauss
          Sidef::DataTypes::Number::Mod           Sidef::Types::Number::Mod
          Sidef::DataTypes::Number::Quadratic     Sidef::Types::Number::Quadratic
          Sidef::DataTypes::Number::Quaternion    Sidef::Types::Number::Quaternion
          Sidef::DataTypes::Range::RangeNumber    Sidef::Types::Range::RangeNumber
          Sidef::DataTypes::Range::RangeString    Sidef::Types::Range::RangeString
          Sidef::DataTypes::Glob::Backtick        Sidef::Types::Glob::Backtick
          Sidef::DataTypes::Glob::Socket          Sidef::Types::Glob::Socket
          Sidef::DataTypes::Glob::Pipe            Sidef::Types::Glob::Pipe
          Sidef::DataTypes::Glob::Dir             Sidef::Types::Glob::Dir
          Sidef::DataTypes::Glob::File            Sidef::Types::Glob::File
          Sidef::DataTypes::Perl::Perl            Sidef::Types::Perl::Perl
          )
    );

    my %cache;
    {

        sub methods {
            my ($package, @names) = @_;
            my $module = ($cache{$package} //= (($package =~ s{::}{/}gr) . '.pm'));
            exists($INC{$module}) || require($module);
            map {
                $cache{join(' ', $package, $_)} //= do {
                    defined(my $method = UNIVERSAL::can($package, $_))
                      or die "[ERROR] Invalid method $package: $_";
                    $method;
                }
            } @names;
        }

        sub dtypes {
            my ($type, @names) = @_;

            exists($dt_table{$type}) || die "[ERROR] Non-existent data type: $type";

            my $package = $dt_table{$type};
            my $module  = ($cache{$package} //= (($package =~ s{::}{/}gr) . '.pm'));

            exists($INC{$module}) || require($module);

            map {
                $cache{join(' ', $type, $_)} //= do {
                    defined(my $method = UNIVERSAL::can($package, $_))
                      or die "[ERROR] Invalid method $package: $_";
                    $method;
                }
            } @names;
        }
    }

    sub table {
        [@_];
    }

    sub build_tree {
        my (@data) = @_;

        require Algorithm::Loops;

        my %tree;
        foreach my $node (@data) {
            my $ref = ($tree{$node->[0]} //= {});
            $ref = $ref->{$#{$node->[1]}} //= {};
            my $orig = $ref;
            my $iter = Algorithm::Loops::NestedLoops($node->[1]);
            while (my @list = $iter->()) {
                $ref = $orig;
                foreach my $key (@list) {
                    $ref = $ref->{$key} //= {};
                }
            }
        }

        \%tree;
    }

    my %rules = (
        (STRING) => build_tree(

            # String.method(String)
            (
                map { [$_, [table(STRING)]] } methods(
                    STRING, qw(
                      to
                      downto

                      pack
                      concat
                      prepend

                      gt lt le ge cmp

                      xor and or
                      eq ne

                      index
                      crypt

                      levenshtein
                      jaro
                      contains
                      overlaps
                      begins_with
                      ends_with
                      count
                      range

                      sprintf
                      sprintlnf

                      encode
                      decode
                      )
                )
            ),

            # String.method()
            (
                map { [$_, []] } methods(
                    STRING, qw(
                      lc uc fc tc wc tclc lcfirst

                      pop
                      chop
                      chomp

                      chars_len
                      bytes_len
                      graphs_len

                      pipe
                      chars
                      bytes
                      lines
                      words
                      backtick
                      graphemes

                      ord
                      oct
                      hex
                      bin
                      num
                      not

                      first
                      last

                      repeat
                      reverse
                      clear
                      sort
                      split
                      range

                      is_empty
                      is_palindrome

                      trim
                      trim_beg
                      trim_end

                      encode_utf8
                      decode_utf8

                      sprintf
                      sprintlnf

                      dump to_s
                      apply_escapes
                      unescape
                      quotemeta
                      looks_like_number
                      )
                )
            ),

            # String.method(Number)
            (
                map { [$_, [table(NUMBER)]] } methods(
                    STRING, qw(
                      eq ne

                      mul
                      div
                      repeat
                      char
                      slice

                      sprintf
                      sprintlnf

                      shift_left
                      shift_right
                      )
                )
            ),

            # String.method(String | Number | Regex)
            (map { [$_, [table(STRING, NUMBER, REGEX)]] } methods(STRING, qw(split))),

            # String.method(String, String)
            (
                map { [$_, [table(STRING), table(STRING)]] } methods(
                    STRING, qw(
                      tr
                      )
                )
            ),

            # String.method(String, String, String)
            (
                map { [$_, [table(STRING), table(STRING), table(STRING)]] } methods(
                    STRING, qw(
                      tr
                      )
                )
            ),

            # String.method(Number, Number)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } methods(
                    STRING, qw(
                      slice
                      )
                )
            ),

            # String.method(String, Number)
            (
                map { [$_, [table(STRING), table(NUMBER)]] } methods(
                    STRING, qw(
                      index
                      contains
                      sprintf
                      sprintlnf
                      )
                )
            ),

            # String.method(String, Bool)
            (
                map { [$_, [table(STRING), table(BOOL)]] } methods(
                    STRING, qw(
                      range
                      )
                )
            ),
        ),

        (MOD) => build_tree(

            # Mod.method()
            (
                map { [$_, []] } methods(
                    MOD, qw(
                      abs dump fib lucas inv
                      is_inf is_mone is_nan
                      is_neg is_ninf is_one
                      is_pos is_real is_zero
                      lift neg norm pretty
                      re sqr sqrt to_s znorder
                      not chinese factorial
                      inc dec eval
                      )
                )
            ),

            # Mod.method(Mod | Number)
            (
                map { [$_, [table(MOD, NUMBER)]] } methods(
                    MOD, qw(
                      + - / * %

                      lt gt le ge cmp
                      eq ne
                      and or xor

                      eval ChebyshevT ChebyshevU cyclotomic
                      )
                )
            ),

            # Mod.method(Number)
            (
                map { [$_, [table(MOD, NUMBER)]] } methods(
                    MOD, qw(
                      << >> **
                      ChebyshevT ChebyshevU cyclotomic
                      )
                )
            ),

            # Mod.method(Mod)
            (
                map { [$_, [table(MOD)]] } methods(
                    MOD, qw(
                      chinese
                      )
                )
            ),

            # Mod.method(Number, Number, Number)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } methods(
                    MOD, qw(
                      LucasU LucasV
                      )
                )
            ),
        ),

        (FRACTION) => build_tree(

            # Fraction.method()
            (
                map { [$_, []] } methods(
                    FRACTION, qw(
                      nu de abs ceil floor trunc dump
                      float inv inc dec
                      is_mone is_nan is_one
                      is_real is_zero lift neg
                      parts pretty round eval
                      sgn sqr to_s to_n not
                      )
                )
            ),

            # Fraction.method(Fraction | Number)
            (
                map { [$_, [table(FRACTION, NUMBER)]] } methods(
                    FRACTION, qw(
                      + - / * % ** << >>

                      lt gt le ge cmp
                      eq ne
                      and or xor

                      eval invmod round
                      )
                )
            ),

            # Fraction.method(Number, Number)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } methods(
                    FRACTION, qw(
                      powmod
                      )
                )
            ),
        ),

        (GAUSS) => build_tree(

            # Gauss.method()
            (
                map { [$_, []] } methods(
                    GAUSS, qw(
                      a b abs ceil conj dump
                      float floor i iabs inv inc dec
                      is_imag is_mone is_one is_prime
                      is_real is_zero lift neg
                      norm parts pretty round
                      sgn sqr to_c to_s not eval
                      )
                )
            ),

            # Gauss.method(Gauss | Number)
            (
                map { [$_, [table(GAUSS, NUMBER)]] } methods(
                    GAUSS, qw(
                      + - / * % ** << >>

                      lt gt le ge cmp
                      eq ne
                      and or xor

                      gcd gcd_norm eval
                      invmod is_coprime round
                      )
                )
            ),

            # Gauss.method(Number, Gauss | Number)
            (
                map { [$_, [table(NUMBER), table(GAUSS, NUMBER)]] } methods(
                    GAUSS, qw(
                      powmod
                      )
                )
            ),
        ),

        (QUADRATIC) => build_tree(

            # Quadratic.method()
            (
                map { [$_, []] } methods(
                    QUADRATIC, qw(
                      a b abs ceil conj dump
                      float floor inv inc dec not
                      is_mone is_one is_zero eval
                      lift neg norm order parts
                      pretty round sgn sqr to_c to_s
                      )
                )
            ),

            # Quadratic.method(Quadratic | Number)
            (
                map { [$_, [table(QUADRATIC, NUMBER)]] } methods(
                    QUADRATIC, qw(
                      + - / * % ** << >>

                      lt gt le ge cmp
                      eq ne
                      and or xor

                      eval invmod is_coprime round
                      )
                )
            ),

            # Quadratic.method(Number, Number)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } methods(
                    QUADRATIC, qw(
                      powmod
                      )
                )
            ),
        ),

        (QUATERNION) => build_tree(

            # Quaternion.method()
            (
                map { [$_, []] } methods(
                    QUATERNION, qw(
                      a b c d abs ceil conj dump
                      float floor inv inc dec not
                      is_mone is_one is_zero
                      lift neg norm parts
                      pretty round sgn sqr to_c to_s
                      to_gauss eval
                      )
                )
            ),

            # Quaternion.method(Quaternion | Number)
            (
                map { [$_, [table(QUATERNION, NUMBER)]] } methods(
                    QUATERNION, qw(
                      + - / * % ** << >>

                      lt gt le ge cmp
                      eq ne
                      and or xor

                      eval invmod is_coprime round
                      )
                )
            ),

            # Quaternion.method(Number, Number)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } methods(
                    QUATERNION, qw(
                      powmod
                      )
                )
            ),
        ),

        (NUMBER) => build_tree(

            # Number.method(Number)
            (
                map { [$_, [table(MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION)]] } methods(
                    NUMBER, qw(
                      + - * /
                      )
                )
            ),

            # Number.method(Number)
            (
                map { [$_, [table(NUMBER)]] } methods(
                    NUMBER, qw(
                      + - / * % %% **

                      lt gt le ge cmp
                      eq ne
                      and or xor

                      sigma
                      usigma

                      prime_sigma
                      prime_usigma

                      is_power

                      complex
                      root iroot
                      log
                      next_pow
                      prev_pow
                      max min
                      roundf
                      binomial
                      subfactorial
                      invmod
                      isub
                      iadd
                      imul
                      idiv
                      ipow
                      imod
                      range
                      to xto
                      downto xdownto

                      shift_right
                      shift_left
                      )
                )
            ),

            # Number.method()
            (
                map { [$_, []] } methods(
                    NUMBER, qw(
                      inc dec not range

                      factorial
                      subfactorial
                      superfactorial
                      hyperfactorial
                      lnsuperfactorial
                      lnhyperfactorial
                      sqrt isqrt
                      abs int rat float complex
                      norm conj sqr cube

                      zeta
                      eta
                      beta
                      gamma
                      Ai
                      Li
                      Li2
                      Ei

                      sigma
                      sigma0

                      usigma
                      usigma0

                      prime_sigma
                      prime_usigma

                      divisors
                      udivisors

                      factor
                      factor_exp

                      exp
                      exp2
                      exp10

                      cos sin

                      ln
                      log
                      log2
                      log10

                      sin
                      asin
                      sinh
                      asinh

                      cos
                      acos
                      cosh
                      acosh

                      tan
                      atan
                      tanh
                      atanh

                      cot
                      acot
                      coth
                      acoth

                      sec
                      sech
                      asec
                      asech

                      csc
                      csch
                      acsc
                      acsch

                      cot
                      acot
                      coth
                      acoth

                      inf
                      neg
                      sign
                      nan
                      chr

                      i pi tau
                      e ln2 phi
                      EulerGamma
                      CatalanG

                      is_zero
                      is_one
                      is_nan
                      is_pos
                      is_neg
                      is_even
                      is_odd
                      is_inf
                      is_ninf
                      is_int

                      is_prime
                      is_square
                      is_power

                      sgn
                      ceil
                      floor
                      length

                      ilog
                      ilog2
                      ilog10

                      isqrt
                      icbrt

                      numerator
                      denominator

                      digits

                      as_bin
                      as_oct
                      as_hex
                      as_rat
                      as_frac

                      dump
                      eval
                      commify
                      )
                )
            ),

            # Number.method(Number, Number)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } methods(
                    NUMBER, qw(
                      powmod
                      range
                      )
                )
            ),
        ),

        (BOOL) => build_tree(
            (
                map { [$_, []] } methods(
                    BOOL, qw(
                      not
                      is_true
                      true
                      false
                      to_bool
                      dump
                      )
                )
            ),
        ),

        (ARRAY) => build_tree(
            (
                map { [$_, []] } methods(
                    ARRAY, qw(
                      first
                      last

                      freq
                      len end
                      is_empty
                      min max

                      sum
                      prod

                      zip
                      cartesian
                      permutations
                      derangements
                      circular_permutations

                      sort
                      reverse

                      unique
                      last_unique
                      flatten

                      to_s
                      dump
                      )
                )
            ),

            (
                map { [$_, [table(NUMBER)]] } methods(
                    ARRAY, qw(
                      count
                      index
                      rindex
                      exists
                      defined
                      contains

                      subsets
                      partitions
                      variations
                      variations_with_repetition
                      combinations
                      combinations_with_repetition

                      nth_permutation

                      div
                      mul

                      rotate

                      first
                      last
                      item
                      slice

                      sum
                      prod

                      take_right
                      take_left
                      )
                )
            ),

            (
                map { [$_, [table(ARRAY)]] } methods(
                    ARRAY, qw(
                      and
                      or
                      xor
                      concat

                      eq ne
                      contains_type
                      contains_any
                      contains_all
                      )
                )
            ),

            (
                map { [$_, [table(STRING)]] } methods(
                    ARRAY, qw(
                      pack
                      join
                      index
                      rindex
                      count
                      contains
                      contains_type
                      reduce
                      reduce_operator
                      )
                )
            ),

            (map { [$_, [table('')]] } methods(ARRAY, qw(reduce_operator))),
        ),

        (RANGENUM) => build_tree(

            # RangeNum.method(Number)
            (
                map { [$_, [table(NUMBER)]] } methods(
                    RANGENUM, qw(
                      from to by
                      sum add sub mul div
                      )
                )
            ),

            # RangeNum.method()
            (
                map { [$_, []] } methods(
                    RANGENUM, qw(
                      first last reverse
                      min max step flip
                      sum length neg
                      )
                )
            ),
        ),

        (RANGESTR) => build_tree(

            # RangeStr.method(Number)
            (
                map { [$_, [table(NUMBER)]] } methods(
                    RANGESTR, qw(
                      by add sub mul div
                      )
                )
            ),

            # RangeStr.method()
            (
                map { [$_, []] } methods(
                    RANGESTR, qw(
                      first last reverse
                      min max step flip
                      length neg
                      )
                )
            ),
        ),

        (NUMBER_DT) => build_tree(

            # Number.method()
            (
                map { [$_, []] } dtypes(
                    NUMBER_DT, qw(
                      pi
                      tau
                      ln2
                      EulerGamma
                      CatalanG
                      e i
                      phi
                      nan
                      inf
                      ninf
                      )
                )
            ),

            # Number.method(STRING|NUMBER)
            (
                map { [$_, [table(STRING, NUMBER)]] } dtypes(
                    NUMBER_DT, qw(
                      new
                      call
                      )
                )
            ),

            # Number.method(NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } dtypes(
                    NUMBER_DT, qw(
                      new
                      call
                      )
                )
            ),

            # Number.method(STRING, NUMBER)
            (
                map { [$_, [table(STRING), table(NUMBER)]] } dtypes(
                    NUMBER_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (STRING_DT) => build_tree(

            # String.method(STRING|NUMBER)
            (
                map { [$_, [table(STRING, NUMBER)]] } dtypes(
                    STRING_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (REGEX_DT) => build_tree(

            # Regex.method(STRING)
            (
                map { [$_, [table(STRING)]] } dtypes(
                    REGEX_DT, qw(
                      new
                      call
                      )
                )
            ),

            # Regex.method(STRING, STRING)
            (
                map { [$_, [table(STRING), table(STRING)]] } dtypes(
                    REGEX_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (FILE_DT) => build_tree(

            # File.method(STRING)
            (
                map { [$_, [table(STRING)]] } dtypes(
                    FILE_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (PIPE_DT) => build_tree(

            # Pipe.method(STRING)
            (
                map { [$_, [table(STRING)]] } dtypes(
                    PIPE_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (BACKTICK_DT) => build_tree(

            # Backtick.method(STRING)
            (
                map { [$_, [table(STRING)]] } dtypes(
                    BACKTICK_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (PERL_DT) => build_tree(

            # Perl.method(STRING)
            (
                map { [$_, [table(STRING)]] } dtypes(
                    PERL_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (DIR_DT) => build_tree(

            # Dir.method(STRING)
            (
                map { [$_, [table(STRING)]] } dtypes(
                    DIR_DT, qw(
                      new
                      call
                      )
                )
            ),
        ),

        (GAUSS_DT) => build_tree(

            # Gauss.method(NUMBER)
            (
                map { [$_, [table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION)]] } dtypes(
                    GAUSS_DT, qw(
                      new call
                      )
                )
            ),

            # Gauss.method(NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION), table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION)]] } dtypes(
                    GAUSS_DT, qw(
                      new call
                      )
                )
            ),
        ),

        (MOD_DT) => build_tree(

            # Mod.method(NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION), table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION)]] } dtypes(
                    MOD_DT, qw(
                      new call
                      )
                )
            ),
        ),

        (FRACTION_DT) => build_tree(

            # Fraction.method(NUMBER)
            (
                map { [$_, [table(NUMBER)]] } dtypes(
                    FRACTION_DT, qw(
                      new call
                      )
                )
            ),

            # Fraction.method(NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION), table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION)]] } dtypes(
                    FRACTION_DT, qw(
                      new call
                      )
                )
            ),
        ),

        (QUADRATIC_DT) => build_tree(

            # Quadratic.method(NUMBER, NUMBER, NUMBER)
            (
                map {
                    [$_, [table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION), table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION), table(NUMBER)]
                    ]
                } dtypes(
                    QUADRATIC_DT, qw(
                      new call
                      )
                )
            ),
        ),

        (QUATERNION_DT) => build_tree(

            # Quaternion.method(NUMBER, NUMBER, NUMBER, NUMBER)
            (
                map {
                    [$_,
                     [table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION),
                      table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION),
                      table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION),
                      table(NUMBER, MOD, GAUSS, QUADRATIC, QUATERNION, FRACTION)
                     ]
                    ]
                } dtypes(
                    QUATERNION_DT, qw(
                      new call
                      )
                )
            ),
        ),

        (RANGENUM_DT) => build_tree(

            # RangeNum.method(NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } dtypes(
                    RANGENUM_DT, qw(
                      new call
                      )
                )
            ),

            # RangeNum.method(NUMBER, NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER), table(NUMBER), table(NUMBER)]] } dtypes(
                    RANGENUM_DT, qw(
                      new call
                      )
                )
            ),
        ),

        (RANGESTR_DT) => build_tree(

            # RangeStr.method(STRING, STRING)
            (
                map { [$_, [table(STRING), table(STRING)]] } dtypes(
                    RANGESTR_DT, qw(
                      call
                      )
                )
            ),

            # RangeStr.method(NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER), table(NUMBER)]] } dtypes(
                    RANGESTR_DT, qw(
                      new
                      )
                )
            ),

            # RangeStr.method(STRING, STRING, NUMBER)
            (
                map { [$_, [table(STRING), table(STRING), table(NUMBER)]] } dtypes(
                    RANGESTR_DT, qw(
                      call
                      )
                )
            ),

            # RangeStr.method(NUMBER, NUMBER, NUMBER)
            (
                map { [$_, [table(NUMBER), table(NUMBER), table(NUMBER)]] } dtypes(
                    RANGESTR_DT, qw(
                      new
                      )
                )
            ),
        ),

        (COMPLEX_DT) => build_tree(

            # Complex.method()
            (
                map { [$_, []] } dtypes(
                    COMPLEX_DT, qw(
                      i
                      e
                      pi
                      phi
                      new
                      call
                      )
                )
            ),

            # Complex.method(STRING|NUMBER)
            (
                map { [$_, [table(STRING, NUMBER)]] } dtypes(
                    COMPLEX_DT, qw(
                      new call
                      )
                )
            ),

            # Complex.method(NUMBER|STRING, NUMBER|STRING)
            (
                map { [$_, [table(STRING, NUMBER), table(STRING, NUMBER)]] } dtypes(
                    COMPLEX_DT, qw(
                      new call
                      )
                )
            ),
        ),
    );

    my %addr;

    sub new {
        my (undef, %opts) = @_;
        undef(%addr);    # reset the %addr hash
        bless \%opts, __PACKAGE__;
    }

    sub optimize_expr {
        my ($self, $expr) = @_;

        my $obj = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $obj = $self->optimize($obj);
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if ($obj->{type} eq 'var') {
                ## ok
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{refaddr($obj)}++) {
                    ## ok
                }
                else {
                    $obj->{value} = $self->optimize_expr({self => $obj->{value}});
                }
            }
        }
        elsif (($ref eq 'Sidef::Variable::Static' or $ref eq 'Sidef::Variable::Const' or $ref eq 'Sidef::Variable::Define')
               and exists($obj->{value})) {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{value} = {$self->optimize($obj->{value})};
            }
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                if (exists $obj->{args}) {
                    $obj->{args} = {$self->optimize($obj->{args})};
                }
            }
        }
        elsif (   $ref eq 'Sidef::Variable::ClassInit'
               or $ref eq 'Sidef::Types::Block::Do'
               or $ref eq 'Sidef::Types::Block::Loop'
               or $ref eq 'Sidef::Types::Block::Given'
               or $ref eq 'Sidef::Types::Block::Gather'
               or $ref eq 'Sidef::Types::Block::When'
               or $ref eq 'Sidef::Types::Block::Case'
               or $ref eq 'Sidef::Types::Block::Default') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{block}{code} = {$self->optimize($obj->{block}{code})};
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Try') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{try}{code}   = {$self->optimize($obj->{try}{code})};
                $obj->{catch}{code} = {$self->optimize($obj->{catch}{code})} if defined($obj->{catch});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::BlockInit') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{code} = {$self->optimize($obj->{code})};
            }
        }
        elsif ($ref eq 'Sidef::Types::Array::HCArray') {

            #~ my $has_expr = 0;

            foreach my $i (0 .. $#{$obj}) {
                if (ref($obj->[$i]) eq 'HASH') {
                    $obj->[$i] = $self->optimize_expr($obj->[$i]);

                    #~ $has_expr ||= ref($obj->[$i]) eq 'HASH';
                }
            }

            # Has no expressions, so let's convert it into an Array
            #~ if (not $has_expr) {
            #~ #$obj = Sidef::Types::Array::Array->new(@{$obj});
            #~ bless $obj, 'Sidef::Types::Array::Array';
            #~ }
        }
        elsif ($ref eq 'Sidef::Types::Block::If') {
            foreach my $i (0 .. $#{$obj->{if}}) {
                $obj->{if}[$i]{block}{code} = {$self->optimize($obj->{if}[$i]{block}{code})};
                $obj->{if}[$i]{expr} = {$self->optimize($obj->{if}[$i]{expr})};
            }
            if (exists $obj->{else}) {
                $obj->{else}{block}{code} = {$self->optimize($obj->{else}{block}{code})};
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::With') {
            foreach my $i (0 .. $#{$obj->{with}}) {
                $obj->{with}[$i]{block}{code} = {$self->optimize($obj->{with}[$i]{block}{code})};
                $obj->{with}[$i]{expr} = {$self->optimize($obj->{with}[$i]{expr})};
            }
            if (exists $obj->{else}) {
                $obj->{else}{block}{code} = {$self->optimize($obj->{else}{block}{code})};
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::ForIn') {
            foreach my $loop (@{$obj->{loops}}) {
                $loop->{expr} = {$self->optimize($loop->{expr})};
            }

            $obj->{block}{code} = {$self->optimize($obj->{block}{code})};
        }
        elsif (   $ref eq 'Sidef::Types::Block::While'
               or $ref eq 'Sidef::Types::Block::ForEach') {
            $obj->{expr} = {$self->optimize($obj->{expr})};
            $obj->{block}{code} = {$self->optimize($obj->{block}{code})};
        }
        elsif ($ref eq 'Sidef::Types::Block::CFor') {
            foreach my $i (0 .. $#{$obj->{expr}}) {
                $obj->{expr}[$i] = {$self->optimize($obj->{expr}[$i])};
            }
            $obj->{block}{code} = {$self->optimize($obj->{block}{code})};
        }
        elsif ($ref eq 'Sidef::Variable::NamedParam') {
            $obj->{value} = [map { {main => [$self->optimize_expr({self => $_})]} } @{$obj->{value}}];
        }
        elsif ($ref eq 'Sidef::Meta::PrefixMethod') {
            $obj->{expr} = {$self->optimize($obj->{expr})};
        }
        elsif ($ref eq 'Sidef::Types::Block::Take') {
            $obj->{expr} = {$self->optimize($obj->{expr})};
        }
        elsif ($ref eq 'Sidef::Meta::Assert') {
            $obj->{arg} = {$self->optimize($obj->{arg})};
        }
        elsif ($ref eq 'Sidef::Meta::Module') {
            $obj->{block}{code} = {$self->optimize($obj->{block}{code})};
        }
        elsif ($ref eq 'Sidef::Meta::Included') {
            foreach my $info (@{$obj->{included}}) {
                $info->{ast} = {$self->optimize($info->{ast})};
            }
        }
        elsif ($ref eq 'Sidef::Types::Bool::Ternary') {
            $obj->{cond}  = {$self->optimize($obj->{cond})};
            $obj->{true}  = {$self->optimize($obj->{true})};
            $obj->{false} = {$self->optimize($obj->{false})};
        }

        if (not exists($expr->{ind}) and not exists($expr->{call})) {
            return (ref($obj) eq 'HASH' ? {self => $obj} : $obj);
        }

        $obj = {
                self => $obj,
                (exists($expr->{ind})  ? (ind  => []) : ()),
                (exists($expr->{call}) ? (call => []) : ()),
               };

        # Array and hash indices
        if (exists $expr->{ind}) {
            foreach my $i (0 .. $#{$expr->{ind}}) {
                my $ind = $expr->{ind}[$i];
                if (exists $ind->{array}) {
                    $obj->{ind}[$i]{array} = [map { ref($_) eq 'HASH' ? $self->optimize_expr($_) : $_ } @{$ind->{array}}];
                }
                else {
                    $obj->{ind}[$i]{hash} = [map { ref($_) eq 'HASH' ? $self->optimize_expr($_) : $_ } @{$ind->{hash}}];
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {

            my $count   = 0;
            my $ref_obj = ref($obj->{self});

            foreach my $i (0 .. $#{$expr->{call}}) {

                my $call = $expr->{call}[$i];

                # Method call
                my $method = $call->{method};

                if (defined $method) {
                    if (ref($method) eq 'HASH') {
                        $method = $self->optimize_expr($method) // {self => {}};

                        # Optimize `obj.("method")` to `obj.method`
                        if (ref($method) eq 'Sidef::Types::String::String') {
                            $method = $$method;
                        }
                    }

                    if (ref($obj) ne 'HASH') {
                        $obj = {self => $obj};
                    }

                    $obj->{call}[$i] = {method => $method};
                }
                elsif (exists $call->{keyword}) {
                    $obj->{call}[$i] = {keyword => $call->{keyword}};
                }

                # Method arguments
                if (exists $call->{arg}) {

                    state $unary_methods = {
                                            '-' => 'neg',
                                            '√' => 'sqrt',
                                            '~' => 'not',
                                            '^' => 'range',
                                            '+' => undef,
                                           };

                    my $unary_optimized = 0;

                    if (    defined($ref_obj)
                        and $ref_obj eq 'Sidef::Operator::Unary'
                        and exists($unary_methods->{$method})
                        and scalar(@{$call->{arg}}) == 1) {
                        my $arg = $call->{arg}[0];
                        my $opt_obj = $self->optimize_expr(
                                                           {
                                                            self => $arg,
                                                            (defined($unary_methods->{$method}) ? (call => [{method => $unary_methods->{$method}}]) : ())
                                                           }
                                                          );
                        if (($method eq '+') ? (ref($opt_obj) ne 'HASH') : 1) {
                            $obj             = $opt_obj;
                            $unary_optimized = 1;
                        }
                    }

                    if (!$unary_optimized) {
                        foreach my $j (0 .. $#{$call->{arg}}) {
                            my $arg = $call->{arg}[$j];
                            push @{$obj->{call}[$i]{arg}},
                                ref($arg) eq 'HASH' ? {$self->optimize($arg)}
                              : ref($arg)           ? $self->optimize_expr({self => $arg})
                              :                       $arg;
                        }
                    }
                }

                # Block
                if (exists $call->{block}) {
                    foreach my $j (0 .. $#{$call->{block}}) {
                        my $arg = $call->{block}[$j];
                        push @{$obj->{call}[$i]{block}},
                            ref $arg eq 'HASH' ? {$self->optimize($arg)}
                          : ref($arg)          ? $self->optimize_expr({self => $arg})
                          :                      $arg;
                    }
                }

                #
                ## Constant folding support
                #
                my $optimized = 0;
                if (    defined($ref_obj)
                    and exists($rules{$ref_obj})
                    and !ref($method)) {

                    my $code = ($cache{join(' ', $ref_obj, $method)} //= UNIVERSAL::can($ref_obj, $method));

                    if (defined $code) {
                        my $obj_call = $obj->{call}[$i];

                        my $ref = $rules{$ref_obj};
                        if (exists($ref->{$code}) and (exists($obj_call->{arg}) ? ($#{$obj_call->{arg}} == 0) : 1)) {
                            $ref = $ref->{$code};

                            my @args = (
                                          exists($obj_call->{arg})
                                        ? ref($obj_call->{arg}[0]) eq 'HASH'
                                              ? @{(values(%{$obj_call->{arg}[0]}))[0]}
                                              : $obj_call->{arg}[0]
                                        : ()
                                       );

                            if (exists $ref->{$#args}) {
                                $ref = $ref->{$#args};
                                my $ok = 1;
                                foreach my $arg (@args) {
                                    if (exists $ref->{ref($arg)}) {
                                        $ref = $ref->{ref($arg)};
                                    }
                                    else {
                                        $ok = 0;
                                        last;
                                    }
                                }

                                if ($ok) {
                                    if (exists $dt_table{$ref_obj}) {
                                        $obj->{self} = $dt_table{$ref_obj};
                                    }
                                    $obj->{self} = $obj->{self}->$code(@args);
                                    $ref_obj     = ref($obj->{self});
                                    $optimized   = 1;
                                }
                            }
                        }
                    }
                }

                if ($optimized) {
                    ++$count;
                }
                else {
                    undef $ref_obj;
                }
            }

            if ($count > 0) {
                if ($count == @{$obj->{call}}) {
                    if (not exists $expr->{ind}) {
                        return $obj->{self};
                    }
                    else {
                        delete $obj->{call};
                    }
                }
                else {
                    splice(@{$obj->{call}}, 0, $count);
                }
            }
        }

        # Concept for converting small RangeNumber objects into arrays
        # (disabled for now, as it breaks some code)
        if (0 and ref($obj->{self}) eq RANGENUM) {
            state $range_len_limit = Sidef::Types::Number::Number::_set_int(100);
            if ($obj->{self}->len->le($range_len_limit)) {
                $obj->{self} = $obj->{self}->to_a;
            }
        }

        return $obj;
    }

    sub optimize {
        my ($self, $struct) = @_;

        my %opt_struct;
        my @classes = keys %{$struct};

        foreach my $class (@classes) {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                push @{$opt_struct{$class}}, scalar $self->optimize_expr($struct->{$class}[$i]);
            }
        }

        wantarray ? %opt_struct : ($#{$opt_struct{$classes[-1]}} > 0) ? \%opt_struct : $opt_struct{$classes[-1]}[-1];
    }
};

1;
