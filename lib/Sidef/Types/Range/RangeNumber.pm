package Sidef::Types::Range::RangeNumber;

use utf8;
use 5.016;

use parent qw(
  Sidef::Types::Range::Range
);

use overload q{""} => sub {
    my ($self) = @_;
    "RangeNum(" . join(', ', $self->{from}->dump, $self->{to}->dump, $self->{step}->dump) . ")";
};

use Sidef::Types::Bool::Bool;
use Sidef::Types::Number::Number;
use Sidef::Types::Block::Block;

# Pre-cached class names to bypass string allocations
my $NUMBER_CLASS = 'Sidef::Types::Number::Number';
my $BLOCK_CLASS  = 'Sidef::Types::Block::Block';

# Pre-cached static block for empty/exhausted iterators
state $EMPTY_ITERATOR = CORE::bless({code => sub { undef }}, $BLOCK_CLASS);

sub new {
    my (undef, $from, $to, $step) = @_;

    if (not defined $from) {
        $from = Sidef::Types::Number::Number::ZERO;
        $to   = Sidef::Types::Number::Number::MONE;
    }

    if (not defined $to) {
        $to   = $from->sub(Sidef::Types::Number::Number::ONE);
        $from = Sidef::Types::Number::Number::ZERO;
    }

    if (ref($to) eq __PACKAGE__) {
        $to = $to->{to};
    }

    bless {
           from => $from,
           to   => $to,
           step => $step // Sidef::Types::Number::Number::ONE,
          },
      __PACKAGE__;
}

*call = \&new;

sub iter {
    my ($self) = @_;

    my $step = $self->{step};
    my $from = $self->{from};
    my $to   = $self->{to};

    # -------------------------------------------------------------------------
    # Fast native integers / single-word GMPz
    # -------------------------------------------------------------------------
    if (ref($step) eq $NUMBER_CLASS and ref($from) eq $NUMBER_CLASS and ref($to) eq $NUMBER_CLASS) {

        my $u_from = $$from;
        my $u_step = $$step;
        my $u_to   = $$to;

        my $r_from = ref($u_from);
        my $r_step = ref($u_step);
        my $r_to   = ref($u_to);

        # Extract native machine integers if available
        if (   (!$r_to || ($r_to eq 'Math::GMPz' && Math::GMPz::Rmpz_fits_slong_p($u_to)))
            && (!$r_from || ($r_from eq 'Math::GMPz' && Math::GMPz::Rmpz_fits_slong_p($u_from)))
            && (!$r_step || ($r_step eq 'Math::GMPz' && Math::GMPz::Rmpz_fits_slong_p($u_step)))) {

            my $curr  = $r_from ? Math::GMPz::Rmpz_get_si($u_from) : $u_from;
            my $inc   = $r_step ? Math::GMPz::Rmpz_get_si($u_step) : $u_step;
            my $limit = $r_to   ? Math::GMPz::Rmpz_get_si($u_to)   : $u_to;

            #$inc || return $EMPTY_ITERATOR;
            my $repetitions = ($inc == 0) ? 'Inf' : CORE::int(($limit - $curr + $inc) / $inc);
            return $EMPTY_ITERATOR if $repetitions <= 0;

            # Check if range guarantees no overflow of standard integer bounds
            my $final_val = $curr + ($repetitions - 1) * $inc;

            if (   $final_val > Sidef::Types::Number::Number::LONG_MIN
                && $final_val < Sidef::Types::Number::Number::ULONG_MAX) {

                # Step == 1 (Most common case)
                if ($inc == 1) {
                    return CORE::bless(
                        {
                         code => sub {
                             $repetitions-- > 0 or return undef;
                             my $v = $curr++;
                             CORE::bless(\$v, $NUMBER_CLASS);
                         }
                        },
                        $BLOCK_CLASS
                    );
                }

                # Step == -1
                if ($inc == -1) {
                    return CORE::bless(
                        {
                         code => sub {
                             $repetitions-- > 0 or return undef;
                             my $v = $curr--;
                             CORE::bless(\$v, $NUMBER_CLASS);
                         }
                        },
                        $BLOCK_CLASS
                    );
                }

                # Generic Native Integer Step
                return CORE::bless(
                    {
                     code => sub {
                         $repetitions-- > 0 or return undef;
                         my $v = $curr;
                         $curr += $inc;
                         CORE::bless(\$v, $NUMBER_CLASS);
                     }
                    },
                    $BLOCK_CLASS
                );
            }
        }

        # -------------------------------------------------------------------------
        # Pure Math::GMPz range iteration (Heavy/Overflow Path)
        # -------------------------------------------------------------------------
        if (   (!$r_to || ($r_to eq 'Math::GMPz'))
            && (!$r_from || ($r_from eq 'Math::GMPz'))
            && (!$r_step || ($r_step eq 'Math::GMPz'))) {

            my $mpz_from  = $r_from ? $u_from : ($u_from > 0 ? Math::GMPz::Rmpz_init_set_ui($u_from) : Math::GMPz::Rmpz_init_set_si($u_from));
            my $curr_mpz  = Math::GMPz::Rmpz_init_set($mpz_from);
            my $times_mpz = $self->{_times};

            # Calculate repetition count via GMPz
            if (!defined $times_mpz) {
                my $mpz_step = $r_step ? $u_step : ($u_step > 0 ? Math::GMPz::Rmpz_init_set_ui($u_step) : Math::GMPz::Rmpz_init_set_si($u_step));
                my $mpz_to   = $r_to   ? $u_to   : ($u_to > 0   ? Math::GMPz::Rmpz_init_set_ui($u_to)   : Math::GMPz::Rmpz_init_set_si($u_to));

                $times_mpz = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_sub($times_mpz, $mpz_to, $mpz_from);
                Math::GMPz::Rmpz_add($times_mpz, $times_mpz, $mpz_step);

                if (Math::GMPz::Rmpz_cmp_ui($mpz_step, 1) != 0 and Math::GMPz::Rmpz_sgn($mpz_step) != 0) {
                    Math::GMPz::Rmpz_tdiv_q($times_mpz, $times_mpz, $mpz_step);
                }

                $self->{_times} = $times_mpz;
            }

            return $EMPTY_ITERATOR if Math::GMPz::Rmpz_sgn($times_mpz) <= 0;

            # Repetitions stored as native counter if it fits
            if (Math::GMPz::Rmpz_fits_ulong_p($times_mpz)) {
                my $rep_count = Math::GMPz::Rmpz_get_ui($times_mpz);

                # GMPz with native step
                if (!$r_step and $u_step >= 0 and $u_step < Sidef::Types::Number::Number::ULONG_MAX) {
                    return CORE::bless(
                        {
                         code => sub {
                             $rep_count-- > 0 or return undef;
                             my $out_mpz = Math::GMPz::Rmpz_init_set($curr_mpz);
                             Math::GMPz::Rmpz_add_ui($curr_mpz, $curr_mpz, $u_step);
                             CORE::bless(\$out_mpz, $NUMBER_CLASS);
                         }
                        },
                        $BLOCK_CLASS
                    );
                }

                # Generic GMPz Step
                my $mpz_step = $r_step ? $u_step : ($u_step > 0 ? Math::GMPz::Rmpz_init_set_ui($u_step) : Math::GMPz::Rmpz_init_set_si($u_step));
                return CORE::bless(
                    {
                     code => sub {
                         $rep_count-- > 0 or return undef;
                         my $out_mpz = Math::GMPz::Rmpz_init_set($curr_mpz);
                         Math::GMPz::Rmpz_add($curr_mpz, $curr_mpz, $mpz_step);
                         CORE::bless(\$out_mpz, $NUMBER_CLASS);
                     }
                    },
                    $BLOCK_CLASS
                );
            }
        }

        # -------------------------------------------------------------------------
        # Pure Math::GMPz range iteration: infinite positive (ascending) range
        # -------------------------------------------------------------------------
        if (   ($r_to eq 'Math::MPFR' and Math::MPFR::Rmpfr_inf_p($u_to) and Math::MPFR::Rmpfr_sgn($u_to) > 0)
            && (!$r_from || ($r_from eq 'Math::GMPz'))
            && (!$r_step || ($r_step eq 'Math::GMPz'))) {

            my $mpz_from = $r_from ? $u_from : ($u_from > 0 ? Math::GMPz::Rmpz_init_set_ui($u_from) : Math::GMPz::Rmpz_init_set_si($u_from));
            my $curr_mpz = Math::GMPz::Rmpz_init_set($mpz_from);

            # GMPz with native step
            if (!$r_step and $u_step > 0 and $u_step < Sidef::Types::Number::Number::ULONG_MAX) {
                return CORE::bless(
                    {
                     code => sub {
                         my $out_mpz = Math::GMPz::Rmpz_init_set($curr_mpz);
                         Math::GMPz::Rmpz_add_ui($curr_mpz, $curr_mpz, $u_step);
                         CORE::bless(\$out_mpz, $NUMBER_CLASS);
                     }
                    },
                    $BLOCK_CLASS
                );
            }

            if (!$r_step and $u_step < 0) {
                return $EMPTY_ITERATOR;
            }

            # Generic GMPz Step
            my $mpz_step = $r_step ? $u_step : ($u_step > 0 ? Math::GMPz::Rmpz_init_set_ui($u_step) : Math::GMPz::Rmpz_init_set_si($u_step));
            Math::GMPz::Rmpz_sgn($mpz_step) >= 0 or return $EMPTY_ITERATOR;

            return CORE::bless(
                {
                 code => sub {
                     my $out_mpz = Math::GMPz::Rmpz_init_set($curr_mpz);
                     Math::GMPz::Rmpz_add($curr_mpz, $curr_mpz, $mpz_step);
                     CORE::bless(\$out_mpz, $NUMBER_CLASS);
                 }
                },
                $BLOCK_CLASS
            );

        }
    }

    # -------------------------------------------------------------------------
    # Generic Fallback Path (Objects, Fractions, Reals, Floats)
    # -------------------------------------------------------------------------
    my $asc = ($self->{_asc} //= !!($step->is_pos // return $EMPTY_ITERATOR));

    return CORE::bless(
        {
         code => $asc
         ? sub {
             $from->le($to) || return undef;
             my $tmp = $from;
             $from = $from->add($step);
             return $tmp;
         }
         : sub {
             $from->ge($to) || return undef;
             my $tmp = $from;
             $from = $from->add($step);
             return $tmp;
         }
        },
        $BLOCK_CLASS
    );
}

sub _reduce_by {
    my ($self, $method, $result, $callback) = @_;

    my @list;
    my $count = 0;

    my $iter = $self->iter;

    while (1) {
        push @list, $callback->($iter->run() // last);

        if (++$count > 1e5) {
            $count  = 0;
            $result = $result->$method(splice(@list));
        }
    }

    if (@list) {
        $result = $result->$method(splice(@list));
    }

    $result;
}

sub sum_by {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_reduce_by('sum', Sidef::Types::Number::Number::ZERO, sub { $block->run($_[0]) });
}

sub sum {
    my ($self, $arg) = @_;

    if (defined($arg)) {
        goto &sum_by;
    }

    # Formula:
    #   sum(x .. y `by` z) = (floor((y - x)/z) + 1) * (z * floor((y - x)/z) + 2*x) / 2

    my ($x, $y, $z) = @{$self}{'from', 'to', 'step'};

    my $n = $y->sub($x)->div($z);

    if ($n->is_neg) {
        return Sidef::Types::Number::Number::ZERO;
    }

    state $two = Sidef::Types::Number::Number::_set_int(2);

    $n = $n->floor;
    $n->inc->mul($z->mul($n)->add($x->mul($two)))->div($two);
}

*Σ = \&sum;

sub avg_by {
    my ($self, $block) = @_;
    $self->sum_by($block)->div($self->len);
}

sub avg {
    my ($self, $arg) = @_;

    if (defined($arg)) {
        goto &avg_by;
    }

    $self->sum->div($self->len);
}

sub prod_by {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_reduce_by('prod', Sidef::Types::Number::Number::ONE, sub { $block->run($_[0]) });
}

sub prod {
    my ($self, $arg) = @_;

    if (defined($arg)) {
        goto &prod_by;
    }

    if (    $self->{step}->is_one
        and $self->{from}->is_one
        and $self->{to}->is_pos) {
        return $self->{to}->factorial;
    }

    Sidef::Types::Number::Number::prod($self->to_list);
}

*Π = \&prod;

sub lcm_by {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_reduce_by('lcm', Sidef::Types::Number::Number::ONE, sub { $block->run($_[0]) });
}

sub lcm {
    my ($self, $arg) = @_;

    if (defined($arg)) {
        goto &lcm_by;
    }

    if (    $self->{step}->is_one
        and $self->{from}->is_one
        and $self->{to}->is_pos) {
        return $self->{to}->consecutive_lcm;
    }

    Sidef::Types::Number::Number::lcm($self->to_list);
}

sub gcd_by {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_reduce_by('gcd', Sidef::Types::Number::Number::ZERO, sub { $block->run($_[0]) });
}

sub gcd {
    my ($self, $arg) = @_;

    if (defined($arg)) {
        goto &gcd_by;
    }

    Sidef::Types::Number::Number::gcd($self->to_list);
}

sub bsearch {
    my ($self, $block) = @_;

    if ($self->{step}->is_one) {
        my $left  = Sidef::Types::Number::Number->new($self->{from});
        my $right = Sidef::Types::Number::Number->new($self->{to});
        return Sidef::Types::Number::Number::bsearch($left, $right, $block);
    }

    $self->to_a->bsearch($block);
}

sub bsearch_le {
    my ($self, $block) = @_;

    if ($self->{step}->is_one) {
        my $left  = Sidef::Types::Number::Number->new($self->{from});
        my $right = Sidef::Types::Number::Number->new($self->{to});
        return Sidef::Types::Number::Number::bsearch_le($left, $right, $block);
    }

    $self->to_a->bsearch_le($block);
}

sub bsearch_ge {
    my ($self, $block) = @_;

    if ($self->{step}->is_one) {
        my $left  = Sidef::Types::Number::Number->new($self->{from});
        my $right = Sidef::Types::Number::Number->new($self->{to});
        return Sidef::Types::Number::Number::bsearch_ge($left, $right, $block);
    }

    $self->to_a->bsearch_ge($block);
}

sub faulhaber_sum {
    my ($self, $k) = @_;

    $k = Sidef::Types::Number::Number->new($k);

    if ($self->{step}->is_one) {

        my $left  = Sidef::Types::Number::Number->new($self->{from});
        my $right = Sidef::Types::Number::Number->new($self->{to});

        return Sidef::Types::Number::Number::faulhaber_range($left, $right, $k);
    }

    $self->lazy->map(Sidef::Types::Block::Block->new(code => sub { $_[0]->ipow($k) }))->sum;
}

*faulhaber = \&faulhaber_sum;

sub mertens {
    my ($self) = @_;

    if ($self->{step}->is_one) {

        my $left  = Sidef::Types::Number::Number->new($self->{from});
        my $right = Sidef::Types::Number::Number->new($self->{to});

        return Sidef::Types::Number::Number::mertens($left, $right);
    }

    $self->lazy->grep(Sidef::Types::Block::Block->new(code => sub { $_[0]->is_squarefree }))
      ->map(Sidef::Types::Block::Block->new(code => sub { $_[0]->moebius }))
      ->sum;
}

sub dump {
    my ($self) = @_;
    Sidef::Types::String::String->new("$self");
}

*to_s   = \&dump;
*to_str = \&dump;

{
    no strict 'refs';

    {
        my @methods = (
                       {
                        each_name  => 'each_squarefree',
                        arr_name   => 'squarefree',
                        count_name => 'squarefree_count',
                        sum_name   => 'squarefree_sum',
                        predicate  => sub { $_[0]->is_squarefree },
                       },
                       {
                        each_name  => 'each_cubefree',
                        arr_name   => 'cubefree',
                        count_name => 'cubefree_count',
                        sum_name   => 'cubefree_sum',
                        predicate  => sub { $_[0]->is_cubefree },
                       },
                       {
                        each_name  => 'each_squarefull',
                        arr_name   => 'squarefull',
                        count_name => 'squarefull_count',
                        sum_name   => 'squarefull_sum',
                        predicate  => sub { $_[0]->is_squarefull },
                       },
                       {
                        each_name  => 'each_cubefull',
                        arr_name   => 'cubefull',
                        count_name => 'cubefull_count',
                        sum_name   => 'cubefull_sum',
                        predicate  => sub { $_[0]->is_cubefull },
                       },
                       {
                        each_name  => 'each_nonsquarefree',
                        arr_name   => 'nonsquarefree',
                        count_name => 'nonsquarefree_count',
                        sum_name   => 'nonsquarefree_sum',
                        predicate  => sub { $_[0]->is_nonsquarefree },
                       },
                       {
                        each_name  => 'each_noncubefree',
                        arr_name   => 'noncubefree',
                        count_name => 'noncubefree_count',
                        sum_name   => 'noncubefree_sum',
                        predicate  => sub { $_[0]->is_noncubefree },
                       },
                       {
                        each_name  => 'each_semiprime',
                        arr_name   => 'semiprimes',
                        count_name => 'semiprime_count',
                        sum_name   => 'semiprime_sum',
                        predicate  => sub { $_[0]->is_semiprime },
                       },
                       {
                        each_name  => 'each_squarefree_semiprime',
                        arr_name   => 'squarefree_semiprimes',
                        count_name => 'squarefree_semiprime_count',
                        sum_name   => 'squarefree_semiprime_sum',
                        predicate  => sub { $_[0]->is_squarefree_semiprime },
                       },
                       {
                        each_name  => 'each_composite',
                        arr_name   => 'composites',
                        count_name => 'composite_count',
                        sum_name   => 'composite_sum',
                        predicate  => sub { $_[0]->is_composite },
                       },
                       {
                        each_name  => 'each_prime',
                        arr_name   => 'primes',
                        count_name => 'prime_count',
                        sum_name   => 'prime_sum',
                        predicate  => sub { $_[0]->is_prime },
                       },
                       {
                        each_name  => 'each_prime_power',
                        arr_name   => 'prime_powers',
                        count_name => 'prime_power_count',
                        sum_name   => 'prime_power_sum',
                        predicate  => sub { $_[0]->is_prime_power },
                       },
                      );

        foreach my $method (@methods) {

            # Each
            if (defined($method->{each_name})) {
                *{__PACKAGE__ . '::' . $method->{each_name}} = sub {
                    my ($self, $block) = @_;

                    if ($self->{step}->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        &{'Sidef::Types::Number::Number::' . $method->{each_name}}($left, $right, $block);
                        return $self;
                    }

                    $self->lazy->grep(Sidef::Types::Block::Block->new(code => $method->{predicate}))->each($block);
                    return $self;
                };
            }

            # Array
            if (defined($method->{arr_name})) {
                *{__PACKAGE__ . '::' . $method->{arr_name}} = sub {
                    my ($self) = @_;

                    if ($self->{step}->abs->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        if ($self->{step}->is_neg) {
                            return &{'Sidef::Types::Number::Number::' . $method->{arr_name}}($right, $left)->flip;
                        }

                        return &{'Sidef::Types::Number::Number::' . $method->{arr_name}}($left, $right);
                    }

                    $self->lazy->grep(Sidef::Types::Block::Block->new(code => $method->{predicate}));
                };
            }

            # Sum
            if (defined($method->{sum_name})) {
                *{__PACKAGE__ . '::' . $method->{sum_name}} = sub {
                    my ($self) = @_;

                    if ($self->{step}->abs->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        if ($self->{step}->is_neg) {
                            ($right, $left) = ($left, $right);
                        }

                        return &{'Sidef::Types::Number::Number::' . $method->{sum_name}}($left, $right);
                    }

                    $self->lazy->grep(Sidef::Types::Block::Block->new(code => $method->{predicate}))->sum;
                };
            }

            # Count
            if (defined($method->{count_name})) {
                *{__PACKAGE__ . '::' . $method->{count_name}} = sub {
                    my ($self) = @_;

                    if ($self->{step}->abs->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        if ($self->{step}->is_neg) {
                            ($right, $left) = ($left, $right);
                        }

                        return &{'Sidef::Types::Number::Number::' . $method->{count_name}}($left, $right);
                    }

                    $self->count_by(Sidef::Types::Block::Block->new(code => $method->{predicate}));
                };
            }
        }
    }

    {
        my @methods = (
            {
             arr_name   => 'squarefree_almost_primes',
             each_name  => 'each_squarefree_almost_prime',
             count_name => 'squarefree_almost_prime_count',
             sum_name   => 'squarefree_almost_prime_sum',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_squarefree_almost_prime($k) };
             },
            },
            {
             arr_name  => 'carmichael',
             each_name => 'each_carmichael',
             predicate => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_carmichael && $_[0]->is_almost_prime($k) };
             },
            },
            {
             arr_name  => 'lucas_carmichael',
             each_name => 'each_lucas_carmichael',
             predicate => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_lucas_carmichael && $_[0]->is_almost_prime($k) };
             },
            },
            {
             arr_name   => 'omega_primes',
             each_name  => 'each_omega_prime',
             count_name => 'omega_prime_count',
             sum_name   => 'omega_prime_sum',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_omega_prime($k) };
             },
            },
            {
             arr_name   => 'almost_primes',
             each_name  => 'each_almost_prime',
             count_name => 'almost_prime_count',
             sum_name   => 'almost_prime_sum',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_almost_prime($k) };
             },
            },
            {
             arr_name   => 'powerful',
             each_name  => 'each_powerful',
             count_name => 'powerful_count',
             sum_name   => 'powerful_sum',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_powerful($k) };
             },
            },
            {
             arr_name   => 'nonpowerfree',
             each_name  => 'each_nonpowerfree',
             count_name => 'nonpowerfree_count',
             sum_name   => 'nonpowerfree_sum',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_nonpowerfree($k) };
             },
            },
            {
             arr_name   => 'powerfree',
             each_name  => 'each_powerfree',
             count_name => 'powerfree_count',
             sum_name   => 'powerfree_sum',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_powerfree($k) };
             },
            },
            {
             count_name => 'smooth_count',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_smooth($k) };
             },
            },
            {
             count_name => 'rough_count',
             predicate  => sub {
                 my ($k) = @_;
                 sub { $_[0]->is_rough($k) };
             },
            },
        );

        foreach my $method (@methods) {

            # Each
            if (defined($method->{each_name})) {
                *{__PACKAGE__ . '::' . $method->{each_name}} = sub {
                    my ($self, $k, $block) = @_;

                    $k = Sidef::Types::Number::Number->new($k);

                    if ($self->{step}->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        &{'Sidef::Types::Number::Number::' . $method->{each_name}}($k, $left, $right, $block);
                        return $self;
                    }

                    $self->lazy->grep(Sidef::Types::Block::Block->new(code => $method->{predicate}->($k)))->each($block);
                    return $self;
                };
            }

            # Array
            if (defined($method->{arr_name})) {
                *{__PACKAGE__ . '::' . $method->{arr_name}} = sub {
                    my ($self, $k) = @_;

                    $k = Sidef::Types::Number::Number->new($k);

                    if ($self->{step}->abs->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        if ($self->{step}->is_neg) {
                            return &{'Sidef::Types::Number::Number::' . $method->{arr_name}}($k, $right, $left)->flip;
                        }

                        return &{'Sidef::Types::Number::Number::' . $method->{arr_name}}($k, $left, $right);
                    }

                    $self->lazy->grep(Sidef::Types::Block::Block->new(code => $method->{predicate}->($k)));
                };
            }

            # Sum
            if (defined($method->{sum_name})) {
                *{__PACKAGE__ . '::' . $method->{sum_name}} = sub {
                    my ($self, $k) = @_;

                    $k = Sidef::Types::Number::Number->new($k);

                    if ($self->{step}->abs->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        if ($self->{step}->is_neg) {
                            ($right, $left) = ($left, $right);
                        }

                        return &{'Sidef::Types::Number::Number::' . $method->{sum_name}}($k, $left, $right);
                    }

                    $self->lazy->grep(Sidef::Types::Block::Block->new(code => $method->{predicate}->($k)))->sum;
                };
            }

            # Count
            if (defined($method->{count_name})) {

                *{__PACKAGE__ . '::' . $method->{count_name}} = sub {
                    my ($self, $k) = @_;

                    $k = Sidef::Types::Number::Number->new($k);

                    if ($self->{step}->abs->is_one) {

                        my $left  = Sidef::Types::Number::Number->new($self->{from});
                        my $right = Sidef::Types::Number::Number->new($self->{to});

                        if ($self->{step}->is_neg) {
                            ($right, $left) = ($left, $right);
                        }

                        return &{'Sidef::Types::Number::Number::' . $method->{count_name}}($k, $left, $right);
                    }

                    $self->count_by(Sidef::Types::Block::Block->new(code => $method->{predicate}->($k)));
                };

            }
        }
    }
}

1
