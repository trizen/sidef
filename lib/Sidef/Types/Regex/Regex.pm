package Sidef::Types::Regex::Regex {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $regex, $mod) = @_;

        if (ref($mod) eq 'Sidef::Types::String::String') {
            $mod = $$mod;
        }

        my $global_mode = 0;
        if (defined($mod)) {
            if (index($mod, 'g') != -1) {
                $mod =~ tr/g//d;
                $global_mode = 1;
            }
        }

        if (not defined $mod or $mod eq '') {
            $mod = q{^};
        }

        my $str_re = qr{(?$mod:$regex)};

        bless {
               regex  => $str_re,
               global => $global_mode,
               pos    => 0,
              },
          __PACKAGE__;
    }

    sub get_value { $_[0]{regex} }

    *def_method = \&Sidef::def_method;

    sub match {
        my ($self, $object, $pos) = @_;

        if (ref $object eq 'Sidef::Types::Array::Array') {
            foreach my $item (@{$object}) {
                my $match = $self->matches($item->get_value);
                $match->matched && return $match;
            }
        }

        $self->_is_string($object) || return;
        $object = $$object;

        require Sidef::Types::Regex::Matches;
        Sidef::Types::Regex::Matches->new(
                                          obj  => $object,
                                          self => $self,
                                          pos  => defined($pos) ? $self->_is_number($pos) ? $$pos : return : undef,
                                         );
    }

    *matches = \&match;

    sub gmatch {
        my ($self, $obj, $pos) = @_;
        local $self->{global} = 1;
        $self->matches($obj, $pos);
    }

    *gmatches = \&gmatch;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=~'} = \&matches;    # alias to the 'matches' method
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('/' . $self->{regex} =~ s{/}{\\/}gr . '/');
    }
}
