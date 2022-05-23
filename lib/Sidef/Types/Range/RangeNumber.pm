package Sidef::Types::Range::RangeNumber {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Range::Range
      Sidef::Object::Object
    );

    use overload q{""} => sub {
        my ($self) = @_;
        "RangeNum(" . join(', ', $self->{from}->dump, $self->{to}->dump, $self->{step}->dump) . ")";
    };

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

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

    my @cache;

    sub iter {
        my ($self) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $times = ($self->{_times} //= $to->sub($from)->add($step)->div($step));

        if (ref($times) eq 'Sidef::Types::Number::Number') {
            my $repetitions = CORE::int(Sidef::Types::Number::Number::__numify__($$times));

            if ($repetitions < 0) {
                return Sidef::Types::Block::Block->new(code => sub { undef; });
            }

            if (    ref($step) eq 'Sidef::Types::Number::Number'
                and ref($from) eq 'Sidef::Types::Number::Number'
                and ref($$from) eq 'Math::GMPz'
                and ref($$step) eq 'Math::GMPz') {

                $from = $$from;
                $step = $$step;

                if (    ref($to) eq 'Sidef::Types::Number::Number'
                    and ref($$to) eq 'Math::GMPz'
                    and Math::GMPz::Rmpz_fits_slong_p($$to)
                    and Math::GMPz::Rmpz_fits_slong_p($from)
                    and Math::GMPz::Rmpz_fits_slong_p($step)) {

                    $from = Math::GMPz::Rmpz_get_si($from);
                    $step = Math::GMPz::Rmpz_get_si($step);

                    return Sidef::Types::Block::Block->new(
                        code => sub {
                            --$repetitions >= 0 or return undef;

                            if ($from < 8192 and $from >= 0) {
                                my $obj = ($cache[$from] //=
                                           bless(\Math::GMPz::Rmpz_init_set_ui($from), 'Sidef::Types::Number::Number'));
                                $from += $step;
                                return $obj;
                            }

                            if (Math::GMPz::get_refcnt($$Sidef::Types::Number::Number::MPZ) > 1) {
                                $Sidef::Types::Number::Number::MPZ =
                                  bless(\Math::GMPz::Rmpz_init_set_si($from), 'Sidef::Types::Number::Number');
                            }
                            else {
                                Math::GMPz::Rmpz_set_si($$Sidef::Types::Number::Number::MPZ, $from);
                            }

                            $from += $step;
                            $Sidef::Types::Number::Number::MPZ;
                        },
                    );
                }

                my $counter_mpz = Math::GMPz::Rmpz_init_set($from);

                return Sidef::Types::Block::Block->new(
                    code => sub {
                        --$repetitions >= 0 or return undef;
                        if (Math::GMPz::get_refcnt($$Sidef::Types::Number::Number::MPZ) > 1) {
                            $Sidef::Types::Number::Number::MPZ =
                              bless(\Math::GMPz::Rmpz_init_set($counter_mpz), 'Sidef::Types::Number::Number');
                        }
                        else {
                            Math::GMPz::Rmpz_set($$Sidef::Types::Number::Number::MPZ, $counter_mpz);
                        }

                        Math::GMPz::Rmpz_add($counter_mpz, $counter_mpz, $step);
                        $Sidef::Types::Number::Number::MPZ;
                    },
                );
            }
        }

        my $asc = ($self->{_asc} //= !!($step->is_pos // return Sidef::Types::Block::Block->new(code => sub { undef; })));

        my $tmp;
        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $from->le($to) : $from->ge($to)) || return undef;
                $tmp  = $from;
                $from = $from->add($step);
                $tmp;
            },
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
          ->map(Sidef::Types::Block::Block->new(code => sub { $_[0]->moebius }))->sum;
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
                            each_name  => 'each_semiprime',
                            arr_name   => 'semiprimes',
                            count_name => 'semiprime_count',
                            predicate  => sub { $_[0]->is_semiprime },
                           },
                           {
                            each_name  => 'each_composite',
                            arr_name   => 'composites',
                            count_name => 'composite_count',
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
                 predicate  => sub {
                     my ($k) = @_;
                     sub { $_[0]->is_squarefree && $_[0]->is_almost_prime($k) };
                 },
                },
                {
                 arr_name   => 'omega_primes',
                 each_name  => 'each_omega_prime',
                 count_name => 'omega_prime_count',
                 predicate  => sub {
                     my ($k) = @_;
                     sub { $_[0]->is_omega_prime($k) };
                 },
                },
                {
                 arr_name   => 'almost_primes',
                 each_name  => 'each_almost_prime',
                 count_name => 'almost_prime_count',
                 predicate  => sub {
                     my ($k) = @_;
                     sub { $_[0]->is_almost_prime($k) };
                 },
                },
                {
                 arr_name   => 'powerful',
                 each_name  => 'each_powerful',
                 count_name => 'powerful_count',
                 predicate  => sub {
                     my ($k) = @_;
                     sub { $_[0]->is_powerful($k) };
                 },
                },
                {
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
}

1;
