package Sidef::Types::Array::Range {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        my (undef, %opt) = @_;
        bless \%opt;
    }

    sub each {
        my ($self, $code) = @_;

        $code // return ($self->pairs);
        $self->_is_code($code) || return;

        my ($var_ref) = $code->init_block_vars();

        if ($self->{type} eq 'number') {

            my $step  = $self->{step};
            my $from  = $self->{from};
            my $limit = $self->{to};

            for (my $i = $from ;
                 $self->{direction} eq 'up' ? ($i <= $limit) : ($i >= $limit) ;
                 $self->{direction} eq 'up' ? ($i += $step) : ($i -= $step)) {
                $var_ref->set_value(Sidef::Types::Number::Number->new($i));
                if (defined(my $res = $code->_run_code)) {
                    $code->pop_stack();
                    return $res;
                }
            }

            $code->pop_stack();
        }
        else {

            my $from = $self->{from};
            my $to   = $self->{to};

            if ($self->{direction} eq 'up') {
                if (length($from) == 1 and length($to) == 1) {
                    foreach my $i (ord($from) .. ord($to)) {
                        $var_ref->set_value(Sidef::Types::String::String->new(chr($i)));
                        if (defined(my $res = $code->_run_code)) {
                            $code->pop_stack();
                            return $res;
                        }
                    }
                }
                else {
                    foreach my $str ($from .. $to) {    # this is lazy
                        $var_ref->set_value(Sidef::Types::String::String->new($str));
                        if (defined(my $res = $code->_run_code)) {
                            $code->pop_stack();
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
                        $var_ref->set_value(Sidef::Types::String::String->new(chr($f)));
                        if (defined(my $res = $code->_run_code)) {
                            $code->pop_stack();
                            return $res;
                        }
                    }
                }
                else {
                    foreach my $str (reverse($from .. $to)) {    # this is not lazy
                        $var_ref->set_value(Sidef::Types::String::String->new($str));
                        if (defined(my $res = $code->_run_code)) {
                            $code->pop_stack();
                            return $res;
                        }
                    }
                }
            }
        }

        $self;
    }

    sub to_array {
        my ($self) = @_;
        $self->AUTOLOAD();
    }

    *to_a = \&to_array;

    our $AUTOLOAD;
    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my $array;
        my $method = $self->{direction} eq 'up' ? 'to' : 'downto';
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
