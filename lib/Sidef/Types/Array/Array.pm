package Sidef::Types::Array::Array {

    use 5.014;
    use strict;
    use warnings;

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
        my $new_array = $self->new();

        $self->_is_array($array) || return ($self);

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

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($self, $array) = @_;
            $self->_grep($array, 1);
        };

        *{__PACKAGE__ . '::' . '&'} = sub {
            my ($self, $array) = @_;
            $self->_grep($array, 0);
        };

        *{__PACKAGE__ . '::' . '<<'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1, 0) || return $self->new();
            $number->is_positive()
              || do {
                warn "[WARN] Array's method '<<' requires a positive number!\n";
                return $self->new();
              };
            $self->new(map { $_->get_value } CORE::splice(@{$self}, 0, $$number));
        };

        *{__PACKAGE__ . '::' . '>>'} = sub {
            my ($self, $number) = @_;
            $self->_is_number($number, 1, 0) || return $self->new();
            $number->is_positive()
              || do {
                warn "[WARN] Array's method '>>' requires a positive number!\n";
                return $self->new();
              };
            $self->new(map { $_->get_value } CORE::splice(@{$self}, -$$number));
        };

        *{__PACKAGE__ . '::' . '|'} = sub {
            my ($self, $array) = @_;
            my $new_array = $self->new;

            $self->_is_array($array) || return;

            my $add = '+';
            my $xor = '^';
            my $and = '&';
            $self->$xor($array)->$add($self->$and($array));
        };

        *{__PACKAGE__ . '::' . '^'} = sub {
            my ($self, $array) = @_;
            my $new_array = $self->new;

            $self->_is_array($array) || return;

            my $add    = '+';
            my $and    = '&';
            my $substr = '-';
            ($self->$add($array))->$substr($self->$and($array));
        };

        *{__PACKAGE__ . '::' . '+'} = sub {
            my ($self, $array) = @_;

            $self->_is_array($array) || return ($self);
            __PACKAGE__->new(map { $_->get_value } @{$self}, @{$array});
        };

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

        *{__PACKAGE__ . '::' . '&&'} = \&mesh;

        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($self, $array) = @_;

            $self->_is_array($array) || return ($self);

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
        };

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $arg) = @_;

            if (ref $arg eq 'Sidef::Types::Array::Array') {
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

    sub mesh {
        my ($self, $array) = @_;

        $self->_is_array($array) || return ($self);

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
        $self->_is_number($size) || return $self;
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

    sub _op_equal {
        my ($self, $method) = @_;

        $#{$self} > -1 || return;
        my $first = $self->[0]->get_value;

        foreach my $i (1 .. $#{$self}) {
            my $obj = $self->[$i]->get_value;

            if ($obj->can($method)) {
                $first = $first->$method($obj);
            }
        }

        $first;
    }

    sub sum {
        $_[0]->_op_equal('+');
    }

    *combine = \&sum;

    sub multiply {
        $_[0]->_op_equal('*');
    }

    sub divide {
        $_[0]->_op_equal('/');
    }

    sub last {
        my ($self) = @_;
        $#{$self} >= 0 || return;
        $self->[-1]->get_value;
    }

    sub first {
        my ($self) = @_;
        $#{$self} >= 0 || return;
        $self->[0]->get_value;
    }

    sub exists {
        my ($self, $index) = @_;
        $self->_is_number($index, 1) || return;
        Sidef::Types::Bool::Bool->new(exists $self->[$$index]);
    }

    sub defined {
        my ($self, $index) = @_;
        $self->_is_number($index, 1) || return;
        Sidef::Types::Bool::Bool->new(defined($self->[$$index]) and $self->[$$index]->is_defined);
    }

    sub ft {
        my ($self, $from, $to) = @_;

        $from //= 0;
        $to   //= $#{$self};

        $self->new(map { $_->get_value } @{$self}[$from .. $to]);
    }

    sub map {
        my ($self, $code) = @_;

        $self->_is_code($code) || return $self;

        my $exec = Sidef::Exec->new();
        my ($var_ref) = $code->_get_private_var();

        $self->new(
            map {
                my $val = $_->get_value;
                $var_ref->get_var->set_value($val);
                my $result = $code->run;
                $_->set_value($var_ref->get_var->get_value);
                $result;
              } @{$self}
        );
    }

    sub grep {
        my ($self, $code) = @_;

        $self->_is_code($code) || return $self;

        my $exec = Sidef::Exec->new();
        my ($var_ref) = $code->_get_private_var();

        $self->new(
            grep {
                my $val = $_->get_value;
                $var_ref->get_var->set_value($val);
                $code->run;
              } @{$self}
        );
    }

    *filter = \&grep;

    sub find {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        my $exec = Sidef::Exec->new();
        my ($var_ref) = $code->_get_private_var();

        foreach my $var (@{$self}) {
            my $val = $var->get_value;
            $var_ref->get_var->set_value($val);
            return $val if ($code->run);
        }

        return;
    }

    sub all {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        my $exec = Sidef::Exec->new();
        my ($var_ref) = $code->_get_private_var();

        foreach my $var (@{$self}) {
            my $val = $var->get_value;
            $var_ref->get_var->set_value($val);
            if (not $code->run) {
                return Sidef::Types::Bool::Bool->false;
            }
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub first_index {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        my $exec = Sidef::Exec->new();
        my ($var_ref) = $code->_get_private_var();

        foreach my $i (0 .. $#{$self}) {
            my $var = $self->[$i];
            my $val = $var->get_value;
            $var_ref->get_var->set_value($val);
            if ($code->run) {
                return Sidef::Types::Number::Number->new($i);
            }
        }

        Sidef::Types::Number::Number->new(-1);
    }

    *indexWhere = \&first_index;
    *firstIndex = \&first_index;

    sub last_index {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        my $exec = Sidef::Exec->new();
        my ($var_ref) = $code->_get_private_var();

        my $offset = $#{$self};
        for (my $i = $offset ; $i >= 0 ; $i--) {
            my $var = $self->[$i];
            my $val = $var->get_value;
            $var_ref->get_var->set_value($val);
            if ($code->run) {
                return Sidef::Types::Number::Number->new($i);
            }
        }

        Sidef::Types::Number::Number->new(-1);
    }

    *lastIndexWhere = \&last_index;
    *lastIndex      = \&last_index;

    sub reducePairs {
        my ($self, $method) = @_;

        $self->_is_string($method) || return;

        (my $offset = $#{$self}) >= 0 || return;

        my $array = $self->new();
        for (my $i = 1 ; $i <= $offset ; $i += 2) {
            my $x = $self->[$i - 1]->get_value;

            if ($x->can($$method)) {
                $array->push($x->$$method($self->[$i]->get_value));
            }
            else {
                warn "[WARN] Array.reducePairs: can't find method '$$method' for object '", ref($x), "'!\n";
            }
        }

        $array;
    }

    sub shuffle {
        my ($self) = @_;
        require List::Util;
        $self->new(map { $_->get_value } List::Util::shuffle(@{$self}));
    }

    sub reduce {
        my ($self, $method) = @_;

        $self->_is_string($method) || return;
        (my $offset = $#{$self}) >= 0 || return;

        my $x = $self->[0]->get_value;
        foreach my $i (1 .. $offset) {
            if ($x->can($$method)) {
                $x = ($x->$$method($self->[$i]->get_value));
            }
            else {
                warn "[WARN] Array.reducePairs: can't find method '$$method' for object '", ref($x), "'!\n";
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

    sub range {
        my ($self) = @_;
        __PACKAGE__->new(map { Sidef::Types::Number::Number->new($_) } 0 .. $#{$self});
    }

    sub insert {
        my ($self, $index, @objects) = @_;
        $self->_is_number($index) || return $self;
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

    sub uniqueLast {
        my ($self) = @_;
        $self->_unique(1);
    }

    *uniqLast    = \&uniqueLast;
    *unique_last = \&uniqueLast;
    *uniq_last   = \&uniqueLast;

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

            return ((CORE::splice(@{$self}, $$index, 1))->get_value);
        }

        $#{$self} > -1 || return;
        (pop @{$self})->get_value;
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

    sub shift {
        my ($self) = @_;
        $#{$self} > -1 || return;
        (shift @{$self})->get_value;
    }

    sub sort {
        my ($self, $code) = @_;

        if (defined $code) {

            my ($var_ref, $class) = $code->_get_private_var();
            my $comp_code = {$class => [@{$code->{$class}}[1 .. $#{$code->{$class}}]]};

            return $self->new(
                sort {
                    $var_ref->get_var->set_value(Sidef::Types::Array::Array->new($a, $b));
                    Sidef::Types::Block::Code->new($comp_code)->run;
                  } map { $_->get_value } @{$self}
            );
        }

        my $method = '<=>';
        $self->new(sort { $a->can($method) && ($a->$method($b) // -1) } map { $_->get_value } @{$self});
    }

    sub push {
        my ($self, @args) = @_;
        push @{$self}, @{$self->new(@args)};
        $self;
    }

    sub unshift {
        my ($self, @args) = @_;
        unshift @{$self}, @{$self->new(@args)};
        $self;
    }

    # Join the array as string
    sub join {
        my ($self, $delim) = @_;
        $delim = ref($delim) && $self->_is_string($delim) ? $$delim : '';
        Sidef::Types::String::String->new(CORE::join($delim, @{$self}));
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

    sub sliceReverse {
        my ($self) = @_;
        my $array = $self->new();
        CORE::push(@{$array}, CORE::reverse(@{$self}));
        $array;
    }

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(map { $_->get_value } @{$self});
    }

    *toHash = \&to_hash;

    sub dump {
        my ($self) = @_;

        my $string = Sidef::Types::String::String->new("[");

        foreach my $i (0 .. $#{$self}) {
            my $item = $self->[$i]->get_value;

            if (defined $item and defined $item->can('dump')) {
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

}
