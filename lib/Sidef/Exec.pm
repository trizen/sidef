package Sidef::Exec {

    use 5.014;
    our @ISA = qw(Sidef);

    our @NAMESPACES;

    sub new {
        bless {

            # `1` for primary operators
            # `0` for composed operators
            lazy_ops => {
                         '||'    => 1,
                         '&&'    => 1,
                         ':='    => 0,
                         '||='   => 0,
                         '&&='   => 0,
                         '\\\\'  => 1,
                         '\\\\=' => 0,
                        },
              },
          __PACKAGE__;
    }

    sub execute_expr {
        my ($self, $expr) = @_;

        my $self_obj = $expr->{self};

        if (ref $self_obj eq 'HASH') {
            local $self->{var_ref} = 1;

            # Here can be added some run-time optimizations
            # (at least, theoretically)
            if (exists $self_obj->{self}) {
                $self_obj = $self->execute_expr($self_obj);
            }
            else {
                $self_obj = $self->execute($self_obj);
            }

            if (not exists $expr->{call}
                and ref($self_obj) eq 'Sidef::Variable::Init') {
                $self_obj->set_value();
            }
        }

        if (ref($self_obj) eq 'Sidef::Types::Array::HCArray') {
            local $self->{var_ref} = 0;
            $self_obj = Sidef::Types::Array::Array->new(
                map {
                    my $val =
                        ref($_) eq 'HASH'
                      ? exists($_->{self})
                          ? $self->execute_expr($_)
                          : $self->execute($_)
                      : ref($_) eq 'Sidef::Types::Array::HCArray' ? $self->execute_expr({self => $_})
                      :                                             $_;
                    (ref($val) eq 'Sidef::Variable::Variable' || ref($val) eq 'Sidef::Variable::ClassVar') ? $val->get_value
                      : ref($val) eq 'Sidef::Types::Array::List' ? @{$val}
                      : $val
                  } @{$self_obj}
            );
        }
        elsif (ref($self_obj) eq 'Sidef::Variable::Local') {
            $self_obj = $self->{vars}{$self_obj->_get_name};
        }

        if (exists $expr->{ind}) {

            my $ref = ref($self_obj);
            if ($ref eq 'Sidef::Variable::Variable' or $ref eq 'Sidef::Variable::ClassVar') {
                $self_obj = $self_obj->get_value;
            }

            for (my $l = 0 ; $l <= $#{$expr->{ind}} ; $l++) {

                if (ref($self_obj) eq 'Sidef::Types::String::String') {
                    $self_obj = $self_obj->to_chars;
                }

                my $level = do {
                    local $self->{var_ref} = 0;
                    [
                     map {
                         my $result =
                             ref($_) eq 'HASH' ? $self->execute_expr($_)
                           : ref($_) eq 'Sidef::Types::Array::HCArray' ? $self->execute_expr({self => $_})
                           :                                             $_;
                         (ref($result) eq 'Sidef::Variable::Variable' or ref($result) eq 'Sidef::Variable::ClassVar')
                           ? $result->get_value
                           : $result;
                       } @{$expr->{ind}[$l]}
                    ];
                };

                my $is_hash = ref($self_obj) eq 'Sidef::Types::Hash::Hash';

                if (
                    $#{$level} > 0
                    || (
                        $#{$level} == 0
                        && do {
                            my $obj = $level->[0];
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

                        if (ref $self_obj eq 'Sidef::Variable::Class') {
                            push @indices, $ind;
                            next;
                        }

                        $is_hash
                          ? ($self_obj->{data}{$ind} //= Sidef::Variable::Variable->new(name => '', type => 'var'))
                          : do {
                            my $num = do {
                                local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                                $ind->get_value;
                            };

                            if (ref $num) {
                                warn "[WARN] Invalid array index of type '", ref($ind), "'!\n";
                                next;
                            }

                            foreach my $ind ($#{$self_obj} + 1 .. $num) {
                                $self_obj->[$ind] //= Sidef::Variable::Variable->new(name => '', type => 'var');
                            }

                            $ind = $num;
                          };

                        push @indices, $ind;
                    }

                    if (ref $self_obj eq 'Sidef::Variable::Class') {
                        local $self_obj->{index_access} = 1;
                        $self_obj = Sidef::Types::Array::Array->new(map { $self_obj->$_->get_value } @indices);
                    }
                    else {
                        my $array = Sidef::Types::Array::Array->new();
                        push @{$array}, $is_hash
                          ? (@{$self_obj->{data}}{@indices})
                          : (@{$self_obj}[@indices]);
                        $self_obj = $array;

                        #$self_obj = Sidef::Types::Array::Array->new(map {$_->get_value} @{$self_obj}[@indices]);
                    }
                }
                else {
                    return if not exists $level->[0];
                    my $ind = $level->[0];

                    if (ref($self_obj) eq 'Sidef::Variable::Class') {
                        local $self_obj->{index_access} = 1;
                        $self_obj = $self_obj->$ind;
                    }
                    else {
                        $self_obj = (
                            $is_hash
                            ? do {
                                (ref($self_obj) && $self_obj->isa('HASH'))
                                  || ($self_obj = Sidef::Types::Hash::Hash->new);

                                $self_obj->{data}{$ind->get_value} //= Sidef::Variable::Variable->new(
                                    name  => '',
                                    type  => 'var',
                                    value => $l < $#{$expr->{ind}}
                                    ? Sidef::Types::Hash::Hash->new
                                    : do {
                                        my $default = $self_obj->{__DEFAULT_VALUE__};
                                        defined($default) && $default->SUPER::isa('Sidef::Types::Block::Code')
                                          ? $default->run
                                          : $default;
                                      }
                                );
                              }
                            : do {
                                (ref($self_obj) && $self_obj->isa('ARRAY'))
                                  || ($self_obj = Sidef::Types::Array::Array->new());

                                my $num = do {
                                    local $Sidef::Types::Number::Number::GET_PERL_VALUE = 1;
                                    $ind->get_value || 0;
                                };

                                if (ref $num) {
                                    warn "[WARN] Invalid array index of type '", ref($ind), "'!\n";
                                    return;
                                }

                                foreach my $j ($#{$self_obj} + 1 .. $num - 1) {
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

                if (    (ref($self_obj) eq 'Sidef::Variable::Variable' or ref($self_obj) eq 'Sidef::Variable::ClassVar')
                    and ($l < $#{$expr->{ind}})) {
                    $self_obj = $self_obj->get_value;
                }
            }
        }

        if (exists $expr->{call}) {

            foreach my $call (@{$expr->{call}}) {

                my @arguments;
                my $method = $call->{method};

                if (ref($method) eq 'HASH') {
                    $method = $self->execute_expr($method) // '';
                }

                if (ref($method) eq 'Sidef::Variable::Variable') {
                    $method = $method->get_value;
                }

                if (ref $method) {
                    $method = $method->get_value;
                }

                $self_obj //= $self->{__NIL__} //= Sidef::Types::Nil::Nil->new;

                my $type = ref($self_obj);
                last if $type eq 'Sidef::Types::Black::Hole';

                # When the variable holds a module, get the
                # value of variable and set it to $self_obj;
                if ($type eq 'Sidef::Variable::Variable') {
                    my $value = $self_obj->get_value;
                    $type = ref($value);
                    if (   $type eq 'Sidef::Module::OO'
                        or $type eq 'Sidef::Module::Func') {
                        $self_obj = $value;
                    }
                }
                elsif ($type eq 'Sidef::Variable::ClassVar') {
                    $type = ref($self_obj->get_value);
                }

                if (exists $call->{arg}) {
                    foreach my $arg (@{$call->{arg}}) {
                        if (
                            ref($arg) eq 'HASH'
                            and not(
                                    (
                                        exists($self->{lazy_ops}{$method})
                                     || ($type eq 'Sidef::Types::Bool::Ternary' && $method eq ':')
                                     || ($method eq '?' && $type->can($method) eq Sidef::Object::Object->can($method))
                                    )
                                    || (
                                        $type eq 'Sidef::Variable::Init'
                                        && (   $self_obj->{vars}[0]->{type} eq 'static'
                                            || $self_obj->{vars}[0]->{type} eq 'const')
                                        && exists($self_obj->{vars}[0]->{inited})
                                       )
                                   )
                          ) {
                            local $self->{var_ref} = ref($self_obj) eq 'Sidef::Variable::Ref' && $method ne '*';
                            push @arguments, $self->execute($arg);
                        }
                        else {
                            push @arguments, $arg;
                        }
                    }

                    my @args;
                    while (@arguments) {
                        my $obj = shift @arguments;

                        my $ref = ref($obj);
                        if ($ref eq 'Sidef::Variable::Variable' or $ref eq 'Sidef::Variable::ClassVar') {
                            if (ref($self_obj) ne 'Sidef::Variable::Ref') {
                                push @args, $obj->get_value;
                            }
                            elsif (ref($self_obj) eq 'Sidef::Variable::Ref' and $method eq '*') {
                                push @args, $obj->get_value;
                            }
                            else {
                                push @args, $obj;
                            }
                        }
                        elsif ($ref eq 'Sidef::Variable::Init') {
                            push @args, $obj->{vars}[0];
                        }
                        elsif ($ref eq 'Sidef::Types::Array::List') {
                            push @args, @{$obj};
                        }
                        else {
                            push @args, $obj;
                        }
                    }

                    # if (exists $self->{lazy_ops}{$method}) {
                    #     if ($self_obj->$method(@args) and $self->{lazy_ops}{$method}) {
                    #         $self_obj = $self->execute(@args);
                    #     }
                    # } else {
                    #    $self_obj = $self_obj->$method(@args);
                    # }

                    $self_obj = $self_obj->$method(@args);
                }
                else {
                    $self_obj = $self_obj->$method;
                }

                my $ref = ref($self_obj);
                if ($ref eq 'Sidef::Types::Block::Return') {
                    $self->{expr_i} = $self->{expr_i_max};
                    return $self_obj;
                }
                elsif ($ref eq 'Sidef::Types::Block::Break' or $ref eq 'Sidef::Types::Block::Next') {
                    last;
                }
            }
        }
        else {
            if (not $self->{var_ref}) {
                if (ref($self_obj) eq 'Sidef::Variable::Variable' or ref($self_obj) eq 'Sidef::Variable::ClassVar') {
                    $self_obj = $self_obj->get_value;
                }
            }
        }

        my $ref = ref($self_obj);
        if (   $ref eq 'Sidef::Types::Block::Break'
            or $ref eq 'Sidef::Types::Block::Next'
            or $ref eq 'Sidef::Types::Block::Return') {
            $self->{expr_i} = $self->{expr_i_max};
        }

        $self_obj;
    }

    sub execute {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class (grep exists $struct->{$_}, @NAMESPACES, 'main') {

            my $i = -1;
            local $self->{expr_i_max} = $#{$struct->{$class}};

          INIT_VAR: ($i++ != -1)
              && (
                  local $self->{vars}{
                      ref($struct->{$class}[$i - 1]) eq 'HASH' ? $struct->{$class}[$i - 1]{self}->_get_name
                      : $struct->{$class}[$i - 1]->_get_name
                  }
                  = Sidef::Variable::Variable->new(
                                      name => (
                                          ref($struct->{$class}[$i - 1]) eq 'HASH' ? $struct->{$class}[$i - 1]{self}->_get_name
                                          : $struct->{$class}[$i - 1]->_get_name
                                      ),
                                      type => 'var',
                  )
                 );

            for (local $self->{expr_i} = $i ; $self->{expr_i} <= $self->{expr_i_max} ; $self->{expr_i}++) {

                my $expr     = $struct->{$class}[$self->{expr_i}];
                my $ref_expr = ref($expr);

                if (($ref_expr eq 'HASH' and ref($expr->{self}) eq 'Sidef::Variable::InitLocal')
                    or $ref_expr eq 'Sidef::Variable::InitLocal') {
                    goto INIT_VAR;
                }

                ++$i;
                my $obj =
                    $ref_expr eq 'HASH' ? $self->execute_expr($expr)
                  : $ref_expr eq 'Sidef::Types::Array::HCArray' ? $self->execute_expr({self => $expr})
                  : $ref_expr eq 'Sidef::Variable::Init' ? do { $expr->set_value; $expr }
                  : $ref_expr eq 'Sidef::Variable::Local' ? $self->{vars}{$expr->_get_name}
                  :                                         $expr;

                my $ref_obj = ref($obj);
                if (   $ref_obj eq 'Sidef::Types::Block::Return'
                    or $ref_obj eq 'Sidef::Types::Block::Break'
                    or $ref_obj eq 'Sidef::Types::Block::Next') {
                    return $obj;
                }

                if ($ref_obj eq 'Sidef::Types::Black::Hole') {
                    $obj = $obj->{value};
                }

                if (wantarray and $ref_obj eq 'Sidef::Types::Array::List') {
                    push @results, @{$obj};
                }
                else {
                    push @results, $obj;
                }
            }
        }

        wantarray ? @results : $results[-1];
    }
};

1
