package Sidef::Types::Regex::Match {

    use 5.014;
    use overload
      q{bool} => \&to_bool,
      q{""}   => \&to_s,
      q{@{}}  => sub {
        $_[0]->{_cached_arr} //= [map { Sidef::Types::String::String->new($_) } @{$_[0]->{captures}}];
      };

    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, %hash) = @_;

        my @captures;
        if ($hash{self}{global}) {
            pos($hash{obj}) = $hash{self}{pos};
            my $match = $hash{obj} =~ /$hash{self}{regex}/g;

            if ($match) {
                $hash{self}{pos} = pos($hash{obj});

                foreach my $i (1 .. $#{+}) {
                    push @captures, substr($hash{obj}, $-[$i], $+[$i] - $-[$i]);
                }

                $hash{matched} = 1;
            }
            else {
                $hash{self}{pos} = 0;
                $hash{matched} = 0;
            }

            foreach my $key (keys %+) {
                $hash{named_captures}{$key} = $+{$key};
            }
        }
        else {
            @captures =
              defined($hash{pos})
              ? (substr($hash{obj}, $hash{pos}) =~ $hash{self}{regex})
              : ($hash{obj} =~ $hash{self}{regex});

            $hash{matched} = (@captures != 0);
            $hash{match_pos} = $hash{matched} ? [$-[0] + ($hash{pos} // 0), $+[0] + ($hash{pos} // 0)] : [];

            foreach my $key (keys %+) {
                $hash{named_captures}{$key} = $+{$key};
            }
        }

        $hash{captures} = \@captures;

        #if (defined $hash{parser}) {
        #    while (my ($key, $value) = each %{$hash{parser}{regexp_vars}}) {
        #        $value->set_value(Sidef::Types::String::String->new($captures[$key - 1]));
        #    }
        #}

        bless \%hash, __PACKAGE__;
    }

    sub get_value {
        $_[0]->{matched};
    }

    sub matched {
        ($_[0]->{matched}) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *to_bool       = \&matched;
    *is_successful = \&matched;

    sub pos {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::Number::Number->new($_) } @{$self->{match_pos}});
    }

    sub captures {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } @{$self->{captures}});
    }

    *cap  = \&captures;
    *caps = \&captures;

    sub named_captures {
        my ($self) = @_;

        my $hash = Sidef::Types::Hash::Hash->new();
        while (my ($key, $value) = each %{$self->{named_captures}}) {
            $hash->{$key} = Sidef::Types::String::String->new($value);
        }
        $hash;
    }

    *ncap  = \&named_captures;
    *ncaps = \&named_captures;

    sub join {
        my ($self, $sep) = @_;
        Sidef::Types::String::String->new(CORE::join($sep->get_value, @{$self->{captures}}));
    }

    sub to_s {
        my ($self) = @_;
        Sidef::Types::String::String->new(CORE::join(' ', @{$self->{captures}}));
    }
};

1
