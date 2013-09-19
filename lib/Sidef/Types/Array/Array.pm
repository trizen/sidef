package Sidef::Types::Array::Array {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, @items) = @_;
        bless [map { Sidef::Variable::Variable->new(rand, 'var', $_) } @items], __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;

            if (defined $item and defined $item->can('get_value')) {
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

    sub last {
        my ($self) = @_;
        $#{$self} >= 0 || return;
        $self->[-1];
    }

    sub first {
        my ($self) = @_;
        $#{$self} >= 0 || return;
        $self->[0];
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

    sub ft {
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
            return $self->new();
        }

        if (abs($to) > $max) {
            $to = $max;
        }

        $self->new(map { $_->get_value } @{$self}[$from .. $to]);
    }

    *fromTo  = \&ft;
    *from_to = \&ft;

    sub for {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my $var_ref = ($code->_get_private_var)[0]->get_var;

        foreach my $item (@{$self}) {
            $var_ref->set_value($item->get_value);
            $code->run;
            $item->set_value($var_ref->get_value);
        }

        $self;
    }

    sub map {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my $var_ref = ($code->_get_private_var)[0]->get_var;

        $self->new(
            map {
                $var_ref->set_value($_->get_value);
                $code->run;
              } @{$self}
        );
    }

    sub grep {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my $var_ref = ($code->_get_private_var)[0]->get_var;

        $self->new(
            grep {
                $var_ref->set_value($_);
                $code->run;
              } map { $_->get_value } @{$self}
        );
    }

    *filter = \&grep;

    sub find {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my $var_ref = ($code->_get_private_var)[0]->get_var;

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

        my $var_ref = ($code->_get_private_var)[0]->get_var;

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
        $self->_is_var_ref($_) || return for @vars;

        for my $i (0 .. $#vars) {
            if (exists $self->[$i] and ref($self->[$i]) eq 'Sidef::Variable::Variable') {
                $vars[$i]->get_var->set_value($self->[$i]->get_value);
            }
        }

        $self;
    }

    *assignTo = \&assign_to;

    sub first_index {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my $var_ref = ($code->_get_private_var)[0]->get_var;

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
        my $var_ref = ($code->_get_private_var)[0]->get_var;

        my $offset = $#{$self};
        for (my $i = $offset ; $i >= 0 ; $i--) {
            $var_ref->set_value($self->[$i]->get_value);
            i $code->run
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
            my $code = $obj;
            my ($var_ref, $class) = $code->_get_private_var();
            my $comp_code = {$class => [@{$code->{$class}}[1 .. $#{$code->{$class}}]]};

            $var_ref = $var_ref->get_var;

            for (my $i = 1 ; $i <= $offset ; $i += 2) {
                $var_ref->set_value(
                                   Sidef::Types::Array::Array->new($self->[$i - 1]->get_value, $self->[$i]->get_value));
                $array->push(Sidef::Types::Block::Code->new($comp_code)->run);
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
            my $code = $obj;
            my ($var_ref, $class) = $code->_get_private_var();
            my $comp_code = {$class => [@{$code->{$class}}[1 .. $#{$code->{$class}}]]};

            $var_ref = $var_ref->get_var;

            foreach my $i (1 .. $offset) {
                $var_ref->set_value(Sidef::Types::Array::Array->new($x, $self->[$i]->get_value));
                $x = Sidef::Types::Block::Code->new($comp_code)->run;
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

    sub rand {
        my ($self) = @_;
        $self->[rand($#{$self} + 1)];
    }

    sub range {
        my ($self) = @_;
        __PACKAGE__->new(map { Sidef::Types::Number::Number->new($_) } 0 .. $#{$self});
    }

    sub each {
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

                if (ref($x) eq ref($y) and $x->can($method) and $x->$method($y)) {

                    undef $indices{$last ? ($i + $diff) : ($j + $diff)};

                    --$max;
                    --$j;
                    --$i;
                }
            }
        }

        $self->new(map { $self->[$_]->get_value } grep { not exists $indices{$_} } 0 .. $#{$self});
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

    sub contains {
        my ($self, $obj) = @_;

        foreach my $var (@{$self}) {

            my $item = $var->get_value;
            if (ref($item) eq ref($obj)) {
                my $method = '==';
                if (defined $item->can($method)) {
                    if ($item->$method($obj)) {
                        return Sidef::Types::Bool::Bool->true;
                    }
                }
            }
        }

        Sidef::Types::Bool::Bool->false;
    }

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

    sub splice {
        my ($self, $offset, $length, $array) = @_;

        $offset = defined($offset) && $self->_is_number($offset) ? $$offset : 0;
        $length = defined($length) && $self->_is_number($length) ? $$length : scalar(@{$self});

        if (defined($array)) {
            $self->_is_array($array) || return;
            return $self->new(map { $_->get_value }
                              CORE::splice(@{$self}, $offset, $length, @{$self->new(map { $_->get_value } @{$array})}));
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

            my ($var_ref, $class) = $code->_get_private_var();
            my $comp_code = {$class => [@{$code->{$class}}[1 .. $#{$code->{$class}}]]};

            $var_ref = $var_ref->get_var;

            return $self->new(
                sort {
                    $var_ref->set_value(Sidef::Types::Array::Array->new($a, $b));
                    Sidef::Types::Block::Code->new($comp_code)->run
                  } map { $_->get_value } @{$self}
            );
        }

        my $method = '<=>';
        $self->new(sort { ref($a) eq ref($b) && $a->can($method) ? ($a->$method($b)) : -1 }
                   map { $_->get_value } @{$self});
    }

    sub permute {
        my ($self, $code) = @_;

        $#{$self} == -1 && return $self;
        my @idx = 0 .. $#{$self};

        if (defined($code)) {

            $self->_is_code($code) || return;
            my $var_ref = ($code->_get_private_var())[0]->get_var;

            while (1) {
                $var_ref->set_value($self->new(map { $_->get_value } @{$self}[@idx]));

                if (ref(my $res = $code->run) eq 'Sidef::Types::Bool::Bool') {
                    $$res eq 'true' || return $self;
                }

                my $p = $#idx;
                --$p while $idx[$p - 1] > $idx[$p];
                my $q = $p or (return $self);
                push @idx, CORE::reverse CORE::splice @idx, $p;
                ++$q while $idx[$p - 1] > $idx[$q];
                @idx[$p - 1, $q] = @idx[$q, $p - 1];
            }
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
        my ($self, $delim) = @_;
        $delim = ref($delim) && $self->_is_string($delim) ? $$delim : '';
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

    sub copy {
        my ($self) = @_;
        $self->new(map { $_->get_value } @{$self});
    }

    sub dump {
        my ($self) = @_;

        my $string = Sidef::Types::String::String->new("[");

        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;

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
                    $self->[$i]->set_value(exists $values[$i] ? $values[$i] : Sidef::Types::Nil::Nil->new);
                }
            }
            else {
                map { $_->set_value($arg) } @{$self};
            }

            $self;
        };
    }

};

1
