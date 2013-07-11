package Sidef::Types::Regex::Matches {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, %hash) = @_;

        my (@matches) = ($hash{obj} =~ $hash{regex});
        $hash{matched} = (@matches != 0);

        if (not defined $1) {
            @matches = ();
        }

        $hash{matches} = \@matches;
        foreach my $key (keys %+) {
            $hash{named_matches}{$key} = $+{$key};
        }

        bless \%hash, __PACKAGE__;
    }

    sub matched {
        Sidef::Types::Bool::Bool->new($_[0]->{matched});
    }

    sub matches {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } @{$self->{matches}});
    }

    sub named_matches {
        my ($self) = @_;
        my $hash = Sidef::Types::Hash::Hash->new();

        foreach my $key (keys %{$self->{named_matches}}) {
            $hash->{$key} = Sidef::Types::String::String->new($self->{named_matches}{$key});
        }

        $hash;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '??'} = \&matched;
    }
}
