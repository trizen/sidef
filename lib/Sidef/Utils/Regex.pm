
use 5.014;
use strict;
use warnings;
use re 'eval';

package Sidef::Utils::Regex {

    my %bdelims;

    {
        local $" = q{};
        foreach my $d (get_delim_pairs()) {
            my @ed = map { quotemeta } @{$d};

            $bdelims{$d->[0]} = qr{
            $ed[0]
            (?>
                [^@ed\\]+
                    |
                \\.
                    |
                (??{$bdelims{$d->[0]}})
            )*
            $ed[1]
          }xs;
        }
    }

    # First of balanced pairs
    my $bbpair = qr~[<\[\{\(]~;

    # Double pairs
    my $dpairs = qr{
    (?=
      (?(?<=\s)
                (.)
            |
                (\W)
     )
    )
        (??{$bdelims{$+} // make_esc_delim($+)})
    }x;

    # Double pairs -- comments
    my $dcomm = qr{
       \s* (?>(?<=\s)\# (?-s:.*) \s*)*
    }x;

    sub make_esc_delim {
        if ($_[0] ne '\\') {
            my $delim = quotemeta shift;
            return qr{$delim([^$delim\\]*+(?>\\.|[^$delim\\]+)*+)$delim}s;
        }
        else {
            return qr{\\(.*?)\\}s;
        }
    }

    sub make_end_delim {
        if ($_[0] ne '\\') {
            my $delim = quotemeta shift;
            return qr{[^$delim\\]*+(?>\\.|[^$delim\\]+)*+$delim}s;
        }
        else {
            return qr{.*?\\}s;
        }
    }

    sub get_delim_pairs {
        return [qw~< >~], [qw~( )~], [qw~{ }~], [qw~[ ]~];
    }

    sub make_single_q_balanced {
        my $name = shift;
        qr{
            $name
            $dcomm
            $dpairs
        }x;
    }

    sub make_double_q_balanced {
        my $name = shift;
        qr{
          $name
          $dcomm

        (?(?=$bbpair)                    # balanced pairs (e.g.: s{}//)
           $dpairs
              $dcomm
           $dpairs
               |                         # or: single delims (e.g.: s///)
           $dpairs
          (??{make_end_delim($+)})
        )
       }x;
    }
}

1;
