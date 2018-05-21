package Sidef::Types::Regex::Match {

    use utf8;
    use 5.016;

    use overload
      q{bool} => \&get_value,
      q{""}   => sub { CORE::join(' ', @{$_[0]->{captures}}) },
      q{@{}}  => sub {
        $_[0]->{_cached_cap} //= [map { Sidef::Types::String::String->new($_) } @{$_[0]->{captures}}];
      };

    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, %hash) = @_;

        my @captures;
        if ($hash{regex}{global}) {
            pos($hash{string}) = $hash{regex}{pos};
            my $match = $hash{string} =~ /$hash{regex}{regex}/g;

            if ($match) {
                $hash{regex}{pos} = pos($hash{string});

                foreach my $i (1 .. $#{+}) {
                    push @captures, substr($hash{string}, $-[$i], $+[$i] - $-[$i]);
                }

                $hash{matched} = 1;
            }
            else {
                $hash{regex}{pos} = 0;
                $hash{matched} = 0;
            }

            foreach my $key (keys %+) {
                $hash{named_captures}{$key} = $+{$key};
            }
        }
        else {
            @captures =
              defined($hash{pos})
              ? (substr($hash{string}, $hash{pos}) =~ $hash{regex}{regex})
              : ($hash{string} =~ $hash{regex}{regex});

            $hash{matched} = (@captures != 0);
            $hash{match_pos} = $hash{matched} ? [$-[0] + ($hash{pos} // 0), $+[0] + ($hash{pos} // 0)] : [];

            foreach my $key (keys %+) {
                $hash{named_captures}{$key} = $+{$key};
            }
        }

        $hash{captures} = \@captures;

        bless \%hash, __PACKAGE__;
    }

    sub get_value {
        $_[0]->{matched};
    }

    sub matched {
        $_[0]->{matched}
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *to_bool       = \&matched;
    *is_successful = \&matched;

    sub pos {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                    [@{$self->{_cached_pos} //= [map { Sidef::Types::Number::Number->_set_uint($_) } @{$self->{match_pos}}]}]);
    }

    sub captures {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                           [@{$self->{_cached_cap} //= [map { Sidef::Types::String::String->new($_) } @{$self->{captures}}]}]);
    }

    *cap  = \&captures;
    *caps = \&captures;
    *to_a = \&captures;

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
        Sidef::Types::String::String->new(CORE::join("$sep", @{$self->{captures}}));
    }

    sub string {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{string});
    }

    sub regex {
        my ($self) = @_;
        $self->{regex};
    }

    sub to_s {
        my ($self) = @_;
        Sidef::Types::String::String->new("$self");
    }

    sub dump {
        my ($self) = @_;
        my $re     = $self->{regex}->dump;
        my $str    = Sidef::Types::String::String->new($self->{string})->dump;
        Sidef::Types::String::String->new("($str =~ $re)");
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '...'} = sub {
            @{$_[0]->{_cached_cap} //= [map { Sidef::Types::String::String->new($_) } @{$_[0]->{captures}}]};
        };
    }
};

1
