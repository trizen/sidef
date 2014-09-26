package Sidef::Types::Array::Range {

    use 5.014;
    our @ISA = qw(Sidef);

    # use overload '@{}' => \&to_array,
    #               '""' => \&to_array;

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
                foreach my $str ($from .. $to) {    # this is lazy
                    $var_ref->set_value(Sidef::Types::String::String->new($str));

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

        $self;
    }

    sub to_array {
        my ($self) = @_;
        $self->AUTOLOAD();
    }

    our $AUTOLOAD;
    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my $array;
        if ($self->{type} eq 'number') {

            my $step  = $self->{step};
            my $from  = $self->{from};
            my $limit = $self->{to};

            $array = Sidef::Types::Array::Array->new();
            for (my $i = $from ;
                 $self->{direction} eq 'up' ? ($i <= $limit) : ($i >= $limit) ;
                 $self->{direction} eq 'up' ? ($i += $step) : ($i -= $step)) {
                $array->push(Sidef::Types::Number::Number->new($i));
            }
        }
        else {

            my $from = $self->{from};
            my $to   = $self->{to};

            my @range = ($from .. $to);
            $array = Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) }
                                                     $self->{direction} eq 'down' ? reverse(@range) : @range);
        }

        $name eq '' ? $array : $array->$name(@args);
    }
}

1;
