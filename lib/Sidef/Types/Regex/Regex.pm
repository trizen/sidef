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

        $regex = defined($regex) ? ref($regex) ? $regex->get_value : $regex : '';
        $mode  = defined($mode)  ? ref($mode)  ? $mode->get_value  : $mode  : '';

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

        $object //= do { state $x = Sidef::Types::String::String->new('') };

        if ($object->SUPER::isa('ARRAY')) {
            my $match;
            foreach my $item (@{$object}) {
                $match = $self->match($item);
                $match->matched && return $match;
            }
            return $match // $self->match(Sidef::Types::String::String->new);
        }

        Sidef::Types::Regex::Match->new(
                                        obj  => $object->get_value,
                                        self => $self,
                                        pos  => defined($pos) ? $pos->get_value : undef,
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
