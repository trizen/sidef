package Sidef::Types::Set::Set {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Types::Hash::Hash
    );

    use overload
      q{bool} => sub { scalar(CORE::keys(%{$_[0]})) },
      q{0+}   => sub { scalar(CORE::keys(%{$_[0]})) },
      q{""}   => \&_dump;

    use Sidef::Types::Block::Block;
    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    my $serialize = sub {
        my ($obj) = @_;
        my $key = ref($obj) ? (UNIVERSAL::can($obj, 'dump') ? $obj->dump : $obj) : ($obj // 'nil');
        "$key";
    };

    sub new {
        my (undef, @objects) = @_;
        bless {map { $serialize->($_) => $_ } @objects};
    }

    *call = \&new;

    sub get_value {
        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              && return $addr{$refaddr};

            my @set;
            $addr{$refaddr} = \@set;

            foreach my $v (CORE::values(%$obj)) {
                CORE::push(@set, (index(ref($v), 'Sidef::') == 0) ? $v->get_value : $v);
            }

            $addr{$refaddr};
        };

        no warnings 'redefine';
        local *Sidef::Types::Set::Set::get_value = $sub;
        $sub->($_[0]);
    }

    sub concat {
        my ($A, $B) = @_;

        ref($A) eq ref($B)
          ? bless({%$A, %$B}, ref($A))
          : bless({%$A, $serialize->($B) => $B}, ref($A));
    }

    sub union {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_set;
        }

        $A->SUPER::union($B);
    }

    *or = \&union;

    sub intersection {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_set;
        }

        $A->SUPER::intersection($B);
    }

    *and = \&intersection;

    sub difference {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_set;
        }

        $A->SUPER::difference($B);
    }

    *sub  = \&difference;
    *diff = \&difference;

    sub symmetric_difference {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_set;
        }

        $A->SUPER::symmetric_difference($B);
    }

    *xor     = \&symmetric_difference;
    *symdiff = \&symmetric_difference;

    sub append {
        my ($self, @objects) = @_;

        foreach my $obj (@objects) {
            my $key = $serialize->($obj);
            $self->{$key} = $obj;
        }

        $self;
    }

    *add  = \&append;
    *push = \&append;

    sub pop {
        my ($self) = @_;
        CORE::delete(@{$self}{(CORE::keys(%$self))[-1]});
    }

    sub shift {
        my ($self) = @_;
        CORE::delete(@{$self}{(CORE::keys(%$self))[0]});
    }

    sub delete {
        my ($self, @objects) = @_;
        CORE::delete(@{$self}{map { $serialize->($_) } @objects});
    }

    *remove  = \&delete;
    *discard = \&delete;

    sub map {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {
            foreach my $value ($block->run($self->{$key})) {
                $new{$serialize->($value)} = $value;
            }
        }

        bless \%new, ref($self);
    }

    sub map_2d {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::ARRAY_IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {
            foreach my $value ($block->run(@{$self->{$key}})) {
                $new{$serialize->($value)} = $value;
            }
        }

        bless \%new, ref($self);
    }

    sub collect {
        my ($self, $block) = @_;

        my @array;
        foreach my $value (CORE::values(%$self)) {
            CORE::push(@array, $block->run($value));
        }

        Sidef::Types::Array::Array->new(\@array);
    }

    sub grep {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        my %new;
        foreach my $key (CORE::keys(%$self)) {
            my $value = $self->{$key};
            if ($block->run($value)) {
                $new{$key} = $value;
            }
        }

        bless \%new, ref($self);
    }

    *select = \&grep;

    sub grep_2d {
        my ($self, $block) = @_;

        my %new;
        foreach my $key (CORE::keys(%$self)) {
            my $value = $self->{$key};
            if ($block->run(@$value)) {
                $new{$key} = $value;
            }
        }

        bless \%new, ref($self);
    }

    sub count_by {
        my ($self, $block) = @_;

        my $count = 0;
        foreach my $value (CORE::values(%$self)) {
            if ($block->run($value)) {
                ++$count;
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
            return Sidef::Types::Number::Number::ONE;
        }

        return Sidef::Types::Number::Number::ZERO;
    }

    sub delete_if {
        my ($self, $block) = @_;

        foreach my $key (CORE::keys(%$self)) {
            if ($block->run($self->{$key})) {
                CORE::delete($self->{$key});
            }
        }

        $self;
    }

    sub delete_first_if {
        my ($self, $block) = @_;

        foreach my $key (CORE::keys(%$self)) {
            if ($block->run($self->{$key})) {
                CORE::delete($self->{$key});
                last;
            }
        }

        $self;
    }

    sub iter {
        my ($self) = @_;

        my $i      = 0;
        my @values = CORE::values(%$self);
        Sidef::Types::Block::Block->new(
            code => sub {
                $values[$i++];
            }
        );
    }

    sub each {
        my ($self, $block) = @_;

        foreach my $value (CORE::values(%$self)) {
            $block->run($value);
        }

        $self;
    }

    sub each_2d {
        my ($self, $block) = @_;

        foreach my $value (CORE::values(%$self)) {
            $block->run(@$value);
        }

        $self;
    }

    sub sort_by {
        my ($self, $block) = @_;
        $self->values->sort_by($block);
    }

    sub sort {
        my ($self, $block) = @_;
        $self->values->sort(defined($block) ? $block : ());
    }

    sub min {
        my ($self) = @_;
        $self->values->min;
    }

    sub max {
        my ($self) = @_;
        $self->values->max;
    }

    sub max_by {
        my ($self, $block) = @_;
        $self->values->max_by($block);
    }

    sub min_by {
        my ($self, $block) = @_;
        $self->values->min_by($block);
    }

    sub sum {
        my ($self, $block) = @_;
        $self->to_a->sum($block);
    }

    *sum_by = \&sum;

    sub prod {
        my ($self, $block) = @_;
        $self->to_a->prod($block);
    }

    *prod_by = \&prod;

    sub sum_2d {
        my ($self, $block) = @_;
        $self->to_a->sum_2d($block);
    }

    sub prod_2d {
        my ($self, $block) = @_;
        $self->to_a->prod_2d($block);
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
            $B = $B->to_set;
        }

        foreach my $key (CORE::keys(%$A)) {
            if (!CORE::exists($B->{$key})) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub is_superset {
        my ($A, $B) = @_;

        if (ref($B) ne __PACKAGE__) {
            $B = $B->to_set;
        }

        foreach my $key (CORE::keys(%$B)) {
            if (!CORE::exists($A->{$key})) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub contains_all {
        my ($self, @objects) = @_;

        foreach my $obj (@objects) {
            if (!CORE::exists($self->{$serialize->($obj)})) {
                return Sidef::Types::Bool::Bool::FALSE;
            }
        }

        return Sidef::Types::Bool::Bool::TRUE;
    }

    sub join {
        my ($self, @rest) = @_;
        $self->to_a->join(@rest);
    }

    sub all {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        foreach my $key (CORE::keys(%$self)) {
            $block->run($self->{$key})
              || return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub any {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        foreach my $key (CORE::keys(%$self)) {
            $block->run($self->{$key})
              && return Sidef::Types::Bool::Bool::TRUE;
        }

        Sidef::Types::Bool::Bool::FALSE;
    }

    sub none {
        my ($self, $block) = @_;

        $block //= Sidef::Types::Block::Block::IDENTITY;

        foreach my $key (CORE::keys(%$self)) {
            $block->run($self->{$key})
              && return Sidef::Types::Bool::Bool::FALSE;
        }

        Sidef::Types::Bool::Bool::TRUE;
    }

    sub _dump {
        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              and return $addr{$refaddr};

            my @values = CORE::values(%$obj);

            $addr{$refaddr} = "Set(#`($refaddr)...)";

            my $s;
            "Set("
              . CORE::join(', ', map { (ref($_) && ($s = UNIVERSAL::can($_, 'dump'))) ? $s->($_) : ($_ // 'nil') } @values)
              . ')';
        };

        no warnings 'redefine';
        local *Sidef::Types::Set::Set::dump = $sub;
        $sub->($_[0]);
    }

    sub dump {
        Sidef::Types::String::String->new($_[0]->_dump);
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(ref($self) ? [CORE::values(%$self)] : $self);
    }

    *values   = \&to_a;
    *to_array = \&to_a;

    sub to_list {
        my ($self) = @_;
        CORE::values(%$self);
    }

    sub to_bag {
        my ($self) = @_;
        Sidef::Types::Set::Bag->new(CORE::values(%$self));
    }

    sub to_set {
        $_[0];
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '<<'}  = \&append;
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
        *{__PACKAGE__ . '::' . '∋'}   = \&contains;
        *{__PACKAGE__ . '::' . '∌'}   = sub { $_[0]->contains($_[1])->not };
        *{__PACKAGE__ . '::' . '≡'}   = \&Sidef::Types::Hash::Hash::eq;
    }
};

1
