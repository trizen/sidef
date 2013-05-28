
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Code {

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        my ($class, $code) = @_;
        bless $code, $class;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '||'} = sub {
            my ($self, $code) = @_;

            my $method = '||';
            my @results = $exec->execute(struct => $self);

            return $results[-1]->$method($code);
        };

        *{__PACKAGE__ . '::' . '&&'} = sub {
            my ($self, $code) = @_;

            my $method = '&&';
            my @results = $exec->execute(struct => $self);

            return $results[-1]->$method($code);
        };

        *{__PACKAGE__ . '::' . '?'} = sub {
            my ($self, $code) = @_;

            my $method = '?';
            my @results = $exec->execute(struct => $self);

            return $results[-1]->$method($code);
        };

        *{__PACKAGE__ . '::' . '*'} = sub {
            my ($self, $num) = @_;

            foreach my $i (1 .. $num->_get_number) {
                $exec->execute(struct => $self);
            }

            $self;
        };
    }

    sub run {
        my ($self) = @_;
        my @results = $exec->execute(struct => $self);
        return $results[-1];
    }

    sub call {
        my ($self, @args) = @_;

        my @results;

        foreach my $class (keys %{$self}) {

            my $argc = 0;
            my @vars = @{$self->{$class}}[1 .. $#args + 1];

            foreach my $var (@vars) {
                if (   ref $var ne 'HASH'
                    or exists $var->{call}
                    or exists $var->{arg}
                    or ref $var->{self} ne 'Sidef::Variable::Variable') {
                    warn "[WARN] Too many arguments in function call!",
                      " Expected $argc, but got ${\(scalar @vars)} of them.\n";
                    last;
                }

                ++$argc;
                my $var_ref = $exec->execute_expr(expr => $var, class => $class);
                $var_ref->set_value(shift @args);
            }

            push @results, $exec->execute(struct => $self);
        }

        return $results[-1];
    }

    sub if {
        my ($self, $bool) = @_;

        if ($bool->is_true) {
            $exec->execute(struct => $self);
        }

        return $bool;
    }

    sub for {
        my ($self, $arg) = @_;

        if (ref $arg eq 'Sidef::Types::Array::Array') {

            foreach my $i (0 .. $#{$arg}) {
                $exec->execute(struct => $self);
            }

        }
        elsif (ref $arg eq 'Sidef::Types::Block::Code') {

            my $counter = 0;
            {
                foreach my $class (keys %{$arg}) {

                    if ($counter++ == 0) {

                        if ((my $argn = $#{$arg->{$class}}) != 3) {
                            warn "[WARN] The 'for' loop needs exactly three arguments! We got $argn of them.\n";
                        }

                        $exec->execute_expr(expr => $arg->{$class}[1], class => $class);
                    }

                    my $expr = $arg->{$class}[3];
                    my ($bool) = $exec->execute_expr(expr => $arg->{$class}[2], class => $class);

                    if ($bool->is_true) {
                        $exec->execute(struct => $self);
                        $exec->execute_expr(expr => $expr, class => $class);
                        redo;
                    }
                }
            }
        }

        $self;
    }

}

1;
