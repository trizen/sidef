package Sidef::Types::Block::Code {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    our @ISA = qw(Sidef);

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        $#_ == 1
          ? (bless {code => $_[1]}, __PACKAGE__)
          : do {
            my (undef, %hash) = @_;
            bless \%hash, __PACKAGE__;
          };
    }

    sub get_value {
        my ($self) = @_;
        sub {
            if (defined($a) || defined($b)) { push @_, $a, $b }
            elsif (defined($_)) { push @_, $_ }
            $self->call(Sidef::Types::Array::Array->new(@_));
        };
    }

    sub copy {
        my ($self) = @_;

        require Data::Dump;
        eval Data::Dump::pp($self);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '*'} = \&repeat;

        *{__PACKAGE__ . '::' . ':'} = sub {
            my ($self, $code) = @_;

            if (ref($code) eq 'HASH') {
                return Sidef::Types::Hash::Hash->new($exec->execute($code));
            }

            warn "[WARN] Missing argument for hash operator ':'!\n";
            return;
        };
    }

    sub repeat {
        my ($self, $num) = @_;

        my ($var) = $self->init_block_vars();

        foreach my $i (1 .. (defined($num) ? $self->_is_number($num) ? ($$num) : return : (1))) {
            $var->set_value(Sidef::Types::Number::Number->new($i));

            if (defined(my $res = $self->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    sub to_hash {
        my ($self) = @_;
        my @results = $exec->execute($self->{code});
        shift @results;    # ignore the block private variable (_)
        Sidef::Types::Hash::Hash->new(@results);
    }

    *toHash = \&to_hash;
    *to_h   = \&to_hash;

    sub to_array {
        my ($self) = @_;
        my @results = $exec->execute($self->{code});
        shift @results;    # ignore the block private variable (_)
        Sidef::Types::Array::Array->new(@results);
    }

    *toArray = \&to_array;

    sub _run_code {
        my ($self) = @_;
        my $result = $self->run;
        ref($result) eq 'Sidef::Types::Block::Return'
          ? $result
          : ref($result) eq 'Sidef::Types::Block::Break' ? --$result->{depth} <= 0
              ? $self
              : $result
          : ();
    }

    sub run {
        my ($self) = @_;
        my @results = $exec->execute($self->{code});
        $self->pop_stack();
        return $results[-1];
    }

    sub exec {
        my ($self) = @_;
        $exec->execute($self->{code});
        $self;
    }

    *do = \&exec;

    sub while {
        my ($self, $condition, $old_self) = @_;

        {
            if (Sidef::Types::Block::Code->new($condition)->run) {
                defined($old_self) && ($old_self->{did_while} //= 1);
                my $res = $self->_run_code();
                defined($res) && return (ref($res) eq __PACKAGE__ && defined($old_self) ? $old_self : $res);
                redo;
            }
        }

        $old_self // $self;
    }

    sub init_block_vars {
        my ($self, @args) = @_;

        my $last = $#{$self->{init_vars}};
        while (my ($i, $var) = each @{$self->{init_vars}}) {
            $i == $last
              ? $var->set_value(Sidef::Types::Array::Array->new(@args[$i .. $#args]))
              : $var->set_value($args[$i]);
        }

        return $last == 0 ? @{$self->{init_vars}} : @{$self->{init_vars}}[0 .. $last - 1];
    }

    sub pop_stack {
        my ($self) = @_;

        require List::Util;
        my @stack_vars = grep { ref($_) eq 'Sidef::Variable::Variable' && exists $_->{stack} } @{$self->{vars}};
        my $max_depth = List::Util::max(map { $#{$_->{stack}} } @stack_vars);

        foreach my $var (@stack_vars) {
            if ($#{$var->{stack}} == $max_depth) {
                pop @{$var->{stack}};
            }
        }
    }

    sub call {
        my ($self, @args) = @_;

        my $result;
        $self->init_block_vars(@args);

        my $obj = $self->run;
        if (ref $obj eq 'Sidef::Types::Block::Return') {
            $result = $obj->{obj};
        }
        elsif (ref $obj eq 'Sidef::Variable::Variable') {
            $result = $obj->get_value;
        }
        else {
            $result = $obj;
        }

        return $result;
    }

    sub if {
        my ($self, $bool) = @_;

        if ($bool) {
            return $self->run;
        }

        return $bool;
    }

    sub given {
        my ($self) = @_;
        Sidef::Types::Block::Switch->new($self->run);
    }

    sub for {
        my ($self, $arg, @rest) = @_;

        $self->_is_array($arg, 1, 1)
          && return $arg->each($self);

        if (ref $arg eq 'HASH') {
            my $counter = 0;
            {
                foreach my $class (keys %{$arg}) {

                    if ($counter++ == 0) {
                        if ((my $argn = @{$arg->{$class}}) != 3) {
                            warn "[WARN] The 'for' loop needs exactly three arguments! We got $argn of them.\n";
                        }
                        $exec->execute_expr($arg->{$class}[0], $class);
                    }

                    my $expr = $arg->{$class}[2];
                    my ($bool) = $exec->execute_expr($arg->{$class}[1], $class);

                    if ($bool) {
                        if (defined(my $res = $self->_run_code)) {
                            return $res;
                        }
                        $exec->execute_expr($expr, $class);
                        redo;
                    }

                    last;
                }
            }
        }
        else {
            my ($var_ref) = $self->init_block_vars();
            foreach my $item ($arg, @rest) {
                $var_ref->set_value($item);
                if (defined(my $res = $self->_run_code)) {
                    return $res;
                }
            }
        }

        $self;
    }
};

1;
