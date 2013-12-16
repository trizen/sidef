package Sidef::Types::Block::Code {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    our @ISA = qw(Sidef);

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        my (undef, $code) = @_;
        bless $code, __PACKAGE__;
    }

    sub get_value {
        my ($self) = @_;
        sub {
            if (defined($a) || defined($b)) { push @_, $a, $b }
            elsif (defined($_)) { push @_, $_ }
            $self->call(@_);
        };
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

        my $var = ($self->_get_private_var)[0]->get_var;

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
        my @results = $exec->execute($self);
        shift @results;    # ignore the block private variable (_)
        Sidef::Types::Hash::Hash->new(@results);
    }

    *toHash = \&to_hash;

    sub to_array {
        my ($self) = @_;
        my @results = $exec->execute($self);
        shift @results;    # ignore the block private variable (_)
        Sidef::Types::Array::Array->new(@results);
    }

    *toArray = \&to_array;

    sub _run_code {
        my ($self) = @_;
        my $result = $self->run;
            ref($result) eq 'Sidef::Types::Block::Return' ? $result
          : ref($result) eq 'Sidef::Types::Block::Break'  ? $self
          :                                                 ();
    }

    sub _get_private_var {
        my ($self) = @_;

        my ($class) = keys %{$self};
        $exec->execute_expr($self->{$class}[0], $class), $class;
    }

    sub run {
        my ($self) = @_;
        my @results = $exec->execute($self);
        return $results[-1];
    }

    sub exec {
        my ($self) = @_;
        $exec->execute($self);
        $self;
    }

    *do = \&exec;

    sub while {
        my ($self, $condition) = @_;

        {
            if (Sidef::Types::Block::Code->new($condition)->run) {
                my $res = $self->_run_code();
                return $res if defined $res;
                redo;
            }
        }

        $self;
    }

    sub call {
        my ($self, @args) = @_;

        my $result;

        foreach my $class (keys %{$self}) {

            my ($var_ref) = $self->_get_private_var();
            $var_ref->get_var->set_value(Sidef::Types::Array::Array->new(@args));

            my $obj = $self->run;

            if (ref $obj eq 'Sidef::Types::Block::Return') {
                return $obj->{obj};
            }
            else {
                $result = $obj;
            }
        }

        return $result;
    }

    sub if {
        my ($self, $bool) = @_;

        if ($bool) {
            $self->exec;
        }

        return $bool;
    }

    sub given {
        my ($self) = @_;
        Sidef::Types::Block::Switch->new($self->run);
    }

    sub for {
        my ($self, $arg, $var) = @_;

        if ($self->_is_array($arg, 1, 1)) {
            my $var_ref = ref($var) eq 'Sidef::Variable::Ref' ? $var->get_var : ($self->_get_private_var)[0]->get_var;

            foreach my $item (@{$arg}) {
                $var_ref->set_value($item->get_value);
                if (defined(my $res = $self->_run_code)) {
                    return $res;
                }
            }
        }
        elsif (ref $arg eq 'HASH') {

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
            warn sprintf("[WARN] The 'for' loop expected (;;) or [], but got '%s'!\n", ref($arg));
        }

        $self;
    }

}
