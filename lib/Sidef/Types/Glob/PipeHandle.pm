package Sidef::Types::Glob::PipeHandle {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef::Types::Glob::FileHandle
    );

    sub new {
        my (undef, %opt) = @_;

        bless {
               fh   => $opt{pipe_h},
               pipe => $opt{pipe},
              },
          __PACKAGE__;
    }

    sub get_value {
        $_[0]->{fh};
    }

    sub pipe {
        $_[0]{pipe};
    }

    *parent = \&pipe;

};

1;
