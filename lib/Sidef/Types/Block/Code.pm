
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

    sub if {
        my ($self, $bool) = @_;

        if ($bool->is_true) {
            $exec->execute(struct => $self);
        }

        $self;
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

                        if ((my $argn = scalar(@{$arg->{$class}})) != 3) {
                            warn "[WARN] The 'for' loop needs exactly three arguments! We got $argn of them.\n";
                        }

                        $exec->execute_expr(expr => splice(@{$arg->{$class}}, 0, 1), class => $class);
                    }

                    my $expr = splice(@{$arg->{$class}}, -1);
                    my ($bool) = $exec->execute(struct => $arg);
                    splice @{$arg->{$class}}, scalar(@{$arg->{$class}}), 0, $expr;

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
