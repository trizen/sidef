package Sidef::Types::Set::Bag {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Set::Set
    );

    use overload
      q{bool} => sub { scalar(CORE::keys(%{$_[0]})) },
      q{0+}   => sub { scalar(CORE::keys(%{$_[0]})) },
      q{""}   => \&_dump;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    my $serialize = sub {
        my ($obj) = @_;
        my $key = ref($obj) ? (UNIVERSAL::can($obj, 'dump') ? $obj->dump : $obj) : ($obj // 'nil');
        "$key";
    };

    sub new {
        my (undef, @objects) = @_;

        my %bag;
        foreach my $obj (@objects) {
            ($bag{$serialize->($obj)} //= {value => $obj})->{count}++;
        }

        bless \%bag;
    }

    *call = \&new;

    sub get_value {
        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            CORE::exists($addr{$refaddr})
              && return $addr{$refaddr};

            my @bag;
            $addr{$refaddr} = \@bag;

            foreach my $hash (CORE::values(%$obj)) {

                my $v = $hash->{value};
                my $c = $hash->{count};

                CORE::push(@bag, ((index(ref($v), 'Sidef::') == 0) ? $v->get_value : $v) x $c);
            }

            $addr{$refaddr};
        };

        no warnings 'redefine';
        local *Sidef::Types::Set::Bag::get_value = $sub;
        $sub->($_[0]);
    }

    sub concat {
        my ($A, $B) = @_;

        if (ref($A) eq ref($B)) {

            my %C = map { $_ => {%{$A->{$_}}} } CORE::keys(%$A);

            foreach my $key (CORE::keys(%$B)) {
                ($C{$key} //= {value => $B->{$key}{value}})->{count} += $B->{$key}{count};
            }

            return bless \%C, ref($A);
        }

        my %C   = %$A;
        my $key = $serialize->($B);
        ($C{$key} //= {value => $B})->{count}++;
        bless \%C, ref($A);
    }

    sub union {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_bag;
        }

        my %C = map { $_ => {%{$A->{$_}}} } CORE::keys(%$A);

        foreach my $key (CORE::keys(%$B)) {
            if (CORE::exists($C{$key})) {

                my $elem = $C{$key};
                my $c1   = $elem->{count};
                my $c2   = $B->{$key}{count};

                if ($c2 > $c1) {
                    $elem->{count} = $c2;
                }
            }
            else {
                $C{$key} = {%{$B->{$key}}};
            }
        }

        bless \%C, ref($A);
    }

    *or = \&union;

    sub intersection {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_bag;
        }

        my %C;

        foreach my $key (CORE::keys(%$A)) {
            if (CORE::exists($B->{$key})) {

                my $h_A = $A->{$key};
                my $h_B = $B->{$key};

                my $c_A = $h_A->{count};
                my $c_B = $h_B->{count};

                $C{$key} = {
                            value => $h_A->{value},
                            count => ($c_A < $c_B ? $c_A : $c_B),
                           };
            }
        }

        bless \%C, ref($A);
    }

    *and = \&intersection;

    sub difference {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_bag;
        }

        my %C;

        foreach my $key (CORE::keys(%$A)) {
            if (CORE::exists($B->{$key})) {

                my $h_A = $A->{$key};
                my $h_B = $B->{$key};

                my $c_A = $h_A->{count};
                my $c_B = $h_B->{count};

                if ($c_A > $c_B) {
                    $C{$key} = {
                                value => $h_A->{value},
                                count => $c_A - $c_B,
                               };
                }
            }
            else {
                $C{$key} = {%{$A->{$key}}};
            }
        }

        bless \%C, ref($A);
    }

    *sub  = \&difference;
    *diff = \&difference;

    sub symmetric_difference {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_bag;
        }

        my %C;

        foreach my $key (CORE::keys(%$A)) {
            if (CORE::exists($B->{$key})) {

                my $h_A = $A->{$key};
                my $h_B = $B->{$key};

                my $c_A = $h_A->{count};
                my $c_B = $h_B->{count};

                if ($c_A > $c_B) {
                    $C{$key} = {
                                value => $h_A->{value},
                                count => $c_A - $c_B,
                               };
                }
            }
            else {
                $C{$key} = {%{$A->{$key}}};
            }
        }

        foreach my $key (CORE::keys(%$B)) {
            if (CORE::exists($A->{$key})) {

                my $h_A = $A->{$key};
                my $h_B = $B->{$key};

                my $c_A = $h_A->{count};
                my $c_B = $h_B->{count};

                if ($c_B > $c_A) {
                    $C{$key} = {
                                value => $h_A->{value},
                                count => $c_B - $c_A,
                               };
                }
            }
            else {
                $C{$key} = {%{$B->{$key}}};
            }
        }

        bless \%C, ref($A);
    }

    *xor     = \&symmetric_difference;
    *symdiff = \&symmetric_difference;

    sub append {
        my ($self, @objects) = @_;

        foreach my $obj (@objects) {
            my $key = $serialize->($obj);
            ($self->{$key} //= {value => $obj})->{count}++;
        }

        $self;
    }

    *add  = \&append;
    *push = \&append;

    sub replace_pair {
        my ($self, $obj, $n) = @_;

        my $count = CORE::int($n);
        my $key   = $serialize->($obj);

        $self->{$key} = {
                         value => $obj,
                         count => $count,
                        };

        $self;
    }

    *set_kv      = \&replace_pair;
    *update_kv   = \&replace_pair;
    *update_pair = \&replace_pair;

    sub replace_pairs {
        my ($self, @pairs) = @_;

        while (@pairs) {
            my ($key, $value) = CORE::splice(@pairs, 0, 2);
            $self->replace_pair($key, $value);
        }

        $self;
    }

    *set_kvs      = \&replace_pairs;
    *update_kvs   = \&replace_pairs;
    *update_pairs = \&replace_pairs;

    sub add_pair {
        my ($self, $obj, $n) = @_;

        my $count = CORE::int($n);
        my $key   = $serialize->($obj);

        if (CORE::exists($self->{$key})) {
            $self->{$key}{count} += $count;
        }
        else {
            $self->{$key} = {
                             value => $obj,
                             count => $count,
                            };
        }

        $self;
    }

    *add_kv      = \&add_pair;
    *push_kv     = \&add_pair;
    *append_kv   = \&add_pair;
    *push_pair   = \&add_pair;
    *append_pair = \&add_pair;

    sub add_pairs {
        my ($self, @pairs) = @_;

        while (@pairs) {
            my ($key, $value) = CORE::splice(@pairs, 0, 2);
            $self->add_pair($key, $value);
        }

        $self;
    }

    *add_kvs      = \&add_pairs;
    *push_kvs     = \&add_pairs;
    *append_kvs   = \&add_pairs;
    *push_pairs   = \&add_pairs;
    *append_pairs = \&add_pairs;

    sub pop {
        my ($self) = @_;

        my $key  = (CORE::keys(%$self))[-1] // return undef;
        my $elem = $self->{$key};

        if ($elem->{count} > 1) {
            --$elem->{count};
        }
        else {
            CORE::delete($self->{$key});
        }

        return $elem->{value};
    }

    sub shift {
        my ($self) = @_;

        my $key  = (CORE::keys(%$self))[0] // return undef;
        my $elem = $self->{$key};

        if ($elem->{count} > 1) {
            --$elem->{count};
        }
        else {
            CORE::delete($self->{$key});
        }

        return $elem->{value};
    }

    sub delete {
        my ($self, @objects) = @_;

        my @values;
        foreach my $obj (@objects) {
            my $key = $serialize->($obj);

            if (CORE::exists($self->{$key})) {
                my $elem = $self->{$key};
                push @values, $elem->{value};

                if ($elem->{count} > 1) {
                    --$elem->{count};
                }
                else {
                    CORE::delete($self->{$key});
                }
            }
        }

        return @values;
    }

    *remove  = \&delete;
    *discard = \&delete;

    sub delete_all {
        my ($self, @objects) = @_;
        map { ($_->{value}) x $_->{count} } CORE::delete(@{$self}{map { $serialize->($_) } @objects});
    }

    *remove_all  = \&delete_all;
    *discard_all = \&delete_all;

    sub delete_key {
        my ($self, $obj) = @_;
        my $key  = $serialize->($obj);
        my $elem = CORE::delete($self->{$key}) // return undef;
        return $elem->{value};
    }

    *remove_key  = \&delete_key;
    *discard_key = \&delete_key;

    sub map {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {

            my $elem = $self->{$key};

            foreach my $value ($block->run($elem->{value})) {
                ($new{$serialize->($value)} //= {value => $value})->{count} += $elem->{count};
            }
        }

        bless \%new, ref($self);
    }

    sub map_2d {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::ARRAY_IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {

            my $elem = $self->{$key};

            foreach my $value ($block->run(@{$elem->{value}})) {
                ($new{$serialize->($value)} //= {value => $value})->{count} += $elem->{count};
            }
        }

        bless \%new, ref($self);
    }

    sub map_kv {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::LIST_IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {

            my $elem  = $self->{$key};
            my @pairs = $block->run($elem->{value}, Sidef::Types::Number::Number::_set_int($elem->{count}));

            while (@pairs) {
                my $k = CORE::shift(@pairs);
                my $v = CORE::int(CORE::shift(@pairs));

                if ($v > 0) {
                    $new{$serialize->($k)} = {value => $k, count => $v};
                }
            }
        }

        bless \%new, ref($self);
    }

    sub collect {
        my ($self, $block) = @_;

        my @array;
        foreach my $elem (CORE::values(%$self)) {
            CORE::push(@array, ($block->run($elem->{value})) x $elem->{count});
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub grep {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {

            my $elem  = $self->{$key};
            my $value = $elem->{value};

            if ($block->run($value)) {
                $new{$key} = {
                              value => $value,
                              count => $elem->{count},
                             };
            }
        }

        bless \%new, ref($self);
    }

    *select = \&grep;

    sub grep_2d {
        my ($self, $block) = @_;

        my %new;
        foreach my $key (CORE::keys(%$self)) {

            my $elem  = $self->{$key};
            my $value = $elem->{value};

            if ($block->run(@$value)) {
                $new{$key} = {
                              value => $value,
                              count => $elem->{count},
                             };
            }
        }

        bless \%new, ref($self);
    }

    sub grep_kv {
        my ($self, $block) = @_;

        my %new;
        foreach my $key (CORE::keys(%$self)) {

            my $elem  = $self->{$key};
            my $value = $elem->{value};

            if ($block->run($value, Sidef::Types::Number::Number::_set_int($elem->{count}))) {
                $new{$key} = {
                              value => $value,
                              count => $elem->{count},
                             };
            }
        }

        bless \%new, ref($self);
    }

    sub count_by {
        my ($self, $block) = @_;

        my $count = 0;
        foreach my $elem (CORE::values(%$self)) {
            if ($block->run($elem->{value})) {
                $count += $elem->{count};
            }
        }

        Sidef::Types::Number::Number::_set_int($count);
    }

    sub count {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            goto &count_by;
        }

        my $key = $serialize->($obj);
        if (CORE::exists($self->{$key})) {
            return Sidef::Types::Number::Number::_set_int($self->{$key}{count});
        }

        return Sidef::Types::Number::Number::ZERO;
    }

    *get = \&count;

    sub delete_if {
        my ($self, $block) = @_;

        foreach my $key (CORE::keys(%$self)) {
            if ($block->run($self->{$key}{value})) {
                CORE::delete($self->{$key});
            }
        }

        $self;
    }

    sub delete_first_if {
        my ($self, $block) = @_;

        foreach my $key (CORE::keys(%$self)) {
            if ($block->run($self->{$key})) {

                my $elem = $self->{$key};

                if ($elem->{count} > 1) {
                    --$elem->{count};
                }
                else {
                    CORE::delete($self->{$key});
                }

                last;
            }
        }

        $self;
    }

    sub freq {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                    map { Sidef::Types::Array::Array->new([$_->{value}, Sidef::Types::Number::Number::_set_int($_->{count})]) }
                      CORE::values(%$self));
    }

    sub most_common {
        my ($self, $n) = @_;

        my @sorted = sort { $b->{count} <=> $a->{count} } CORE::values(%$self);
        my @top    = splice(@sorted, 0, CORE::int($n));

        Sidef::Types::Array::Array->new(
             map { Sidef::Types::Array::Array->new([$_->{value}, Sidef::Types::Number::Number::_set_int($_->{count})]) } @top);
    }

    *top = \&most_common;

    sub uniq {
        my ($self) = @_;

        my %new;

        foreach my $key (CORE::keys(%$self)) {
            $new{$key} = {
                          value => $self->{$key}{value},
                          count => 1
                         };
        }

        bless \%new, ref($self);
    }

    *unique = \&uniq;

    sub iter {
        my ($self) = @_;

        my $i      = 0;
        my @values = CORE::values(%$self);

        Sidef::Types::Block::Block->new(
            code => sub {
                my $elem = $values[$i++] // return undef;
                Sidef::Types::Array::Array->new([$elem->{value}, Sidef::Types::Number::Number::_set_int($elem->{count})]);
            }
        );
    }

    sub each {
        my ($self, $block) = @_;

        foreach my $elem (CORE::values(%$self)) {
            my $value = $elem->{value};
            foreach my $i (1 .. $elem->{count}) {
                $block->run($value);
            }
        }

        $self;
    }

    sub each_2d {
        my ($self, $block) = @_;

        foreach my $elem (CORE::values(%$self)) {
            my $value = $elem->{value};
            foreach my $i (1 .. $elem->{count}) {
                $block->run(@$value);
            }
        }

        $self;
    }

    sub each_kv {
        my ($self, $block) = @_;

        foreach my $elem (CORE::values(%$self)) {
            $block->run($elem->{value}, Sidef::Types::Number::Number::_set_int($elem->{count}));
        }

        $self;
    }

    sub length {
        my ($self) = @_;

        my $len = 0;
        foreach my $elem (CORE::values(%$self)) {
            $len += $elem->{count};
        }

        Sidef::Types::Number::Number::_set_int($len);
    }

    *len  = \&length;
    *size = \&length;

    sub elems {
        my ($self) = @_;
        Sidef::Types::Number::Number::_set_int(scalar CORE::keys(%$self));
    }

    *keys_len = \&elems;

    sub sort_by {
        my ($self, $block) = @_;
        $self->expand->sort_by($block);
    }

    sub sort {
        my ($self, $block) = @_;
        $self->expand->sort(defined($block) ? $block : ());
    }

    sub min {
        my ($self) = @_;
        $self->keys->min;
    }

    sub max {
        my ($self) = @_;
        $self->keys->max;
    }

    sub max_by {
        my ($self, $block) = @_;
        $self->keys->max_by($block);
    }

    sub min_by {
        my ($self, $block) = @_;
        $self->keys->min_by($block);
    }

    sub has {
        my ($self, $obj) = @_;
        my $key = $serialize->($obj);

        CORE::exists($self->{$key})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *haskey   = \&has;
    *has_key  = \&has;
    *exists   = \&has;
    *include  = \&has;
    *includes = \&has;
    *contain  = \&has;
    *contains = \&has;

    sub is_subset {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_bag;
        }

        foreach my $key (CORE::keys(%$A)) {
            if (!CORE::exists($B->{$key}) or $B->{$key}{count} < $A->{$key}{count}) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_superset {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_bag;
        }

        foreach my $key (CORE::keys(%$B)) {
            if (!CORE::exists($A->{$key}) or $A->{$key}{count} < $B->{$key}{count}) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub contains_all {
        my ($self, @objects) = @_;
        __PACKAGE__->new(@objects)->is_subset($self);
    }

    sub join {
        my ($self, @rest) = @_;
        $self->to_a->join(@rest);
    }

    sub to_a {
        my ($self) = @_;
        ref($self) || return Sidef::Types::Array::Array->new($self);
        Sidef::Types::Array::Array->new([map { ($_->{value}) x $_->{count} } CORE::values(%$self)]);
    }

    *to_array = \&to_a;
    *expand   = \&to_a;

    sub keys {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { $_->{value} } CORE::values(%$self)]);
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::Number::Number::_set_int($_->{count}) } CORE::values(%$self)]);
    }

    sub pairs {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                      [map { Sidef::Types::Array::Pair->new($_->{value}, Sidef::Types::Number::Number::_set_int($_->{count})) }
                         CORE::values(%$self)
                      ]
        );
    }

    *kv = \&pairs;

    sub to_list {
        my ($self) = @_;
        map { ($_->{value}) x $_->{count} } CORE::values(%$self);
    }

    sub to_set {
        my ($self) = @_;
        bless {map { $_ => $self->{$_}{value} } CORE::keys(%$self)}, 'Sidef::Types::Set::Set';
    }

    sub to_bag {
        $_[0];
    }

    sub clone {
        my ($self) = @_;

        my %new;
        foreach my $key (CORE::keys(%$self)) {
            $new{$key} = {%{$self->{$key}}};
        }

        bless \%new, ref($self);
    }

    sub eq {
        my ($self, $hash) = @_;

        my %addr;    # support for cyclic references

        my $sub = sub {
            my ($h1, $h2) = @_;

            scalar(CORE::keys(%$h1)) == scalar(CORE::keys(%$h2))
              or return (Sidef::Types::Bool::Bool::FALSE);

            my $refaddr1 = Scalar::Util::refaddr($h1);
            my $refaddr2 = Scalar::Util::refaddr($h2);

            if ($refaddr1 == $refaddr2) {
                return Sidef::Types::Bool::Bool::TRUE;
            }

            CORE::exists($addr{$refaddr1})
              and return $addr{$refaddr1};

            CORE::exists($addr{$refaddr2})
              and return $addr{$refaddr2};

            $addr{$refaddr1} = Sidef::Types::Bool::Bool::FALSE;
            $addr{$refaddr2} = Sidef::Types::Bool::Bool::FALSE;

            foreach my $key (CORE::keys(%$h1)) {

                CORE::exists($h2->{$key})
                  or return (Sidef::Types::Bool::Bool::FALSE);

                my $t1 = $h1->{$key};
                my $t2 = $h2->{$key};

                ($t1->{count} == $t2->{count} and $t1->{value} eq $t2->{value})
                  or return (Sidef::Types::Bool::Bool::FALSE);
            }

            (Sidef::Types::Bool::Bool::TRUE);
        };

        no strict 'refs';
        no warnings 'redefine';

        local *{__PACKAGE__ . '::' . 'eq'} = $sub;
        local *{__PACKAGE__ . '::' . '=='} = $sub;
        $sub->($self, $hash);
    }

    sub ne {
        my ($self, $obj) = @_;
        $self->eq($obj)->not;
    }

    sub _dump {
        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            CORE::exists($addr{$refaddr})
              and return $addr{$refaddr};

            my @values = CORE::values(%$obj);

            $addr{$refaddr} = "Bag(#`($refaddr)...)";

            my ($s, $v);
            "Bag("
              . CORE::join(
                ', ',
                map { ((ref($v = $_->{value}) && ($s = UNIVERSAL::can($v, 'dump'))) ? $s->($v) : ($v // 'nil')) x $_->{count} }
                             @values
                          )
              . ')';
        };

        no warnings 'redefine';
        local *Sidef::Types::Set::Bag::dump = $sub;
        $sub->($_[0]);
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '∪'}   = \&union;
        *{__PACKAGE__ . '::' . '|'}   = \&union;
        *{__PACKAGE__ . '::' . '&'}   = \&intersection;
        *{__PACKAGE__ . '::' . '∩'}   = \&intersection;
        *{__PACKAGE__ . '::' . '-'}   = \&difference;
        *{__PACKAGE__ . '::' . '∖'}   = \&difference;
        *{__PACKAGE__ . '::' . '^'}   = \&symmetric_difference;
        *{__PACKAGE__ . '::' . '<='}  = \&is_subset;
        *{__PACKAGE__ . '::' . '≤'}   = \&is_subset;
        *{__PACKAGE__ . '::' . '>='}  = \&is_superset;
        *{__PACKAGE__ . '::' . '≥'}   = \&is_superset;
        *{__PACKAGE__ . '::' . '⊆'}   = \&is_subset;
        *{__PACKAGE__ . '::' . '⊇'}   = \&is_superset;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;
        *{__PACKAGE__ . '::' . '≡'}   = \&eq;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '≠'}   = \&ne;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '<<'}  = \&append;
        *{__PACKAGE__ . '::' . '∋'}   = \&contains;
        *{__PACKAGE__ . '::' . '∌'}   = sub { $_[0]->contains($_[1])->not };
    }
};

1
