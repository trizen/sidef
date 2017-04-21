package Sidef::Types::Array::Array {

    use utf8;
    use 5.016;

    use List::Util qw();

    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{""}   => \&_dump,
      q{0+}   => sub { scalar(@{$_[0]}) },
      q{bool} => sub { scalar(@{$_[0]}) };

    use Sidef::Types::Number::Number;

    sub new {
        @_ == 2 && ref($_[1]) eq 'ARRAY'
          ? bless($_[1], __PACKAGE__)
          : do {
            shift(@_);
            bless [@_], __PACKAGE__;
          };
    }

    *call = \&new;

    sub get_value {
        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              && return $addr{$refaddr};

            my @array;
            $addr{$refaddr} = \@array;

            foreach my $item (@$obj) {
                if (index(ref($item), 'Sidef::') == 0) {
                    CORE::push(@array, $item->get_value);
                }
                else {
                    CORE::push(@array, $item);
                }
            }

            $addr{$refaddr};
        };

        local *Sidef::Types::Array::Array::get_value = $sub;
        $sub->($_[0]);
    }

    sub unroll_operator {
        my ($self, $operator, $arg) = @_;

        $operator = "$operator" if ref($operator);

        my @array;

        my @arg  = @$arg;
        my @self = @$self;

        (my $argc = @arg) || return bless(\@self, __PACKAGE__);
        my $selfc = @self;

        my $max = $argc > $selfc ? $argc - 1 : $selfc - 1;

        foreach my $i (0 .. $max) {
            CORE::push(@array, $self[$i % $selfc]->$operator($arg[$i % $argc]));
        }

        bless \@array, __PACKAGE__;
    }

    sub map_operator {
        my ($self, $operator, @args) = @_;

        $operator = "$operator" if ref($operator);

        my @array;
        foreach my $i (0 .. $#$self) {
            CORE::push(@array, $self->[$i]->$operator(@args));
        }

        bless \@array, __PACKAGE__;
    }

    sub pam_operator {
        my ($self, $operator, $arg) = @_;

        $operator = "$operator" if ref($operator);

        my @array;
        foreach my $i (0 .. $#$self) {
            CORE::push(@array, $arg->$operator($self->[$i]));
        }

        bless \@array, __PACKAGE__;
    }

    sub reduce_operator {
        my ($self, $operator) = @_;

        $operator = "$operator" if ref($operator);
        (my $end = $#$self) >= 0 || return undef;

        my $x = $self->[0];
        foreach my $i (1 .. $end) {
            $x = $x->$operator($self->[$i]);
        }
        $x;
    }

    sub cross_operator {
        my ($self, $operator, $arg) = @_;

        $operator = "$operator" if ref($operator);

        my @arg = @$arg;

        my @array;
        if ($operator eq '') {
            foreach my $i (@$self) {
                foreach my $j (@arg) {
                    CORE::push(@array, bless([$i, $j], __PACKAGE__));
                }
            }
        }
        else {
            foreach my $i (@$self) {
                foreach my $j (@arg) {
                    CORE::push(@array, $i->$operator($j));
                }
            }
        }

        bless \@array, __PACKAGE__;
    }

    sub zip_operator {
        my ($self, $operator, $arg) = @_;

        $operator = "$operator" if ref($operator);

        my @arg  = @$arg;
        my @self = @$self;

        my $self_len = $#self;
        my $arg_len  = $#arg;
        my $min      = $self_len < $arg_len ? $self_len : $arg_len;

        my @array;
        if ($operator eq '') {
            foreach my $i (0 .. $min) {
                CORE::push(@array, bless([$self[$i], $arg[$i]], __PACKAGE__));
            }
        }
        else {
            foreach my $i (0 .. $min) {
                CORE::push(@array, $self[$i]->$operator($arg[$i]));
            }
        }

        bless \@array, __PACKAGE__;
    }

    sub mul {
        my ($self, $num) = @_;
        bless [(@$self) x $num], __PACKAGE__;
    }

    sub div {
        my ($self, $num) = @_;

        my @obj = @$self;

        my @array;
        my $len = @obj / CORE::int($num);

        my $i   = 1;
        my $pos = $len;
        while (@obj) {
            my $j = $pos - $i * CORE::int($len);
            $pos -= $j if $j >= 1;
            CORE::push(@array, bless [splice @obj, 0, $len + $j], __PACKAGE__);
            $pos += $len;
            $i++;
        }

        bless \@array, __PACKAGE__;
    }

    sub part {
        my ($self, $num) = @_;

        my @first = @$self;
        my @second = splice(@first, CORE::int($num));

        (bless(\@first, __PACKAGE__), bless(\@second, __PACKAGE__));
    }

    *partition = \&part;

    sub or {
        my ($self, $array) = @_;

        #$self->and($array)->concat($self->xor($array));
        $self->concat($array)->uniq;
    }

    sub xor {
        my ($self, $array) = @_;

        my @x = sort { $a cmp $b } @$self;
        my @y = sort { $a cmp $b } @$array;

        my $endx = $#x;
        my $endy = $#y;

        my $i = 0;
        my $j = 0;

        my ($cmp, @new);

        while (1) {

            $cmp = CORE::int($x[$i] cmp $y[$j]);

            if ($cmp < 0) {
                push @new, $x[$i];
                ++$i;
            }
            elsif ($cmp > 0) {
                push @new, $y[$j];
                ++$j;
            }
            else {
                my $k = $i;
                do { ++$i } while ($i <= $endx and $x[$i] eq $y[$j]);
                do { ++$j } while ($j <= $endy and $x[$k] eq $y[$j]);
            }

            if ($i > $endx) {
                push @new, @y[$j .. $endy];
                last;
            }
            elsif ($j > $endy) {
                push @new, @x[$i .. $endx];
                last;
            }
        }

        bless \@new, __PACKAGE__;
    }

    sub and {
        my ($self, $array) = @_;

        my @x = sort { $a cmp $b } @$self;
        my @y = sort { $a cmp $b } @$array;

        my $i = 0;
        my $j = 0;

        my $end1 = @x;
        my $end2 = @y;

        my ($cmp, @new);
        while ($i < $end1 and $j < $end2) {

            $cmp = CORE::int($x[$i] cmp $y[$j]);

            if ($cmp < 0) {
                ++$i;
            }
            elsif ($cmp > 0) {
                ++$j;
            }
            else {
                push @new, $x[$i];
                ++$i;
                ++$j;
            }
        }

        bless \@new, __PACKAGE__;
    }

    sub is_empty {
        my ($self) = @_;
        ($#$self == -1) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub sub {
        my ($self, $array) = @_;

        my @x = sort { $a cmp $b } @$self;
        my @y = sort { $a cmp $b } @$array;

        my $i = 0;
        my $j = 0;

        my $end1 = @x;
        my $end2 = @y;

        my ($cmp, @new);
        while ($i < $end1 and $j < $end2) {

            $cmp = CORE::int($x[$i] cmp $y[$j]);

            if ($cmp < 0) {
                push @new, $x[$i];
                ++$i;
            }
            elsif ($cmp > 0) {
                ++$j;
            }
            else {
                1 while (++$i < $end1 and $x[$i] eq $y[$j]);
            }
        }

        if ($i < $end1) {
            push @new, @x[$i .. $#x];
        }

        bless \@new, __PACKAGE__;
    }

    sub diff {
        my ($self, $array) = @_;

        my @x = sort { $a cmp $b } @$self;
        my @y = sort { $a cmp $b } @$array;

        my $i = 0;
        my $j = 0;

        my $end1 = @x;
        my $end2 = @y;

        my ($cmp, @new);
        while ($i < $end1 and $j < $end2) {

            $cmp = CORE::int($x[$i] cmp $y[$j]);

            if ($cmp < 0) {
                push @new, $x[$i];
                ++$i;
            }
            elsif ($cmp > 0) {
                ++$j;
            }
            else {
                ++$i;
                ++$j;
            }
        }

        if ($i < $end1) {
            push @new, @x[$i .. $#x];
        }

        bless \@new, __PACKAGE__;
    }

    sub concat {
        my ($self, $arg) = @_;

        UNIVERSAL::isa($arg, 'ARRAY')
          ? bless([@$self, @$arg], __PACKAGE__)
          : bless([@$self, $arg],  __PACKAGE__);
    }

    *add = \&concat;

    sub levenshtein {
        my ($self, $arg) = @_;

        my @s = @$self;
        my @t = @$arg;

        my $len1 = scalar(@s);
        my $len2 = scalar(@t);

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

    sub jaro_distance {
        my ($self, $arg, $winkler) = @_;

        my @s = @$self;
        my @t = @$arg;

        my $s_len = @s;
        my $t_len = @t;

        if ($s_len == 0 and $t_len == 0) {
            return 1;
        }

        my $match_distance = CORE::int(List::Util::max($s_len, $t_len) / 2) - 1;

        my @s_matches;
        my @t_matches;

        my $matches = 0;
        foreach my $i (0 .. $#s) {

            my $start = List::Util::max(0, $i - $match_distance);
            my $end = List::Util::min($i + $match_distance + 1, $t_len);

            foreach my $j ($start .. $end - 1) {
                $t_matches[$j] and next;
                $s[$i] eq $t[$j] or next;
                $s_matches[$i] = 1;
                $t_matches[$j] = 1;
                $matches++;
                last;
            }
        }

        return Sidef::Types::Number::Number::ZERO if $matches == 0;

        my $k              = 0;
        my $transpositions = 0;

        foreach my $i (0 .. $#s) {
            $s_matches[$i] or next;
            until ($t_matches[$k]) { ++$k }
            $s[$i] eq $t[$k] or ++$transpositions;
            ++$k;
        }

        my $jaro = (($matches / $s_len) + ($matches / $t_len) + (($matches - $transpositions / 2) / $matches)) / 3;

        $winkler || return Sidef::Types::Number::Number->new($jaro);    # return the Jaro distance instead of Jaro-Winkler

        my $prefix = 0;
        foreach my $i (0 .. List::Util::min(3, $#t, $#s)) {
            $s[$i] eq $t[$i] ? ++$prefix : last;
        }

        Sidef::Types::Number::Number->new($jaro + $prefix * 0.1 * (1 - $jaro));
    }

    sub count {
        my ($self, $obj) = @_;

        my $counter = 0;
        if (ref($obj) eq 'Sidef::Types::Block::Block') {

            foreach my $item (@$self) {
                if ($obj->run($item)) {
                    ++$counter;
                }
            }

            return Sidef::Types::Number::Number->_set_uint($counter);
        }

        foreach my $item (@$self) {
            $item eq $obj and $counter++;
        }

        Sidef::Types::Number::Number->_set_uint($counter);
    }

    *count_by = \&count;

    sub eq {
        my ($self, $array) = @_;

        if ($#$self != $#$array) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        my $i = -1;
        foreach my $item (@$self) {
            ($item eq $array->[++$i])
              or return (Sidef::Types::Bool::Bool::FALSE);
        }

        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub ne {
        my ($self, $array) = @_;
        $self->eq($array)->neg;
    }

    sub make {
        my ($self, $size, $type) = @_;
        bless([($type) x $size], __PACKAGE__);
    }

    sub _min_max {
        my ($self, $value) = @_;

        @$self || return undef;

        my $item = $self->[0];
        foreach my $i (1 .. $#$self) {
            my $val = $self->[$i];
            $item = $val if (CORE::int($val cmp $item) == $value);
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

    sub collapse {
        $_[0]->reduce_operator('+');
    }

    sub sum_by {
        my ($self, $arg) = @_;

        my $sum = Sidef::Types::Number::Number::ZERO;

        foreach my $obj (@$self) {
            $sum = $sum->add($arg->run($obj));
        }

        return $sum;
    }

    sub sum {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Block::Block') {
            goto \&sum_by;
        }

        my $sum = $arg // Sidef::Types::Number::Number::ZERO;

        foreach my $obj (@$self) {
            $sum = $sum->add($obj);
        }

        $sum;
    }

    sub prod_by {
        my ($self, $arg) = @_;

        my $prod = Sidef::Types::Number::Number::ONE;

        foreach my $obj (@$self) {
            $prod = $prod->mul($arg->run($obj));
        }

        return $prod;
    }

    sub prod {
        my ($self, $arg) = @_;

        if (ref($arg) eq 'Sidef::Types::Block::Block') {
            goto \&prod_by;
        }

        my $prod = $arg // Sidef::Types::Number::Number::ONE;

        foreach my $obj (@$self) {
            $prod = $prod->mul($obj);
        }

        $prod;
    }

    sub _min_max_by {
        my ($self, $code, $value) = @_;

        @$self || return undef;

        my @pairs = map { [$_, scalar $code->run($_)] } @$self;
        my $item = $pairs[0];

        foreach my $i (1 .. $#pairs) {
            $item = $pairs[$i] if (CORE::int($pairs[$i][1] cmp $item->[1]) == $value);
        }

        $item->[0];
    }

    sub max_by {
        @_ = (@_[0, 1], 1);
        goto \&_min_max_by;
    }

    sub min_by {
        @_ = (@_[0, 1], -1);
        goto \&_min_max_by;
    }

    sub swap {
        my ($self, $i, $j) = @_;
        @$self[$i, $j] = @$self[$j, $i];
        $self;
    }

    sub change_to {
        my ($self, $arg) = @_;
        @$self = @$arg;
        $self;
    }

    sub first {
        my ($self, $arg) = @_;

        if (defined $arg) {

            if (ref($arg) eq 'Sidef::Types::Block::Block') {
                goto \&first_by;
            }

            my $max = $#$self;
            $arg = CORE::int($arg) - 1;
            return bless([@$self[0 .. ($arg > $max ? $max : $arg)]], __PACKAGE__);
        }

        @$self ? $self->[0] : ();
    }

    sub last {
        my ($self, $arg) = @_;

        if (defined $arg) {

            if (ref($arg) eq 'Sidef::Types::Block::Block') {
                goto \&last_by;
            }

            my $from = @$self - CORE::int($arg);
            return bless([@$self[($from < 0 ? 0 : $from) .. $#$self]], __PACKAGE__);
        }

        @$self ? $self->[-1] : ();
    }

    sub _flatten {    # this exists for performance reasons
        my ($self) = @_;

        my @array;
        foreach my $i (0 .. $#$self) {
            my $item = $self->[$i];
            CORE::push(@array, ref($item) eq ref($self) ? $item->_flatten : $item);
        }

        @array;
    }

    sub flatten {
        my ($self) = @_;

        my @new_array;
        foreach my $i (0 .. $#$self) {
            my $item = $self->[$i];
            CORE::push(@new_array, ref($item) eq ref($self) ? ($item->_flatten) : $item);
        }

        bless \@new_array, __PACKAGE__;
    }

    *flat = \&flatten;

    sub exists {
        my ($self, $index) = @_;
        exists($self->[$index])
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *has_index = \&exists;

    sub defined {
        my ($self, $index) = @_;
        defined($self->[$index])
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub items {
        my ($self, @indices) = @_;
        bless([map { exists($self->[$_]) ? $self->[$_] : undef } @indices], __PACKAGE__);
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

        my $value = $self->fetch($key) // return undef;

        foreach my $key (@keys) {
            $value = $value->fetch($key) // return undef;
        }

        $value;
    }

    sub _slice {
        my ($self, $from, $to) = @_;

        my $max = @$self;

        $from = defined($from) ? CORE::int($from) : 0;
        $to   = defined($to)   ? CORE::int($to)   : $max - 1;

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

        @$self[$from .. $to];
    }

    sub ft {
        my ($self) = @_;
        bless [_slice(@_)], __PACKAGE__;
    }

    *slice = \&ft;

    sub each {
        my ($self, $code) = @_;

        foreach my $item (@$self) {
            $code->run($item);
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    sub each_slice {
        my ($self, $n, $code) = @_;

        $n = CORE::int($n);

        my $end = @$self;
        for (my $i = $n - 1 ; $i < $end ; $i += $n) {
            $code->run(@$self[$i - ($n - 1) .. $i]);
        }

        my $mod = $end % $n;
        if ($mod != 0) {
            $code->run(@$self[$end - $mod .. $end - 1]);
        }

        $self;
    }

    sub slice_before {
        my ($self, $block) = @_;

        my @new;
        my $i = 0;
        foreach my $item (@$self) {
            if ($block->run($item)) {
                ++$i if @new;
            }
            push @{$new[$i]}, $item;
        }

        bless([map { bless($_, __PACKAGE__) } @new], __PACKAGE__);
    }

    sub slice_after {
        my ($self, $block) = @_;

        my @new;
        my $i = 0;
        foreach my $item (@$self) {
            push @{$new[$i]}, $item;
            ++$i if $block->run($item);
        }

        bless [map { bless($_, __PACKAGE__) } @new], __PACKAGE__;
    }

    sub slices {
        my ($self, $n) = @_;

        $n = CORE::int($n);

        $n <= 0
          && return bless([], __PACKAGE__);

        my @slices;
        my $end = @$self;
        for (my $i = $n - 1 ; $i < $end ; $i += $n) {
            CORE::push(@slices, bless([@$self[$i - ($n - 1) .. $i]], __PACKAGE__));
        }

        my $mod = $end % $n;
        if ($mod != 0) {
            CORE::push(@slices, bless([@$self[$end - $mod .. $end - 1]], __PACKAGE__));
        }

        bless \@slices, __PACKAGE__;
    }

    sub cons {
        my ($self, $n) = @_;

        $n = CORE::int($n);

        my @array;
        foreach my $i ($n - 1 .. $#$self) {
            push @array, bless([@$self[$i - $n + 1 .. $i]], __PACKAGE__);
        }

        bless \@array, __PACKAGE__;
    }

    sub each_cons {
        my ($self, $n, $code) = @_;

        $n = CORE::int($n);

        foreach my $i ($n - 1 .. $#$self) {
            $code->run(@$self[$i - $n + 1 .. $i]);
        }

        $self;
    }

    sub each_index {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#$self) {
            $code->run(Sidef::Types::Number::Number->_set_uint($i));
        }

        $self;
    }

    *each_key = \&each_index;

    sub each_kv {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#$self) {
            $code->run(Sidef::Types::Number::Number->_set_uint($i), $self->[$i]);
        }

        $self;
    }

    sub map {
        my ($self, $code) = @_;

        my @array;
        foreach my $item (@$self) {
            CORE::push(@array, $code->run($item));
        }

        bless \@array, __PACKAGE__;
    }

    sub map_kv {
        my ($self, $code) = @_;

        my @arr;
        foreach my $i (0 .. $#$self) {
            CORE::push(@arr, $code->run(Sidef::Types::Number::Number->_set_uint($i), $self->[$i]));
        }

        bless \@arr, __PACKAGE__;
    }

    sub flat_map {
        my ($self, $code) = @_;

        my @array;
        foreach my $item (@$self) {
            CORE::push(@array, @{scalar $code->run($item)});
        }

        bless \@array, __PACKAGE__;
    }

    sub grep {
        my ($self, $obj) = @_;

        my @array;
        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            foreach my $item (@$self) {
                CORE::push(@array, $item) if $obj->match($item);
            }
        }
        else {
            foreach my $item (@$self) {
                CORE::push(@array, $item) if $obj->run($item);
            }
        }

        bless \@array, __PACKAGE__;
    }

    *select = \&grep;

    sub grep_kv {
        my ($self, $code) = @_;

        my @array;
        foreach my $i (0 .. $#$self) {
            CORE::push(@array, $self->[$i]) if $code->run(Sidef::Types::Number::Number->_set_uint($i), $self->[$i]);
        }

        bless \@array, __PACKAGE__;
    }

    *select_kv = \&grep_kv;

    sub group_by {
        my ($self, $code) = @_;

        my %hash;
        foreach my $item (@$self) {
            CORE::push(@{$hash{$code->run($item)}}, $item);
        }

        Sidef::Types::Hash::Hash->new(map { $_ => bless($hash{$_}, __PACKAGE__) } CORE::keys(%hash));
    }

    sub match {
        my ($self, $regex) = @_;

        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              && return Sidef::Types::Bool::Bool::FALSE;

            undef $addr{$refaddr};

            foreach my $item (@$obj) {
                if (defined(my $sub = UNIVERSAL::can($item, 'match'))) {
                    $sub->($item, $regex)
                      && return Sidef::Types::Bool::Bool::TRUE;
                }
                elsif ("$item" =~ $regex->{regex}) {
                    return Sidef::Types::Bool::Bool::TRUE;
                }
            }

            Sidef::Types::Bool::Bool::FALSE;
        };

        local *Sidef::Types::Array::Array::match = $sub;
        $sub->($_[0]);
    }

    sub iter {
        my ($self) = @_;

        my $i = 0;
        Sidef::Types::Block::Block->new(
            code => sub {
                $self->[$i++];
            }
        );
    }

    sub freq_by {
        my ($self, $code) = @_;

        my %hash;
        foreach my $item (@$self) {
            my $r = $hash{$code->run($item)} //= {
                                                  count => 0,
                                                  items => [],
                                                 };
            CORE::push(@{$r->{items}}, $item);
            ++$r->{count};
        }

        my %freq;
        foreach my $key (CORE::keys(%hash)) {
            my $r = $hash{$key};
            my $n = Sidef::Types::Number::Number->_set_uint($r->{count});
            @freq{@{$r->{items}}} = ($n) x scalar(@{$r->{items}});
        }

        Sidef::Types::Hash::Hash->new(%freq);
    }

    sub freq {
        my ($self, $code) = @_;

        if (defined($code)) {
            goto \&freq_by;
        }

        my %hash;
        foreach my $item (@$self) {
            $hash{$item}++;
        }

        foreach my $key (CORE::keys %hash) {
            $hash{$key} = Sidef::Types::Number::Number->_set_uint($hash{$key});
        }

        Sidef::Types::Hash::Hash->new(%hash);
    }

    sub first_by {
        my ($self, $code) = @_;
        foreach my $val (@$self) {
            return $val if $code->run($val);
        }
        return undef;
    }

    *find = \&first_by;

    sub last_by {
        my ($self, $code) = @_;
        for (my $i = $#$self ; $i >= 0 ; --$i) {
            return $self->[$i] if $code->run($self->[$i]);
        }
        return undef;
    }

    sub any {
        my ($self, $code) = @_;

        foreach my $val (@$self) {
            $code->run($val)
              && return (Sidef::Types::Bool::Bool::TRUE);
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub all {
        my ($self, $code) = @_;

        @$self || return (Sidef::Types::Bool::Bool::FALSE);

        foreach my $val (@$self) {
            $code->run($val)
              || return (Sidef::Types::Bool::Bool::FALSE);
        }

        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub assign_to {
        my ($self, @vars) = @_;

        my @values = CORE::splice(@$self, 0, $#vars + 1);

        for my $i (0 .. $#vars) {
            if (exists $values[$i]) {
                if (ref($vars[$i]) eq 'REF') {
                    ${$vars[$i]} = $values[$i];
                }
            }
        }

        bless \@values, __PACKAGE__;
    }

    sub bindex {
        my ($self, $obj) = @_;

        my $left  = 0;
        my $right = $#$self;
        my ($middle, $item, $cmp);

        if (ref($obj) eq 'Sidef::Types::Block::Block') {

            while ($left <= $right) {
                $middle = (($right + $left) >> 1);
                $item   = $self->[$middle];
                $cmp    = CORE::int($obj->run($item)) || return Sidef::Types::Number::Number->_set_uint($middle);

                if ($cmp > 0) {
                    $right = $middle - 1;
                }
                else {
                    $left = $middle + 1;
                }
            }

            return Sidef::Types::Number::Number::MONE;
        }

        while ($left <= $right) {
            $middle = int(($right + $left) >> 1);
            $item   = $self->[$middle];
            $cmp    = CORE::int($item cmp $obj);

            if (!$cmp) {
                return Sidef::Types::Number::Number->_set_uint($middle);
            }
            elsif ($cmp > 0) {
                $right = $middle - 1;
            }
            else {
                $left = $middle + 1;
            }
        }

        return Sidef::Types::Number::Number::MONE;
    }

    *bindex_by = \&bindex;

    sub index {
        my ($self, $obj) = @_;

        if (@_ > 1) {

            if (ref($obj) eq 'Sidef::Types::Block::Block') {
                foreach my $i (0 .. $#$self) {
                    $obj->run($self->[$i])
                      && return Sidef::Types::Number::Number->_set_uint($i);
                }
                return Sidef::Types::Number::Number::MONE;
            }

            foreach my $i (0 .. $#$self) {
                $self->[$i] eq $obj
                  and return Sidef::Types::Number::Number->_set_uint($i);
            }

            return Sidef::Types::Number::Number::MONE;
        }

        @$self
          ? Sidef::Types::Number::Number::ZERO
          : Sidef::Types::Number::Number::MONE;
    }

    *index_by    = \&index;
    *first_index = \&index;

    sub rindex {
        my ($self, $obj) = @_;

        if (@_ > 1) {
            if (ref($obj) eq 'Sidef::Types::Block::Block') {
                for (my $i = $#$self ; $i >= 0 ; $i--) {
                    $obj->run($self->[$i])
                      && return Sidef::Types::Number::Number->_set_uint($i);
                }

                return Sidef::Types::Number::Number::MONE;
            }

            for (my $i = $#$self ; $i >= 0 ; $i--) {
                $self->[$i] eq $obj
                  and return Sidef::Types::Number::Number->_set_uint($i);
            }

            return Sidef::Types::Number::Number::MONE;
        }

        $self->end;
    }

    *rindex_by  = \&rindex;
    *last_index = \&rindex;

    sub pairmap {
        my ($self, $obj) = @_;

        my $end = @$self;

        my @array;
        for (my $i = 1 ; $i < $end ; $i += 2) {
            CORE::push(@array, scalar $obj->run(@$self[$i - 1, $i]));
        }

        bless \@array, __PACKAGE__;
    }

    sub shuffle {
        my ($self) = @_;
        bless [List::Util::shuffle(@$self)], __PACKAGE__;
    }

    sub best_shuffle {
        my ($s) = @_;
        my ($t) = $s->shuffle;

        my $end = $#$s;

        foreach my $i (0 .. $end) {
            foreach my $j (0 .. $end) {
                $i != $j
                  && !($t->[$i] eq $s->[$j])
                  && !($t->[$j] eq $s->[$i])
                  && do {
                    @$t[$i, $j] = @$t[$j, $i];
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
        my ($self, $obj, $initial) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            (my $end = $#$self) >= 0 || return undef;
            my ($beg, $x) = defined($initial) ? (0, $initial) : (1, $self->[0]);
            foreach my $i ($beg .. $end) {
                $x = $obj->run($x, $self->[$i]);
            }

            return $x;
        }

        $self->reduce_operator("$obj");
    }

    *inject = \&reduce;

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->_set_uint(scalar @$self);
    }

    *len  = \&length;    # alias
    *size = \&length;

    sub end {
        my $end = $#{$_[0]};
            $end == -1 ? Sidef::Types::Number::Number::MONE
          : $end == 0  ? Sidef::Types::Number::Number::ZERO
          : $end == 1  ? Sidef::Types::Number::Number::ONE
          : $end > 0   ? Sidef::Types::Number::Number->_set_uint($end)
          :              Sidef::Types::Number::Number->_set_int($end);
    }

    *offset = \&end;

    sub resize {
        my ($self, $num) = @_;
        $#$self = $num;
        $self;
    }

    *resize_to = \&resize;

    sub pick {
        my ($self, $amount) = @_;

        if (defined $amount) {
            $amount = CORE::int($amount);

            my $len = @$self;
            if ($amount >= $len) {
                return bless([List::Util::shuffle(@$self)], __PACKAGE__);
            }

            my @result;
            for (my ($i, $amount_left) = (0, $len) ; $amount > 0 ; ++$i, --$amount_left) {
                my $rand = CORE::int(CORE::rand($amount_left));
                if ($rand < $amount) {
                    push @result, $self->[$i];
                    $amount--;
                }
            }

            return bless([List::Util::shuffle(@result)], __PACKAGE__);
        }

        $self->[CORE::rand(scalar @$self)];
    }

    sub rand {
        my ($self, $amount) = @_;

        if (defined $amount) {
            $amount = CORE::int($amount);

            my $len = @$self;
            return (
                    $len > 0
                    ? bless([map { $self->[CORE::rand($len)] } 1 .. $amount], __PACKAGE__)
                    : bless([], __PACKAGE__)
                   );
        }

        $self->[CORE::rand(scalar @$self)];
    }

    *sample = \&rand;

    sub range {
        my ($self) = @_;
        Sidef::Types::Range::RangeNumber->new(Sidef::Types::Number::Number::ZERO,
                                              Sidef::Types::Number::Number->_set_int($#$self),
                                              Sidef::Types::Number::Number::ONE,
                                             );
    }

    sub indices {
        my ($self) = @_;
        bless [map { Sidef::Types::Number::Number->_set_uint($_) } 0 .. $#$self], __PACKAGE__;
    }

    *keys = \&indices;

    sub pairs {
        my ($self) = @_;
        bless [map { Sidef::Types::Array::Pair->new(Sidef::Types::Number::Number->_set_uint($_), $self->[$_]) } 0 .. $#$self],
          __PACKAGE__;
    }

    *kv = \&pairs;

    sub insert {
        my ($self, $i, @objects) = @_;

        $i = CORE::int($i);

        if ($#$self < $i) {
            $#$self = $i - 1;
        }

        CORE::splice(@$self, $i, 0, @objects);
        $self;
    }

    sub binsert {
        my ($self, $obj) = @_;

        my $left  = 0;
        my $right = $#$self;
        my ($middle, $item, $cmp);

        if ($right < 0) {
            CORE::push(@$self, $obj);
            return $self;
        }

        while (1) {
            $middle = (($right + $left) >> 1);
            $item   = $self->[$middle];
            $cmp    = CORE::int($item cmp $obj) || last;

            if ($cmp < 0) {
                $left = $middle + 1;
                if ($left > $right) {
                    ++$middle;
                    last;
                }
            }
            else {
                $right = $middle - 1;
                $left > $right && last;
            }
        }

        CORE::splice(@$self, $middle, 0, $obj);
        $self;
    }

    sub compact {
        my ($self) = @_;
        bless([grep { defined($_) } @$self], __PACKAGE__);
    }

    sub unique {
        my ($self) = @_;

        my @sorted = do {
            my @arr;
            foreach my $i (0 .. $#$self) {
                CORE::push(@arr, [$i, $self->[$i]]);
            }
            CORE::sort { $a->[1] cmp $b->[1] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            $unique[$sorted[$i][0]] = $sorted[$i][1];
            ++$i while ($i < $max and $sorted[$i][1] eq $sorted[$i + 1][1]);
        }

        bless [grep { defined } @unique], __PACKAGE__;
    }

    *uniq     = \&unique;
    *distinct = \&unique;

    sub last_unique {
        my ($self) = @_;

        my @sorted = do {
            my @arr;
            foreach my $i (0 .. $#$self) {
                CORE::push(@arr, [$i, $self->[$i]]);
            }
            CORE::sort { $a->[1] cmp $b->[1] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            ++$i while ($i < $max and $sorted[$i][1] eq $sorted[$i + 1][1]);
            $unique[$sorted[$i][0]] = $sorted[$i][1];
        }

        bless [grep { defined } @unique], __PACKAGE__;
    }

    *last_uniq = \&last_unique;

    sub uniq_by {
        my ($self, $block) = @_;

        my @sorted = do {
            my @arr;
            my $i = -1;
            foreach my $item (@$self) {
                CORE::push(@arr, [++$i, $item, scalar $block->run($item)]);
            }
            CORE::sort { $a->[2] cmp $b->[2] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            $unique[$sorted[$i][0]] = $sorted[$i][1];
            ++$i while ($i < $max and $sorted[$i][2] eq $sorted[$i + 1][2]);
        }

        bless [grep { defined } @unique], __PACKAGE__;
    }

    *unique_by = \&uniq_by;

    sub last_uniq_by {
        my ($self, $block) = @_;

        my @sorted = do {
            my @arr;
            my $i = -1;
            foreach my $item (@$self) {
                CORE::push(@arr, [++$i, $item, scalar $block->run($item)]);
            }
            CORE::sort { $a->[2] cmp $b->[2] } @arr;
        };

        my @unique;
        my $max = $#sorted;

        for (my $i = 0 ; $i <= $max ; $i++) {
            ++$i while ($i < $max and $sorted[$i][2] eq $sorted[$i + 1][2]);
            $unique[$sorted[$i][0]] = $sorted[$i][1];
        }

        bless [grep { defined } @unique], __PACKAGE__;
    }

    *last_unique_by = \&last_uniq_by;

    sub abbrev {
        my ($self, $block) = @_;

        my $tail     = {};                # some unique value
        my $callback = defined($block);

        my %table;
        foreach my $sub_array (@$self) {
            my $ref = \%table;
            foreach my $item (@$sub_array) {
                $ref = $ref->{$item} //= {};
            }
            $ref->{$tail} = $sub_array;
        }

        my @abbrev;
        sub {
            my ($hash) = @_;

            foreach my $key (my @keys = CORE::sort keys %{$hash}) {
                next if $key eq $tail;
                __SUB__->($hash->{$key});

                if ($#keys > 0) {
                    my $count = 0;
                    my $ref   = delete $hash->{$key};
                    while (my ($key) = CORE::each %{$ref}) {
                        if ($key eq $tail) {

                            if ($callback) {
                                $block->run(@{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]);
                            }
                            else {
                                CORE::push(@abbrev, bless([@{$ref->{$key}}[0 .. $#{$ref->{$key}} - $count]], __PACKAGE__));
                            }

                            last;
                        }
                        $ref = $ref->{$key};
                        $count++;
                    }
                }
            }
          }
          ->(\%table);

        bless \@abbrev, __PACKAGE__;
    }

    *abbreviations = \&abbrev;

    sub contains {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            foreach my $item (@$self) {
                if ($obj->run($item)) {
                    return (Sidef::Types::Bool::Bool::TRUE);
                }
            }

            return (Sidef::Types::Bool::Bool::FALSE);
        }

        foreach my $item (@$self) {
            if ($item eq $obj) {
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub contains_type {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        foreach my $item (@$self) {
            if (ref($item) eq $ref || UNIVERSAL::isa($item, $ref)) {
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        return (Sidef::Types::Bool::Bool::FALSE);
    }

    sub contains_any {
        my ($self, $array) = @_;

        foreach my $item (@$array) {
            if ($self->contains($item)) {
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    sub contains_all {
        my ($self, $array) = @_;

        foreach my $item (@$array) {
            unless ($self->contains($item)) {
                return (Sidef::Types::Bool::Bool::FALSE);
            }
        }

        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub shift {
        my ($self, $num) = @_;

        if (defined $num) {
            return bless([CORE::splice(@$self, 0, $num)], __PACKAGE__);
        }

        shift(@$self);
    }

    *drop_first = \&shift;
    *drop_left  = \&shift;

    sub pop {
        my ($self, $num) = @_;

        if (defined $num) {
            $num = CORE::int($num);
            $num = $num > $#$self ? 0 : @$self - $num;
            return bless([CORE::splice(@$self, $num)], __PACKAGE__);
        }

        pop(@$self);
    }

    *drop_last  = \&pop;
    *drop_right = \&pop;

    sub pop_rand {
        my ($self) = @_;
        $#$self > -1 || return undef;
        CORE::splice(@$self, CORE::rand(scalar @$self), 1);
    }

    sub delete_index {
        my ($self, $offset) = @_;
        CORE::splice(@$self, $offset, 1);
    }

    *pop_at    = \&delete_index;
    *delete_at = \&delete_index;

    sub splice {
        my ($self, $offset, $length, @objects) = @_;

        $offset = defined($offset) ? CORE::int($offset) : 0;
        $length = defined($length) ? CORE::int($length) : scalar(@$self);

        bless([CORE::splice(@$self, $offset, $length, @objects)], __PACKAGE__);
    }

    sub take_right {
        my ($self, $amount) = @_;

        my $end = $#$self;
        $amount = CORE::int($amount);
        $amount = $end > ($amount - 1) ? $amount - 1 : $end;

        bless [@$self[$end - $amount .. $end]], __PACKAGE__;
    }

    sub take_left {
        my ($self, $amount) = @_;

        my $end = $#$self;
        $amount = CORE::int($amount);
        $amount = $end > ($amount - 1) ? $amount - 1 : $end;

        bless [@$self[0 .. $amount]], __PACKAGE__;
    }

    sub sort {
        my ($self, $code) = @_;

        if (defined $code) {
            return bless([CORE::sort { scalar $code->run($a, $b) } @$self], __PACKAGE__);
        }

        bless [CORE::sort { $a cmp $b } @$self], __PACKAGE__;
    }

    sub sort_by {
        my ($self, $code) = @_;
        bless [map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [$_, scalar $code->run($_)] } @$self], __PACKAGE__;
    }

    sub cmp {
        my ($self, $arg) = @_;

        my $l1 = $#$self;
        my $l2 = $#$arg;

        my $cmp;
        my $min = $l1 < $l2 ? $l1 : $l2;

        foreach my $i (0 .. $min) {
            if ($cmp = CORE::int($self->[$i] cmp $arg->[$i])) {
                return ($cmp < 0 ? Sidef::Types::Number::Number::MONE : Sidef::Types::Number::Number::ONE);
            }
        }

            $l1 == $l2 ? Sidef::Types::Number::Number::ZERO
          : $l1 < $l2  ? Sidef::Types::Number::Number::MONE
          :              Sidef::Types::Number::Number::ONE;
    }

    # Inserts an object between each element
    sub join_insert {
        my ($self, $delim_obj) = @_;

        my $end = $#$self;

        $end >= 0
          || return bless([], __PACKAGE__);

        my @array = $self->[0];
        foreach my $i (1 .. $end) {
            CORE::push(@array, $delim_obj, $self->[$i]);
        }

        bless \@array, __PACKAGE__;
    }

    sub combinations {
        my ($self, $k, $block) = @_;

        $k = CORE::int($k);

        if (defined($block)) {

            if ($k == 0) {
                $block->run();
                return $self;
            }

            my $n = @$self;
            return $self if ($k < 0 or $k > $n or $n == 0);

            my @c = (0 .. $k - 1);

            while (1) {
                $block->run(@$self[@c]);
                next if ($c[$k - 1]++ < $n - 1);
                my $i = $k - 2;
                $i-- while ($i >= 0 && $c[$i] >= $n - ($k - $i));
                last if $i < 0;
                $c[$i]++;
                while (++$i < $k) { $c[$i] = $c[$i - 1] + 1; }
            }

            return $self;
        }

        ($k == 0)
          && return bless [bless [], __PACKAGE__], __PACKAGE__;

        my $n = @$self;

        ($k < 0 or $k > $n or $n == 0)
          && return bless([], __PACKAGE__);

        my @c = (0 .. $k - 1);
        my @result;

        while (1) {
            CORE::push(@result, bless([@$self[@c]], __PACKAGE__));
            next if ($c[$k - 1]++ < $n - 1);
            my $i = $k - 2;
            $i-- while ($i >= 0 && $c[$i] >= $n - ($k - $i));
            last if $i < 0;
            $c[$i]++;
            while (++$i < $k) { $c[$i] = $c[$i - 1] + 1; }
        }

        bless \@result, __PACKAGE__;
    }

    *each_comb = \&combinations;

    sub permutations {
        my ($self, $code) = @_;

        my @idx = 0 .. $#$self;

        if (not @idx) {

            if (defined $code) {
                $code->run();
                return $self;
            }

            return bless [bless [], __PACKAGE__], __PACKAGE__;
        }

        if (defined($code)) {
            my @perm;

            while (1) {
                @perm = @$self[@idx];

                my $p = $#idx;
                --$p while $idx[$p - 1] > $idx[$p];

                my $q = $p || do {
                    $code->run(@perm);
                    return $self;
                };

                CORE::push(@idx, CORE::reverse CORE::splice @idx, $p);
                ++$q while $idx[$p - 1] > $idx[$q];
                @idx[$p - 1, $q] = @idx[$q, $p - 1];

                $code->run(@perm);
            }

            return $self;
        }

        my @array;
        while (1) {
            CORE::push(@array, bless([@$self[@idx]], __PACKAGE__));
            my $p = $#idx;
            --$p while $idx[$p - 1] > $idx[$p];
            my $q = $p || (return bless(\@array, __PACKAGE__));
            CORE::push(@idx, CORE::reverse CORE::splice @idx, $p);
            ++$q while $idx[$p - 1] > $idx[$q];
            @idx[$p - 1, $q] = @idx[$q, $p - 1];
        }
    }

    *permute     = \&permutations;    # deprecated
    *permutation = \&permutations;    # deprecated
    *each_perm   = \&permutations;

    sub cartesian {
        my ($self, $block) = @_;

        my ($more, @arrs, @lengths);

        foreach my $arr (@$self) {
            my @arr = @$arr;

            if (@arr) {
                $more ||= 1;
            }
            else {
                $more = 0;
                last;
            }

            push @arrs,    \@arr;
            push @lengths, $#arr;
        }

        my @indices = (0) x @arrs;
        my (@temp, @cartesian);

      OUTER: while ($more) {
            @temp = @indices;

            for (my $i = $#indices ; $i >= 0 ; --$i) {
                if ($indices[$i] == $lengths[$i]) {
                    $indices[$i] = 0;
                    $more = 0 if $i == 0;
                }
                else {
                    ++$indices[$i];
                    last;
                }
            }

            if (defined($block)) {
                $block->run(map { @$_ ? $_->[CORE::shift(@temp)] : () } @arrs);
            }
            else {
                push @cartesian, bless [map { @$_ ? $_->[CORE::shift(@temp)] : () } @arrs], __PACKAGE__;
            }
        }

        defined($block)
          ? $self
          : bless(\@cartesian, __PACKAGE__);
    }

    sub zip {
        my ($self, $block) = @_;

        my @arrays = @{$self};
        my $min = List::Util::min(map { scalar @$_ } @arrays);

        my @first = @{CORE::shift(@arrays)};

        my @new_array;
        foreach my $i (0 .. $min - 1) {

            my @tmp = ($first[$i], map { $_->[$i] } @arrays);

            if (defined($block)) {
                $block->run(@tmp);
            }
            else {
                CORE::push(@new_array, bless(\@tmp, __PACKAGE__));
            }
        }

        defined($block) ? $self : bless(\@new_array, __PACKAGE__);
    }

    sub mzip {
        my ($self, $block) = @_;

        my @arrays = @{$self};
        my $min = List::Util::min(map { scalar @$_ } @arrays);

        my @first = @{CORE::shift(@arrays)};

        my @new_array;
        foreach my $i (0 .. $#first) {

            my @tmp = ($first[$i], map { $_->[$i % $min] } @arrays);

            if (defined($block)) {
                $block->run(@tmp);
            }
            else {
                CORE::push(@new_array, bless(\@tmp, __PACKAGE__));
            }
        }

        defined($block) ? $self : bless(\@new_array, __PACKAGE__);
    }

    sub pack {
        my ($self, $format) = @_;
        Sidef::Types::String::String->new(CORE::pack("$format", @$self));
    }

    sub push {
        my ($self, @args) = @_;
        CORE::push(@$self, @args);
        $self;
    }

    *append = \&push;

    sub unshift {
        my ($self, @args) = @_;
        CORE::unshift(@$self, @args);
        $self;
    }

    *prepend = \&unshift;

    sub rotate {
        my ($self, $num) = @_;

        $num = CORE::int($num);
        $num %= ($#$self + 1);
        return bless([@$self], __PACKAGE__) if $num == 0;

        my @array = @$self;
        CORE::unshift(@array, CORE::splice(@array, $num));
        bless \@array, __PACKAGE__;
    }

    # Join the array as string
    sub join {
        my ($self, $delim, $block) = @_;
        $delim = defined($delim) ? "$delim" : '';

        if (defined $block) {
            return Sidef::Types::String::String->new(CORE::join($delim, map { scalar $block->run($_) } @$self));
        }

        Sidef::Types::String::String->new(CORE::join($delim, @$self));
    }

    sub join_bytes {
        my ($self, $encoding) = @_;
        state $x = require Encode;
        $encoding = defined($encoding) ? "$encoding" : 'UTF-8';
        Sidef::Types::String::String->new(
            eval {
                Encode::decode($encoding, CORE::join('', map { CORE::chr($_) } @$self));
              } // return
        );
    }

    *encode = \&join_bytes;    # somehow, I got this alias wrong...
    *decode = \&join_bytes;

    sub reverse {
        my ($self) = @_;
        bless [CORE::reverse @$self], __PACKAGE__;
    }

    *flip = \&reverse;

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new(@$self);
    }

    *to_h = \&to_hash;

    sub to_a {
        $_[0];
    }

    *to_array = \&to_a;

    sub copy {
        my ($self) = @_;
        state $x = warn "[WARNING] Array.copy() is deprecated: use .clone() or .dclone() instead!\n";
        $self->dclone;
    }

    sub delete_first {
        my ($self, $obj) = @_;

        foreach my $i (0 .. $#$self) {
            if ($self->[$i] eq $obj) {
                CORE::splice(@$self, $i, 1);
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    *remove_first = \&delete_first;

    sub delete_last {
        my ($self, $obj) = @_;

        for (my $i = $#$self ; $i >= 0 ; $i--) {
            if ($self->[$i] eq $obj) {
                CORE::splice(@$self, $i, 1);
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    *remove_last = \&delete_last;

    sub delete {
        my ($self, $obj) = @_;

        for (my $i = $#$self ; $i >= 0 ; --$i) {
            if ($self->[$i] eq $obj) {
                CORE::splice(@$self, $i, 1);
            }
        }

        $self;
    }

    *remove = \&delete;

    sub delete_if {
        my ($self, $code) = @_;

        for (my $i = 0 ; $i <= $#$self ; $i++) {
            if ($code->run($self->[$i])) {
                CORE::splice(@$self, $i--, 1);
            }
        }

        $self;
    }

    *remove_if = \&delete_if;

    sub delete_first_if {
        my ($self, $code) = @_;

        foreach my $i (0 .. $#$self) {
            if ($code->run($self->[$i])) {
                CORE::splice(@$self, $i, 1);
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    *remove_first_if = \&delete_first_if;

    sub delete_last_if {
        my ($self, $code) = @_;

        for (my $i = $#$self ; $i >= 0 ; --$i) {
            my $item = $self->[$i];
            if ($code->run($item)) {
                CORE::splice(@$self, $i, 1);
                return (Sidef::Types::Bool::Bool::TRUE);
            }
        }

        (Sidef::Types::Bool::Bool::FALSE);
    }

    *remove_last_if = \&delete_last_if;

    sub to_list { @{$_[0]} }

    sub getopt {
        my ($self, %opts) = @_;

        state $x = require Getopt::Long;

        my @argv = map { "$_" } @$self;
        my @opts = CORE::keys %opts;

        my %parsed;
        Getopt::Long::GetOptionsFromArray(\@argv, \%parsed, @opts);

        my %lookup = map {
            my ($name) = Getopt::Long::ParseOptionSpec($_, \my %info);
            defined($name) ? ($name => {obj => $opts{$_}, type => $info{$name}[0]}) : ();
        } @opts;

        foreach my $key (CORE::keys %parsed) {

            my $rec  = $lookup{$key};
            my $obj  = $rec->{obj};
            my $type = $rec->{type};

            if (ref($obj) eq 'REF' or ref($obj) eq 'SCALAR') {
                my $ref = ref($$obj);

                # Determine the type for undefined references
                if ($ref eq '') {
                    if ($type eq 'i' or $type eq 'f') {
                        $ref = 'Sidef::Types::Number::Number';
                    }
                    elsif ($type eq '') {
                        $ref = 'Sidef::Types::Bool::Bool';
                    }
                    else {
                        $ref = 'Sidef::Types::String::String';
                    }
                }

                if (   $ref eq 'Sidef::Types::String::String'
                    or $ref eq 'Sidef::Types::Number::Number') {
                    $$obj = $ref->new($parsed{$key});
                }
                elsif ($ref eq 'Sidef::Types::Bool::Bool') {
                    $$obj =
                      $parsed{$key}
                      ? Sidef::Types::Bool::Bool::TRUE
                      : Sidef::Types::Bool::Bool::FALSE;
                }
                else {
                    if ($type eq '') {
                        $$obj = $ref->new(
                                          $parsed{$key}
                                          ? Sidef::Types::Bool::Bool::TRUE
                                          : Sidef::Types::Bool::Bool::FALSE
                                         );
                    }
                    elsif ($type eq 'i' or $type eq 'f') {
                        $$obj = $ref->new(Sidef::Types::Number::Number->new($parsed{$key}));
                    }
                    else {
                        $$obj = $ref->new(Sidef::Types::String::String->new($parsed{$key}));
                    }
                }
            }
            else {
                $obj->call();
            }
        }

        bless [map { Sidef::Types::String::String->new($_) } @argv], __PACKAGE__;
    }

    sub _dump {
        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              and return $addr{$refaddr};

            $addr{$refaddr} = "Array(#`($refaddr)...)";

            my $s;

            '['
              . CORE::join(', ',
                           map { ref($_) && ($s = UNIVERSAL::can($_, 'dump')) ? $s->($_) : defined($_) ? $_ : 'nil' } @$obj)
              . ']';
        };

        local *Sidef::Types::Array::Array::dump = $sub;
        $sub->($_[0]);
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    *to_s = \&dump;

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '<<'}  = \&append;
        *{__PACKAGE__ . '::' . '«'}  = \&append;
        *{__PACKAGE__ . '::' . '>>'}  = \&assign_to;
        *{__PACKAGE__ . '::' . '»'}  = \&assign_to;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;

        *{__PACKAGE__ . '::' . '++'} = sub {
            my ($self, $obj) = @_;
            CORE::push(@$self, $obj);
            $self;
        };

        *{__PACKAGE__ . '::' . '--'} = sub {
            my ($self) = @_;
            CORE::pop(@$self);
            $self;
        };
    }

};

1
