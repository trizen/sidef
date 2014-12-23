package Sidef::Types::Char::Char {

    our @ISA = qw(
      Sidef::Types::String::String
      );

    sub new {
        my (undef, $char) = @_;
        ref($char) && return $char->to_char;
        bless \$char, __PACKAGE__;
    }

    sub call {
        my ($self, $char) = @_;
        $self->new(chr ord $char);
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(q{Char.new('} . $$self =~ s{'}{\\'}gr . q{')});
    }
};

1
