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
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
            map {
                Sidef::Types::Array::Array->new(Sidef::Types::String::String->new($_), $self->{$_}->get_value)
              } CORE::keys %{$self}
        );
    }

    sub exists {
        my ($self, $key) = @_;
        $key // do {
            warn sprintf(
                           "[exists] %s\n", @_ == 1
                         ? "No keyword specified!"
                         : "Invalid keyword: not defined!"
                        );
            return;
        };
        Sidef::Types::Bool::Bool->new(exists $self->{$key});
    }

    sub map {
        my ($self, $keys, $struct) = @_;

        for (my $i = 0 ; $i < $#{$struct} ; $i += 2) {
            my ($key, $value) = map { $_->get_value } @{$struct}[$i, $i + 1];

            $self->{$key} //= Sidef::Variable::Variable->new(rand, 'var', $self->new());

            foreach my $i (0 .. $#{$keys}) {
                my $hash = $self->{$key}->get_value;
                $hash->{$keys->[$i]} = Sidef::Variable::Variable->new(rand, 'var', $value->[$i]->get_value);
            }
        }

        return $self;
    }

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{CORE::values %{$self}} =
          (map { Sidef::Types::String::String->new($_) } CORE::keys %{$self});
        $new_hash;
    }
}
