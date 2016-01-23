package Sidef::Types::Hash::Hash {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { scalar(CORE::keys %{$_[0]}) },
      q{""}   => \&dump;

    use Sidef::Types::Bool::Bool;

    sub new {
        my ($class, %pairs) = @_;
        bless \%pairs, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my ($self) = @_;

        my %hash;
        foreach my $k (CORE::keys %$self) {
            my $v = $self->{$k};
            $hash{$k} = (
                         index(ref($v), 'Sidef::') == 0
                         ? $v->get_value
                         : $v
                        );
        }

        \%hash;
    }

    sub items {
        my ($self, @keys) = @_;
        Sidef::Types::Array::Array->new(map { exists($self->{$_}) ? $self->{$_} : undef } @keys);
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

        my $value = $self->fetch($key) // return;

        foreach my $key (@keys) {
            $value = $value->fetch($key) // return;
        }

        $value;
    }

    sub slice {
        my ($self, @keys) = @_;
        $self->new(map { ($_ => exists($self->{$_}) ? $self->{$_} : undef) } @keys);
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
        $self->eq($obj)->not;
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

    sub map_val {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            $hash{$key} = $code->run(Sidef::Types::String::String->new($key), $self->{$key});
        }

        $self->new(%hash);
    }

    *map_v = \&map_val;

    sub map {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            my ($k, $v) = $code->run(Sidef::Types::String::String->new($key), $self->{$key});
            $hash{$k} = $v;
        }

        $self->new(%hash);
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

        $self->new(%hash);
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

        $self->new(%hash);
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

        $self->new(@list);
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
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } CORE::keys %$self);
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(CORE::values %$self);
    }

    sub each_value {
        my ($self, $code) = @_;

        foreach my $value (CORE::values %$self) {
            if (defined(my $res = $code->_run_code($value))) {
                return $res;
            }
        }

        $code;
    }

    *each_v = \&each_value;

    sub each_key {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %$self) {
            if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($key)))) {
                return $res;
            }
        }

        $code;
    }

    *each_k = \&each_key;

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {

            foreach my $key (CORE::keys %$self) {
                if (defined(my $res = $obj->_run_code(Sidef::Types::String::String->new($key), $self->{$key}))) {
                    return $res;
                }
            }

            return $obj;
        }

        my ($key, $value) = each(%$self);

        $key // return;
        Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value);
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

        Sidef::Types::Array::Array->new(map { Sidef::Types::Array::Array->new($_->[1], $self->{$_->[0]}) }
                                        (sort { $a->[2] cmp $b->[2] } @array));
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{$_})
              } CORE::keys %$self
        );
    }

    *pairs    = \&to_a;
    *to_array = \&to_a;

    sub exists {
        my ($self, $key) = @_;
        (CORE::exists $self->{$key}) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *has_key  = \&exists;
    *contain  = \&exists;
    *contains = \&exists;
    *include  = \&exists;
    *includes = \&exists;

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{CORE::values %$self} =
          (map { Sidef::Types::String::String->new($_) } CORE::keys %$self);

        $new_hash;
    }

    sub copy {
        my ($self) = @_;

        state $x = require Storable;
        Storable::dclone($self);
    }

    sub to_list {
        my ($self) = @_;
        map { (Sidef::Types::String::String->new($_), $self->{$_}) } CORE::keys %$self;
    }

    *as_list = \&to_list;

    sub dump {
        my ($self) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;

        # Sort the keys case insensitively
        my @keys = sort { (lc($a) cmp lc($b)) || ($a cmp $b) } CORE::keys(%$self);

        my $str = Sidef::Types::String::String->new(
            "Hash(" . (
                @keys
                ? (
                   (@keys > 1 ? "\n" : '') . join(
                       ",\n",
                       map {
                           my $val = $self->{$_};
                           (@keys > 1 ? (' ' x $Sidef::SPACES) : '')
                             . "${Sidef::Types::String::String->new($_)->dump} => "
                             . (eval { $val->can('dump') } ? ${$val->dump} : defined($val) ? $val : 'nil')
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
