package Sidef::Exec {

    use 5.014;
    use strict;
    use warnings;

    no warnings 'recursion';

    our @ISA = qw(Sidef);

    sub new {
        my $self = bless {
            bool_assign_method => {
                                   ':='  => 1,
                                   '||=' => 1,
                                   '&&=' => 1,
                                  },
            types => {
                'Sidef::Types::Bool::Bool' => {
                                               '&&' => 1,
                                               '||' => 1,
                                               '?'  => 1,
                                               '?:' => 1,
                                              },
                'Sidef::Types::Block::Code' => {
                                                'while' => 1,
                                                ':'     => 1,
                                               },
                'Sidef::Types::Bool::While' => {
                                                'while' => 1,
                                               },
                'Sidef::Types::Bool::Ternary' => {
                                                  ':' => 1,
                                                 },
                'Sidef::Types::Bool::If' => {
                                             'if'    => 1,
                                             'elsif' => 1,
                                            },

                     },
          },
          __PACKAGE__;

        $self->{types}{'Sidef::Variable::Init'}     = $self->{bool_assign_method};
        $self->{types}{'Sidef::Variable::Variable'} = $self->{bool_assign_method};

        $self;
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

            if (ref $self_obj eq 'Sidef::Variable::My') {
                $self_obj = $self->{vars}{$self_obj->_get_name};
            }

            if (ref $self_obj eq 'Sidef::Types::Array::Array') {
                $self_obj = $self->eval_array(array => $self_obj, class => $opt{class});
            }

            if (exists $expr->{ind}) {

                if (ref($self_obj) eq 'Sidef::Variable::Variable') {
                    $self_obj = $self_obj->get_value;
                }

                for (my $l = 0 ; $l <= $#{$expr->{ind}} ; $l++) {

                    my $level   = $expr->{ind}[$l];
                    my $is_hash = ref($self_obj) eq 'Sidef::Types::Hash::Hash';

                    if (ref($self_obj) eq 'Sidef::Types::String::String') {
                        $self_obj = $self_obj->to_chars;
                    }

                  MULTI_INDEX: if ($#{$level} > 0) {
                        my @indices;

                        foreach my $ind (@{$level}) {
                            if (ref $ind eq 'HASH') {
                                $ind = $self->execute_expr(expr => $ind, class => $opt{class});
                            }

                            !$is_hash && ($self->valid_index($ind) || next);

                            $is_hash ? do { $self_obj->{$ind} //= Sidef::Variable::Variable->new(rand, 'var') } : do {

                                foreach my $ind (0 .. $ind->get_value) {
                                    $self_obj->[$ind] //=
                                      Sidef::Variable::Variable->new(rand, 'var', Sidef::Types::Nil::Nil->new);
                                }

                            };

                            push @indices, $ind;
                        }

                        my $array = Sidef::Types::Array::Array->new();
                        push @{$array},
                          $is_hash ? (@{$self_obj}{@indices}) : (@{$self_obj}[map { $_->get_value } @indices]);
                        $self_obj = $array;

                        #$self_obj = Sidef::Types::Array::Array->new(map {$_->get_value} @{$self_obj}[@indices]);

                    }
                    else {
                        my $ind = $self->execute_expr(expr => $level->[0], class => $opt{class});

                        if (ref($ind) eq 'Sidef::Types::Array::Array') {
                            $level = [map { $_->get_value } @{$ind}];
                            goto MULTI_INDEX;
                        }

                        !$is_hash && ($self->valid_index($ind) || next);

                        $self_obj = (
                            $is_hash
                            ? do {
                                (defined($self_obj) && (ref($self_obj) eq 'HASH' || $self_obj->isa('HASH')))
                                  || ($self_obj = Sidef::Types::Hash::Hash->new());

                                $self_obj->{$ind} //=
                                  Sidef::Variable::Variable->new(
                                                                 rand, 'var',
                                                                 (
                                                                  $l < $#{$expr->{ind}}
                                                                  ? Sidef::Types::Hash::Hash->new
                                                                  : ()
                                                                 )
                                                                );
                              }
                            : do {
                                (defined($self_obj) && (ref($self_obj) eq 'ARRAY' || $self_obj->isa('ARRAY')))
                                  || ($self_obj = Sidef::Types::Array::Array->new());

                                my $num = $ind->get_value;

                                foreach my $ind (0 .. $num - 1) {
                                    $self_obj->[$ind] //=
                                      Sidef::Variable::Variable->new(rand, 'var', Sidef::Types::Nil::Nil->new);
                                }

                                $self_obj->[$num] //=
                                  Sidef::Variable::Variable->new(
                                                                 rand, 'var',
                                                                 (
                                                                  $l < $#{$expr->{ind}}
                                                                  ? Sidef::Types::Array::Array->new
                                                                  : ()
                                                                 )
                                                                );
                              }
                        );
                    }

                    if (
                        ref($self_obj) eq 'Sidef::Variable::Variable'
                        and ($l < $#{$expr->{ind}}
                             or ref($expr->{self}) eq 'HASH')
                      ) {
                        $self_obj = $self_obj->get_value;
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

                    $method //= '';
                    if ((my $ref = ref($method))) {
                        if ($ref eq 'Sidef::Types::String::String') {
                            $method = $$method;
                        }
                        else {
                            warn "[WARN] Invalid method of type: '$ref'!\n";
                            return;
                        }
                    }

                    # When the variable holds a module, get the
                    # value of variable and set it to $self_obj;
                    if (ref $self_obj eq 'Sidef::Variable::Variable') {

                        my $value = $self_obj->get_value;
                        if (   ref($value) eq 'Sidef::Module::Caller'
                            or ref($value) eq 'Sidef::Module::Func') {
                            $self_obj = $value;
                        }
                    }

                    ref($self_obj) && eval { $self_obj->can('can') } || do {
                        $self_obj = Sidef::Types::Nil::Nil->new();
                    };

                    if (not $self_obj->can('AUTOLOAD') and not $self_obj->can($method)) {
                        warn sprintf("[WARN] Inexistent method '%s' for object %s\n",
                                     $method, ref($self_obj) || '- undefined!');
                        return $self_obj;
                    }

                    #<<<

                    my $type =
                      (
                        (ref($self_obj) eq 'Sidef::Variable::Variable')
                          && (
                              ref($self_obj->get_value) eq 'Sidef::Types::Bool::Bool'
                              ? (not exists $self->{bool_assign_method}{$method})
                              : ($method ne ':=')
                             )
                      ) ? ref($self_obj->get_value)
                      : ref($self_obj);

                    #>>>

                    if (exists $call->{arg}) {

                        foreach my $arg (@{$call->{arg}}) {
                            if (
                                ref($arg) eq 'HASH'
                                and not(
                                       (exists($self->{types}{$type}) && exists($self->{types}{$type}{$method}))
                                       || (($type eq 'Sidef::Types::Block::Code' || $type eq 'Sidef::Types::Block::For')
                                           and ($method eq 'for' || $method eq 'foreach')
                                           and ref $arg->{$opt{class}} eq 'ARRAY'
                                           and @{$arg->{$opt{class}}} == 3)
                                       )
                              ) {
                                local $self->{var_ref} = ref($self_obj) eq 'Sidef::Variable::Ref';
                                push @arguments, $self->execute(struct => $arg);
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
                            elsif (ref $obj eq 'Sidef::Variable::Init') {
                                $obj = $obj->{vars}[0];
                            }
                        }

                        $self_obj = $self_obj->$method(@arguments);
                    }
                    else {
                        $method //= '';

                        if ($method eq '...') {
                            $self->{plain_array} = 1;
                        }

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
                if (not $self->{var_ref}) {
                    if (ref($self_obj) eq 'Sidef::Variable::Variable') {
                        $self_obj = $self_obj->get_value;
                    }
                }
            }

            if (   ref($self_obj) eq 'Sidef::Types::Block::Break'
                or ref($self_obj) eq 'Sidef::Types::Block::Next'
                or ref($self_obj) eq 'Sidef::Types::Block::Return') {
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
        foreach my $key ((grep { $_ ne 'main' } keys %{$struct}), 'main') {

            my $i = -1;
            local $self->{expr_i_max} = $#{$struct->{$key}};

          INIT_VAR: ($i++ != -1)
              && (local $self->{vars}{$struct->{$key}[$i - 1]{self}->_get_name} =
                  Sidef::Variable::Variable->new($struct->{$key}[$i - 1]{self}->_get_name, 'var'));

            for (local $self->{expr_i} = $i ; $self->{expr_i} <= $self->{expr_i_max} ; $self->{expr_i}++) {

                my $expr = $struct->{$key}[$self->{expr_i}];

                if (ref($expr->{self}) eq 'Sidef::Variable::InitMy') {
                    goto INIT_VAR;
                }

                ++$i;

                my $obj = $self->execute_expr(%opt, class => $key, expr => $expr);

                $self->{plain_array} && do {
                    $self->{plain_array} = 0;
                    push @results, @{$obj};
                    next;
                };

                if (ref($obj) eq 'Sidef::Types::Block::Return') {

                    my $caller = [caller(1)]->[0];
                    if (defined($caller) and ($caller eq __PACKAGE__ or $caller eq 'Sidef::Variable::Variable')) {
                        return $obj->get_obj();
                    }

                    return $obj;
                }
                elsif (ref($obj) eq 'Sidef::Types::Block::Break') {
                    return $obj;
                }

                push @results, $obj;
            }
        }

        return @results;
    }
}
