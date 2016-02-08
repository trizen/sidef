package Sidef::Perl::Perl {

    use 5.014;
    use Sidef::Types::Number::Number;

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
                return undef;
            }

            if ($ref eq 'ARRAY') {
                my $array = $refs{$val} //= Sidef::Types::Array::Array->new;
                foreach my $item (@{$val}) {
                    $array->push(
                                 ref($item) eq 'ARRAY' && $item eq $val
                                 ? $array
                                 : $guess_type->($item)
                                );
                }
                return $array;
            }

            if ($ref eq 'HASH') {
                my $hash = $refs{$val} //= Sidef::Types::Hash::Hash->new;
                foreach my $key (keys %{$val}) {
                    my $value = $val->{$key};
                    $hash->append(
                                    $key, ref($value) eq 'HASH' && $value eq $val
                                  ? $hash
                                  : $guess_type->($value)
                                 );
                }
                return $hash;
            }

            if ($ref eq 'Regexp') {
                return Sidef::Types::Regex::Regex->new($val);
            }

            if ($ref eq 'Math::BigFloat' or $ref eq 'Math::BigInt' or $ref eq 'Math::BigRat') {
                return (
                        $val->is_nan
                        ? Sidef::Types::Number::Nan->new
                        : $val->is_inf ? $val->is_inf('-')
                              ? Sidef::Types::Number::Ninf->new
                              : Sidef::Types::Number::Inf->new
                          : Sidef::Types::Number::Number->new($val->bstr, 10)
                       );
            }

            if ($ref eq 'Math::Complex') {
                return Sidef::Types::Number::Complex->new($val->Re, $val->Im);
            }

            if ($ref eq 'Math::MPFR') {
                return Sidef::Types::Number::Number::_mpfr2big($val);
            }

            if ($ref eq 'Math::GMPz') {
                return Sidef::Types::Number::Number::_mpz2big($val);
            }

            if ($ref eq 'Math::GMPq') {
                return bless(\$val, 'Sidef::Types::Number::Number');
            }

            if ($ref eq '') {
                state $x = require Scalar::Util;

                if (Scalar::Util::looks_like_number($val)) {
                    return Sidef::Types::Number::Number->new($val, 10);
                }

                return Sidef::Types::String::String->new($val);
            }

            # Return an OO object when $val is blessed
            state $x = require Scalar::Util;
            if (defined Scalar::Util::blessed($val)) {
                return Sidef::Module::OO->__NEW__($val);
            }

            $val;
        };

        $guess_type->($data);
    }

    sub eval {
        my ($self, $perl_code) = @_;
        $self->to_sidef(eval $perl_code->get_value);
    }
};

1
