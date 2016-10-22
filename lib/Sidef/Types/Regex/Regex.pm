package Sidef::Types::Regex::Regex {

    use 5.014;

    use re 'eval';    # XXX: do we really want this?

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{""}   => \&get_value,
      q{bool} => \&get_value,
      q{0+}   => \&get_value;

    sub new {
        my (undef, $regex, $mode) = @_;

        $regex = defined($regex) ? ref($regex) ? "$regex" : $regex : '';
        $mode  = defined($mode)  ? ref($mode)  ? "$mode"  : $mode  : '';

        my $global_mode = $mode =~ tr/g//d;
        my $compiled_re = $mode eq '' ? qr{$regex} : qr{(?$mode:$regex)};

        bless {
               regex  => $compiled_re,
               raw    => $regex,
               flags  => $mode,
               global => $global_mode,
               pos    => 0,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub get_value { $_[0]{regex} }

    sub to_regex { $_[0] }
    *to_re = \&to_regex;

    sub match {
        my ($self, $object, $pos) = @_;

        # Return a new Match object
        Sidef::Types::Regex::Match->new(
                                        obj  => "$object",
                                        self => $self,
                                        pos  => defined($pos) ? CORE::int($pos) : undef,
                                       );
    }

    sub gmatch {
        my ($self, $obj, $pos) = @_;
        local $self->{global} = 1;
        $self->match($obj, $pos);
    }

    sub dump {
        my ($self) = @_;

        my $str   = $self->{raw};
        my $flags = $self->{flags};

        Sidef::Types::String::String->new('/' . $str =~ s{/}{\\/}gr . '/' . $flags . ($self->{global} ? 'g' : ''));
    }

    *to_s = \&dump;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=~'} = \&match;
    }

};

1
