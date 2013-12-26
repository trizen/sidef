package Sidef::Types::Hash::Hash {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef::Convert::Convert);

    sub new {
        my (undef, @pairs) = @_;

        my %hash;
        my $offset = $#pairs;

        for (my $i = 0 ; $i < $offset ; $i += 2) {
            $hash{$pairs[$i]} = Sidef::Variable::Variable->new(rand, 'var', $pairs[$i + 1]);
        }

        bless \%hash, __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;

        my %hash;
        while (my ($k, $v) = each %{$self}) {
            $hash{$k} = ref($v) && $v->can('get_value') ? $v->get_value : $v;
        }

        \%hash;
    }

    sub get {
        my ($self, @keys) = @_;

        if ($#keys == 0) {
            return $self->{$keys[0]};
        }

        Sidef::Types::Array::Array->new(map { defined($_) ? $_->get_value : $_ } @{$self}{@keys});
    }

    sub select {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($key_var, $val_var) = $code->init_block_vars;

        if (not defined $val_var) {
            $val_var = Sidef::Types::Black::Hole->new;
        }

        my $new_hash = $self->new;

        while (my ($key, $value) = each %{$self}) {

            my $key_obj = Sidef::Types::String::String->new($key);
            my $val_obj = $value->get_value;

            $key_var->set_value($key_obj);
            $val_var->set_value($val_obj);

            if ($code->run) {
                $new_hash->append($key_obj, $val_obj);
            }
        }

        $new_hash;
    }

    *grep = \&select;

    sub duplicate_of {
        my ($self, $obj) = @_;

        $self->_is_hash($obj);
        %{$self} eq %{$obj} || return Sidef::Types::Bool::Bool->false;

        my $ne_method = '!=';
        while (my ($key, $value) = each %{$self}) {
            !exists($obj->{$key})
              && (return Sidef::Types::Bool::Bool->false);

            $value->get_value->$ne_method($obj->{$key}->get_value)
              && return (Sidef::Types::Bool::Bool->false);
        }

        Sidef::Types::Bool::Bool->true;
    }

    *duplicateOf = \&duplicate_of;

    sub eq {
        my ($self, $obj) = @_;

        $self->_is_hash($obj);
        %{$self} eq %{$obj} || return Sidef::Types::Bool::Bool->false;

        while (my ($key) = each %{$self}) {
            !exists($obj->{$key})
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
        $self->{$key} = Sidef::Variable::Variable->new(rand, 'var', $value);
    }

    sub concat {
        my ($self, $obj) = @_;

        my @list;
        while (my ($key, $val) = each %{$self}) {
            push @list, $key, $val->get_value;
        }

        if ($self->_is_hash($obj, 1, 1)) {

            while (my ($key, $val) = each %{$obj}) {
                push @list, $key, $val->get_value;
            }
        }
        elsif ($self->_is_array($obj, 1, 1)) {
            push @list, map { $_->get_value } @{$obj};
        }
        else {
            warn "[WARN] Invalid object for hash concatenation! Expected hash or array.\n";
            return $self;
        }

        $self->new(@list);
    }

    *merge = \&concat;

    sub merge_values {
        my ($self, $obj) = @_;

        $self->_is_hash($obj) || return;

        while (my ($key, undef) = each %{$self}) {
            if (exists $obj->{$key}) {
                $self->{$key} = $obj->{$key};
            }
        }

        $self;
    }

    *mergeValues = \&merge_values;

    sub keys {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } keys %{$self});
    }

    sub values {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { $_->get_value } values %{$self});
    }

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {
            $self->_is_code($obj) || return;

            my $array = Sidef::Types::Array::Array->new();
            while (my ($key, $value) = each %{$self}) {
                $array->push(Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value->get_value));
            }

            return $obj->for($array);
        }

        my ($key, $value) = each(%{$self});

        $key // return;
        Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value->get_value);
    }

    sub sort_by {
        my ($self, $block) = @_;
        $self->_is_code($block) || return;

        my @array;
        while (my ($key, $value) = CORE::each %{$self}) {
            push @array, [$key, $block->call(Sidef::Types::String::String->new($key), $value->get_value)];
        }

        my $method = '<=>';
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($_->[0]), $self->{$_->[0]}->get_value)
              } (sort { $a->[1]->can($method) ? ($a->[1]->$method($b->[1])) : -1 } @array)
        );
    }

    sub to_a {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($_), $self->{$_}->get_value)
              } CORE::keys %{$self}
        );
    }

    *pairs    = \&to_a;
    *toArray  = \&to_a;
    *to_array = \&to_a;

    sub exists {
        my ($self, $key) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->{$key});
    }

    *has_key = \&exists;

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{CORE::values %{$self}} =
          (map { Sidef::Types::String::String->new($_) } CORE::keys %{$self});
        $new_hash;
    }

    sub copy {
        my ($self) = @_;
        $self->new(map { ref($_) ? $_->get_value : $_ } %{$self});
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
            "Hash.new(\n" . join(
                ",\n",
                map {
                    my $val =
                      ref($self->{$_}) eq 'Sidef::Variable::Variable'
                      ? $self->{$_}->get_value
                      : Sidef::Types::Nil::Nil->new;
                    "\t${Sidef::Types::String::String->new($_)->dump} => "
                      . (eval { $val->can('dump') } ? ${$val->dump} : $val)
                  } sort(CORE::keys(%{$self}))
              )
              . "\n)"
        );
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '==='} = \&duplicateOf;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
    }
};

1
