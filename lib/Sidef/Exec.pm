
use 5.014;
use strict;
use warnings;

no if $] >= 5.018, warnings => "experimental::smartmatch";

package Sidef::Exec {

    use parent qw(Sidef);

    require Sidef::Parser;
    my $parser = Sidef::Parser->new();

    sub new {
        bless {}, __PACKAGE__;
    }

    sub eval_array {
        my ($self, %opt) = @_;
        Sidef::Types::Array::Array->new(
            map {
                    ref eq 'HASH' ? $self->execute_expr(expr => $_, class => $opt{class})
                  : ref($_) eq 'Sidef::Variable::Variable' ? $_->get_value
                  : $_
              } @{$opt{array}}
        );
    }

    sub valid_index {
        my ($self, $index) = @_;

        (
         $self->_is_number($index, 1, 1)
           || do {
             warn sprintf("[WARN] Array index must be a number, not '%s'!\n", ref($index));
             return;
           }
        );

        return 1;
    }

    sub execute_expr {
        my ($self, %opt) = @_;

        my $expr = $opt{'expr'};

        if (exists $expr->{self}) {

            my $self_obj = $expr->{self};
            if (ref $self_obj eq 'HASH') {
                ($self_obj) = $self->execute(struct => $self_obj);
            }

            if (ref $self_obj eq 'Sidef::Types::Array::Array') {
                $self_obj = $self->eval_array(array => $self_obj, class => $opt{class});
            }

            if (exists $expr->{ind}) {

                if (ref $self_obj eq 'Sidef::Variable::Variable') {
                    $self_obj = $self_obj->get_value;
                }

                for (my $l = 0 ; $l <= $#{$expr->{ind}} ; $l++) {

                    my $level   = $expr->{ind}[$l];
                    my $is_hash = ref($self_obj) eq 'Sidef::Types::Hash::Hash';

                    if ($#{$level} > 0) {
                        my @indices;

                        foreach my $ind (@{$level}) {
                            if (ref $ind eq 'HASH') {
                                $ind = $self->execute_expr(expr => $ind, class => $opt{class});
                            }

                            !$is_hash && ($self->valid_index($ind) || next);

                            (
                               $is_hash
                             ? $self_obj->{$ind}
                             : $self_obj->[$ind]
                            )
                              //= Sidef::Variable::Variable->new(rand, 'var');
                            push @indices, $ind;
                        }

                        my $array = Sidef::Types::Array::Array->new();
                        push @{$array}, $is_hash ? (@{$self_obj}{@indices}) : (@{$self_obj}[@indices]);
                        $self_obj = $array;

                        #$self_obj = Sidef::Types::Array::Array->new(map {$_->get_value} @{$self_obj}[@indices]);

                    }
                    else {
                        my $ind = $self->execute_expr(expr => $level->[0], class => $opt{class});

                        if (ref($ind) eq 'Sidef::Variable::Variable') {
                            $ind = $ind->get_value;
                        }

                        if (ref($ind) eq 'Sidef::Types::Array::Array') {
                            $expr->{ind}[$l] = [map { $_->get_value } @{$ind}];
                            --$l;
                            next;
                        }

                        !$is_hash && ($self->valid_index($ind) || next);

                        $self_obj = (
                                     (
                                        $is_hash
                                      ? $self_obj->{$ind}
                                      : $self_obj->[$ind]
                                     )
                                     //= Sidef::Variable::Variable->new(rand, 'var')
                                    );
                    }

                    if (not $is_hash) {
                        if ($l < $#{$expr->{ind}} or ref($expr->{self}) eq 'HASH') {
                            $self_obj = $self_obj->get_value;
                        }
                    }
                }
            }

            if (exists $expr->{call}) {

                foreach my $call (@{$expr->{call}}) {

                    my @arguments;
                    my $method = $call->{name};

                    if (ref $method eq 'HASH') {
                        $method = $self->execute_expr(expr => $method);
                    }

                    if (
                        ref $self_obj eq 'Sidef::Variable::Variable'
                        and not $$method ~~ [
                            qw(
                              =  :=  +=  -=  *=  /=
                              %=  **=  ||=  &&=  |=
                              ^=  &=  ++  -- \\\\
                              )
                        ]
                      ) {
                        $self_obj = $self_obj->get_value;
                    }

                    $self_obj //= Sidef::Types::Nil::Nil->new();

                    if (not $self_obj->can('AUTOLOAD') and not $self_obj->can($method)) {
                        warn sprintf("[WARN] Inexistent method '%s' for object %s\n", $method, ref($self_obj));
                        return $self_obj;
                    }

                    if (exists $call->{arg}) {

                        foreach my $arg (@{$call->{arg}}) {
                            if (ref $arg eq 'HASH') {
                                push @arguments,
                                  $self->execute(struct  => $arg,
                                                 var_ref => (ref($self_obj) eq 'Sidef::Variable::Ref') ? 1 : 0,);
                            }
                            else {
                                push @arguments, $arg;
                            }
                        }

                        foreach my $obj (@arguments) {
                            if (ref $obj eq 'Sidef::Variable::Variable') {
                                if (ref($self_obj) ne 'Sidef::Variable::Ref') {
                                    $obj = $obj->get_value;
                                }
                            }
                        }

                        $self_obj = $self_obj->$method(@arguments);
                    }
                    else {
                        $self_obj = $self_obj->$method;
                    }

                    if (ref($self_obj) eq 'Sidef::Variable::Variable') {
                        $self_obj = $self_obj->get_value;
                    }

                    if (ref($self_obj) eq 'Sidef::Types::Block::Return') {
                        $self->{expr_i} = $self->{expr_i_max};
                        return $self_obj;
                    }
                }
            }
            else {
                if (ref($self_obj) eq 'Sidef::Variable::Variable' and not $opt{var_ref}) {
                    $self_obj = $self_obj->get_value;
                }
            }

            if (ref($self_obj) eq 'Sidef::Types::Block::Return') {
                $self->{expr_i} = $self->{expr_i_max};
                return $self_obj;
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
            local $self->{expr_i_max} = $#{$struct->{$key}};
            for (local $self->{expr_i} = 0 ; $self->{expr_i} <= $self->{expr_i_max} ; $self->{expr_i} += 1) {

                my $expr = $struct->{$key}[$self->{expr_i}];
                my $obj = $self->execute_expr(%opt, class => $key, expr => $expr);

                if (ref($obj) eq 'Sidef::Types::Block::Return') {

                    if ([caller(1)]->[0] eq __PACKAGE__) {
                        return $obj->{obj};
                    }

                    return $obj;
                }

                push @results, $obj;

            }
        }

        return @results;
    }
};

1;
