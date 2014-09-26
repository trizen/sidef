package Sidef::Exec {

    use 5.014;
    our @ISA = qw(Sidef);

    sub new {
        my $self = bless {
            bool_assign_method => {
                                   ':='    => 1,
                                   '||='   => 1,
                                   '|='    => 1,
                                   '&&='   => 1,
                                   '&='    => 1,
                                   '\\\\'  => 1,
                                   '\\\\=' => 1,
                                  },
            plain_array_methods => {
                                    '...'     => 1,
                                    'asList'  => 1,
                                    'as_list' => 1,
                                    'toList'  => 1,
                                    'to_list' => 1,
                                   },
            types => {
                'Sidef::Types::Bool::Bool' => {
                                               '&&'  => 1,
                                               '&'   => 1,
                                               'and' => 1,
                                               '||'  => 1,
                                               'or'  => 1,
                                               '|'   => 1,
                                               '?'   => 1,
                                               '?:'  => 1,
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

        while (my (undef, $value) = each %{$self->{types}}) {
            @{$self->{short_circuit_methods}}{keys %{$value}} = ();
        }

        $self->{types}{'Sidef::Variable::Variable'} = $self->{bool_assign_method};
        $self;
    }

    sub valid_index {
        my ($self, $index) = @_;

        (
              $self->_is_number($index, 1, 1)
           || $self->_is_bool($index, 1, 1)
           || do {
             warn sprintf("[WARN] Array index must be a number, not '%s'!\n", ref($index));
             return;
           }
        );

        1;
    }

    sub execute_expr {
        my ($self, $expr, $class) = @_;

        exists($expr->{self}) || die "Struct error!\n";

        my $self_obj = $expr->{self};

        if (ref $self_obj eq 'HASH') {
            local $self->{var_ref} = 1;
            $self_obj = $self->execute($self_obj);

            if (not exists $expr->{call}
                and ref($self_obj) eq 'Sidef::Variable::Init') {
                $self_obj->set_value();
            }
        }

        if (ref $self_obj eq 'Sidef::Variable::My') {
            $self_obj = $self->{vars}{$self_obj->_get_name};
        }

        if (ref $self_obj eq 'Sidef::Types::Array::HCArray') {
            local $self->{var_ref} = 0;
            $self_obj = Sidef::Types::Array::Array->new(
                map {
                    my $val = $self->execute_expr($_, $class);
                    ref($val) eq 'Sidef::Args::Args' ? @{$val} : $val
                  } @{$self_obj}
            );
        }

        if (exists $expr->{ind}) {

            if (ref($self_obj) eq 'Sidef::Variable::Variable') {
                $self_obj = $self_obj->get_value;
            }

            for (my $l = 0 ; $l <= $#{$expr->{ind}} ; $l++) {

                my $level = do {
                    local $self->{var_ref} = 0;
                    $self->execute_expr({self => $expr->{ind}[$l]}, $class);
                };

                my $is_hash = ref($self_obj) eq 'Sidef::Types::Hash::Hash';

                if (ref($self_obj) eq 'Sidef::Types::String::String') {
                    $self_obj = $self_obj->to_chars;
                }

                if (
                    $#{$level} > 0
                    || (
                        $#{$level} == 0
                        && do {
                            my $obj = $level->[0]->get_value;
                            ref($obj) eq 'Sidef::Types::Array::Array'
                              ? do {
                                $level = [map { $_->get_value } @{$obj}];
                                1;
                              }
                              : 0;
                        }
                       )
                  ) {
                    my @indices;

                    foreach my $ind (@{$level}) {

                        if (ref $ind eq 'HASH') {
                            local $self->{var_ref} = 0;
                            $ind = $self->execute_expr($ind, $class);
                        }

                        if (ref $ind eq 'Sidef::Variable::Variable') {
                            $ind = $ind->get_value;
                        }

                        if (ref $self_obj eq 'Sidef::Variable::Class') {
                            die "[ERROR]: Can't fetch multiple class values at once!";
                        }

                        !$is_hash && ($self->valid_index($ind) || next);

                        if (ref $ind ne '') {
                            $ind = $ind->get_value;
                        }

                        $is_hash
                          ? do {
                            $self_obj->{data}{$ind} //= Sidef::Variable::Variable->new(name => '', type => 'var');
                          }
                          : do {
                            foreach my $ind (0 .. $ind) {
                                $self_obj->[$ind] //= Sidef::Variable::Variable->new(name => '', type => 'var');
                            }
                          };

                        push @indices, $ind;
                    }

                    my $array = Sidef::Types::Array::Array->new();
                    push @{$array}, $is_hash
                      ? (@{$self_obj->{data}}{@indices})
                      : (@{$self_obj}[@indices]);
                    $self_obj = $array;

                    #$self_obj = Sidef::Types::Array::Array->new(map {$_->get_value} @{$self_obj}[@indices]);

                }
                else {
                    return if not exists $level->[0];
                    my $ind = $level->[0]->get_value;

                    if (ref($self_obj) eq 'Sidef::Variable::Class') {
                        $self_obj = $self_obj->{__VARS__}{$ind};
                    }
                    else {

                        !$is_hash && ($self->valid_index($ind) || next);

                        $self_obj = (
                            $is_hash
                            ? do {
                                (
                                 defined($self_obj) && (ref($self_obj) eq 'HASH'
                                                        || $self_obj->isa('HASH'))
                                )
                                  || ($self_obj = Sidef::Types::Hash::Hash->new);

                                $self_obj->{data}{$ind} //=
                                  Sidef::Variable::Variable->new(
                                                                 name  => '',
                                                                 type  => 'var',
                                                                 value => $l < $#{$expr->{ind}}
                                                                 ? Sidef::Types::Hash::Hash->new
                                                                 : ($self_obj->default)
                                                                );
                              }
                            : do {
                                (
                                 defined($self_obj) && (ref($self_obj) eq 'ARRAY'
                                                        || $self_obj->isa('ARRAY'))
                                )
                                  || ($self_obj = Sidef::Types::Array::Array->new());

                                my $num = $ind->get_value;

                                foreach my $j (0 .. $num - 1) {
                                    $self_obj->[$j] //= Sidef::Variable::Variable->new(name => '', type => 'var');
                                }

                                $self_obj->[$num] //=
                                  Sidef::Variable::Variable->new(
                                                                 name  => '',
                                                                 type  => 'var',
                                                                 value => $l < $#{$expr->{ind}}
                                                                 ? Sidef::Types::Array::Array->new
                                                                 : undef
                                                                );

                              }
                        );
                    }
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
                my $method = $call->{method};

                if (ref $method eq 'HASH') {
                    $method = $self->execute_expr($method, $class) // '';
                    if (ref $method eq 'Sidef::Variable::Variable') {
                        $method = $method->get_value;
                    }
                }

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
                    $self_obj = $self->{__NIL__} //= Sidef::Types::Nil::Nil->new;
                };

                my $sub = $self_obj->can($method) // (
                    $self_obj->can('AUTOLOAD') ? $method : do {
                        warn
                          sprintf("[WARN] Inexistent method '%s' for object %s\n", $method, ref($self_obj) || '- undefined!');
                        return $self_obj;
                      }
                );

                my $type = ref($self_obj);
                if (
                    $type eq 'Sidef::Variable::Variable'
                    and (   exists $self->{short_circuit_methods}{$method}
                         or exists($self->{bool_assign_method}{$method})
                         && $method ne ':='
                         && $method ne '\\\\'
                         && $method ne '\\\\='
                         && (my $ref_val = ref($self_obj->get_value)) ne 'Sidef::Types::Bool::Bool')
                  ) {
                    $type = $ref_val // ref($self_obj->get_value);
                }

                if (exists $call->{arg}) {

                    foreach my $arg (@{$call->{arg}}) {
                        if (
                            ref($arg) eq 'HASH'
                            and not(
                                       (exists($self->{types}{$type}) && exists($self->{types}{$type}{$method}))
                                    || (ref($self_obj) eq 'Sidef::Types::Black::Hole')
                                    || (
                                        ref($self_obj) eq 'Sidef::Variable::Init'
                                        && (   $self_obj->{vars}[0]->{type} eq 'static'
                                            || $self_obj->{vars}[0]->{type} eq 'const')
                                        && exists($self_obj->{vars}[0]->{inited})
                                       )
                                    || (    ($type eq 'Sidef::Types::Block::Code' || $type eq 'Sidef::Types::Block::For')
                                        and ($method eq 'for' || $method eq 'foreach')
                                        and ref $arg->{$class} eq 'ARRAY'
                                        and $#{$arg->{$class}} == 2)
                                   )
                          ) {
                            local $self->{var_ref} = ref($self_obj) eq 'Sidef::Variable::Ref';
                            push @arguments, $self->execute($arg);
                        }
                        else {
                            push @arguments, $arg;
                        }
                    }

                    my @args;
                    while (@arguments) {
                        my $obj = shift @arguments;

                        if (ref $obj eq 'Sidef::Variable::Variable') {
                            if (ref($self_obj) ne 'Sidef::Variable::Ref') {
                                push @args, $obj->get_value;
                            }
                            else {
                                push @args, $obj;
                            }
                        }
                        elsif (ref $obj eq 'Sidef::Variable::Init') {
                            push @args, $obj->{vars}[0];
                        }
                        elsif (ref $obj eq 'Sidef::Args::Args') {
                            push @args, @{$obj};
                        }
                        else {
                            push @args, $obj;
                        }
                    }

                    $self_obj = $self_obj->$sub(@args);

                }
                else {
                    $self_obj = $self_obj->$sub;

                    if (exists $self->{plain_array_methods}{$method}) {
                        return Sidef::Args::Args->new(@{$self_obj});
                    }
                }

                if (ref($self_obj) eq 'Sidef::Variable::Variable') {
                    $self_obj = $self_obj->get_value;
                }

                if (ref($self_obj) eq 'Sidef::Types::Block::Return') {
                    $self->{expr_i} = $self->{expr_i_max};
                    return $self_obj;
                }
                elsif (ref($self_obj) eq 'Sidef::Types::Block::Break') {
                    last;
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

        $self_obj;
    }

    sub execute {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class ((grep { $_ ne 'main' } keys %{$struct}), 'main') {

            exists $struct->{$class} || next;

            my $i = -1;
            local $self->{expr_i_max} = $#{$struct->{$class}};

          INIT_VAR: ($i++ != -1)
              && (local $self->{vars}{$struct->{$class}[$i - 1]{self}->_get_name} =
                  Sidef::Variable::Variable->new(name => $struct->{$class}[$i - 1]{self}->_get_name, type => 'var'));

            for (local $self->{expr_i} = $i ; $self->{expr_i} <= $self->{expr_i_max} ; $self->{expr_i}++) {

                my $expr = $struct->{$class}[$self->{expr_i}];

                if (ref($expr->{self}) eq 'Sidef::Variable::InitMy') {
                    goto INIT_VAR;
                }

                ++$i;
                my $obj = $self->execute_expr($expr, $class);

                if (   ref($obj) eq 'Sidef::Types::Block::Return'
                    or ref($obj) eq 'Sidef::Types::Block::Break') {
                    return $obj;
                }

                if (wantarray and ref($obj) eq 'Sidef::Args::Args') {
                    push @results, @{$obj};
                }
                else {
                    push @results, $obj;
                }
            }
        }

        wantarray ? @results : $results[-1];
    }
}
