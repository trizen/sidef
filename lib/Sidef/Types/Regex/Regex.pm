package Sidef::Types::Regex::Regex {

    use 5.014;

    use re 'eval';    # XXX: do we really want this?

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $regex, $mode, $parser) = @_;

        if (ref($mode) eq 'Sidef::Types::String::String') {
            $mode = $mode->get_value;
        }

        my $global_mode = defined($mode) && $mode =~ tr/g//d;

        if (not defined $mode or $mode eq '') {
            $mode = q{^};
        }

        my $compiled_re = qr{(?$mode:$regex)};

        bless {
               regex  => $compiled_re,
               global => $global_mode,
               pos    => 0,
               parser => $parser,
              },
          __PACKAGE__;
    }

    sub get_value { $_[0]{regex} }

    sub match {
        my ($self, $object, $pos) = @_;

        if (ref $object eq 'Sidef::Types::Array::Array') {
            my $match;
            foreach my $item (@{$object}) {
                $match = $self->matches($item->get_value);
                $match->matched && return $match;
            }
            return $match // $self->matches(Sidef::Types::String::String->new);
        }

        $self->_is_string($object, 0, 1) || return;
        $object = $$object;

        require Sidef::Types::Regex::Matches;
        Sidef::Types::Regex::Matches->new(
                                          obj    => $object,
                                          self   => $self,
                                          parser => $self->{parser},
                                          pos    => defined($pos) ? $self->_is_number($pos) ? $$pos : return : undef,
                                         );
    }

    *matches = \&match;

    sub gmatch {
        my ($self, $obj, $pos) = @_;
        local $self->{global} = 1;
        $self->matches($obj, $pos);
    }

    *gmatches = \&gmatch;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('/' . $self->{regex} =~ s{/}{\\/}gr . '/');
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=~'} = \&match;
    }

};

1
