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

    sub iter {
        my ($self) = @_;

        my $step = $self->{step};
        my $from = $self->{from};
        my $to   = $self->{to};

        my $tmp;
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
                            $tmp = bless(\Math::GMPz::Rmpz_init_set_si($from), 'Sidef::Types::Number::Number');
                            $from += $step;
                            $tmp;
                        },
                    );
                }

                my $counter_mpz = Math::GMPz::Rmpz_init_set($from);

                return Sidef::Types::Block::Block->new(
                    code => sub {
                        --$repetitions >= 0 or return undef;
                        $tmp = bless(\Math::GMPz::Rmpz_init_set($counter_mpz), 'Sidef::Types::Number::Number');
                        Math::GMPz::Rmpz_add($counter_mpz, $counter_mpz, $step);
                        $tmp;
                    },
                );
            }
        }

        my $asc = ($self->{_asc} //= !!($step->is_pos // return Sidef::Types::Block::Block->new(code => sub { undef; })));

        Sidef::Types::Block::Block->new(
            code => sub {
                ($asc ? $from->le($to) : $from->ge($to)) || return undef;
                $tmp  = $from;
                $from = $from->add($step);
                $tmp;
            },
        );
    }

    sub _sum_prod_by {
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
        $self->_sum_prod_by('sum', Sidef::Types::Number::Number::ZERO, sub { $block->run($_[0]) });
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

        state $two = Sidef::Types::Number::Number->_set_uint(2);

        $n = $n->floor;
        $n->inc->mul($z->mul($n)->add($x->mul($two)))->div($two);
    }

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
        $self->_sum_prod_by('prod', Sidef::Types::Number::Number::ONE, sub { $block->run($_[0]) });
    }

    sub prod {
        my ($self, $arg) = @_;

        if (defined($arg)) {
            goto &prod_by;
        }

        if (    $self->{step}->is_one
            and $self->{from}->is_one
            and $self->{to}->is_pos) {
            $self->{_asc} //= 1;
            return $self->{to}->factorial;
        }

        Sidef::Types::Number::Number::prod($self->to_list);
    }

    sub bsearch {
        my ($self, $block) = @_;

        if ($self->{step}->abs->is_one) {
            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});
            return Sidef::Types::Number::Number::bsearch($left, $right, $block);
        }

        $self->to_a->bsearch($block);
    }

    sub bsearch_le {
        my ($self, $block) = @_;

        if ($self->{step}->abs->is_one) {
            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});
            return Sidef::Types::Number::Number::bsearch_le($left, $right, $block);
        }

        $self->to_a->bsearch_le($block);
    }

    sub bsearch_ge {
        my ($self, $block) = @_;

        if ($self->{step}->abs->is_one) {
            my $left  = Sidef::Types::Number::Number->new($self->{from});
            my $right = Sidef::Types::Number::Number->new($self->{to});
            return Sidef::Types::Number::Number::bsearch_ge($left, $right, $block);
        }

        $self->to_a->bsearch_ge($block);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }

    *to_s   = \&dump;
    *to_str = \&dump;
}

1;
