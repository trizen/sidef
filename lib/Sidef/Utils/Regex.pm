
use 5.014;
use strict;
use warnings;

package Sidef::Utils::Regex {

    sub make_esc_delim {
        if ($_[0] ne '\\') {
            my $delim = quotemeta shift;
            return qr{$delim([^$delim\\]*+(?>\\.|[^$delim\\]+)*+)$delim}s;
        }
        else {
            return qr{\\(.*?)\\}s;
        }
    }

}

1;
