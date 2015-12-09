package Sidef::Types::Array::Array {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{""}   => \&dump,
      q{0+}   => sub { scalar(@{$_[0]}) },
      q{bool} => sub { scalar(@{$_[0]}) };

    sub new {
        my (undef, @items) = @_;
        bless \@items, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $item (@{$self}) {
            if (index(ref($item), 'Sidef::') == 0) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    sub unroll_operator {
        my ($self, $operator, $arg) = @_;

        $operator = $operator->get_value if ref($operator);

        my @array;
        if (defined $arg) {
            my $argc  = @{$arg};
            my $selfc = @{$self};
            my $max   = $argc > $selfc ? $argc - 1 : $selfc - 1;
            foreach my $i (0 .. $max) {
                push @array, $self->[$i % $selfc]->$operator($arg->[$i % $argc]);
            }
        }
        else {
            foreach my $i (0 .. $#{$self}) {
                push @array, $self->[$i]->$operator;
            }
        }

        $self->new(@array);
    }

    sub map_operator {
        my ($self, $operator, @args) = @_;

        $operator = $operator->get_value if ref($operator);

        my @array;
        foreach my $i (0 .. $#{$self}) {
            push @array, $self->[$i]->$operator(@args);
        }

        $self->new(@array);
    }

    sub pam_operator {
        my ($self, $operator, $arg) = @_;

        $operator = $operator->get_value if ref($operator);

        my @array;
        foreach my $i (0 .. $#{$self}) {
            push @array, $arg->$operator($self->[$i]);
        }

        $self->new(@array);
    }

    sub reduce_operator {
        my ($self, $operator) = @_;

        $operator = $operator->get_value if ref($operator);
        (my $offset = $#{$self}) >= 0 || return;

        my $x = $self->[0];
        foreach my $i (1 .. $offset) {
            $x = $x->$operator($self->[$i]);
        }
        $x;
    }

    sub cross_operator {
        my ($self, $operator, $arg) = @_;

        $operator = $operator->get_value if ref($operator);

        my @array;
        if ($operator eq '') {
            foreach my $i (@{$self}) {
                foreach my $j (@{$arg}) {
                    push @array, $self->new($i, $j);
                }
            }
        }
        else {
            foreach my $i (@{$self}) {
                foreach my $j (@{$arg}) {
                    push @array, $i->$operator($j);
                }
            }
        }

        $self->new(@array);
    }

    sub zip_operator {
        my ($self, $operator, $arg) = @_;

        $operator = $operator->get_value if ref($operator);

        my $self_len = $#{$self};
        my $arg_len  = $#{$arg};
        my $min      = $self_len < $arg_len ? $self_len : $arg_len;

        my @array;
        if ($operator eq '') {
            foreach my $i (0 .. $min) {
                push @array, $self->new($self->[$i], $arg->[$i]);
            }
        }
        else {
            foreach my $i (0 .. $min) {
                push @array, $self->[$i]->$operator($arg->[$i]);
            }
        }

        $self->new(@array);
    }

    sub _grep {
        my ($self, $array, $bool) = @_;

        my @new_array;
        foreach my $item (@{$self}) {

            my $exists = 0;
            my $value  = $item;

            if ($array->contains($value)) {
                $exists = 1;
            }

            push(@new_array, $value) if ($exists - $bool);
        }

        $self->new(@new_array);
    }

    sub multiply {
        my ($self, $num) = @_;
        $self->new((@{$self}) x $num->get_value);
    }

    *mul = \&multiply;

    sub divide {
        my ($self, $num) = @_;

        my @obj = @{$self};

        my @array;
        my $len = @obj / $num->get_value;

        my $i   = 1;
        my $pos = $len;
        while (@obj) {
            my $j = $pos - $i * int($len);
            $pos -= $j if $j >= 1;
            push @array, $self->new(splice @obj, 0, $len + $j);
            $pos += $len;
            $i++;
        }

        $self->new(@array);
    }

    *div = \&divide;

    sub or {
        my ($self, $array) = @_;
        my $new_array = $self->new;

        $self->xor($array)->concat($self->and($array));
    }

    sub xor {
        my ($self, $array) = @_;
        my $new_array = $self->new;

        ($self->concat($array))->subtract($self->and($array));
    }

    sub and {
        my ($self, $array) = @_;
        $self->_grep($array, 0);
    }

    sub is_empty {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($#{$self} == -1);
    }

    sub subtract {
        my ($self, $array) = @_;
        $self->_grep($array, 1);
    }

    *sub = \&subtract;

    sub concat {
        my ($self, $arg) = @_;

        eval { $arg->isa('ARRAY') }
          ? $self->new(@{$self}, @{$arg})
          : $self->new(@{$self}, $arg);
    }

    sub levenshtein {
        my ($self, $arg) = @_;

        my @s = @{$self};
        my @t = @{$arg};

        my $len1 = scalar(@s);
        my $len2 = scalar(@t);

        state $x = require List::Util;

        my @d = ([0 .. $len2], map { [$_] } 1 .. $len1);
        foreach my $i (1 .. $len1) {
            foreach my $j (1 .. $len2) {
                $d[$i][$j] =
                    $s[$i - 1] eq $t[$j - 1]
                  ? $d[$i - 1][$j - 1]
                  : List::Util::min($d[$i - 1][$j], $d[$i][$j - 1], $d[$i - 1][$j - 1]) + 1;
            }
        }

        Sidef::Types::Number::Number->new($d[-1][-1]);
    }

    *lev   = \&levenshtein;
    *leven = \&levenshtein;

    sub _combinations {
        my ($n, @set) = @_;

        @set || return;
        $n == 1 && return map { [$_] } @set;

        my $head = shift @set;
        my @result = _combinations($n - 1, @set);
        foreach my $subarray (@result) {
            CORE::unshift @{$subarray}, $head;
        }
        @result, _combinations($n, @set);
    }

    sub combinations {
        my ($self, $n) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::Array::Array->new(@{$_}) } _combinations($n->get_value, @{$self}));
    }

    *combination = \&combinations;

    sub count {
        my ($self, $obj) = @_;

        my $counter = 0;
        if (ref($obj) eq 'Sidef::Types::Block::Block') {

            foreach my $item (@{$self}) {
                if ($obj->run($item)) {
                    ++$counter;
                }
            }

            return Sidef::Types::Number::Number->new($counter);
        }

        foreach my $item (@{$self}) {
            $item eq $obj and $counter++;
        }

        Sidef::Types::Number::Number->new($counter);
    }

    *count_by = \&count;

    sub eq {
        my ($self, $array) = @_;

        if ($#{$self} != $#{$array}) {
            return Sidef::Types::Bool::Bool->false;
        }

        foreach my $i (0 .. $#{$self}) {
            my ($x, $y) = ($self->[$i], $array->[$i]);
            $x eq $y
              or return Sidef::Types::Bool::Bool->false;
        }

        return Sidef::Types::Bool::Bool->true;
    }

    sub ne {
        my ($self, $array) = @_;
        $self->eq($array)->not;
    }

    sub zip {
        my ($self, @arrays) = @_;

        my @new_array;
        foreach my $i (0 .. $#{$self}) {

            my @tmp_array = ($self->[$i]);
            foreach my $array (@arrays) {
                push @tmp_array, $array->[$i];
            }

            push @new_array, $self->new(@tmp_array);
        }

        $self->new(@new_array);
    }

    sub mzip {
        my ($self, $array) = @_;

        my $arr_max = @{$array};

        my @new_array;
        foreach my $i (0 .. $#{$self}) {
            push @new_array, $self->[$i], $array->[$i % $arr_max];
        }

        $self->new(@new_array);
    }

    sub make {
        my ($self, $size, $type) = @_;
        $self->new(($type) x $size->get_value);
    }

    sub _min_max {
        my ($self, $value) = @_;

        @{$self} || return;

        my $item = $self->[0];
        foreach my $i (1 .. $#{$self}) {
            my $val = $self->[$i];
            $item = $val if (($val cmp $item) == $value);
        }

        $item;
    }

    sub max {
        $_[0]->_min_max(1);
    }

    sub min {
        $_[0]->_min_max(-1);
    }

    sub minmax {
        my ($self) = @_;
        ($self->min, $self->max);
    }

    sub sum {
        defined($_[1])
          ? do {
            my $sum = $_[1];
            state $method = '+';
            foreach my $obj (@{$_[0]}) {
                $sum = $sum->$method($obj);
            }
            $sum;
          }
          : $_[0]->reduce_operator('+');
    }

    *collapse = \&sum;

    sub prod {
        defined($_[1])
          ? do {
            my $prod = $_[1];
            state $method = '*';
            foreach my $obj (@{$_[0]}) {
                $prod = $prod->$method($obj);
            }
            $prod;
          }
          : $_[0]->reduce_operator('*');
    }

    *product = \&prod;

    sub _min_max_by {
        my ($self, $code, $value) = @_;

        @{$self} || return;

        my @pairs = map { [$_, scalar $code->run($_)] } @{$self};

        my $item = $pairs[0];

        foreach my $i (1 .. $#pairs) {
            my $val = $pairs[$i][1];
            $item = $pairs[$i] if (($val cmp $item->[1]) == $value);
        }

        $item->[0];
    }

    sub max_by {
        $_[0]->_min_max_by($_[1], 1);
    }

    sub min_by {
        $_[0]->_min_max_by($_[1], -1);
    }

    sub swap {
        my ($self, $i, $j) = @_;
        @{$self}[$i, $j] = @{$self}[$j, $i];
        $self;
    }

    sub change_to {
        my ($self, $arg) = @_;
        @{$self} = @{$arg};
        $self;
    }

    sub first {
        my ($self, $arg) = @_;

        if (defined $arg) {

            if (ref($arg) eq 'Sidef::Types::Block::Block') {
                return $self->first_by($arg);
            }

            my $max = $#{$self};
            $arg = $arg->get_value - 1;
            return $self->new(@{$self}[0 .. ($arg > $max ? $max : $arg)]);
        }

        @{$self} ? $self->[0] : ();
    }

    sub last {
        my ($self, $arg) = @_;

        if (defined $arg) {

            if (ref($arg) eq 'Sidef::Types::Block::Block') {
                return $self->last_by($arg);
            }

            my $from = @{$self} - $arg->get_value;
            return $self->new(@{$self}[($from < 0 ? 0 : $from) .. $#{$self}]);
        }

        @{$self} ? $self->[-1] : ();
    }

    sub _flatten {    # this exists for performance reasons
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i];
            push @array, ref($item) eq ref($self) ? $item->_flatten : $item;
        }

        @array;
    }

    sub flatten {
        my ($self) = @_;

        my @new_array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i];
            push @new_array, ref($item) eq ref($self) ? ($item->_flatten) : $item;
        }

        $self->new(@new_array);
    }

    sub exists {
        my ($self, $index) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->[$index->get_value]);
    }

    *has_index = \&exists;

    sub defined {
        my ($self, $index) = @_;
        Sidef::Types::Bool::Bool->new(defined($self->[$index->get_value]));
    }

    sub items {
        my ($self, @indices) = @_;
        $self->new(map { exists($self->[$_]) ? $self->[$_] : undef } @indices);
    }

    sub item {
        my ($self, $index) = @_;
        exists($self->[$index]) ? $self->[$index] : ();
    }

    sub fetch {
        my ($self, $index, $default) = @_;
        exists($self->[$index]) ? $self->[$index] : $default;
    }

    sub dig {
        my ($self, $key, @keys) = @_;

        my $value = $self->fetch($key) // return;

        foreach my $key (@keys) {
            $value = $value->fetch($key) // return;
        }

        $value;
    }

    sub _slice {
        my ($self, $from, $to) = @_;

        my $max = @{$self};

        $from = defined($from) ? ($from->get_value) : 0;
        $to   = defined($to)   ? ($to->get_value)   : $max - 1;

        if (abs($from) > $max) {
            return;
        }

        if ($from < 0) {
            $from += $max;
        }

        if ($to < 0) {
            $to += $max;
        }

        if ($to >= $max) {
            $to = $max - 1;
        }

        @{$self}[$from .. $to];
    }

    sub slice {
        my ($self) = @_;
        my @items  = _slice(@_);
        my $array  = $self->new;
        push @{$array}, @items if @items;
        $array;
    }

    sub ft {
        my ($self) = @_;
        $self->new(_slice(@_));
    }

    *from_to = \&ft;

    sub each {
        my ($self, $code) = @_;

        foreach my $item (@{$self}) {
            if (defined(my $res = $code->_run_code($item))) {
                return $res;
            }
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub each_index {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                return $res;
            }
        }

        $self;
    }

    sub each_with_index {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i), $self->[$i]))) {
                return $res;
            }
        }

        $self;
    }

    sub map {
        my ($self, $code) = @_;
        $self->new(map { $code->run($_) } @{$self});
    }

    *collect = \&map;

    sub map_with_index {
        my ($self, $code) = @_;

        my @arr;
        foreach my $i (0 .. $#{$self}) {
            push @arr, $code->run(Sidef::Types::Number::Number->new($i), $self->[$i]);
        }

        $self->new(@arr);
    }

    *collect_with_index = \&map_with_index;

    sub flat_map {
        my ($self, $code) = @_;
        $self->new(map { @{scalar $code->run($_)} } @{$self});
    }

    sub grep {
        my ($self, $code) = @_;
        $self->new(grep { scalar $code->run($_) } @{$self});
    }

    *filter = \&grep;
    *select = \&grep;

    sub group_by {
        my ($self, $code) = @_;

        my $hash = Sidef::Types::Hash::Hash->new;
        foreach my $item (@{$self}) {
            my $key = $code->run(my $val = $item);
            exists($hash->{$key}) || $hash->append($key, Sidef::Types::Array::Array->new);
            $hash->{$key}->append($val);
        }

        $hash;
    }

    sub freq {
        my ($self) = @_;

        my %hash;
        foreach my $item (@{$self}) {
            $hash{$item}++;
        }

        foreach my $key (keys %hash) {
            $hash{$key} = Sidef::Types::Number::Number->new($hash{$key});
        }

        Sidef::Types::Hash::Hash->new(%hash);
    }

    *frequency = \&freq;

    sub first_by {
        my ($self, $code) = @_;
        foreach my $val (@{$self}) {
            return $val if $code->run($val);
        }
        return;
    }

    *find = \&first_by;

    sub last_by {
        my ($self, $code) = @_;
        for (my $i = $#{$self} ; $i >= 0 ; --$i) {
            return $self->[$i] if $code->run($self->[$i]);
        }
        return;
    }

    sub any {
        my ($self, $code) = @_;

        foreach my $val (@{$self}) {
            if ($code->run($val)) {
                return Sidef::Types::Bool::Bool->true;
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    sub all {
        my ($self, $code) = @_;

        @{$self} || return Sidef::Types::Bool::Bool->false;

        foreach my $val (@{$self}) {
            if (not $code->run($val)) {
                return Sidef::Types::Bool::Bool->false;
            }
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub assign_to {
        my ($self, @vars) = @_;

        my @values = splice(@{$self}, 0, $#vars + 1);

        for my $i (0 .. $#vars) {
            if (exists $values[$i]) {
                ${$vars[$i]} = $values[$i];
            }
        }

        $self->new(@values);
    }

    sub index {
        my ($self, $obj) = @_;

        if (@_ > 1) {

            if (ref($obj) eq 'Sidef::Types::Block::Block') {
                foreach my $i (0 .. $#{$self}) {
                    $obj->run($self->[$i])
                      && return Sidef::Types::Number::Number->new($i);
                }
                return Sidef::Types::Number::Number->new(-1);
            }

            foreach my $i (0 .. $#{$self}) {
                $self->[$i] eq $obj
                  and return Sidef::Types::Number::Number->new($i);
            }

            return Sidef::Types::Number::Number->new(-1);
        }

        Sidef::Types::Number::Number->new(@{$self} ? 0 : -1);
    }

    *first_index = \&index;

    sub rindex {
        my ($self, $obj) = @_;

        if (@_ > 1) {
            if (ref($obj) eq 'Sidef::Types::Block::Block') {
                for (my $i = $#{$self} ; $i >= 0 ; $i--) {
                    $obj->run($self->[$i])
                      && return Sidef::Types::Number::Number->new($i);
                }

                return Sidef::Types::Number::Number->new(-1);
            }

            for (my $i = $#{$self} ; $i >= 0 ; $i--) {
                $self->[$i] eq $obj
                  and return Sidef::Types::Number::Number->new($i);
            }

            return Sidef::Types::Number::Number->new(-1);

        }

        Sidef::Types::Number::Number->new($#{$self});
    }

    *last_index = \&rindex;

    sub reduce_pairs {
        my ($self, $obj) = @_;

        (my $end = $#{$self}) == -1
          && return $self->new;

        my @array;
        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            for (my $i = 1 ; $i <= $end ; $i += 2) {
                push @array, scalar $obj->run($self->[$i - 1], $self->[$i]);
            }
        }
        else {
            my $method = $obj->get_value;
            for (my $i = 1 ; $i <= $end ; $i += 2) {
                my $x = $self->[$i - 1];
                push @array, $x->$method($self->[$i]);
            }
        }

        $self->new(@array);
    }

    sub shuffle {
        my ($self) = @_;
        state $x = require List::Util;
        $self->new(List::Util::shuffle(@{$self}));
    }

    sub best_shuffle {
        my ($s) = @_;
        my ($t) = $s->shuffle;

        foreach my $i (0 .. $#{$s}) {
            foreach my $j (0 .. $#{$s}) {
                $i != $j
                  && !($t->[$i] eq $s->[$j])
                  && !($t->[$j] eq $s->[$i])
                  && do {
                    @{$t}[$i, $j] = @{$t}[$j, $i];
                    last;
                  }
            }
        }

        $t;
    }

    *bshuffle = \&best_shuffle;

    sub pair_with {
        my ($self, @args) = @_;
        Sidef::Types::Array::MultiArray->new($self, @args);
    }

    sub reduce {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            (my $end = $#{$self}) >= 0 || return;

            my $x = $self->[0];
            foreach my $i (1 .. $end) {
                $x = $obj->run($x, $self->[$i]);
            }

            return $x;
        }

        $self->reduce_operator($obj->get_value);
    }

    *inject = \&reduce;

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar @{$self});
    }

    *len  = \&length;    # alias
    *size = \&length;

    sub end {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($#{$self});
    }

    *offset = \&end;

    sub resize {
        my ($self, $num) = @_;
        $#{$self} = $num;
        $num;
    }

    *resize_to = \&resize;

    sub rand {
        my ($self, $amount) = @_;
        if (defined $amount) {
            return $self->new(map { $self->[CORE::rand(scalar @{$self})] } 1 .. $amount);
        }
        $self->[CORE::rand(scalar @{$self})];
    }

    *pick   = \&rand;
    *sample = \&rand;

    sub range {
        my ($self) = @_;
        Sidef::Types::Range::RangeNumber->__new__(from => 0, to => $#{$self}, step => 1);
    }

    sub pairs {
        my ($self) = @_;
        __PACKAGE__->new(map { Sidef::Types::Array::Pair->new(Sidef::Types::Number::Number->new($_), $self->[$_]) }
                         0 .. $#{$self});
    }

    sub insert {
        my ($self, $index, @objects) = @_;
        splice(@{$self}, $index->get_value, 0, @{__PACKAGE__->new(@objects)});
        $self;
    }

    sub unique {
        my ($self) = @_;

        my @sorted = do {
            my @arr;
            foreach my $i (0 .. $#{$self}) {
                push @arr, [$i, $self->[$i]];
            }
            CORE::sort { $a->[1] cmp $b->[1] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            $unique[$sorted[$i][0]] = $sorted[$i][1];
            ++$i while ($i < $max and $sorted[$i][1] eq $sorted[$i + 1][1]);
        }

        $self->new(grep { defined } @unique);
    }

    *uniq     = \&unique;
    *distinct = \&unique;

    sub last_unique {
        my ($self) = @_;

        my @sorted = do {
            my @arr;
            foreach my $i (0 .. $#{$self}) {
                push @arr, [$i, $self->[$i]];
            }
            CORE::sort { $a->[1] cmp $b->[1] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            ++$i while ($i < $max and $sorted[$i][1] eq $sorted[$i + 1][1]);
            $unique[$sorted[$i][0]] = $sorted[$i][1];
        }

        $self->new(grep { defined } @unique);
    }

    *last_uniq = \&last_unique;

    sub uniq_by {
        my ($self, $block) = @_;

        my @sorted = do {
            my @arr;
            my $i = -1;
            foreach my $item (@{$self}) {
                push @arr, [++$i, $item, scalar $block->run($item)];
            }
            CORE::sort { $a->[2] cmp $b->[2] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            $unique[$sorted[$i][0]] = $sorted[$i][1];
            ++$i while ($i < $max and $sorted[$i][2] eq $sorted[$i + 1][2]);
        }

        $self->new(grep { defined } @unique);
    }

    *unique_by = \&uniq_by;

    sub last_uniq_by {
        my ($self, $block) = @_;

        my @sorted = do {
            my @arr;
            my $i = -1;
            foreach my $item (@{$self}) {
                push @arr, [++$i, $item, scalar $block->run($item)];
            }
            CORE::sort { $a->[2] cmp $b->[2] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            ++$i while ($i < $max and $sorted[$i][2] eq $sorted[$i + 1][2]);
            $unique[$sorted[$i][0]] = $sorted[$i][1];
        }

        $self->new(grep { defined } @unique);
    }

    *last_unique_by = \&last_uniq_by;

    sub abbrev {
        my ($self, $code) = @_;

        my $__END__ = {};                                                                # some unique value
        my $__CALL__ = defined($code) && (ref($code) eq 'Sidef::Types::Block::Block');

        my %table;
        foreach my $sub_array (@{$self}) {
            my $ref = \%table;

            foreach my $item (@{$sub_array}) {
                $ref = $ref->{$item} //= {};
            }
            $ref->{$__END__} = $sub_array;
        }

        my $abbrevs = $__CALL__ ? undef : $self->new();
        my $callback = sub {
            $abbrevs->append($self->new(@_));
        };

        my $traverse;
        (
         $traverse = sub {
             my ($hash) = @_;

             foreach my $key (my @keys = CORE::sort keys %{$hash}) {
                 next if $key eq $__END__;
                 $traverse->($hash->{$key});

                 if ($#keys > 0) {
                     my $count = 0;
                     my $ref   = delete $hash->{$key};
                     while (my ($key) = CORE::each %{$ref}) {
                         if ($key eq $__END__) {

                             if ($__CALL__) {
                                 $code->run($self->new(@{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]));
                             }
                             else {
                                 $callback->(@{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]);
                             }

                             last;
                         }
                         $ref = $ref->{$key};
                         $count++;
                     }
                 }
             }
         }
        )->(\%table);

        $abbrevs;
    }

    *abbreviations = \&abbrev;

    sub contains {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            foreach my $item (@{$self}) {
                if ($obj->run($item)) {
                    return Sidef::Types::Bool::Bool->true;
                }
            }

            return Sidef::Types::Bool::Bool->false;
        }

        foreach my $item (@{$self}) {
            if ($item eq $obj) {
                return Sidef::Types::Bool::Bool->true;
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub contains_type {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        foreach my $item (@{$self}) {
            if (ref($item) eq $ref || eval { $item->SUPER::isa($ref) }) {
                return Sidef::Types::Bool::Bool->true;
            }
        }

        return Sidef::Types::Bool::Bool->false;
    }

    sub contains_any {
        my ($self, $array) = @_;

        foreach my $item (@{$array}) {
            return Sidef::Types::Bool::Bool->true if $self->contains($item);
        }

        Sidef::Types::Bool::Bool->false;
    }

    sub contains_all {
        my ($self, $array) = @_;

        foreach my $item (@{$array}) {
            return Sidef::Types::Bool::Bool->false unless $self->contains($item);
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub shift {
        my ($self, $num) = @_;

        if (defined $num) {
            return $self->new(CORE::splice(@{$self}, 0, $num->get_value));
        }

        @{$self} || return;
        shift(@{$self});
    }

    *drop_first = \&shift;
    *drop_left  = \&shift;

    sub pop {
        my ($self, $num) = @_;

        if (defined $num) {
            $num = $num->get_value > $#{$self} ? 0 : @{$self} - $num->get_value;
            return $self->new(CORE::splice(@{$self}, $num));
        }

        @{$self} || return;
        pop(@{$self});
    }

    *drop_last  = \&pop;
    *drop_right = \&pop;

    sub pop_rand {
        my ($self) = @_;
        $#{$self} > -1 || return;
        CORE::splice(@{$self}, CORE::rand(scalar @{$self}), 1);
    }

    sub delete_index {
        my ($self, $offset) = @_;
        CORE::splice(@{$self}, $offset->get_value, 1);
    }

    *pop_at    = \&delete_index;
    *delete_at = \&delete_index;

    sub splice {
        my ($self, $offset, $length, @objects) = @_;

        $offset = defined($offset) ? $offset->get_value : 0;
        $length = defined($length) ? $length->get_value : scalar(@{$self});

        if (@objects) {
            return $self->new(CORE::splice(@{$self}, $offset, $length, @{__PACKAGE__->new(@objects)}));
        }

        $self->new(CORE::splice(@{$self}, $offset, $length));
    }

    sub take_right {
        my ($self, $amount) = @_;

        my $offset = $#{$self};
        $amount = $offset > ($amount->get_value - 1) ? $amount->get_value - 1 : $offset;
        $self->new(@{$self}[$offset - $amount .. $offset]);
    }

    sub take_left {
        my ($self, $amount) = @_;

        $amount = $#{$self} > ($amount->get_value - 1) ? $amount->get_value - 1 : $#{$self};
        $self->new(@{$self}[0 .. $amount]);
    }

    sub sort {
        my ($self, $code) = @_;

        if (defined $code) {
            return $self->new(CORE::sort { scalar $code->run($a, $b) } @{$self});
        }

        $self->new(CORE::sort { $a cmp $b } @{$self});
    }

    sub sort_by {
        my ($self, $code) = @_;
        $self->new(map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [$_, scalar $code->run($_)] } @{$self});
    }

    sub cmp {
        my ($self, $arg) = @_;

        state $mone = Sidef::Types::Number::Number->new(-1);
        state $zero = Sidef::Types::Number::Number->new(0);
        state $one  = Sidef::Types::Number::Number->new(1);

        my $l1 = $#{$self};
        my $l2 = $#{$arg};

        my $min = $l1 < $l2 ? $l1 : $l2;

        foreach my $i (0 .. $min) {

            my $obj1 = $self->[$i];
            my $obj2 = $arg->[$i];

            my $value = $obj1 cmp $obj2;
            $value == 0 or return ($value == -1 ? $mone : $one);
        }

        $l1 == $l2 ? $zero : $l1 < $l2 ? $mone : $one;
    }

    # Insert an object between each element
    sub join_insert {
        my ($self, $delim_obj) = @_;

        @{$self} || return $self->new;

        my @array = $self->[0];
        foreach my $i (1 .. $#{$self}) {
            push @array, $delim_obj, $self->[$i];
        }
        $self->new(@array);
    }

    sub permute {
        my ($self, $code) = @_;

        @{$self} || return $self;
        my @idx = 0 .. $#{$self};

        if (defined($code)) {
            while (1) {
                if (defined(my $res = $code->_run_code($self->new(@{$self}[@idx])))) {
                    return $res;
                }

                my $p = $#idx;
                --$p while $idx[$p - 1] > $idx[$p];
                my $q = $p or (return $self);
                push @idx, CORE::reverse CORE::splice @idx, $p;
                ++$q while $idx[$p - 1] > $idx[$q];
                @idx[$p - 1, $q] = @idx[$q, $p - 1];
            }

            return;
        }

        my @array;
        while (1) {
            push @array, $self->new(@{$self}[@idx]);
            my $p = $#idx;
            --$p while $idx[$p - 1] > $idx[$p];
            my $q = $p or (return $self->new(@array));
            push @idx, CORE::reverse CORE::splice @idx, $p;
            ++$q while $idx[$p - 1] > $idx[$q];
            @idx[$p - 1, $q] = @idx[$q, $p - 1];
        }
    }

    *permutations = \&permute;

    sub pack {
        my ($self, $format) = @_;
        Sidef::Types::String::String->new(CORE::pack($format->get_value, @{$self}));
    }

    sub push {
        my ($self, @args) = @_;
        push @{$self}, @{$self->new(@args)};
        $self;
    }

    *append = \&push;

    sub unshift {
        my ($self, @args) = @_;
        CORE::unshift(@{$self}, @{$self->new(@args)});
        $self;
    }

    *prepend = \&unshift;

    sub rotate {
        my ($self, $num) = @_;

        $num = $num->get_value % ($#{$self} + 1);
        return $self->new(@{$self}) if $num == 0;

        # Surprisingly, this is slower:
        # $self->new(@{$self}[$num .. $#{$self}], @{$self}[0 .. $num - 1]);

        # Surprisingly, this is 73% faster:
        my @array = @{$self};
        CORE::unshift(@array, CORE::splice(@array, $num));
        $self->new(@array);
    }

    # Join the array as string
    sub join {
        my ($self, $delim, $block) = @_;
        $delim = defined($delim) ? $delim->get_value : '';

        if (defined $block) {
            return Sidef::Types::String::String->new(CORE::join($delim, map { scalar $block->run($_) } @{$self}));
        }

        Sidef::Types::String::String->new(CORE::join($delim, @{$self}));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(CORE::reverse @{$self});
    }

    *reversed = \&reverse;    # alias

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(@{$self});
    }

    *to_h = \&to_hash;

    sub copy {
        my ($self) = @_;

        state $x = require Storable;
        Storable::dclone($self);
    }

    sub delete_first {
        my ($self, $obj) = @_;

        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i];
            if ($item eq $obj) {
                CORE::splice(@{$self}, $i, 1);
                return Sidef::Types::Bool::Bool->true;
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    *remove_first = \&delete_first;

    sub delete_last {
        my ($self, $obj) = @_;

        for (my $i = $#{$self} ; $i >= 0 ; $i--) {
            my $item = $self->[$i];
            if ($item eq $obj) {
                CORE::splice(@{$self}, $i, 1);
                return Sidef::Types::Bool::Bool->true;
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    *remove_last = \&delete_last;

    sub delete {
        my ($self, $obj) = @_;

        for (my $i = 0 ; $i <= $#{$self} ; $i++) {
            my $item = $self->[$i];
            if ($item eq $obj) {
                CORE::splice(@{$self}, $i--, 1);
            }
        }

        $self;
    }

    *remove = \&delete;

    sub delete_if {
        my ($self, $code) = @_;

        for (my $i = 0 ; $i <= $#{$self} ; $i++) {
            $code->run($self->[$i])
              && CORE::splice(@{$self}, $i--, 1);
        }

        $self;
    }

    *remove_if = \&delete_if;

    sub delete_first_if {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i];
            $code->run($item) && do {
                CORE::splice(@{$self}, $i, 1);
                return Sidef::Types::Bool::Bool->true;
            };
        }

        Sidef::Types::Bool::Bool->false;
    }

    *remove_first_if = \&delete_first_if;

    sub delete_last_if {
        my ($self, $code) = @_;

        for (my $i = $#{$self} ; $i >= 0 ; --$i) {
            my $item = $self->[$i];
            $code->run($item) && do {
                CORE::splice(@{$self}, $i, 1);
                return Sidef::Types::Bool::Bool->true;
              }
        }

        Sidef::Types::Bool::Bool->false;
    }

    *remove_last_if = \&delete_last_if;

    sub to_list {
        @{$_[0]};
    }

    sub dump {
        my ($self) = @_;

        Sidef::Types::String::String->new(
            '[' . CORE::join(
                ', ',
                map {
                    my $item = defined($self->[$_]) ? $self->[$_] : 'nil';
                    ref($item) && defined(eval { $item->can('dump') }) ? $item->dump() : $item;
                  } 0 .. $#{$self}
              )
              . ']'
        );
    }

    sub to_s {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::join(' ', @{$self}));
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '*'}   = \&multiply;
        *{__PACKAGE__ . '::' . '<<'}  = \&append;
        *{__PACKAGE__ . '::' . '«'}  = \&append;
        *{__PACKAGE__ . '::' . '>>'}  = \&assign_to;
        *{__PACKAGE__ . '::' . '»'}  = \&assign_to;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '/'}   = \&divide;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $obj) = @_;
            CORE::push(@{$self}, $obj);
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            CORE::pop(@{$self});
            $self;
        };
    }

};

1
