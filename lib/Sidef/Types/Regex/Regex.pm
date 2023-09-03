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
        $x->cmp($y)->lt(Sidef::Types::Number::Number::ZERO)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub le {
        my ($x, $y) = @_;
        $x->cmp($y)->le(Sidef::Types::Number::Number::ZERO)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub gt {
        my ($x, $y) = @_;
        $x->cmp($y)->gt(Sidef::Types::Number::Number::ZERO)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub ge {
        my ($x, $y) = @_;
        $x->cmp($y)->ge(Sidef::Types::Number::Number::ZERO)
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
        local $self->{pos}    = CORE::int($pos) if defined($pos);
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
            my ($cpos, $lpos) = ($self->{pos}, $self->{pos});
            my $i = 0;

            while ((my $m = $self->match($obj))->{matched}) {
                $lpos = $cpos;
                last if ($lpos == ($cpos = $self->{pos}));
                CORE::push(@matches, $block->run(Sidef::Types::Number::Number::_set_int($i++), $m));
            }
        }
        else {
            my ($cpos, $lpos) = ($self->{pos}, $self->{pos});
            while ((my $m = $self->match($obj))->{matched}) {
                $lpos = $cpos;
                last if ($lpos == ($cpos = $self->{pos}));
                CORE::push(@matches, $m);
            }
        }

        Sidef::Types::Array::Array->new(\@matches);
    }

    *gmatches       = \&global_matches;
    *all_matches    = \&global_matches;
    *map_matches    = \&global_matches;
    *repeated_match = \&global_matches;

    sub add {
        my ($self, $other) = @_;

        my $x = $self->{regex};
        my $y = ref($other) eq __PACKAGE__ ? $other->{regex} : "\Q$other\E";

        __PACKAGE__->new("$x$y");
    }

    *concat = \&add;

    sub union {
        my ($self, $other, $extra_flags) = @_;

        my ($x, $x_flags, $x_global) = ($self->{raw}, $self->{flags}, $self->{global});
        my ($y, $y_flags, $y_global) = (undef, '', 0);

        my %x_flags;
        my %y_flags;

        if (ref($other) eq __PACKAGE__) {
            $y        = $other->{raw};
            $y_flags  = $other->{flags};
            $y_global = $other->{global};
        }
        else {
            $y = "\Q$other\E";
        }

        $x_flags{$_}++ for split(//, $x_flags);
        $y_flags{$_}++ for split(//, $y_flags);

        my %union = %x_flags;

        foreach my $k (keys %y_flags) {
            if (exists $union{$k}) {

                my $c1 = $x_flags{$k};
                my $c2 = $y_flags{$k};

                if ($c2 > $c1) {
                    $union{$k} = $c2;
                }
            }
            else {
                $union{$k} = $y_flags{$k};
            }
        }

        my $global = ($x_global || $y_global) ? 'g' : '';
        my $flags  = join('', map { $_ x $union{$_} } sort keys %union);

        $flags .= $extra_flags if defined($extra_flags);

        __PACKAGE__->new("$x$y", join('', sort split(//, $flags . $global)));
    }

    sub dump {
        my ($self) = @_;

        my $str   = $self->{raw};
        my $flags = $self->{flags};

        Sidef::Types::String::String->new('/' . $str =~ s{(?<!\\)(?:\\\\)*\K/}{\\/}gr . '/' . $flags . ($self->{global} ? 'g' : ''));
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
        *{__PACKAGE__ . '::' . '+'}   = \&concat;
        *{__PACKAGE__ . '::' . '|'}   = \&union;
    }

};

1
