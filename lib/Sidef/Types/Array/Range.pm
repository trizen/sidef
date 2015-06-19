package Sidef::Types::Array::Range {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub by {
        my ($self, $step) = @_;
        $self->{step} = $step->get_value;
        $self;
    }

    sub contains {
        my ($self, $num) = @_;

        my $value = $num->get_value;
        my ($min, $max) = map { $_->get_value } ($self->min, $self->max);

        if ($self->{type} eq 'number') {
            if ($value >= $min and $value <= $max) {
                return Sidef::Types::Bool::Bool->true;
            }
        }
        else {
            if ($value ge $min and $value le $max) {
                return Sidef::Types::Bool::Bool->true;
            }
        }
        Sidef::Types::Bool::Bool->false;
    }

    *includes = \&contains;

    sub min {
        my ($self) = @_;
        ($self->{type} eq 'number' ? 'Sidef::Types::Number::Number' : 'Sidef::Types::String::String')
          ->new($self->{direction} eq 'up' ? $self->{from} : $self->{to});
    }

    sub max {
        my ($self) = @_;
        ($self->{type} eq 'number' ? 'Sidef::Types::Number::Number' : 'Sidef::Types::String::String')
          ->new($self->{direction} eq 'up' ? $self->{to} : $self->{from});
    }

    sub step {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($self->{step});
    }

    sub bounds {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self->min, $self->max);
    }

    sub each {
        my ($self, $code) = @_;

        $code // return ($self->pairs);

        if ($self->{type} eq 'number') {

            my $step  = $self->{step};
            my $from  = $self->{from};
            my $limit = $self->{to};

            if ($self->{direction} eq 'up') {
                if ($step == 1 and not $limit > (-1 >> 1) and not $from > (-1 >> 1)) {
                    foreach my $i ($from .. $limit) {
                        if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                            return $res;
                        }
                    }

                }
                else {
                    for (my $i = $from ; $i <= $limit ; $i += $step) {
                        if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                            return $res;
                        }
                    }
                }
            }
            else {

                for (my $i = $from ; $i >= $limit ; $i -= $step) {
                    if (defined(my $res = $code->_run_code(Sidef::Types::Number::Number->new($i)))) {
                        return $res;
                    }
                }
            }
        }
        else {

            my $from = $self->{from};
            my $to   = $self->{to};

            if ($self->{direction} eq 'up') {
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
        }

        $self;
    }

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
        my $method = $self->{direction} eq 'up' ? 'array_to' : 'array_downto';
        if ($self->{type} eq 'number') {

            my $step = $self->{step};
            my $from = $self->{from};
            my $to   = $self->{to};

            $array = Sidef::Types::Number::Number->new($from)
              ->$method(Sidef::Types::Number::Number->new($to), $step != 1 ? Sidef::Types::Number::Number->new($step) : ());
        }
        else {
            my $from = $self->{from};
            my $to   = $self->{to};
            $array = Sidef::Types::String::String->new($from)->$method(Sidef::Types::String::String->new($to));
        }

        $name eq '' ? $array : $array->$name(@args);
    }
}

1;
