package Sidef::Optimizer {

    use 5.014;
    use Scalar::Util qw(refaddr);

    use constant {
                  STRING  => 'Sidef::Types::String::String',
                  NUMBER  => 'Sidef::Types::Number::Number',
                  REGEX   => 'Sidef::Types::Regex::Regex',
                  BOOL    => 'Sidef::Types::Bool::Bool',
                  ARRAY   => 'Sidef::Types::Array::Array',
                  MATH    => 'Sidef::Math::Math',
                  FILE    => 'Sidef::Types::Glob::File',
                  SOCKET  => 'Sidef::Types::Glob::Socket',
                  COMPLEX => 'Sidef::Types::Number::Complex',
                 };

    {
        my %cache;

        sub methods {
            my ($package, @names) = @_;
            my $module = $cache{$package} //= (($package =~ s{::}{/}gr) . '.pm');
            exists($INC{$module}) || require($module);
            map {

                defined(&{$package . '::' . $_})
                  or die "Invalid method $package: $_";

                \&{$package . '::' . $_}
            } @names;
        }
    }

    sub table {
        scalar {map { $_ => 1 } @_};
    }

    my %rules = (
        (STRING) => [

            # String.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(STRING, qw(
                   new call
                   to downto

                   concat
                   prepend

                   gt lt le ge cmp

                   xor and or
                   eq ne

                   index
                   crypt

                   levenshtein
                   jaro_distance
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
             map {
                 { $_, [] }
               } methods(STRING, qw(
                   lc uc fc tc wc tclc lcfirst

                   pop
                   chop
                   chomp

                   chars_len
                   bytes_len
                   graphs_len

                   chars
                   bytes
                   lines
                   words
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
             map {
                 { $_, [table(NUMBER)] }
               } methods(STRING, qw(
                   eq ne

                   times
                   repeat
                   char

                   sprintf
                   sprintlnf

                   shift_left
                   shift_right
                   )
               )
            ),

            # String.method(String | Number | Regex)
            (
             map {
                 { $_, [table(STRING, NUMBER, REGEX)] }
               } methods(STRING, qw(split))
            ),

            # String.method(String, String)
            (
             map {
                 { $_, [table(STRING), table(STRING)] }
               } methods(STRING, qw(
                   tr
                   )
               )
            ),

            # String.method(String, String, String)
            (
             map {
                 { $_, [table(STRING), table(STRING), table(STRING)] }
               } methods(STRING, qw(
                   tr
                   )
               )
            ),

            # String.method(String, Number)
            (
             map {
                 { $_, [table(STRING), table(NUMBER)] }
               } methods(STRING, qw(
                   index
                   contains
                   sprintf
                   sprintlnf
                   )
               )
            ),

            # String.method(String, Bool)
            (
             map {
                 { $_, [table(STRING), table(BOOL)] }
               } methods(STRING, qw(
                   range
                   )
               )
            ),

        ],

        (NUMBER) => [

            # Number.method(String | Number)
            (
             map {
                 { $_, [table(STRING, NUMBER)] }
               } methods(NUMBER, qw(
                   new call
                   )
               )
            ),

            # Number.method(Number)
            (
             map {
                 { $_, [table(NUMBER)] }
               } methods(NUMBER, qw(
                   + - / * % %% **

                   lt gt le ge cmp acmp
                   eq ne
                   and or xor

                   complex
                   root iroot
                   log
                   next_pow
                   max min
                   roundf
                   nok
                   modinv
                   isub
                   iadd
                   imul
                   idiv
                   ipow
                   imod
                   range
                   to
                   downto

                   shift_right
                   shift_left
                   )
               )
            ),

            # Number.method(String, Number)
            (
             map {
                 { $_, [table(STRING), table(NUMBER)] }
               } methods(NUMBER, qw(
                   new call
                   )
               )
            ),

            # Number.method()
            (
             map {
                 { $_, [] }
               } methods(NUMBER, qw(
                   new call
                   inc dec not

                   factorial
                   sqrt isqrt
                   next_pow2
                   abs

                   exp int
                   cos sin
                   log ln log10 log2

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
                   pi
                   ln2
                   phi
                   tau
                   e
                   Y
                   G

                   is_zero
                   is_one
                   is_nan
                   is_positive
                   is_negative
                   is_even
                   is_odd
                   is_inf
                   is_ninf
                   is_int

                   ceil
                   floor
                   length

                   numerator
                   denominator

                   digits

                   as_bin
                   as_oct
                   as_hex
                   as_rat

                   rat
                   complex i

                   dump
                   commify
                   )
               )
            ),

            # Number.method(Number, Number)
            (
             map {
                 { $_, [table(NUMBER), table(NUMBER)] }
               } methods(NUMBER, qw(
                   modpow
                   range
                   )
               )
            ),
        ],

        (BOOL) => [
            (
             map {
                 { $_, [] }
               } methods(BOOL, qw(
                   not
                   is_true
                   true
                   false
                   to_bool
                   dump
                   )
               )
            ),
        ],

        (ARRAY) => [
            (
             map {
                 { $_, [] }
               } methods(ARRAY, qw(
                   first
                   last

                   len end
                   is_empty
                   min max

                   sum
                   prod

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
             map {
                 { $_, [table(NUMBER)] }
               } methods(ARRAY, qw(
                   count
                   index
                   rindex
                   exists
                   defined
                   contains
                   contains_type

                   divide
                   multiply

                   rotate

                   first
                   last
                   item
                   ft

                   sum
                   prod

                   take_right
                   take_left
                   )
               )
            ),

            (
             map {
                 { $_, [table(ARRAY)] }
               } methods(ARRAY, qw(
                   and
                   or
                   xor
                   concat

                   eq ne
                   mzip
                   contains_type
                   contains_any
                   contains_all
                   )
               )
            ),

            (
             map {
                 { $_, [table(STRING)] }
               } methods(ARRAY, qw(
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

            (
             map {
                 { $_, [table('')] }
               } methods(ARRAY, qw(reduce_operator))
            ),
        ],

        (MATH) => [

            # Math.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(MATH, qw(get_constant))
            ),
        ],

        (FILE) => [

            # File.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(FILE, qw(get_constant))
            ),
        ],

        (SOCKET) => [

            # Socket.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(SOCKET, qw(get_constant))
            ),
        ],

        (COMPLEX) => [

            # Complex.method(Complex|Number)
            (
             map {
                 { $_, [table(COMPLEX, NUMBER)] }
               } methods(COMPLEX, qw(
                   cmp gt lt ge le eq ne
                   roundf

                   mul
                   div
                   add
                   sub
                   exp
                   log
                   pow

                   atan2
                   )
               )
            ),

            # Complex.method(Number|Complex, Number|Complex)
            (
             map {
                 { $_, [table(NUMBER, COMPLEX)] }
               } methods(COMPLEX, qw(
                   call
                   new
                   )
               )
            ),

            # Complex.method(Number|Complex, Number|Complex)
            (
             map {
                 { $_, [table(NUMBER, COMPLEX), table(NUMBER, COMPLEX)] }
               } methods(COMPLEX, qw(
                   call
                   new
                   )
               )
            ),

            # Complex.method()
            (
             map {
                 { $_, [] }
               } methods(COMPLEX, qw(
                   new call

                   inc
                   dec
                   abs

                   log
                   log10
                   sqrt

                   cos
                   sin
                   tan
                   csc
                   sec
                   cot
                   asin
                   acos
                   atan
                   acsc
                   asec
                   acot
                   sinh
                   cosh
                   tanh
                   csch
                   sech
                   coth
                   asinh
                   acosh
                   atanh
                   acsch
                   asech
                   acoth

                   pi
                   neg
                   not

                   real
                   imaginary

                   is_zero
                   is_one
                   is_nan
                   is_real
                   is_inf
                   is_int

                   ceil
                   floor

                   dump
                   )
               )
            ),

            # Complex.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(COMPLEX, qw(get_constant))
            ),
        ],
    );

    my %addr;

    sub new {
        my (undef, %opts) = @_;
        %addr = ();
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
        elsif ($ref eq "Sidef::Variable::Variable") {
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
        elsif ($ref eq 'Sidef::Variable::Static') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                my %code = $self->optimize($obj->{expr});
                $obj->{expr} = \%code;
            }
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                if (exists $obj->{args}) {
                    my %code = $self->optimize($obj->{args});
                    $obj->{args} = \%code;
                }
            }
        }
        elsif (   $ref eq 'Sidef::Variable::ClassInit'
               or $ref eq 'Sidef::Types::Block::Do'
               or $ref eq 'Sidef::Types::Block::ForIn'
               or $ref eq 'Sidef::Types::Block::Loop'
               or $ref eq 'Sidef::Types::Block::Given'
               or $ref eq 'Sidef::Types::Block::When'
               or $ref eq 'Sidef::Types::Block::Case'
               or $ref eq 'Sidef::Types::Block::Default') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                my %code = $self->optimize($obj->{block}{code});
                $obj->{block}{code} = \%code;
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::BlockInit') {
            if ($addr{refaddr($obj)}++) {
                ## ok
            }
            else {
                my %code = $self->optimize($obj->{code});
                $obj->{code} = \%code;
            }
        }
        elsif ($ref eq 'Sidef::Types::Array::HCArray') {
            my $has_expr = 0;

            foreach my $i (0 .. $#{$obj}) {
                if (ref($obj->[$i]) eq 'HASH') {
                    $obj->[$i] = $self->optimize_expr($obj->[$i]);
                    $has_expr ||= ref($obj->[$i]) eq 'HASH';
                }
            }

            # Has no expressions, so let's convert it into an Array
            if (not $has_expr) {
                $obj = Sidef::Types::Array::Array->new(@{$obj});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::If') {
            foreach my $i (0 .. $#{$obj->{if}}) {
                my %code = $self->optimize($obj->{if}[$i]{block}{code});
                $obj->{if}[$i]{block}{code} = \%code;

                my %expr = $self->optimize($obj->{if}[$i]{expr});
                $obj->{if}[$i]{expr} = \%expr;
            }
            if (exists $obj->{else}) {
                my %code = $self->optimize($obj->{else}{block}{code});
                $obj->{else}{block}{code} = \%code;
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::While' or $ref eq 'Sidef::Types::Block::ForEach') {
            my %expr = $self->optimize($obj->{expr});
            $obj->{expr} = \%expr;

            my %code = $self->optimize($obj->{block}{code});
            $obj->{block}{code} = \%code;
        }
        elsif ($ref eq 'Sidef::Types::Block::CFor') {
            foreach my $i (0 .. $#{$obj->{expr}}) {
                my %expr = $self->optimize($obj->{expr}[$i]);
                $obj->{expr}[$i] = \%expr;
            }
            my %code = $self->optimize($obj->{block}{code});
            $obj->{block}{code} = \%code;
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
                    }

                    $obj->{call}[$i] = {method => $method};
                }
                elsif (exists $call->{keyword}) {
                    $obj->{call}[$i] = {keyword => $call->{keyword}};
                }

                # Method arguments
                if (exists $call->{arg}) {
                    foreach my $j (0 .. $#{$call->{arg}}) {
                        my $arg = $call->{arg}[$j];
                        push @{$obj->{call}[$i]{arg}}, ref $arg eq 'HASH'
                          && $ref_obj ne 'Sidef::Types::Block::For' ? do { my %arg = $self->optimize($arg); \%arg } : $arg;
                    }
                }

                # Block
                if (exists $call->{block}) {
                    foreach my $j (0 .. $#{$call->{block}}) {
                        my $arg = $call->{block}[$j];
                        push @{$obj->{call}[$i]{block}},
                          ref $arg eq 'HASH' ? do { my %arg = $self->optimize($arg); \%arg } : $arg;
                    }
                }

                #
                ## Constant folding support
                #
                my $optimized = 0;
                if (    defined($ref_obj)
                    and exists($rules{$ref_obj})
                    and not exists($expr->{ind})
                    and ref($method) eq '') {

                    my $code = $ref_obj->SUPER::can($method);

                    if (defined $code) {
                        my $obj_call = $obj->{call}[$i];

                        foreach my $rule (@{$rules{$ref_obj}}) {

                            if (exists($rule->{$code})
                                and (exists($obj_call->{arg}) ? ($#{$obj_call->{arg}} == 0) : 1)) {

                                my @args = (
                                      exists($obj_call->{arg})
                                    ? ref($obj_call->{arg}[0]) eq 'HASH'
                                          ? do {
                                              @{(values(%{$obj_call->{arg}[0]}))[0]};
                                          }
                                          : $obj_call->{arg}[0]
                                    : ()
                                );

                                if ($#args == $#{$rule->{$code}}) {

                                    my $ok = 1;
                                    foreach my $j (0 .. $#args) {
                                        if (not exists($rule->{$code}[$j]{ref($args[$j])})) {
                                            $ok = 0;
                                            last;
                                        }
                                    }

                                    if ($ok) {
                                        $obj->{self} = $obj->{self}->$code(@args);
                                        $ref_obj     = ref($obj->{self});
                                        $optimized   = 1;
                                    }

                                    last;
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

        wantarray ? %opt_struct : $#{$opt_struct{$classes[-1]}} > 0 ? \%opt_struct : $opt_struct{$classes[-1]}[-1];
    }
};

1;
