package Sidef::Types::Char::Char {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef::Types::String::String
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $char) = @_;
        ref($char) && return $char->to_char;
        bless \$char, __PACKAGE__;
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(q{Char.new('} . $$self =~ s{'}{\\'}gr . q{')});
    }

}
