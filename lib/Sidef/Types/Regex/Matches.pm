package Sidef::Types::Regex::Matches {

    use 5.014;
    use overload 'bool' => \&to_bool;

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

        if (defined $hash{parser}) {
            while (my ($key, $value) = each %{$hash{parser}{regexp_vars}}) {
                $value->set_value(Sidef::Types::String::String->new($captures[$key - 1]));
            }
        }

        bless \%hash, __PACKAGE__;
    }

    sub matched {
        Sidef::Types::Bool::Bool->new($_[0]->{matched});
    }

    *to_bool       = \&matched;
    *toBool        = \&matched;
    *isSuccessful  = \&matched;
    *is_successful = \&matched;
    *get_value     = \&matched;

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

        foreach my $key (keys %{$self->{named_captures}}) {
            $hash->{data}{$key} = Sidef::Types::String::String->new($self->{named_captures}{$key});
        }

        $hash;
    }

    *ncap  = \&named_captures;
    *ncaps = \&named_captures;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '??'} = \&matched;
    }
};

1
