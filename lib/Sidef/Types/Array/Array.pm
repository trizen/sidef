package Sidef::Types::Array::Array {

    use utf8;
    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, @items) = @_;
        bless [map { Sidef::Variable::Variable->new(name => '', type => 'var', value => $_) } @items], __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;

            if (ref $item and defined eval { $item->can('get_value') }) {
                push @array, $item->get_value;
            }
            else {
                push @array, $item;
            }
        }

        \@array;
    }

    sub _grep {
        my ($self, $array, $bool) = @_;

        $self->_is_array($array) || return;

        my $new_array = $self->new();
        foreach my $item (@{$self}) {

            my $exists = 0;
            my $value  = $item->get_value;

            if ($array->contains($value)) {
                $exists = 1;
            }

            $new_array->push($value) if ($exists - $bool);
        }

        $new_array;
    }

    sub multiply {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new((map { $_->get_value } @{$self}) x $$num);
    }

    sub divide {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;

        my @obj = map { $_->get_value } @{$self};

        my $array = $self->new;
        my $len   = @obj / $$num;

        my $i   = 1;
        my $pos = $len;
        while (@obj) {
            my $j = $pos - $i * int($len);
            $pos -= $j if $j >= 1;
            $array->push($self->new(splice @obj, 0, $len + $j));
            $pos += $len;
            $i++;
        }

        $array;
    }

    *div = \&divide;

    sub or {
        my ($self, $array) = @_;
        my $new_array = $self->new;
        $self->_is_array($array) || return;
        $self->xor($array)->concat($self->and($array));
    }

    sub xor {
        my ($self, $array) = @_;
        my $new_array = $self->new;
        $self->_is_array($array) || return;
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

    *isEmpty = \&is_empty;

    sub subtract {
        my ($self, $array) = @_;
        $self->_grep($array, 1);
    }

    sub concat {
        my ($self, $array) = @_;
        $self->_is_array($array) || return;
        $self->new(map { $_->get_value } @{$self}, @{$array});
    }

    sub count {
        my ($self, $obj) = @_;

        my $counter = 0;
        my $method  = '==';
        foreach my $item (@{$self}) {
            my $value = $item->get_value;
            if (ref($value) eq ref($obj) && eval { $value->can($method) }) {
                $value->$method($obj) && $counter++;
            }
        }

        Sidef::Types::Number::Number->new($counter);
    }

    *countObj  = \&count;
    *count_obj = \&count;

    sub to_list {
        my ($self) = @_;
        [map { $_->get_value } @{$self}];
    }

    *toList  = \&to_list;
    *asList  = \&to_list;
    *as_list = \&to_list;

    sub equals {
        my ($self, $array) = @_;

        $self->_is_array($array) || return;

        if ($#{$self} != $#{$array}) {
            return Sidef::Types::Bool::Bool->false;
        }

        foreach my $i (0 .. $#{$self}) {

            my ($x, $y) = ($self->[$i]->get_value, $array->[$i]->get_value);

            if (ref($x) eq ref($y)) {
                my $method = '==';

                if (defined $x->can($method)) {
                    if (not $x->$method($y)) {
                        return Sidef::Types::Bool::Bool->false;
                    }
                }

            }
            else {
                return Sidef::Types::Bool::Bool->false;
            }
        }

        return Sidef::Types::Bool::Bool->true;
    }

    *is = \&equals;
    *eq = \&equals;

    sub mesh {
        my ($self, $array) = @_;

        $self->_is_array($array) || return;

        my $min = $#{$self} > $#{$array} ? $#{$array} : $#{$self};

        my $new_array = $self->new();
        foreach my $i (0 .. $min) {
            $new_array->push($self->[$i]->get_value, $array->[$i]->get_value);
        }

        if ($#{$self} > $#{$array}) {
            foreach my $i ($min + 1 .. $#{$self}) {
                $new_array->push($self->[$i]->get_value);
            }
        }
        else {
            foreach my $i ($min + 1 .. $#{$array}) {
                $new_array->push($array->[$i]->get_value);
            }
        }

        $new_array;
    }

    *zip = \&mesh;

    sub make {
        my ($self, $size, $type) = @_;
        $self->_is_number($size) || return;
        $self->new(($type) x $$size);
    }

    sub _min_max {
        my ($self, $method) = @_;

        $#{$self} > -1 or return;

        my $max_item = $self->[0]->get_value;

        foreach my $i (1 .. $#{$self}) {
            my $val = $self->[$i]->get_value;

            if (defined $val->can($method)) {
                $max_item = $val if $val->$method($max_item);
            }
            else {
                warn sprintf("[WARN] %s():Can't find the method '$method' for object '%s'!\n",
                             $method eq '>' ? 'max' : 'min', ref($val));
            }
        }

        return $max_item;
    }

    sub max {
        $_[0]->_min_max('>');
    }

    sub min {
        $_[0]->_min_max('<');
    }

    sub sum {
        $_[0]->reduce(Sidef::Types::String::String->new('+'));
    }

    *combine = \&sum;

    sub prod {
        $_[0]->reduce(Sidef::Types::String::String->new('*'));
    }

    *product = \&prod;

    sub max_by {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        my $max;
        my $min = Sidef::Types::Number::Number->inf->neg;
        my ($var_ref) = $code->init_block_vars();

        foreach my $item (@{$self}) {
            $var_ref->set_value($item->get_value);
            my $result = $code->run;

            if ($result->gt($min)) {
                $max = $item->get_value;
                $min = $result;
            }
        }

        return $max;
    }

    *maxBy = \&max_by;

    sub min_by {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        my $min;
        my $max = Sidef::Types::Number::Number->inf;
        my ($var_ref) = $code->init_block_vars();

        foreach my $item (@{$self}) {
            $var_ref->set_value($item->get_value);
            my $result = $code->run;

            if ($result->lt($max)) {
                $min = $item->get_value;
                $max = $result;
            }
        }

        return $min;
    }

    *minBy = \&min_by;

    sub last {
        my ($self, $arg) = @_;
        $#{$self} >= 0 || return;

        if (defined $arg) {
            $self->_is_number($arg) || return;
            my $from = @{$self} - $$arg;
            return $self->new(map { $_->get_value } @{$self}[($from < 0 ? 0 : $from) .. $#{$self}]);
        }

        $self->[-1];
    }

    sub swap {
        my ($self, $i, $j) = @_;

        $self->_is_number($i) || return;
        $self->_is_number($j) || return;

        @{$self}[$i, $j] = @{$self}[$j, $i];
        $self;
    }

    sub first {
        my ($self, $arg) = @_;

        if (defined $arg) {
            if (ref($arg) eq 'Sidef::Types::Block::Code') {
                return return $self->find($arg);
            }

            $self->_is_number($arg) || return;
            return $self->new(map { $_->get_value } @{$self}[0 .. $$arg - 1]);
        }

        $self->[0];
    }

    sub _flatten {    # this exists for performance reasons
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;
            push @array, ref($item) eq ref($self) ? $item->_flatten : $item;
        }

        @array;
    }

    sub flatten {
        my ($self) = @_;

        my $new_array = $self->new;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;
            $new_array->push(ref($item) eq ref($self) ? ($item->_flatten) : $item);
        }

        $new_array;
    }

    sub exists {
        my ($self, $index) = @_;
        $self->_is_number($index, 1) || return;
        Sidef::Types::Bool::Bool->new(exists $self->[$$index]);
    }

    *existsIndex = \&exists;

    sub defined {
        my ($self, $index) = @_;
        $self->_is_number($index, 1) || return;
        Sidef::Types::Bool::Bool->new(defined($self->[$$index]) and $self->[$$index]->is_defined);
    }

    sub get {
        my ($self, $index) = @_;
        $self->_is_number($index, 1) || return;
        $self->[$$index];
    }

    *item = \&get;

    sub call {
        my ($self, @idx) = @_;
        return if @idx == 0;

        my $array = $self->new;
        foreach my $index (@idx) {
            if (ref($index) eq __PACKAGE__) {
                $array->append(
                               @{$self}[
                                 map  { $_->get_value }
                                 grep { $self->_is_number($_) }
                                 map  { $_->get_value } @{$index}
                               ]
                              );
            }
            else {
                $self->_is_number($index) || return;
                $index = $index->get_value;
                $index = @{$self} + $index if $index < 0;
                $array->append(
                                 $index < 0 || !exists($self->[$index])
                               ? @idx == 1
                                     ? return ()
                                     : undef
                               : @idx == 1 ? return ($self->[$index]->get_value)
                               :             $self->[$index]->get_value
                              );
            }
        }
        $array;
    }

    sub _slice {
        my ($self, $from, $to) = @_;

        my $max = $#{$self};

        $from = defined($from) ? $self->_is_number($from) ? ($$from) : (return) : 0;
        $to   = defined($to)   ? $self->_is_number($to)   ? ($$to)   : (return) : $max;

        if ($from < 0) {
            $from = $max + $from + 1;
        }

        if ($to < 0) {
            $to = $max + $to + 1;
        }

        if (abs($from) > $max) {
            return;
        }

        if ($to > $max) {
            $to = $max;
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
        $self->new(map { $_->get_value } _slice(@_));
    }

    *fromTo  = \&ft;
    *from_to = \&ft;

    sub each {
        my ($self, $code) = @_;

        $code // return ($self->pairs);
        $self->_is_code($code) || return;

        my (@vars) = $code->init_block_vars();
        my $multi_vars = $#vars > 0;

        foreach my $item (@{$self}) {
            if ($multi_vars) {
                foreach my $i (0 .. $#vars) {
                    $vars[$i]->set_value($item->get_value->[$i]->get_value);
                }
            }
            else {
                $vars[0]->set_value($item->get_value);
            }

            if (defined(my $res = $code->_run_code)) {
                $code->pop_stack();
                return $res;
            }
        }

        $code->pop_stack();
        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub map {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        $self->new(
            map {
                $var_ref->set_value($_->get_value);
                $code->run;
              } @{$self}
        );
    }

    *collect = \&map;

    sub grep {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        $self->new(
            grep {
                $var_ref->set_value($_);
                $code->run;
              } map { $_->get_value } @{$self}
        );
    }

    *filter = \&grep;
    *select = \&grep;

    sub group_by {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        my $hash = Sidef::Types::Hash::Hash->new;
        foreach my $item (@{$self}) {
            $var_ref->set_value(my $val = $item->get_value);
            my $key = $code->run;
            exists($hash->{data}{$key}) || $hash->append($key, Sidef::Types::Array::Array->new);
            $hash->{data}{$key}->get_value->append($val);
        }

        $hash;
    }

    *groupBy = \&group_by;

    sub find {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        foreach my $var (@{$self}) {
            my $val = $var->get_value;
            $var_ref->set_value($val);
            return $val if ($code->run);
        }

        return;
    }

    sub all {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        $#{$self} == -1
          && return Sidef::Types::Bool::Bool->false;

        my ($var_ref) = $code->init_block_vars();

        foreach my $var (@{$self}) {
            $var_ref->set_value($var->get_value);
            if (not $code->run) {
                return Sidef::Types::Bool::Bool->false;
            }
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub assign_to {
        my ($self, @vars) = @_;

        for my $i (0 .. $#vars) {
            $self->_is_var_ref($vars[$i]) || return;
            if (exists $self->[$i]
                and ref($self->[$i]) eq 'Sidef::Variable::Variable') {
                $vars[$i]->get_var->set_value($self->[$i]->get_value);
            }
        }

        $self;
    }

    *unroll_to = \&assign_to;
    *unrollTo  = \&assign_to;
    *assignTo  = \&assign_to;

    sub first_index {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        foreach my $i (0 .. $#{$self}) {
            $var_ref->set_value($self->[$i]->get_value);
            $code->run
              && return Sidef::Types::Number::Number->new($i);
        }

        Sidef::Types::Number::Number->new(-1);
    }

    *indexWhere = \&first_index;
    *firstIndex = \&first_index;

    sub last_index {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        my $offset = $#{$self};
        for (my $i = $offset ; $i >= 0 ; $i--) {
            $var_ref->set_value($self->[$i]->get_value);
            $code->run
              && return Sidef::Types::Number::Number->new($i);
        }

        Sidef::Types::Number::Number->new(-1);
    }

    *lastIndexWhere = \&last_index;
    *lastIndex      = \&last_index;

    sub reducePairs {
        my ($self, $obj) = @_;

        my $array = $self->new();
        (my $offset = $#{$self}) == -1 && return $array;

        if ($self->_is_string($obj, 1, 1)) {
            my $method = $$obj;
            for (my $i = 1 ; $i <= $offset ; $i += 2) {
                my $x = $self->[$i - 1]->get_value;

                if ($x->can($method)) {
                    $array->push($x->$method($self->[$i]->get_value));
                }
                else {
                    warn "[WARN] Array.reducePairs: can't find method '$method' for object '", ref($x), "'!\n";
                }
            }

        }
        elsif ($self->_is_code($obj)) {
            for (my $i = 1 ; $i <= $offset ; $i += 2) {
                $array->push($obj->call($self->[$i - 1]->get_value, $self->[$i]->get_value));
            }
        }

        $array;
    }

    *reduce_pairs = \&reducePairs;

    sub shuffle {
        my ($self) = @_;
        require List::Util;
        $self->new(map { $_->get_value } List::Util::shuffle(@{$self}));
    }

    sub pair_with {
        my ($self, @args) = @_;
        Sidef::Types::Array::MultiArray->new($self, @args);
    }

    *pairWith = \&pair_with;

    sub reduce {
        my ($self, $obj) = @_;

        (my $offset = $#{$self}) >= 0 || return;
        my $x = $self->[0]->get_value;

        if ($self->_is_string($obj, 1, 1)) {
            my $method = $$obj;
            foreach my $i (1 .. $offset) {
                if ($x->can($method)) {
                    $x = ($x->$method($self->[$i]->get_value));
                }
                else {
                    warn "[WARN] Array.reduce: can't find method '$method' for object '", ref($x), "'!\n";
                }
            }
        }
        elsif ($self->_is_code($obj)) {
            foreach my $i (1 .. $offset) {
                $x = $obj->call($x, $self->[$i]->get_value);
            }
        }

        $x;
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar @{$self});
    }

    *len  = \&length;    # alias
    *size = \&length;

    sub offset {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($#{$self});
    }

    sub resize {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $#{$self} = $$num;
        $num;
    }

    *resizeTo  = \&resize;
    *resize_to = \&resize;

    sub rand {
        my ($self) = @_;
        $self->[CORE::rand($#{$self} + 1)];
    }

    sub range {
        my ($self) = @_;
        __PACKAGE__->new(map { Sidef::Types::Number::Number->new($_) } 0 .. $#{$self});
    }

    sub pairs {
        my ($self) = @_;
        __PACKAGE__->new(map { __PACKAGE__->new(Sidef::Types::Number::Number->new($_), $self->[$_]->get_value) }
                         0 .. $#{$self});
    }

    sub insert {
        my ($self, $index, @objects) = @_;
        $self->_is_number($index) || return;
        splice(@{$self}, $$index, 0, @{__PACKAGE__->new(@objects)});
        $self;
    }

    sub _unique {
        my ($self, $last) = @_;

        my %indices;
        my $method = '==';
        my $max    = $#{$self};

        for (my $i = 0 ; $i <= ($max - 1) ; $i++) {
            for (my $j = $i + 1 ; $j <= $max ; $j++) {
                my $diff = ($#{$self} - $max);
                my ($x, $y) = ($self->[$i + $diff]->get_value, $self->[$j + $diff]->get_value);

                if (    ref($x) eq ref($y)
                    and $x->can($method)
                    and $x->$method($y)) {

                    undef $indices{$last ? ($i + $diff) : ($j + $diff)};

                    --$max;
                    --$j;
                    --$i;
                }
            }
        }

        $self->new(map  { $self->[$_]->get_value }
                   grep { not exists $indices{$_} } 0 .. $#{$self});
    }

    sub unique {
        my ($self) = @_;
        $self->_unique(0);
    }

    *uniq     = \&unique;
    *distinct = \&unique;

    sub last_unique {
        my ($self) = @_;
        $self->_unique(1);
    }

    *last_uniq  = \&last_unique;
    *lastUniq   = \&last_unique;
    *lastUnique = \&last_unique;

    sub abbrev {
        my ($self, $code) = @_;

        my $__END__ = {};                                                             # some unique value
        my $__CALL__ = defined($code) && ref($code) eq 'Sidef::Types::Block::Code';

        my %table;
        foreach my $sub_array (map { $_->get_value } @{$self}) {
            my $ref = \%table;
            $self->_is_array($sub_array) || return;
            foreach my $item (@{$sub_array}) {
                $ref = $ref->{$item->get_value} //= {};
            }
            $ref->{$__END__} = $sub_array;
        }

        my $abbrevs = $__CALL__ ? undef : $self->new();
        my $callback = sub {
            $abbrevs->append($self->new(map { $_->get_value } @_));
        };

        my $traverse;
        (
         $traverse = sub {
             my ($hash) = @_;

             foreach my $key (my @keys = sort keys %{$hash}) {
                 $traverse->($hash->{$key}) if $key ne $__END__;

                 if ($#keys > 0) {
                     my $count = 0;
                     my $ref = my $val = delete $hash->{$key};
                     while (my ($key) = CORE::each %{$ref}) {
                        $key eq $__END__
                           ? (
                                $__CALL__
                              ? $code->call($self->new(map { $_->get_value } @{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]))
                              : $callback->(@{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]),
                              last
                             )
                           : ($ref = $val = $ref->{$key});
                         ++$count;
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

        if (ref($obj) eq 'Sidef::Types::Block::Code') {
            my ($var_ref) = $obj->init_block_vars();

            foreach my $var (@{$self}) {
                $var_ref->set_value($var->get_value);

                if ($obj->run) {
                    return Sidef::Types::Bool::Bool->true;
                }
            }

            return Sidef::Types::Bool::Bool->false;
        }

        state $method = '==';
        foreach my $var (@{$self}) {
            my $item = $var->get_value;
            if (    ref($item) eq ref($obj)
                and defined $item->can($method)
                and $item->$method($obj)) {
                return Sidef::Types::Bool::Bool->true;
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    sub contains_type {
        my ($self, $obj) = @_;

        foreach my $item (@{$self}) {
            if (ref($item->get_value) eq ref($obj)) {
                return Sidef::Types::Bool::Bool->true;
            }
        }

        return Sidef::Types::Bool::Bool->false;
    }

    *containsType = \&contains_type;

    sub contains_any {
        my ($self, $array) = @_;

        $self->_is_array($array) || return;

        foreach my $item (@{$array}) {
            return Sidef::Types::Bool::Bool->true if $self->contains($item->get_value);
        }

        Sidef::Types::Bool::Bool->false;
    }

    *containsAny = \&contains_any;

    sub contains_all {
        my ($self, $array) = @_;

        foreach my $item (@{$array}) {
            return Sidef::Types::Bool::Bool->false unless $self->contains($item->get_value);
        }

        Sidef::Types::Bool::Bool->true;
    }

    *containsAll = \&contains_all;

    sub pop {
        my ($self, $index) = @_;

        if (defined $index) {
            if ($self->_is_number($index, 1, 1)) {
                $$index <= $#{$self} or do {
                    warn "[WARN] Array.pop: index '$$index' is bigger than array's offset '$#{$self}'!\n";
                    return;
                };
            }
            else {
                warn sprintf("[WARN] Array.pop: expected a position number object, not '%s'!\n", ref($index));
                return;
            }

            return CORE::splice(@{$self}, $$index, 1);
        }

        $#{$self} > -1 || return;
        pop @{$self};
    }

    *delete_index = \&pop;
    *deleteIndex  = \&pop;
    *pop_index    = \&pop;
    *popIndex     = \&pop;

    sub pop_rand {
        my ($self) = @_;
        CORE::splice @{$self}, CORE::rand($#{$self} + 1), 1;
    }

    *popRand = \&pop_rand;

    sub splice {
        my ($self, $offset, $length, @objects) = @_;

        $offset = defined($offset) && $self->_is_number($offset) ? $$offset : 0;
        $length = defined($length)
          && $self->_is_number($length) ? $$length : scalar(@{$self});

        if (@objects) {
            return $self->new(map { $_->get_value } CORE::splice(@{$self}, $offset, $length, @{__PACKAGE__->new(@objects)}));
        }
        else {
            return $self->new(map { $_->get_value } CORE::splice(@{$self}, $offset, $length));
        }
    }

    sub takeRight {
        my ($self, $amount) = @_;
        $self->_is_number($amount) || return;

        my $offset = $#{$self};
        $offset >= ($$amount - 1)
          || do {
            warn "[WARN] Array.takeRight: too many elements specified ($$amount)! Array's offset is: $offset\n";
            $$amount = $offset + 1;
          };

        $self->new(map { $_->get_value } @{$self}[$offset - $$amount + 1 .. $offset]);
    }

    *take_right = \&takeRight;

    sub dropRight {
        my ($self, $amount) = @_;
        $self->_is_number($amount) || return;

        my $offset = $#{$self};
        $offset >= ($$amount - 1)
          || do {
            warn "[WARN] Array.dropRight: too many elements specified! ($$amount)! Array's offset is: $offset\n";
            $$amount = $offset + 1;
          };

        $self->new(map { $_->get_value } CORE::splice(@{$self}, -$$amount));
    }

    *drop_right = \&dropRight;

    sub takeLeft {
        my ($self, $amount) = @_;
        $self->_is_number($amount) || return;

        my $offset = $#{$self};
        $offset >= ($$amount - 1)
          || do {
            warn "[WARN] Array.takeLeft: too many elements specified ($$amount)! Array's offset is: $offset\n";
            $$amount = $offset + 1;
          };

        $self->new(map { $_->get_value } @{$self}[0 .. $$amount - 1]);
    }

    *take_left = \&takeLeft;

    sub dropLeft {
        my ($self, $amount) = @_;
        $self->_is_number($amount) || return;

        my $offset = $#{$self};
        $offset >= ($$amount - 1)
          || do {
            warn "[WARN] Array.dropLeft: too many elements specified! ($$amount)! Array's offset is: $offset\n";
            $$amount = $offset + 1;
          };

        $self->new(map { $_->get_value } CORE::splice(@{$self}, 0, $$amount));
    }

    *drop_left = \&dropLeft;

    sub shift {
        my ($self) = @_;
        shift @{$self};
    }

    *dropFirst  = \&shift;
    *drop_first = \&shift;

    sub dropLast {
        my ($self) = @_;
        CORE::pop @{$self};
    }

    *drop_last = \&dropLast;

    sub sort {
        my ($self, $code) = @_;

        if (defined $code) {
            $self->_is_code($code) || return;
            return
              $self->new(sort { $code->call($a, $b) }
                         map { $_->get_value } @{$self});
        }

        my $method = '<=>';
        $self->new(sort { $a->can($method) ? ($a->$method($b)) : -1 }
                   map { $_->get_value } @{$self});
    }

    sub permute {
        my ($self, $code) = @_;

        $#{$self} == -1 && return $self;
        my @idx = 0 .. $#{$self};

        if (defined($code)) {
            $self->_is_code($code) || return;
            my ($var_ref) = $code->init_block_vars();

            while (1) {
                $var_ref->set_value($self->new(map { $_->get_value } @{$self}[@idx]));
                if (defined(my $res = $code->_run_code)) {
                    $code->pop_stack();
                    return $res;
                }

                my $p = $#idx;
                --$p while $idx[$p - 1] > $idx[$p];
                my $q = $p or (return $self);
                push @idx, CORE::reverse CORE::splice @idx, $p;
                ++$q while $idx[$p - 1] > $idx[$q];
                @idx[$p - 1, $q] = @idx[$q, $p - 1];
            }

            $code->pop_stack();
        }

        my $array = $self->new;

        while (1) {
            $array->push($self->new(map { $_->get_value } @{$self}[@idx]));
            my $p = $#idx;
            --$p while $idx[$p - 1] > $idx[$p];
            my $q = $p or (return $array);
            push @idx, CORE::reverse CORE::splice @idx, $p;
            ++$q while $idx[$p - 1] > $idx[$q];
            @idx[$p - 1, $q] = @idx[$q, $p - 1];
        }
    }

    sub pack {
        my ($self, $format) = @_;
        $self->_is_string($format) || return;
        Sidef::Types::String::String->new(CORE::pack($$format, map { $_->get_value } @{$self}));
    }

    sub push {
        my ($self, @args) = @_;
        push @{$self}, @{$self->new(@args)};
        $self;
    }

    *append = \&push;

    sub unshift {
        my ($self, @args) = @_;
        unshift @{$self}, @{$self->new(@args)};
        $self;
    }

    sub rotate {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;

        my $array = $self->new(map { $_->get_value } @{$self});
        if ($$num < 0) {
            CORE::unshift(@{$array}, CORE::pop(@{$array})) for 1 .. abs($$num);
        }
        else {
            CORE::push(@{$array}, CORE::shift(@{$array})) for 1 .. $$num;
        }

        $array;
    }

    # Join the array as string
    sub join {
        my ($self, $delim, $block) = @_;
        $delim = ref($delim) && $self->_is_string($delim) ? $$delim : '';

        if (defined $block) {
            $self->_is_code($block) || return;
            my ($var_ref) = $block->init_block_vars();
            return Sidef::Types::String::String->new(
                CORE::join(
                    $delim,
                    map {
                        $var_ref->set_value($_->get_value);
                        $block->run;
                      } @{$self}
                )
            );
        }

        Sidef::Types::String::String->new(CORE::join($delim, map { $_->get_value } @{$self}));
    }

    # Insert an object between every element
    sub join_insert {
        my ($self, $delim_obj) = @_;

        $#{$self} > -1 || return $self->new();

        my $array = $self->new($self->[0]->get_value);

        foreach my $i (1 .. $#{$self}) {
            $array->push($delim_obj, $self->[$i]->get_value);
        }

        $array;
    }

    *joinInsert = \&join_insert;

    sub reverse {
        my ($self) = @_;
        $self->new(reverse map { $_->get_value } @{$self});
    }

    *reversed = \&reverse;    # alias

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(map { $_->get_value } @{$self});
    }

    *toHash = \&to_hash;
    *to_h   = \&to_hash;

    sub copy {
        my ($self) = @_;
        my $new = $self->new;
        foreach my $item (map { $_->get_value } @{$self}) {
            $new->append(eval { $item->can('copy') } ? $item->copy : $item);
        }
        $new;
    }

    sub delete_first {
        my ($self, $obj) = @_;

        my $method = '==';
        while (my ($i, $var) = CORE::each @{$self}) {
            my $item = $var->get_value;
            if (    ref($item) eq ref($obj)
                and defined $item->can($method)
                and $item->$method($obj)) {
                CORE::splice(@{$self}, $i, 1);
                return Sidef::Types::Bool::Bool->true;
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

    *remove_first = \&delete_first;
    *removeFirst  = \&delete_first;
    *deleteFirst  = \&delete_first;

    sub delete {
        my ($self, $obj) = @_;

        my $method = '==';
        for (my $i = 0 ; $i <= $#{$self} ; $i++) {
            my $item = $self->[$i]->get_value;
            if (    ref($item) eq ref($obj)
                and defined $item->can($method)
                and $item->$method($obj)) {
                CORE::splice(@{$self}, $i--, 1);
            }
        }

        $self;
    }

    *remove = \&delete;

    sub delete_if {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        for (my $i = 0 ; $i <= $#{$self} ; $i++) {
            $var_ref->set_value($self->[$i]->get_value);
            $code->run && CORE::splice(@{$self}, $i--, 1);
        }

        $self;
    }

    *remove_if = \&delete_if;
    *removeIf  = \&delete_if;
    *deleteIf  = \&delete_if;

    sub delete_first_if {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        while (my ($i, $item) = CORE::each @{$self}) {
            $var_ref->set_value($item->get_value);
            $code->run && do {
                CORE::splice(@{$self}, $i, 1);
                return Sidef::Types::Bool::Bool->true;
            };
        }

        Sidef::Types::Bool::Bool->false;
    }

    *remove_first_if = \&delete_first_if;
    *removeFirstIf   = \&delete_first_if;
    *deleteFirstIf   = \&delete_first_if;

    sub dump {
        my ($self) = @_;

        my $string = Sidef::Types::String::String->new("[");

        foreach my $i (0 .. $#{$self}) {
            my $item = defined($self->[$i]) ? $self->[$i]->get_value : 'nil';

            if (ref $item and defined eval { $item->can('dump') }) {
                $$string .= $item->dump();
            }
            else {
                $$string .= $item;
            }
            $$string .= ", " if $i != $#{$self};
        }

        $$string .= "]";
        $string;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;
        *{__PACKAGE__ . '::' . '*'}   = \&multiply;
        *{__PACKAGE__ . '::' . '<<'}  = \&dropLeft;
        *{__PACKAGE__ . '::' . '>>'}  = \&dropRight;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '&&'}  = \&mesh;
        *{__PACKAGE__ . '::' . '=='}  = \&equals;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '/'}   = \&divide;
        *{__PACKAGE__ . '::' . '»'}  = \&assign_to;

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $obj) = @_;
            $self->push($obj);
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            $self->pop;
            $self;
        };

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $arg) = @_;

            if ($self->_is_array($arg, 1, 1)) {
                my @values = map { $_->get_value } @{$arg};

                foreach my $i (0 .. $#{$self}) {
                    $self->[$i]->set_value(
                                           exists $values[$i]
                                           ? $values[$i]
                                           : Sidef::Types::Nil::Nil->new
                                          );
                }
            }
            else {
                map { $_->set_value($arg) } @{$self};
            }

            $self;
        };

        *{__PACKAGE__ . '::' . '+='} = sub {
            my ($self, $arg) = @_;

            if ($self->_is_array($arg, 1, 1)) {
                my @values = map { $_->get_value } @{$arg};

                foreach my $i (0 .. $#{$self}) {
                    my $value = $self->[$i]->get_value;
                    ref($value) eq ref($self) || do {
                        $self->[$i]->set_value(
                                               $self->new(
                                                          ref($value) eq 'Sidef::Types::Nil::Nil'
                                                          ? ()
                                                          : $value
                                                         )
                                              );
                    };
                    $self->[$i]->get_value->append(
                                                   exists $values[$i]
                                                   ? $values[$i]
                                                   : Sidef::Types::Nil::Nil->new
                                                  );
                }
            }
            else {
                map {
                    my $value = $_->get_value;
                    ref($value) eq ref($self) || do {
                        $_->set_value(
                                      $self->new(
                                                 ref($value) eq 'Sidef::Types::Nil::Nil'
                                                 ? ()
                                                 : $value
                                                )
                                     );
                    };
                    $_->get_value->append($arg)
                } @{$self};
            }

            $self;
        };
    }

};

1
