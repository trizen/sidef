package Sidef::Types::Regex::Regex {

    use utf8;
    use 5.016;

    use re 'eval';    # XXX: do we really want this?

    use parent qw(Sidef::Object::Object);
    use Sidef::Types::Number::Number;

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

    sub eq {
        my ($x, $y) = @_;

        ($x->{regex} eq $y->{regex})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ne {
        my ($x, $y) = @_;

        ($x->{regex} ne $y->{regex})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub cmp {
        my ($x, $y) = @_;

        my $cmp = $x->{regex} cmp $y->{regex};

        return Sidef::Types::Number::Number::MONE if ($cmp < 0);
        return Sidef::Types::Number::Number::ONE  if ($cmp > 0);
        return Sidef::Types::Number::Number::ZERO;
    }

    sub lt {
        my ($x, $y) = @_;
        Math::GMPz::Rmpz_sgn(${$x->cmp($y)}) < 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub le {
        my ($x, $y) = @_;
        Math::GMPz::Rmpz_sgn(${$x->cmp($y)}) <= 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub gt {
        my ($x, $y) = @_;
        Math::GMPz::Rmpz_sgn(${$x->cmp($y)}) > 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub ge {
        my ($x, $y) = @_;
        Math::GMPz::Rmpz_sgn(${$x->cmp($y)}) >= 0
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub to_regex { $_[0] }
    *to_re = \&to_regex;

    sub match {
        my ($self, $object, $pos) = @_;

        # Return a new Match object
        Sidef::Types::Regex::Match->new(string => "$object", regex => $self, pos => $pos);
    }

    *run = \&match;

    sub global_match {
        my ($self, $obj, $pos) = @_;
        local $self->{global} = 1;
        local $self->{pos}    = CORE::int($pos // 0);
        $self->match($obj);
    }

    *gmatch = \&global_match;

    sub global_matches {
        my ($self, $obj, $third, $fourth) = @_;

        my ($pos, $block) = (0, undef);

        if (UNIVERSAL::isa($third, 'Sidef::Types::Number::Number')) {
            $pos = $third;
        }
        elsif (UNIVERSAL::isa($third, 'Sidef::Types::Block::Block')) {
            $block = $third;
        }

        if (UNIVERSAL::isa($fourth, 'Sidef::Types::Number::Number')) {
            $pos = $fourth;
        }
        elsif (UNIVERSAL::isa($fourth, 'Sidef::Types::Block::Block')) {
            $block = $fourth;
        }

        my @matches;
        local $self->{global} = 1;
        local $self->{pos}    = CORE::int($pos);

        if (defined($block)) {
            my $i = 0;

            while ((my $m = $self->match($obj))->{matched}) {
                CORE::push(@matches, $block->run(Sidef::Types::Number::Number->_set_uint($i++), $m));
            }
        }
        else {
            while ((my $m = $self->match($obj))->{matched}) {
                CORE::push(@matches, $m);
            }
        }

        Sidef::Types::Array::Array->new(\@matches);
    }

    *gmatches       = \&global_matches;
    *all_matches    = \&global_matches;
    *map_matches    = \&global_matches;
    *repeated_match = \&global_matches;

    sub dump {
        my ($self) = @_;

        my $str   = $self->{raw};
        my $flags = $self->{flags};

        Sidef::Types::String::String->new('/' . $str =~ s{/}{\\/}gr . '/' . $flags . ($self->{global} ? 'g' : ''));
    }

    *to_s   = \&dump;
    *to_str = \&dump;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=~'}  = \&match;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'}   = \&ne;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'}   = \&le;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '≥'}   = \&ge;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
    }

};

1
