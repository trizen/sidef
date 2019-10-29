package Sidef::Types::Range::Range {

    use utf8;
    use 5.016;

    use List::Util qw();
    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;
    use Sidef::Types::Block::Block;

    use overload '@{}' => sub {
        $_[0]->{_cached_array} //= do {
            my @array;
            my $iter = $_[0]->iter;
            for (; ;) {
                push @array, ($iter->run() // last);
            }
            \@array;
        };
    };

    sub new {
        shift();
        my $from = shift;
        $from->range(@_);
    }

    *call = \&new;

    sub by {
        my ($self, $step) = @_;
        defined($step)
          ? $self->new(
                        $self->{from}, $self->{to}, $self->{step}->is_neg
                      ? $step->neg
                      : $step
          )
          : $self->{step};
    }

    sub from {
        my ($self, $from) = @_;
        defined($from)
          ? $self->new($from, $self->{to}, $self->{step})
          : $self->{from};
    }

    sub to {
        my ($self, $to) = @_;
        defined($to)
          ? $self->new($self->{from}, $to, $self->{step})
          : $self->{to};
    }

    sub min_by {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my $iter = $self->iter;

        my $min       = $iter->run() // return undef;
        my $min_value = $block->run($min);

        while (1) {
            my $curr       = $iter->run() // last;
            my $curr_value = $block->run($curr);

            if (CORE::int($curr_value cmp $min_value) < 0) {
                $min       = $curr;
                $min_value = $curr_value;
            }
        }

        $min;
    }

    sub min {
        my ($self, $block) = @_;

        if (defined($block)) {
            goto &min_by;
        }

        ($self->{_asc} //= !!$self->{step}->is_pos)
          ? $self->{from}
          : $self->{to};
    }

    sub max_by {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my $iter = $self->iter;

        my $max       = $iter->run() // return undef;
        my $max_value = $block->run($max);

        while (1) {
            my $curr       = $iter->run() // last;
            my $curr_value = $block->run($curr);

            if (CORE::int($curr_value cmp $max_value) > 0) {
                $max       = $curr;
                $max_value = $curr_value;
            }
        }

        $max;
    }

    sub max {
        my ($self, $block) = @_;

        if (defined($block)) {
            goto &max_by;
        }

        ($self->{_asc} //= !!$self->{step}->is_pos)
          ? $self->{to}
          : $self->{from};
    }

    sub step {
        $_[0]->{step};
    }

    sub bounds {
        my ($self) = @_;
        ($self->min, $self->max);
    }

    sub reverse {
        my ($self) = @_;
        $self->new($self->{to}, $self->{from}, $self->{step}->neg);
    }

    *flip = \&reverse;

    sub first_by {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my $iter = $self->iter;

        for (; ;) {
            my $obj = $iter->run() // last;
            return $obj if $block->run($obj);
        }

        undef;
    }

    sub first {
        my ($self, $num) = @_;

        if (ref($num) eq 'Sidef::Types::Block::Block') {
            goto &first_by;
        }

        my $iter = $self->iter;

        if (defined $num) {

            my @array;
            foreach my $i (1 .. CORE::int($num)) {
                my $item = $iter->run() // last;
                push @array, $item;
            }

            return Sidef::Types::Array::Array->new(\@array);
        }

        $iter->run() // undef;
    }

    *head = \&first;

    sub last {
        my ($self, $num) = @_;

        if (ref($num) eq 'Sidef::Types::Block::Block') {
            return $self->reverse->first_by($num);
        }

        defined($num)
          ? $self->reverse->first($num)->reverse
          : $self->reverse->first;
    }

    *tail = \&last;

    sub last_by {
        my ($self, $block) = @_;
        $self->reverse->first_by($block);
    }

    sub contains {
        my ($self, $value) = @_;

        my $step = $self->{step};
        my $asc  = ($self->{_asc} //= !!$step->is_pos);

        my ($from, $to) = (
                           $asc
                           ? ($self->{from}, $self->{to})
                           : ($self->{to}, $self->{from})
                          );

        (
               $value->ge($from)
           and $value->le($to)
           and (
             do { $self->{_is_one} //= ($asc ? $step->is_one : $step->abs->is_one) }
             && $value->is_int ? 1
             : $value->sub(
                             $asc ? $from
                           : $to
             )->div($step)->int->mul($step)->eq(
                                                $value->sub(
                                                              $asc ? $from
                                                            : $to
                                                           )
                                               )
               )
          ) ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub length {
        my ($self) = @_;
        my $len = $self->{to}->sub($self->{from})->add($self->{step})->div($self->{step})->int;
        $len->is_neg ? Sidef::Types::Number::Number::ZERO : $len;
    }

    *len = \&length;

    sub each {
        my ($self, $block) = @_;

        my $iter = $self->iter;

        for (; ;) {
            $block->run($iter->run() // last);
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub map {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my @values;
        my $iter = $self->iter;

        for (; ;) {
            push @values, $block->run($iter->run() // last);
        }

        Sidef::Types::Array::Array->new(\@values);
    }

    sub grep {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my @values;
        my $iter = $self->iter;

        for (; ;) {
            my $obj = $iter->run() // last;
            push(@values, $obj) if $block->run($obj);
        }

        Sidef::Types::Array::Array->new(\@values);
    }

    *select = \&grep;

    sub any {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my $iter = $self->iter;

        for (; ;) {
            $block->run($iter->run() // last)
              && return Sidef::Types::Bool::Bool::TRUE;
        }

        Sidef::Types::Bool::Bool::FALSE;
    }

    sub all {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my $iter = $self->iter;

        for (; ;) {
            $block->run($iter->run() // last)
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub none {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my $iter = $self->iter;

        for (; ;) {
            $block->run($iter->run() // last)
              && return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub to_array {
        my ($self) = @_;

        my @array;
        my $iter = $self->iter;

        for (; ;) {
            push @array, ($iter->run() // last);
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    *to_a = \&to_array;

    sub to_vector {
        my ($self) = @_;
        $self->to_a->to_v;
    }

    *to_v   = \&to_vector;
    *to_vec = \&to_vector;

    sub to_list {
        my ($self) = @_;

        my @array;
        my $iter = $self->iter;

        for (; ;) {
            push @array, ($iter->run() // last);
        }

        (@array);
    }

    sub join {
        my ($self, $sep) = @_;
        Sidef::Types::String::String->new(CORE::join("$sep", $self->to_list));
    }

    sub kv {
        my ($self) = @_;
        $self->to_array->kv;
    }

    *pairs       = \&kv;
    *zip_indices = \&kv;

    sub accumulate {
        my ($self, $arg) = @_;
        $self->to_array->accumulate($arg);
    }

    sub accumulate_by {
        my ($self, $arg) = @_;
        $self->to_array->accumulate_by($arg);
    }

    sub rand {
        my ($self, $n) = @_;

        my $from = $self->{from};
        my $to   = $self->{to};
        my $step = $self->{step};

        my $limit    = $to->sub($from)->div($step);
        my $is_empty = $limit->lt(Sidef::Types::Number::Number::ZERO);

        if ($is_empty) {
            return (defined($n) ? Sidef::Types::Array::Array->new([]) : undef);
        }

        if (not defined $n) {
            return $limit->irand->mul($step)->add($from);
        }

        my @array;
        for (1 .. CORE::int($n)) {
            push @array, $limit->irand->mul($step)->add($from);
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    *sample = \&rand;

    sub pick {
        my ($self, $n) = @_;

        my $from = $self->{from};
        my $to   = $self->{to};
        my $step = $self->{step};

        my $limit    = $to->sub($from)->div($step);
        my $is_empty = $limit->lt(Sidef::Types::Number::Number::ZERO);

        if ($is_empty) {
            return (defined($n) ? Sidef::Types::Array::Array->new([]) : undef);
        }

        if (not defined $n) {
            return $limit->irand->mul($step)->add($from);
        }

        my (%seen, @array);
        my $amount = CORE::int($n);
        my $total  = CORE::int($limit) + 1;

        if ($amount <= 0) {
            return Sidef::Types::Array::Array->new([]);
        }

        while (1) {
            my $rand = $limit->irand->mul($step)->add($from);
            last if keys(%seen) == $total;
            next if $seen{$rand}++;
            push @array, $rand;
            last if --$amount == 0;
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub count_by {
        my ($self, $arg) = @_;

        my $count = 0;
        my $iter  = $self->iter;

        for (; ;) {
            ++$count if $arg->run($iter->run() // last);
        }

        Sidef::Types::Number::Number->_set_uint($count);
    }

    sub count {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Block::Block') {
            goto &count_by;
        }

        $self->contains($arg)
          ? Sidef::Types::Number::Number::ONE
          : Sidef::Types::Number::Number::ZERO;
    }

    sub shuffle {
        Sidef::Types::Array::Array->new([List::Util::shuffle($_[0]->to_list)]);
    }

    sub reduce {
        my ($self, $op, $initial) = @_;

        if (ref($op) eq 'Sidef::Types::Block::Block') {

            my $iter  = $self->iter;
            my $value = $initial // $iter->run();

            for (; ;) {
                $value = $op->run($value, $iter->run() // last);
            }

            return $value;
        }

        $self->reduce_operator("$op", $initial);
    }

    sub reduce_operator {
        my ($self, $op, $initial) = @_;

        $op = "$op" if ref($op);

        my $iter  = $self->iter;
        my $value = $initial // $iter->run();

        for (; ;) {
            $value = $value->$op($iter->run() // last);
        }

        $value;
    }

    sub map_operator {
        my ($self, @args) = @_;
        $self->to_array->map_operator(@args);
    }

    sub pam_operator {
        my ($self, @args) = @_;
        $self->to_array->pam_operator(@args);
    }

    sub unroll_operator {
        my ($self, @args) = @_;
        $self->to_array->unroll_operator(@args);
    }

    sub cross_operator {
        my ($self, @args) = @_;
        $self->to_array->cross_operator(@args);
    }

    sub zip_operator {
        my ($self, @args) = @_;
        $self->to_array->zip_operator(@args);
    }

    sub add {
        my ($self, $arg) = @_;
        $self->new($self->{from}->add($arg), $self->{to}->add($arg), $self->{step});
    }

    sub sub {
        my ($self, $arg) = @_;
        $self->new($self->{from}->sub($arg), $self->{to}->sub($arg), $self->{step});
    }

    sub mul {
        my ($self, $arg) = @_;
        $self->new($self->{from}->mul($arg), $self->{to}->mul($arg), $self->{step});
    }

    sub div {
        my ($self, $arg) = @_;
        $self->new($self->{from}->div($arg), $self->{to}->div($arg), $self->{step});
    }

    sub eq {
        my ($r1, $r2) = @_;

        ref($r1) eq ref($r2)
          && $r1->{from}->eq($r2->{from})
          && $r1->{to}->eq($r2->{to})
          && $r1->{step}->eq($r2->{step})

          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ne {
        my ($r1, $r2) = @_;
        $r1->eq($r2)->not;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'}   = \&ne;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;
    }

};

1
