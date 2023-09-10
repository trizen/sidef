package Sidef::Types::Perl::Perl {

    use utf8;
    use 5.016;

    use parent qw(
      Sidef::Object::Object
    );

    use overload q{""} => sub {
        'Perl(' . ${Sidef::Types::String::String->new(${$_[0]})->dump} . ')';
    };

    sub new {
        my (undef, $code) = @_;

        if (ref($_[0]) eq __PACKAGE__) {
            return $_[0]->eval;
        }

        bless \(my $o = "$code"), __PACKAGE__;
    }

    *call = \&new;

    sub code {
        my ($self) = @_;
        Sidef::Types::String::String->new($$self);
    }

    sub numeric_version {
        Sidef::Types::Number::Number->new($]);
    }

    sub version {
        Sidef::Types::String::String->new($^V);
    }

    sub to_sidef {
        my ($self, $data) = @_;

        my %refs;

        sub {
            my ($val) = @_;

            my $ref = CORE::ref($val // return undef);

            if (index($ref, "Sidef::") == 0) {
                return $val;
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

            if ($ref eq 'CODE') {
                return Sidef::Types::Block::Block->new(
                    code => sub {
                        map { $self->to_sidef($_) } $val->(map { (index(ref($_), 'Sidef::') == 0) ? $_->get_value : $_ } @_);
                    }
                );
            }

            if ($ref eq 'Regexp') {
                return Sidef::Types::Regex::Regex->new($val);
            }

            if (   $ref eq 'Math::BigFloat'
                or $ref eq 'Math::BigInt'
                or $ref eq 'Math::BigRat'
                or $ref eq 'Math::BigInt::Lite') {
                return Sidef::Types::Number::Number->new($val->bstr);
            }

            if ($ref eq 'Math::Complex') {
                return Sidef::Types::Number::Complex->new($val->Re, $val->Im);
            }

            if (   $ref eq 'Math::MPFR'
                or $ref eq 'Math::GMPz'
                or $ref eq 'Math::GMPq'
                or $ref eq 'Math::MPC') {
                return Sidef::Types::Number::Number->new($val);
            }

            if ($ref eq '') {

                if (Scalar::Util::looks_like_number($val)) {

                    if ($val =~ tr/e.//) {    # parse as float
                        return Sidef::Types::Number::Number::_set_str('float', "$val");
                    }

                    return Sidef::Types::Number::Number->new("$val");
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

    sub execute {
        ref($_[0]) || shift(@_);
        my ($self) = @_;
        __PACKAGE__->to_sidef(CORE::eval($$self));
    }

    *run  = \&execute;
    *eval = \&execute;

    sub tie {
        my ($self, $variable, $class_name, @args) = @_;
        state $x = require Scalar::Util;
        my $type = Scalar::Util::reftype($variable);
        __PACKAGE__->to_sidef(
                              CORE::tie(
                                        ($type eq 'ARRAY' ? (@$variable) : $type eq 'HASH' ? %$variable : $variable),
                                        "$class_name",
                                        map { defined($_) ? $_->get_value : $_ } @args
                                       )
                             );
    }

    sub untie {
        my ($self, $variable) = @_;
        state $x = require Scalar::Util;
        my $type = Scalar::Util::reftype($variable);
        __PACKAGE__->to_sidef(CORE::untie($type eq 'ARRAY' ? (@$variable) : $type eq 'HASH' ? %$variable : $variable));
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }

    *to_s   = \&dump;
    *to_str = \&dump;
};

1
