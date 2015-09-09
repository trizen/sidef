package Sidef::Types::Hash::Hash {

    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{bool} => sub { scalar(keys %{$_[0]{data}}) },
      q{""}   => \&dump;

    sub new {
        my ($class, @pairs) = @_;

        my %hash = (data => {});
        my $self = bless \%hash, __PACKAGE__;

        if (@pairs == 1) {

            # Any object to hash
            if ($pairs[0]->can('to_hash')) {
                return $pairs[0]->to_hash;
            }
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

    *call = \&new;

    sub get_value {
        my ($self) = @_;

        my %hash;
        while (my ($k, $v) = each %{$self->{data}}) {
            my $rv = $v->get_value;
            $hash{$k} = (
                         ref($rv) =~ /^Sidef::/
                         ? $rv->get_value
                         : $rv
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

    sub get {
        my ($self, @keys) = @_;

        if (@keys > 1) {
            return Sidef::Types::Array::List->new(map { exists($self->{data}{$_}) ? $self->{data}{$_}->get_value : undef }
                                                  @keys);
        }

        @keys && exists($self->{data}{$keys[0]}) ? $self->{data}{$keys[0]}->get_value : ();
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(scalar CORE::keys %{$self->{data}});
    }

    *len = \&length;

    sub duplicate_of {
        my ($self, $obj) = @_;

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

        if (   not defined($obj)
            or not $obj->isa('HASH')
            or ref($obj->{data}) ne 'HASH'
            or %{$self->{data}} ne %{$obj->{data}}) {
            return Sidef::Types::Bool::Bool->false;
        }

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
        my ($self, @keys) = @_;
        Sidef::Types::Array::List->new(delete @{$self->{data}}{map { $_->get_value } @keys});
    }

    sub _iterate {
        my ($self, $code, $callback) = @_;

        while (my ($key, $value) = each %{$self->{data}}) {
            my $key_obj = Sidef::Types::String::String->new($key);
            my $val_obj = $value->get_value;

            if ($code->run($key_obj, $val_obj)) {
                $callback->($key, $val_obj);
            }
        }

        $self;
    }

    sub mapval {
        my ($self, $code) = @_;

        while (my ($key, $value) = each %{$self->{data}}) {
            $self->{data}{$key} =
              Sidef::Variable::Variable->new(
                                             name  => '',
                                             type  => 'var',
                                             value => $code->run(Sidef::Types::String::String->new($key), $value->get_value)
                                            );
        }

        $self;
    }

    *mapVal  = \&mapval;
    *map_val = \&mapval;

    sub select {
        my ($self, $code) = @_;

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

        foreach my $value (CORE::values %{$self->{data}}) {
            if (defined(my $res = $code->_run_code($value->get_value))) {
                return $res;
            }
        }

        $code;
    }

    sub each_key {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %{$self->{data}}) {
            if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($key)))) {
                return $res;
            }
        }

        $code;
    }

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {

            foreach my $key (CORE::keys %{$self->{data}}) {
                if (
                    defined(my $res = $obj->_run_code(Sidef::Types::String::String->new($key), $self->{data}{$key}->get_value))
                  ) {
                    return $res;
                }
            }

            return $obj;
        }

        my ($key, $value) = each(%{$self->{data}});

        $key // return;
        Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value->get_value);
    }

    *each_pair = \&each;

    sub sort_by {
        my ($self, $code) = @_;

        my @array;
        while (my ($key, $value) = CORE::each %{$self->{data}}) {
            push @array, [$key, $code->run(Sidef::Types::String::String->new($key), $value->get_value)];
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
    *to_array = \&to_a;

    sub exists {
        my ($self, $key) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->{data}{$key});
    }

    *has_key  = \&exists;
    *haskey   = \&exists;
    *contains = \&exists;

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash->{data}}{map { $_->get_value } CORE::values %{$self->{data}}} =
          (map { Sidef::Variable::Variable->new(name => '', type => 'var', value => Sidef::Types::String::String->new($_)) }
            CORE::keys %{$self->{data}});

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
        my @keys = sort { lc($a) cmp lc($b) } CORE::keys(%{$self->{data}});

        my $str = Sidef::Types::String::String->new(
            "Hash.new(" . (
                @keys
                ? (
                   (@keys > 1 ? "\n" : '') . join(
                       ",\n",
                       map {
                           my $val =
                             ref($self->{data}{$_}) eq 'Sidef::Variable::Variable'
                             ? $self->{data}{$_}->get_value
                             : Sidef::Types::Nil::Nil->new;

                           (@keys > 1 ? (' ' x $Sidef::SPACES) : '')
                             . "${Sidef::Types::String::String->new($_)->dump} => "
                             . (eval { $val->can('dump') } ? ${$val->dump} : $val)
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
        *{__PACKAGE__ . '::' . '==='} = \&duplicateOf;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . ':'}   = \&new;
    }
};

1
