package Sidef::Types::Glob::Backtick {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $backtick) = @_;
        bless \$backtick, __PACKAGE__;
    }

    sub _run {
        my ($self) = @_;
        `$$self`;
    }

    sub getString {
        my ($self) = @_;
        Sidef::Types::String::String->new(scalar($self->_run));
    }

    *get_string = \&getString;

    sub getLines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_)->chomp } $self->_run);
    }

    *get_lines = \&getLines;
    *get_array = \&getLines;
    *getArray  = \&getLines;

};

1
