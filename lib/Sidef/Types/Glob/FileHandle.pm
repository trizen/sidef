
use 5.014;
use strict;
use warnings;

package Sidef::Types::Glob::FileHandle {

    sub new {
        my ($class, %opt) = @_;

        bless {
               fh   => $opt{fh},
               name => $opt{name},
              }, $class;
    }

    sub close {

    }

};

1;
