package Sidef::Perl::Perl {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub to_sidef {
        my ($self, $data) = @_;

        my %refs;

        my $guess_type;
        $guess_type = sub {
            my ($val) = @_;

            my $ref = CORE::ref($val);
            if (not defined $val) {
                return Sidef::Types::Nil::Nil->new;
            }

            if ($ref eq 'ARRAY') {
                my $array = $refs{$val} //= Sidef::Types::Array::Array->new;
                foreach my $item (@{$val}) {
                    $array->push(
                                 ref($item) eq 'ARRAY' && $item eq $val
                                 ? Sidef::Variable::Variable->new(type => 'var', name => '', value => $array)
                                 : $guess_type->($item)
                                );
                }
                return $array;
            }

            if ($ref eq 'HASH') {
                my $hash = $refs{$val} //= Sidef::Types::Hash::Hash->new;
                while (my ($key, $value) = each %{$val}) {
                    $hash->append(
                                  $key,
                                  ref($value) eq 'HASH' && $value eq $val
                                  ? Sidef::Variable::Variable->new(type => 'var', name => '', value => $hash)
                                  : $guess_type->($value)
                                 );
                }
                return $hash;
            }

            if ($ref eq 'Regexp') {
                return Sidef::Types::Regex::Regex->new($val);
            }

            if ($ref eq '') {
                require Scalar::Util;

                if (Scalar::Util::looks_like_number($val)) {
                    return Sidef::Types::Number::Number->new($val);
                }

                return Sidef::Types::String::String->new($val);
            }

            $val;
        };

        $guess_type->($data);
    }

    sub eval {
        my ($self, $perl_code) = @_;
        $self->_is_string($perl_code) || return;
        $self->to_sidef(eval $$perl_code);
    }
};

1
