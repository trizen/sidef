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

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'} = sub {
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
        };
    }

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
                $array->push(
                           Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($key), $value->get_value));
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
}
