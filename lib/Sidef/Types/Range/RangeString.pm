package Sidef::Types::Range::RangeString {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload
      '@{}' => \&to_a,
      q{""} => \&dump;
    use Sidef::Types::Bool::Bool;

    sub new {
        my (undef, $from, $to, $direction) = @_;

        if (defined $to) {
            $from      = ref($from)      ? $from->get_value      : $from;
            $to        = ref($to)        ? $to->get_value        : $to;
            $direction = ref($direction) ? $direction->get_value : defined($direction) ? $direction : 1;
        }
        elsif (defined $from) {
            $to        = ref($from) ? $from->get_value : $from;
            $from      = 'a';
            $direction = 1;
        }
        else {
            ($from, $to, $direction) = ('b', 'a', 1);
        }

        bless {
               from => $from,
               to   => $to,
               asc  => $direction,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub min {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{asc} ? $self->{from} : $self->{to});
    }

    sub max {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{asc} ? $self->{to} : $self->{from});
    }

    sub asc {
        my ($self) = @_;
        $self->{asc} ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub bounds {
        my ($self) = @_;
        ($self->min, $self->max);
    }

    sub reverse {
        my ($self) = @_;
        __PACKAGE__->__new__(
                             from => $self->{to},
                             to   => $self->{from},
                             asc  => $self->{asc} ^ 1,
                            );
    }

    sub contains {
        my ($self, $num) = @_;

        my $value = $num->get_value;
        my ($min, $max) = map { $_->get_value } ($self->min, $self->max);

        ($value ge $min and $value le $max) ? (Sidef::Types::Bool::Bool::TRUE) : (Sidef::Types::Bool::Bool::FALSE);
    }

    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub each {
        my ($self, $code) = @_;

        my $from = $self->{from};
        my $to   = $self->{to};

        if ($self->{asc}) {
            if (length($from) == 1 and length($to) == 1) {
                foreach my $i (ord($from) .. ord($to)) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new(chr($i))))) {
                        return $res;
                    }
                }
            }
            else {
                foreach my $str ($from .. $to) {    # this is lazy
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($str)))) {
                        return $res;
                    }
                }
            }
        }
        else {
            if (length($from) == 1 and length($to) == 1) {
                my $f = ord($from);
                my $t = ord($to);
                for (; $f >= $t ; $f--) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new(chr($f))))) {
                        return $res;
                    }
                }
            }
            else {
                foreach my $str (reverse($from .. $to)) {    # this is not lazy
                    if (defined(my $res = $code->_run_code(Sidef::Types::String::String->new($str)))) {
                        return $res;
                    }
                }
            }
        }

        $self;
    }

    *for     = \&each;
    *foreach = \&each;

    our $AUTOLOAD;
    sub DESTROY { }

    sub to_array {
        my ($self) = @_;
        local $AUTOLOAD;
        $self->AUTOLOAD();
    }

    *to_a = \&to_array;

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = (defined($AUTOLOAD) ? ($AUTOLOAD =~ /^.*[^:]::(.*)$/) : '');

        my $array;
        my $method = $self->{asc} ? 'array_to' : 'array_downto';

        $array = Sidef::Types::String::String->new($self->{from})->$method(Sidef::Types::String::String->new($self->{to}));
        $name eq '' ? $array : $array->$name(@args);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=='} = sub {
            my ($r1, $r2) = @_;
            (ref($r1) eq ref($r2) and $r1->{from} eq $r2->{from} and $r1->{to} eq $r2->{to} and $r1->{asc} eq $r2->{asc})
              ? (Sidef::Types::Bool::Bool::TRUE)
              : (Sidef::Types::Bool::Bool::FALSE);
        };
    }

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                                          "RangeStr("
                                            . join(', ',
                                                   ${Sidef::Types::String::String->new($self->{from})->dump},
                                                   ${Sidef::Types::String::String->new($self->{to})->dump},
                                                   Sidef::Types::Bool::Bool->new($self->{asc}),
                                                  )
                                            . ")"
                                         );
    }
}

1;
