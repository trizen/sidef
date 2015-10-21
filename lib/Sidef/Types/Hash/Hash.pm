package Sidef::Types::Hash::Hash {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => sub { scalar(keys %{$_[0]}) },
      q{""}   => \&dump;

    sub new {
        my ($class, %pairs) = @_;
        bless \%pairs, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        my ($self) = @_;

        my %hash;
        foreach my $k (keys %{$self}) {
            my $v = $self->{$k};
            $hash{$k} = (
                         index(ref($v), 'Sidef::') == 0
                         ? $v->get_value
                         : $v
                        );
        }

        \%hash;
    }

    sub default {
        my ($self, $value) = @_;
        if (@_ > 1) {
            $self->{__DEFAULT_VALUE__} = $value;
        }
        $self->{__DEFAULT_VALUE__};
    }

    sub items {
        my ($self, @keys) = @_;
        Sidef::Types::Array::Array->new(map { exists($self->{$_}) ? $self->{$_} : undef } @keys);
    }

    sub item {
        my ($self, $key) = @_;
        exists($self->{$key}) ? $self->{$key} : ();
    }

    sub slice {
        my ($self, @keys) = @_;
        $self->new(map { ($_ => exists($self->{$_}) ? $self->{$_} : undef) } @keys);
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar CORE::keys %{$self});
    }

    *len = \&length;

    sub eq {
        my ($self, $obj) = @_;

        (%{$self} eq %{$obj})
          or return Sidef::Types::Bool::Bool->false;

        while (my ($key, $value) = each %{$self}) {
            exists($obj->{$key})
              or return Sidef::Types::Bool::Bool->false;

            $value eq $obj->{$key}
              or return Sidef::Types::Bool::Bool->false;
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub ne {
        my ($self, $obj) = @_;
        $self->eq($obj)->not;
    }

    sub same_keys {
        my ($self, $obj) = @_;

        if (ref($self) ne ref($obj)
            or %{$self} ne %{$obj}) {
            return Sidef::Types::Bool::Bool->false;
        }

        while (my ($key) = each %{$self}) {
            exists($obj->{$key})
              or return Sidef::Types::Bool::Bool->false;
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub append {
        my ($self, %pairs) = @_;

        foreach my $key (keys %pairs) {
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

    sub _iterate {
        my ($self, $code, $callback) = @_;

        while (my ($key, $value) = each %{$self}) {
            my $key_obj = Sidef::Types::String::String->new($key);

            if ($code->run($key_obj, $value)) {
                $callback->($key, $value);
            }
        }

        $self;
    }

    sub map_val {
        my ($self, $code) = @_;

        while (my ($key, $value) = each %{$self}) {
            $self->{$key} = $code->run(Sidef::Types::String::String->new($key), $value);
        }

        $self;
    }

    sub select {
        my ($self, $code) = @_;

        my @pairs;
        $self->_iterate(
            $code,
            sub {
                push @pairs, @_;
            }
        );

        $self->new(@pairs);
    }

    *grep = \&select;

    sub delete_if {
        my ($self, $code) = @_;
        $self->_iterate(
            $code,
            sub {
                delete $self->{$_[0]};
            }
        );
    }

    *deleteIf = \&delete_if;

    sub concat {
        my ($self, $obj) = @_;

        my @list;
        while (my ($key, $val) = each %{$self}) {
            push @list, $key, $val;
        }

        while (my ($key, $val) = each %{$obj}) {
            push @list, $key, $val;
        }

        $self->new(@list);
    }

    *merge = \&concat;

    sub merge_values {
        my ($self, $obj) = @_;

        while (my ($key, undef) = each %{$self}) {
            if (exists $obj->{$key}) {
                $self->{$key} = $obj->{$key};
            }
        }

        $self;
    }

    sub keys {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } keys %{$self});
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(values %{$self});
    }

    sub each_value {
        my ($self, $code) = @_;

        foreach my $value (CORE::values %{$self}) {
            if (defined(my $res = $code->_run_code($value))) {
                return $res;
            }
        }

        $code;
    }

    sub each_key {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %{$self}) {
            if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($key)))) {
                return $res;
            }
        }

        $code;
    }

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {

            foreach my $key (CORE::keys %{$self}) {
                if (defined(my $res = $obj->_run_code(Sidef::Types::String::String->new($key), $self->{$key}))) {
                    return $res;
                }
            }

            return $obj;
        }

        my ($key, $value) = each(%{$self});

        $key // return;
        Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value);
    }

    *each_pair = \&each;

    sub sort_by {
        my ($self, $code) = @_;

        my @array;
        while (my ($key, $value) = CORE::each %{$self}) {
            push @array, [$key, $code->run(Sidef::Types::String::String->new($key), $value)];
        }

        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($_->[0]), $self->{$_->[0]})
              } (sort { $a->[1] cmp $b->[1] } @array)
        );
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{$_})
              } CORE::keys %{$self}
        );
    }

    *pairs    = \&to_a;
    *to_array = \&to_a;

    sub exists {
        my ($self, $key) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->{$key});
    }

    *has_key  = \&exists;
    *contains = \&exists;

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{map { $_->get_value } CORE::values %{$self}} =
          (map           { Sidef::Types::String::String->new($_) } CORE::keys %{$self});

        $new_hash;
    }

    sub copy {
        my ($self) = @_;

        state $x = require Storable;
        Storable::dclone($self);
    }

    sub dump {
        my ($self) = @_;

        $Sidef::SPACES += $Sidef::SPACES_INCR;

        # Sort the keys case insensitively
        my @keys = sort { (lc($a) cmp lc($b)) || ($a cmp $b) } CORE::keys(%{$self});

        my $str = Sidef::Types::String::String->new(
            "Hash.new(" . (
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

        *{__PACKAGE__ . '::' . '+'}  = \&concat;
        *{__PACKAGE__ . '::' . '=='} = \&eq;
        *{__PACKAGE__ . '::' . '!='} = \&ne;
        *{__PACKAGE__ . '::' . ':'}  = \&new;
    }
};

1
