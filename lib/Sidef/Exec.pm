
use 5.014;
use strict;
use warnings;

package Sidef::Exec {

    require Sidef::Parser;
    my $parser = Sidef::Parser->new();

    sub new {
        my ($class) = @_;
        bless {}, $class;
    }

    sub interpolate {
        my ($self, %opt) = @_;

        my $self_obj = $opt{self};

        ${$self_obj} =~ s{$parser->{re}{var_in_string}}{
                exists $self->{variables}{$opt{class}}{$1}
                    ? $self->{variables}{$opt{class}}{$1}
                    : do{
                        warn "Use of uninitialized variable <$1> in double quoted string!\n";
                        q{};
                    };
        }ego;

        $self_obj->apply_escapes;
    }

    sub execute_expr {
        my ($self, %opt) = @_;

        my $expr = $opt{'expr'};

        if (exists $expr->{self}) {

            my $self_obj = $expr->{self};
            if (ref $self_obj eq 'HASH') {
                ($self_obj) = $self->execute(struct => $self_obj);
            }

            if (ref $self_obj eq 'Sidef::Types::String::Double') {
                $self->interpolate(self => $self_obj, class => $opt{class});
            }

            if (exists $expr->{call}) {
                foreach my $call (@{$expr->{call}}) {

                    my @arguments;
                    my $method = $call->{name};

                    if (exists $call->{arg}) {

                        foreach my $arg (@{$call->{arg}}) {
                            if (ref $arg eq 'HASH') {
                                push @arguments, $self->execute(struct => $arg);
                            }
                            else {
                                push @arguments, $arg;
                            }
                        }

                        foreach my $obj (@arguments) {
                            if (ref $obj eq 'Sidef::Types::String::Double') {
                                $self->interpolate(self => $obj, class => $opt{class});
                            }
                        }

                        if (ref $self_obj eq 'Sidef::Variable::Variable' and $method ne '=') {
                            my $value = $self_obj->get_value;
                            $self->{variables}{$opt{class}}{$self_obj->get_name} = $value;
                            $self_obj = $value;
                        }

                        my $value = $self_obj->$method(@arguments);
                        if (ref $self_obj eq 'Sidef::Variable::Variable') {
                            $self->{variables}{$opt{class}}{$self_obj->get_name} = $value;
                        }
                        $self_obj = $value;

                    }
                    else {

                        if (ref $self_obj eq 'Sidef::Variable::Variable') {
                            my $value = $self_obj->get_value;
                            $self->{variables}{$opt{class}}{$self_obj->get_name} = $value;
                            $self_obj = $value;
                        }
                        elsif (ref $self_obj eq 'HASH') {
                            $self_obj = $self->execute_expr(expr => $self_obj, class => $opt{class});
                        }

                        $self_obj = $self_obj->$method;
                    }
                }
            }

            return $self_obj;
        }
        else {
            die "Struct error!\n";
        }
    }

    sub execute {
        my ($self, %opt) = @_;

        my $struct = $opt{'struct'};

        my @results;
        foreach my $key (keys %{$struct}) {
            foreach my $expr (@{$struct->{$key}}) {
                push @results, $self->execute_expr(class => $key, expr => $expr);
            }
        }

        return @results;
    }
};

1;
