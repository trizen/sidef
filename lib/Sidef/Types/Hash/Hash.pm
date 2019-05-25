package Sidef::Types::Hash::Hash {

    use utf8;
    use 5.016;

    use parent qw(Sidef::Object::Object);

    use overload
      q{bool} => sub { scalar(CORE::keys(%{$_[0]})) },
      q{0+}   => sub { scalar(CORE::keys(%{$_[0]})) },
      q{""}   => \&_dump;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;
    use Sidef::Types::Block::Block;

    sub new {
        my (undef, %pairs) = @_;
        bless \%pairs;
    }

    *call = \&new;

    sub get_value {
        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            CORE::exists($addr{$refaddr})
              && return $addr{$refaddr};

            my %hash;
            $addr{$refaddr} = \%hash;

            foreach my $k (CORE::keys(%$obj)) {
                my $v = $obj->{$k};
                $hash{$k} = (
                             index(ref($v), 'Sidef::') == 0
                             ? $v->get_value
                             : $v
                            );
            }

            $addr{$refaddr};
        };

        local *Sidef::Types::Hash::Hash::get_value = $sub;
        $sub->($_[0]);
    }

    sub is_empty {
        my ($self) = @_;
        CORE::keys(%$self)
          ? Sidef::Types::Bool::Bool::FALSE
          : Sidef::Types::Bool::Bool::TRUE;
    }

    sub clear {
        my ($self) = @_;
        %$self = ();
        $self;
    }

    sub items {
        my ($self, @keys) = @_;
        Sidef::Types::Array::Array->new([map { CORE::exists($self->{$_}) ? $self->{$_} : undef } @keys]);
    }

    sub item {
        my ($self, $key) = @_;
        CORE::exists($self->{$key}) ? $self->{$key} : undef;
    }

    sub fetch {
        my ($self, $key, $default) = @_;
        CORE::exists($self->{$key}) ? $self->{$key} : $default;
    }

    sub dig {
        my ($self, $key, @keys) = @_;

        my $value = $self->fetch($key) // return undef;

        foreach my $key (@keys) {
            $value = $value->fetch($key) // return undef;
        }

        $value;
    }

    sub slice {
        my ($self, @keys) = @_;
        bless {map { ($_ => $self->{$_}) } @keys}, ref($self);
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->_set_uint(scalar CORE::keys(%$self));
    }

    *len  = \&length;
    *size = \&length;

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

                $h1->{$key} eq $h2->{$key}
                  or return (Sidef::Types::Bool::Bool::FALSE);
            }

            (Sidef::Types::Bool::Bool::TRUE);
        };

        no strict 'refs';
        local *{__PACKAGE__ . '::' . 'eq'} = $sub;
        local *{__PACKAGE__ . '::' . '=='} = $sub;
        $sub->($self, $hash);
    }

    sub ne {
        my ($self, $obj) = @_;
        $self->eq($obj)->not;
    }

    sub same_keys {
        my ($self, $obj) = @_;

        if (ref($self) ne ref($obj)
            or scalar(CORE::keys(%$self)) != scalar(CORE::keys(%{$obj}))) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        foreach my $key (CORE::keys(%$self)) {
            CORE::exists($obj->{$key})
              or return (Sidef::Types::Bool::Bool::FALSE);
        }

        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub append {
        my ($self, %pairs) = @_;

        foreach my $key (CORE::keys(%pairs)) {
            $self->{$key} = $pairs{$key};
        }

        $self;
    }

    sub delete {
        my ($self, @keys) = @_;
        CORE::delete(@{$self}{@keys});
    }

    *remove = \&delete;

    sub set_keys {
        my ($self, @keys) = @_;
        undef @{$self}{@keys};
        $self;
    }

    sub map_val {
        my ($self, $block) = @_;

        my %hash;
        foreach my $key (CORE::keys(%$self)) {
            $hash{$key} = $block->run(Sidef::Types::String::String->new($key), $self->{$key});
        }

        bless \%hash, ref($self);
    }

    *map_v = \&map_val;

    sub map {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::LIST_IDENTITY;

        my %hash;
        foreach my $key (CORE::keys(%$self)) {
            my @pairs = $block->run(Sidef::Types::String::String->new($key), $self->{$key});

            while (@pairs) {
                my ($k, $v) = splice(@pairs, 0, 2);
                $hash{$k} = $v;
            }
        }

        bless \%hash, ref($self);
    }

    *map_kv = \&map;

    sub collect {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::ARRAY_IDENTITY;

        my @array;
        foreach my $key (CORE::keys(%$self)) {
            CORE::push(@array, $block->run(Sidef::Types::String::String->new($key), $self->{$key}));
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    *collect_kv = \&collect;

    sub grep {
        my ($self, $block) = @_;

        my %hash;
        foreach my $key (CORE::keys(%$self)) {
            my $value = $self->{$key};
            if ($block->run(Sidef::Types::String::String->new($key), $value)) {
                $hash{$key} = $value;
            }
        }

        bless \%hash, ref($self);
    }

    *grep_kv = \&grep;
    *select  = \&grep;

    sub grep_val {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my %hash;
        foreach my $key (CORE::keys(%$self)) {
            my $value = $self->{$key};
            if ($block->run($value)) {
                $hash{$key} = $value;
            }
        }

        bless \%hash, ref($self);
    }

    *grep_v = \&grep_val;

    sub linear_selection {
        my ($self, $keys) = @_;

        my @keys = $keys->to_list;

        my %retval;
        @{retval}{@keys} = @{$self}{@keys};
        bless \%retval;
    }

    *lsel   = \&linear_selection;
    *linsel = \&linear_selection;

    sub count_by {
        my ($self, $block) = @_;

        my $count = 0;
        foreach my $key (CORE::keys(%$self)) {
            if ($block->run(Sidef::Types::String::String->new($key), $self->{$key})) {
                ++$count;
            }
        }

        Sidef::Types::Number::Number->_set_uint($count);
    }

    sub count {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Block::Block') {
            goto &count_by;
        }

        if (CORE::exists($self->{$obj})) {
            return Sidef::Types::Number::Number::ONE;
        }

        Sidef::Types::Number::Number::ZERO;
    }

    sub delete_if {
        my ($self, $block) = @_;

        foreach my $key (CORE::keys(%$self)) {
            if ($block->run(Sidef::Types::String::String->new($key), $self->{$key})) {
                CORE::delete($self->{$key});
            }
        }

        $self;
    }

    sub concat {
        my ($self, $obj) = @_;

#<<<
            UNIVERSAL::isa($obj, __PACKAGE__)                  ? bless({%$self, %$obj}, ref($self))
          : UNIVERSAL::isa($obj, 'Sidef::Types::Array::Array') ? bless({%$self, @$obj}, ref($self))
          :                                                      bless({%$self,  $obj}, ref($self));
#>>>
    }

    *merge = \&concat;

    sub merge_values {
        my ($self, $obj) = @_;

        foreach my $key (CORE::keys(%$self)) {
            if (CORE::exists($obj->{$key})) {
                $self->{$key} = $obj->{$key};
            }
        }

        $self;
    }

    sub keys {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::String::String->new($_) } CORE::keys(%$self)]);
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([CORE::values(%$self)]);
    }

    sub each_value {
        my ($self, $block) = @_;

        foreach my $value (CORE::values(%$self)) {
            $block->run($value);
        }

        $self;
    }

    *each_v = \&each_value;

    sub each_key {
        my ($self, $block) = @_;

        foreach my $key (CORE::keys(%$self)) {
            $block->run(Sidef::Types::String::String->new($key));
        }

        $self;
    }

    *each_k = \&each_key;

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {

            foreach my $key (CORE::keys(%$self)) {
                $obj->run(Sidef::Types::String::String->new($key), $self->{$key});
            }

            return $obj;
        }

        my ($key, $value) = each(%$self);
        $key // return undef;
        (Sidef::Types::String::String->new($key), $value);
    }

    *each_kv   = \&each;
    *each_pair = \&each;

    sub sort_by {
        my ($self, $block) = @_;

        my @array;
        foreach my $key (CORE::keys(%$self)) {
            my $str = Sidef::Types::String::String->new($key);
            push @array, [$key, $str, $block->run($str, $self->{$key})];
        }

        Sidef::Types::Array::Array->new(
              [map { Sidef::Types::Array::Pair->new($_->[1], $self->{$_->[0]}) } (CORE::sort { $a->[2] cmp $b->[2] } @array)]);
    }

    sub sort {
        my ($self, $block) = @_;

        if (defined $block) {
            return
              Sidef::Types::Array::Array->new(
                                              [
                                               map { Sidef::Types::Array::Pair->new($_->[1], $self->{$_->[0]}) } (
                                                       CORE::sort { scalar $block->run($a->[1], $b->[1]) }
                                                         map { [$_, Sidef::Types::String::String->new($_)] } CORE::keys(%$self)
                                               )
                                              ]
                                             );
        }

        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{$_})
            } CORE::sort(CORE::keys(%$self))
        );
    }

    sub _min_max {
        my ($self, $block, $value) = @_;

        my @pairs = map { [$_, $block->run(Sidef::Types::String::String->new($_), $self->{$_})] } CORE::keys(%$self);

        my $item = $pairs[0];
        foreach my $i (1 .. $#pairs) {
            $item = $pairs[$i] if (($pairs[$i][1] cmp $item->[1]) eq $value);
        }

        Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($item->[0]), $self->{$item->[0]});
    }

    sub max_by {
        my ($self, $block) = @_;
        $self->_min_max($block, Sidef::Types::Number::Number::ONE);
    }

    sub min_by {
        my ($self, $block) = @_;
        $self->_min_max($block, Sidef::Types::Number::Number::MONE);
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            [
             map {
                 Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{$_})
             } CORE::keys(%$self)
            ]
        );
    }

    *to_array = \&to_a;
    *kv       = \&to_a;
    *pairs    = \&to_a;

    sub as_tree {
        my ($self, $root) = @_;

        my %addr;

        my $sub = sub {
            my ($obj, $root) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            CORE::exists($addr{$refaddr})
              && return $addr{$refaddr};

            my @body;
            $addr{$refaddr} = Sidef::Types::Array::Pair->new($root, \@body);

            foreach my $k (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } CORE::keys(%$obj)) {
                my $v = $obj->{$k};
                if (ref($v) eq __PACKAGE__ or UNIVERSAL::isa($v, __PACKAGE__)) {
                    push @body, $v->as_tree(Sidef::Types::String::String->new($k));
                }
                else {
                    push @body,
                      Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($k), Sidef::Types::Array::Array->new);
                }
            }

            bless \@body, 'Sidef::Types::Array::Array';
            $addr{$refaddr};
        };

        local *Sidef::Types::Hash::Hash::as_tree = $sub;
        $sub->($_[0], $root);
    }

    sub get_pairs {
        my ($self, @keys) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::Array::Pair->new($_, $self->{$_}) } @keys]);
    }

    sub get_pair {
        my ($self, $key) = @_;
        Sidef::Types::Array::Pair->new($key, $self->{$key});
    }

    sub exists {
        my ($self, $key) = @_;
        CORE::exists($self->{$key})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *has      = \&exists;
    *haskey   = \&exists;
    *has_key  = \&exists;
    *contain  = \&exists;
    *contains = \&exists;
    *include  = \&exists;
    *includes = \&exists;

    sub reverse {
        my ($self) = @_;
        my %hash;
        @hash{CORE::values(%$self)} = (map { Sidef::Types::String::String->new($_) } CORE::keys(%$self));
        bless \%hash, ref($self);
    }

    *flip   = \&reverse;
    *invert = \&reverse;

    sub intersection {
        my ($A, $B) = @_;

        if (ref($A) ne ref($B)) {
            return $A->linear_selection($A->to_set->intersection($B));
        }

        my %C;

        foreach my $key (CORE::keys(%$A)) {
            if (CORE::exists($B->{$key})) {
                $C{$key} = $A->{$key};
            }
        }

        bless \%C, ref($A);
    }

    *and = \&intersection;

    sub difference {
        my ($A, $B) = @_;

        if (ref($A) ne ref($B)) {
            return $A->linear_selection($A->to_set->difference($B));
        }

        my %C;

        foreach my $key (CORE::keys(%$A)) {
            if (!CORE::exists($B->{$key})) {
                $C{$key} = $A->{$key};
            }
        }

        bless \%C, ref($A);
    }

    *sub  = \&difference;
    *diff = \&difference;

    sub union {
        my ($A, $B) = @_;

        if (ref($A) ne ref($B)) {
            return $A->linear_selection($A->to_set->union($B));
        }

        my %C = %$A;
        foreach my $key (CORE::keys(%$B)) {
            if (!CORE::exists($C{$key})) {
                $C{$key} = $B->{$key};
            }
        }

        bless \%C, ref($A);
    }

    *or = \&union;

    sub symmetric_difference {
        my ($A, $B) = @_;

        if (ref($A) ne ref($B)) {
            return $A->linear_selection($A->to_set->symmetric_difference($B));
        }

        my %C;

        foreach my $key (CORE::keys(%$A)) {
            if (!CORE::exists($B->{$key})) {
                $C{$key} = $A->{$key};
            }
        }

        foreach my $key (CORE::keys(%$B)) {
            if (!CORE::exists($A->{$key})) {
                $C{$key} = $B->{$key};
            }
        }

        bless \%C, ref($A);
    }

    *xor     = \&symmetric_difference;
    *symdiff = \&symmetric_difference;

    sub to_list {
        my ($self) = @_;
        map { (Sidef::Types::String::String->new($_), $self->{$_}) } CORE::keys(%$self);
    }

    sub _dump {
        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            CORE::exists($addr{$refaddr})
              and return $addr{$refaddr};

            $Sidef::SPACES += $Sidef::SPACES_INCR;

            # Sort the keys case insensitively
            my @keys = CORE::sort { (lc($a) cmp lc($b)) || ($a cmp $b) } CORE::keys(%$obj);

            $addr{$refaddr} = "Hash(#`($refaddr)...)";

            my ($s, $val);

            my $str = (
                "Hash(" . (
                    @keys
                    ? (
                       (@keys > 1 ? "\n" : '') . join(
                           ",\n",
                           map {
                                   (@keys > 1 ? (' ' x $Sidef::SPACES) : '')
                                 . "${Sidef::Types::String::String->new($_)->dump} => "
                                 . (
                                    (ref($val = $obj->{$_}) && ($s = UNIVERSAL::can($val, 'dump')))
                                    ? $s->($val)
                                    : ($val // 'nil')
                                   )
                             } @keys
                         )
                         . (@keys > 1 ? ("\n" . (' ' x ($Sidef::SPACES - $Sidef::SPACES_INCR))) : '')
                      )
                    : ""
                  )
                  . ")"
            );

            $Sidef::SPACES -= $Sidef::SPACES_INCR;
            $str;
        };

        local *Sidef::Types::Hash::Hash::dump = $sub;
        $sub->($_[0]);
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    *to_s   = \&dump;
    *to_str = \&dump;

    sub to_set {
        $_[0]->keys->to_set;
    }

    sub to_bag {
        $_[0]->keys->to_bag;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'}   = \&ne;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;

        *{__PACKAGE__ . '::' . '&'} = \&intersection;
        *{__PACKAGE__ . '::' . '-'} = \&difference;
        *{__PACKAGE__ . '::' . '|'} = \&union;
        *{__PACKAGE__ . '::' . '^'} = \&symmetric_difference;
    }
};

1
