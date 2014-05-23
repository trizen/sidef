package Sidef::Perl::Perl {

    use 5.014;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub to_sidef {
        my ($self, $data) = @_;

        my $guess_type;
        $guess_type = sub {
            my ($val) = @_;

            my $ref = CORE::ref($val);
            if ($ref eq 'ARRAY') {
                my $array = Sidef::Types::Array::Array->new;
                foreach my $item (@{$val}) {
                    $array->push($guess_type->($item));
                }
                return $array;
            }
            elsif ($ref eq 'HASH') {
                my $hash = Sidef::Types::Hash::Hash->new;
                while (my ($key, $value) = each %{$val}) {
                    $hash->append($key, $guess_type->($value));
                }
                return $hash;
            }
            elsif ($ref eq 'Regexp') {
                return Sidef::Types::Regex::Regex->new($val);
            }
            elsif ($ref eq '') {
                require Scalar::Util;

                if (Scalar::Util::looks_like_number($val)) {
                    return Sidef::Types::Number::Number->new($val);
                }
            }

            return CORE::ref($val) ? $val : Sidef::Types::String::String->new($val);
        };

        $guess_type->($data);
    }
}

1;
