package Sidef::Perl::Perl {

    use 5.016;
    use Sidef::Types::Number::Number;
    use Scalar::Util qw();

    sub new {
        bless {}, __PACKAGE__;
    }

    sub to_sidef {
        my ($self, $data) = @_;

        my %refs;

        sub {
            my ($val) = @_;

            my $ref = CORE::ref($val);
            if (not defined $val) {
                return undef;
            }

            if ($ref eq 'ARRAY') {
                my $array = $refs{$val} //= Sidef::Types::Array::Array->new([]);
                foreach my $item (@{$val}) {
                    push @$array,
                      (
                        ref($item) eq 'ARRAY' && $item eq $val
                        ? $array
                        : __SUB__->($item)
                      );
                }
                return $array;
            }

            if ($ref eq 'HASH') {
                my $hash = $refs{$val} //= Sidef::Types::Hash::Hash->new;
                foreach my $key (keys %{$val}) {
                    my $value = $val->{$key};
                    $hash->{$key} = (
                                     ref($value) eq 'HASH' && $value eq $val
                                     ? $hash
                                     : __SUB__->($value)
                                    );
                }
                return $hash;
            }

            if ($ref eq 'Regexp') {
                return Sidef::Types::Regex::Regex->new($val);
            }

            if (   $ref eq 'Math::BigFloat'
                or $ref eq 'Math::BigInt'
                or $ref eq 'Math::BigRat'
                or $ref eq 'Math::BigInt::Lite'
            ) {
                return Sidef::Types::Number::Number->new($val->bstr);
            }

            if ($ref eq 'Math::Complex') {
                return Sidef::Types::Number::Complex->new($val->Re, $val->Im);
            }

            if ($ref eq 'Math::MPFR'
            or $ref eq 'Math::GMPz'
            or $ref eq 'Math::GMPq'
            or $ref eq 'Math::MPC'
            ) {
                return Sidef::Types::Number::Number->new($val);
            }

            if ($ref eq '') {
                if (Scalar::Util::looks_like_number($val)) {
                    return Sidef::Types::Number::Number->new($val, 10);
                }

                return Sidef::Types::String::String->new($val);
            }

            # Return an OO object when $val is blessed
            if (defined Scalar::Util::blessed($val)) {
                return Sidef::Module::OO->__NEW__($val);
            }

            $val;
          }
          ->($data);
    }

    sub eval {
        my ($self, $perl_code) = @_;
        $self->to_sidef(eval "$perl_code");
    }
};

1
