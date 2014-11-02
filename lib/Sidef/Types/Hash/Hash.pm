package Sidef::Types::Hash::Hash {

    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my ($class, @pairs) = @_;

        my %hash;
        my $self = bless \%hash, __PACKAGE__;

        # Default value only for: Hash.new(obj);
        if (    @pairs == 1
            and ref($class) eq __PACKAGE__
            and ref($pairs[0]) ne 'Sidef::Types::Array::Pair') {
            $self->default(shift @pairs);
            return $self;
        }

        # Add hash key/value pairs
        while (@pairs) {
            my $key = shift @pairs;

            my $value;
            if (ref($key) eq 'Sidef::Types::Array::Pair') {
                ($key, $value) = ($key->[0], $key->[1]);
            }
            else {
                $value = Sidef::Variable::Variable->new(name => '', type => 'var', value => shift @pairs);
            }

            $hash{data}{$key} = $value;
        }

        $self;
    }

    sub get_value {
        my ($self) = @_;

        my %hash;
        while (my ($k, $v) = each %{$self->{data}}) {
            my $rv = $v->get_value;
            $hash{$k} =
              (ref($rv) && defined eval { $v->can('get_value') })
              ? $rv->get_value
              : $rv;
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

    sub get {
        my ($self, @keys) = @_;

        if ($#keys == 0) {
            return $self->{data}{$keys[0]};
        }

        Sidef::Types::Array::Array->new(map { defined($_) ? $_->get_value : $_ } @{$self->{data}}{@keys});
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar keys %{$self->{data}});
    }

    *len = \&length;

    sub duplicate_of {
        my ($self, $obj) = @_;

        $self->_is_hash($obj);
        %{$self->{data}} eq %{$obj->{data}} || return Sidef::Types::Bool::Bool->false;

        my $ne_method = '!=';
        while (my ($key, $value) = each %{$self->{data}}) {
            !exists($obj->{data}{$key})
              && (return Sidef::Types::Bool::Bool->false);

            $value->get_value->$ne_method($obj->{data}{$key}->get_value)
              && return (Sidef::Types::Bool::Bool->false);
        }

        Sidef::Types::Bool::Bool->true;
    }

    *duplicateOf = \&duplicate_of;

    sub eq {
        my ($self, $obj) = @_;

        $self->_is_hash($obj);
        %{$self->{data}} eq %{$obj->{data}} || return Sidef::Types::Bool::Bool->false;

        while (my ($key) = each %{$self->{data}}) {
            !exists($obj->{data}{$key})
              && return Sidef::Types::Bool::Bool->false;
        }

        Sidef::Types::Bool::Bool->true;
    }

    sub ne {
        my ($self, $obj) = @_;
        $self->eq($obj)->not;
    }

    sub append {
        my ($self, $key, $value) = @_;
        $self->{data}{$key} = Sidef::Variable::Variable->new(name => '', type => 'var', value => $value);
    }

    *add = \&append;

    sub delete {
        my ($self, $key) = @_;
        if (exists $self->{data}{$key}) {
            return (delete $self->{data}{$key})->get_value;
        }
        return;
    }

    sub _iterate {
        my ($self, $code, $callback) = @_;

        while (my ($key, $value) = each %{$self->{data}}) {
            my $key_obj = Sidef::Types::String::String->new($key);
            my $val_obj = $value->get_value;

            if ($code->call($key_obj, $val_obj)) {
                $callback->($key, $val_obj);
            }
        }

        $self;
    }

    sub mapval {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;

        while (my ($key, $value) = each %{$self->{data}}) {
            $self->{data}{$key} =
              Sidef::Variable::Variable->new(
                                             name  => '',
                                             type  => 'var',
                                             value => $code->call(Sidef::Types::String::String->new($key), $value->get_value)
                                            );
        }

        $self;
    }

    *mapVal  = \&mapval;
    *map_val = \&mapval;

    sub select {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        my $new_hash = $self->new;
        $self->_iterate(
            $code,
            sub {
                $new_hash->append(@_);
            }
        );

        $new_hash;
    }

    *grep = \&select;

    sub delete_if {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;
        $self->_iterate(
            $code,
            sub {
                delete $self->{data}{$_[0]};
            }
        );
    }

    *deleteIf = \&delete_if;

    sub concat {
        my ($self, $obj) = @_;
        $self->_is_hash($obj) || return;

        my @list;
        while (my ($key, $val) = each %{$self->{data}}) {
            push @list, $key, $val->get_value;
        }

        while (my ($key, $val) = each %{$obj->{data}}) {
            push @list, $key, $val->get_value;
        }

        $self->new(@list);
    }

    *merge = \&concat;

    sub merge_values {
        my ($self, $obj) = @_;

        $self->_is_hash($obj) || return;

        while (my ($key, undef) = each %{$self->{data}}) {
            if (exists $obj->{data}{$key}) {
                $self->{data}{$key} = $obj->{data}{$key};
            }
        }

        $self;
    }

    *mergeValues = \&merge_values;

    sub keys {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } keys %{$self->{data}});
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { $_->get_value } values %{$self->{data}});
    }

    sub each_value {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;
        $self->values->each($code);
    }

    sub each_key {
        my ($self, $code) = @_;
        $self->_is_code($code) || return;
        $self->keys->each($code);
    }

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {
            $self->_is_code($obj) || return;

            my $array = Sidef::Types::Array::Array->new();
            while (my ($key, $value) = each %{$self->{data}}) {
                $array->push(Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value->get_value));
            }

            return $array->each($obj);
        }

        my ($key, $value) = each(%{$self->{data}});

        $key // return;
        Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value->get_value);
    }

    *each_pair = \&each;

    sub sort_by {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        my @array;
        while (my ($key, $value) = CORE::each %{$self->{data}}) {
            push @array, [$key, $code->call(Sidef::Types::String::String->new($key), $value->get_value)];
        }

        my $method = '<=>';
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($_->[0]), $self->{data}{$_->[0]}->get_value)
              } (sort { $a->[1]->can($method) ? ($a->[1]->$method($b->[1])) : -1 } @array)
        );
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Pair->new(Sidef::Types::String::String->new($_), $self->{data}{$_}->get_value)
              } CORE::keys %{$self->{data}}
        );
    }

    *pairs    = \&to_a;
    *toArray  = \&to_a;
    *to_array = \&to_a;
    *to_pairs = \&to_a;
    *toPairs  = \&to_a;

    sub exists {
        my ($self, $key) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->{data}{$key});
    }

    *has_key  = \&exists;
    *contains = \&exists;

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{CORE::values %{$self->{data}}} =
          (map { Sidef::Types::String::String->new($_) } CORE::keys %{$self->{data}});
        $new_hash;
    }

    sub copy {
        my ($self) = @_;
        $self->new(map { ref($_) ? $_->get_value : $_ } %{$self->{data}});
    }

    sub dump {
        my ($self) = @_;
        my ($i, $s) = $self->_get_indent_level;

        Sidef::Types::String::String->new(
            "Hash.new(\n" . join(
                ",\n",
                map {
                    my $val =
                      ref($self->{data}{$_}) eq 'Sidef::Variable::Variable'
                      ? $self->{data}{$_}->get_value
                      : Sidef::Types::Nil::Nil->new;
                    $s x $i
                      . "${Sidef::Types::String::String->new($_)->dump} => "
                      . (eval { $val->can('dump') } ? ${$val->dump} : $val)
                  } sort(CORE::keys(%{$self->{data}}))
              )
              . "\n"
              . $s x $i . ")"
        );
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '==='} = \&duplicateOf;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;

        *{__PACKAGE__ . '::' . ':'} = sub {
            shift;    # ignore self
            @_ == 1 && ref($_[0]) eq 'Sidef::Types::Block::Code'
              ? $_[0]->to_hash
              : __PACKAGE__->new(@_);
        };
    }
};

1
