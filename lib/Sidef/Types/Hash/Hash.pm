package Sidef::Types::Hash::Hash {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { scalar(CORE::keys %{$_[0]}) },
      q{0+}   => sub { scalar(CORE::keys %{$_[0]}) },
      q{""}   => \&_dump;

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, %pairs) = @_;
        bless \%pairs, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my %addr;

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
              && return $addr{$refaddr};

            my %hash;
            $addr{$refaddr} = \%hash;

            foreach my $k (CORE::keys %$obj) {
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

    sub items {
        my ($self, @keys) = @_;
        Sidef::Types::Array::Array->new([map { exists($self->{$_}) ? $self->{$_} : undef } @keys]);
    }

    sub item {
        my ($self, $key) = @_;
        exists($self->{$key}) ? $self->{$key} : ();
    }

    sub fetch {
        my ($self, $key, $default) = @_;
        exists($self->{$key}) ? $self->{$key} : $default;
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
        bless {map { ($_ => $self->{$_}) } @keys}, __PACKAGE__;
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar CORE::keys %$self);
    }

    *len  = \&length;
    *size = \&length;

    sub eq {
        my ($self, $obj) = @_;

        (%$self eq %{$obj})
          or return (Sidef::Types::Bool::Bool::FALSE);

        while (my ($key, $value) = each %$self) {
            exists($obj->{$key})
              or return (Sidef::Types::Bool::Bool::FALSE);

            $value eq $obj->{$key}
              or return (Sidef::Types::Bool::Bool::FALSE);
        }

        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub ne {
        my ($self, $obj) = @_;
        $self->eq($obj)->neg;
    }

    sub same_keys {
        my ($self, $obj) = @_;

        if (ref($self) ne ref($obj)
            or %$self ne %{$obj}) {
            return (Sidef::Types::Bool::Bool::FALSE);
        }

        while (my ($key) = each %$self) {
            exists($obj->{$key})
              or return (Sidef::Types::Bool::Bool::FALSE);
        }

        (Sidef::Types::Bool::Bool::TRUE);
    }

    sub append {
        my ($self, %pairs) = @_;

        foreach my $key (CORE::keys %pairs) {
            $self->{$key} = $pairs{$key};
        }

        $self;
    }

    *add = \&append;

    sub delete {
        my ($self, @keys) = @_;
        @keys == 1
          ? delete($self->{$keys[0]})
          : (delete @{$self}{@keys});
    }

    *remove = \&delete;

    sub set_keys {
        my ($self, @keys) = @_;
        undef @{$self}{@keys};
        $self;
    }

    sub map_val {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            $hash{$key} = $code->run(Sidef::Types::String::String->new($key), $self->{$key});
        }

        bless \%hash, __PACKAGE__;
    }

    *map_v = \&map_val;

    sub map {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            my ($k, $v) = $code->run(Sidef::Types::String::String->new($key), $self->{$key});
            $hash{$k} = $v;
        }

        bless \%hash, __PACKAGE__;
    }

    *map_kv = \&map;

    sub grep {
        my ($self, $obj) = @_;

        my %hash;
        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            my $re = $obj->{regex};
            my @keys = grep { $_ =~ $re } CORE::keys(%$self);
            @hash{@keys} = @$self{@keys};
        }
        else {
            foreach my $key (CORE::keys %$self) {
                my $value = $self->{$key};
                if ($obj->run(Sidef::Types::String::String->new($key), $value)) {
                    $hash{$key} = $value;
                }
            }
        }

        bless \%hash, __PACKAGE__;
    }

    *grep_kv = \&grep;
    *select  = \&grep;

    sub grep_val {
        my ($self, $obj) = @_;

        my %hash;
        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            my @keys = grep { $obj->match($self->{$_}) } CORE::keys(%$self);
            @hash{@keys} = @$self{@keys};
        }
        else {
            foreach my $key (CORE::keys %$self) {
                my $value = $self->{$key};
                if ($obj->run($value)) {
                    $hash{$key} = $value;
                }
            }
        }

        bless \%hash, __PACKAGE__;
    }

    *grep_v = \&grep_val;

    sub count {
        my ($self, $code) = @_;

        my $count = 0;
        foreach my $key (CORE::keys %$self) {
            if ($code->run(Sidef::Types::String::String->new($key), $self->{$key})) {
                ++$count;
            }
        }

        Sidef::Types::Number::Number->new($count);
    }

    *count_by = \&count;

    sub delete_if {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %$self) {
            if ($code->run(Sidef::Types::String::String->new($key), $self->{$key})) {
                delete($self->{$key});
            }
        }

        $self;
    }

    sub concat {
        my ($self, $obj) = @_;

        my @list;
        while (my ($key, $val) = each %$self) {
            push @list, $key, $val;
        }

        while (my ($key, $val) = each %$obj) {
            push @list, $key, $val;
        }

        bless {@list}, __PACKAGE__;
    }

    *merge = \&concat;

    sub merge_values {
        my ($self, $obj) = @_;

        while (my ($key, undef) = each %$self) {
            if (exists $obj->{$key}) {
                $self->{$key} = $obj->{$key};
            }
        }

        $self;
    }

    sub keys {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::String::String->new($_) } CORE::keys %$self]);
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([CORE::values %$self]);
    }

    sub each_value {
        my ($self, $code) = @_;

        foreach my $value (CORE::values %$self) {
            $code->run($value);
        }

        $code;
    }

    *each_v = \&each_value;

    sub each_key {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %$self) {
            $code->run(Sidef::Types::String::String->new($key));
        }

        $code;
    }

    *each_k = \&each_key;

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {

            foreach my $key (CORE::keys %$self) {
                $obj->run(Sidef::Types::String::String->new($key), $self->{$key});
            }

            return $obj;
        }

        my ($key, $value) = each(%$self);

        $key // return undef;
        Sidef::Types::Array::Array->new([Sidef::Types::String::String->new($key), $value]);
    }

    *each_kv   = \&each;
    *each_pair = \&each;

    sub sort_by {
        my ($self, $code) = @_;

        my @array;
        foreach my $key (CORE::keys %$self) {
            my $str = Sidef::Types::String::String->new($key);
            push @array, [$key, $str, $code->run($str, $self->{$key})];
        }

        Sidef::Types::Array::Array->new(
              [map { Sidef::Types::Array::Pair->new($_->[1], $self->{$_->[0]}) } (CORE::sort { $a->[2] cmp $b->[2] } @array)]);
    }

    sub sort {
        my ($self, $code) = @_;

        if (defined $code) {
            return
              Sidef::Types::Array::Array->new(
                                              [
                                               map { Sidef::Types::Array::Pair->new($_->[1], $self->{$_->[0]}) } (
                                                        CORE::sort { scalar $code->run($a->[1], $b->[1]) }
                                                          map { [$_, Sidef::Types::String::String->new($_)] } CORE::keys %$self
                                               )
                                              ]
                                             );
        }

        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{$_})
              } CORE::sort CORE::keys %$self
        );
    }

    sub _min_max {
        my ($self, $code, $value) = @_;

        my @pairs = map { [$_, $code->run(Sidef::Types::String::String->new($_), $self->{$_})] } CORE::keys %$self;

        my $item = $pairs[0];
        foreach my $i (1 .. $#pairs) {
            $item = $pairs[$i] if (($pairs[$i][1] cmp $item->[1]) eq $value);
        }

        Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($item->[0]), $self->{$item->[0]});
    }

    sub max_by {
        my ($self, $code) = @_;
        $self->_min_max($code, Sidef::Types::Number::Number::ONE);
    }

    sub min_by {
        my ($self, $code) = @_;
        $self->_min_max($code, Sidef::Types::Number::Number::MONE);
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            [
             map {
                 Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{$_})
               } CORE::keys %$self
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

            exists($addr{$refaddr})
              && return $addr{$refaddr};

            my @body;
            $addr{$refaddr} = Sidef::Types::Array::Pair->new($root, \@body);

            foreach my $k (sort { (CORE::length($a) <=> CORE::length($b)) || ($a cmp $b) } CORE::keys %$obj) {
                my $v = $obj->{$k};
                if (ref($v) eq __PACKAGE__) {
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

    *has_key  = \&exists;
    *contain  = \&exists;
    *contains = \&exists;
    *include  = \&exists;
    *includes = \&exists;

    sub reverse {
        my ($self) = @_;
        my %hash;
        @hash{CORE::values %$self} = (map { Sidef::Types::String::String->new($_) } CORE::keys %$self);
        bless \%hash, __PACKAGE__;
    }

    *flip = \&reverse;

    sub copy {
        my ($self) = @_;
        state $x = warn "[WARNING] Hash.copy() is deprecated: use .clone() or .dclone() instead!\n";
        $self->dclone;
    }

    sub to_list {
        my ($self) = @_;
        map { (Sidef::Types::String::String->new($_), $self->{$_}) } CORE::keys %$self;
    }

    sub _dump {
        my %addr;    # keeps track of dumped objects

        my $sub = sub {
            my ($obj) = @_;

            my $refaddr = Scalar::Util::refaddr($obj);

            exists($addr{$refaddr})
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
                                      (ref($val = $obj->{$_}) && ($s = UNIVERSAL::can($val, 'dump'))) ? $s->($val)
                                    : defined($val) ? $val
                                    :                 'nil'
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

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . ':'}   = \&new;
        *{__PACKAGE__ . '::' . '...'} = \&to_list;
    }
};

1
