package Sidef::Types::Block::Block {

    use utf8;
    use 5.016;
    use parent qw(Sidef::Object::Object);

    use List::Util   qw();
    use Scalar::Util qw();
    use Sidef::Types::Number::Number;

    use overload
      q{bool} => sub { 1 },
      q{&{}}  => sub { $_[0]->{code} },
      q{""}   => sub {
        my ($self) = @_;

        my $name = $self->_name;
        my $addr = Scalar::Util::refaddr($self);

        my @vars = map {
            my $v   = $_;
            my $str = defined($v->{type}) ? Sidef::normalize_type($v->{type}) . ' ' : '';
            $str .= $v->{slurpy} ? ($v->{array} ? '*' : ':') : '';
            $str .= Sidef::normalize_type($v->{name});
            $str .= defined($v->{subset}) ? ' < ' . Sidef::normalize_type($v->{subset}) : '';
            $str .= $v->{has_value}       ? ' = nil'                                    : '';
            $str;
        } @{$self->{vars} // []};

        my $sig = @vars ? join(', ', @vars) : '';

        my $prefix =
          $self->{type} eq 'block'
          ? '{' . ($sig ? "|$sig|" : '')
          : "func ($sig) {";

        return "$prefix #`($name|$addr) ... }";
      };

    sub _name {
        my ($self) = @_;
        $self->{_name} //= do {
            my $prefix =
                exists($self->{class})     ? "$self->{class}."
              : exists($self->{namespace}) ? "$self->{namespace}::"
              :                              '';
            Sidef::normalize_type($prefix . ($self->{name} // '__FUNC__'));
        };
    }

    sub new {
        my (undef, %opt) = @_;

        bless {
               name => '__BLOCK__',
               type => 'block',
               %opt
              },
          __PACKAGE__;
    }

#<<<
    use constant {
                  IDENTITY       => __PACKAGE__->new(is_identity => 1, name => 'Block.IDENTITY',       code => sub { $_[0] }),
                  NULL_IDENTITY  => __PACKAGE__->new(is_identity => 1, name => 'Block.NULL_IDENTITY',  code => sub { }),
                  LIST_IDENTITY  => __PACKAGE__->new(is_identity => 1, name => 'Block.LIST_IDENTITY',  code => sub { (@_) }),
                  ARRAY_IDENTITY => __PACKAGE__->new(is_identity => 1, name => 'Block.ARRAY_IDENTITY', code => sub { Sidef::Types::Array::Array->new(@_) }),
                 };
#>>>

    sub identity       { IDENTITY }
    sub list_identity  { LIST_IDENTITY }
    sub array_identity { ARRAY_IDENTITY }
    sub null_identity  { NULL_IDENTITY }

    sub is_identity {
        $_[0]->{is_identity}
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub run {

        # Handle function calls
        if ($_[0]->{type} eq 'func') {
            return shift(@_)->call(@_);
        }

        goto shift(@_)->{code};
    }

    *do = \&run;

    # Recursively walks the ISA hierarchy to discover additional method candidates
    # from parent classes, appending them (with their kids/fallback) to @$methods.
    sub _collect_inherited_methods {
        my ($self, $methods) = @_;

        my $limit = 4096;
        my %visited;

        sub {
            my ($block) = @_;

            my $name = $block->{name};
            my @isa  = do {
                no strict 'refs';
                @{$block->{class} . '::ISA'};
            };

            foreach my $class (@isa) {
                next if $visited{$class}++;
                substr($class, 0, 14) eq 'Sidef::Runtime' or next;

                my $method = do {
                    no strict 'refs';
                    ${$class . '::__SIDEF_CLASS_METHODS__'}{$name};
                };

                defined($method) or next;

                push @$methods, $method;
                push @$methods, @{$method->{kids}}  if exists $method->{kids};
                push @$methods, $method->{fallback} if exists $method->{fallback};

                if (--$limit == 0) {
                    die "[ERROR] Too deep or cyclic class inheritance!";
                }

                __SUB__->($method);
            }
          }
          ->($self);
    }

    # Builds the full list of candidate methods: self, kids, fallback, and any
    # candidates found by walking the class inheritance hierarchy.
    sub _collect_candidate_methods {
        my ($self) = @_;

        my @methods = ($self);

        if (exists $self->{kids}) {
            push @methods, @{$self->{kids}};
        }

        if (exists $self->{fallback}) {
            push @methods, $self->{fallback};
        }

        if (defined $self->{class} and defined $self->{name}) {
            $self->_collect_inherited_methods(\@methods);
        }

        return @methods;
    }

    # Validates type and subset constraints for each parameter and assembles the
    # final positional argument list for the call. Returns an \@pos_args arrayref,
    # or undef if any constraint check fails.
    sub _build_pos_args {
        my ($method, $seen, $vars) = @_;

        my @pos_args;

        foreach my $var (@$vars) {
            if (exists($var->{type}) or exists($var->{subset})) {

                if (exists $seen->{$var->{name}}) {
                    my $value = $seen->{$var->{name}};

                    if (exists $var->{type}) {
                        (ref($value) eq $var->{type} or UNIVERSAL::isa($value, $var->{type}))
                          or return undef;

                        if (exists $var->{where_block}) {
                            $var->{where_block}($value) or return undef;
                        }
                        elsif (exists $var->{where_expr}) {
                            $value eq $var->{where_expr} or return undef;
                        }
                    }

                    if (exists $var->{subset}) {
                        if (UNIVERSAL::isa($var->{subset}, 'Sidef::Object::Object')) {
                            UNIVERSAL::isa($var->{subset}, ref($value)) or return undef;
                        }

                        if (exists $var->{where_block}) {
                            $var->{where_block}($value) or return undef;
                        }
                        elsif (exists $var->{where_expr}) {
                            $value eq $var->{where_expr} or return undef;
                        }

                        my $sub = UNIVERSAL::can($var->{subset}, '__subset_validation__');
                        ($sub ? $sub->($value) : 1) or return undef;
                    }

                    push @pos_args, $value;
                }
                elsif (exists $var->{has_value}) {
                    push @pos_args, undef;
                }
                else {
                    return undef;
                }

            }
            elsif (exists $seen->{$var->{name}}) {

                if (exists($var->{where_block})) {
                    my $value =
                      exists($var->{slurpy})
                      ? Sidef::Types::Array::Array->new([@{$seen->{$var->{name}}}])
                      : $seen->{$var->{name}};

                    if (exists $var->{where_block}) {
                        $var->{where_block}($value) or return undef;
                    }
                }
                elsif (exists $var->{where_expr}) {
                    $var->{where_expr} eq $seen->{$var->{name}} or return undef;
                }

                push @pos_args, exists($var->{slurpy})
                  ? @{$seen->{$var->{name}}}
                  : $seen->{$var->{name}};
            }
            elsif (exists $var->{slurpy}) {
                ## ok - slurpy with no args supplied is valid
            }
            elsif (exists $var->{has_value}) {
                push @pos_args, undef;
            }
            else {
                return undef;
            }
        }

        return \@pos_args;
    }

    # Partitions @$args into named and positional arguments, then binds them to the
    # method's parameter list in order. Returns a \%seen hashref mapping variable
    # names to their bound values, or undef if the method signature does not match.
    sub _resolve_args {
        my ($self, $method, $args, $vars) = @_;

        my $table = $self->{table};
        my %seen;
        my @left_args;

        # Separate named params from positional args, validating named params exist.
        foreach my $arg (@$args) {
            if (ref($arg) eq 'Sidef::Variable::NamedParam') {
                exists($table->{$arg->{name}}) or return undef;
                my $info = $vars->[$table->{$arg->{name}}];
                $seen{$arg->{name}} =
                  exists($info->{slurpy})
                  ? $arg->{value}
                  : $arg->{value}[-1];
            }
            else {
                push @left_args, $arg;
            }
        }

        # Bind remaining positional args to unbound parameters, in declaration order.
        foreach my $var (@$vars) {
            next if exists $seen{$var->{name}};
            last unless @left_args;

            if (exists $var->{slurpy}) {
                $seen{$var->{name}} = [splice(@left_args)];
                last;
            }
            else {
                $seen{$var->{name}} = shift(@left_args);
            }
        }

        # Any leftover positional args mean this method does not match.
        return undef if @left_args;

        return \%seen;
    }

    # Main entry point: finds and dispatches to the first matching method candidate.
    sub _multiple_dispatch {
        my ($self, @args) = @_;

        my @methods = $self->_collect_candidate_methods;

        foreach my $method (@methods) {

            if ($method->{type} eq 'block') {
                return ($method, $method->{code}(@args));
            }

            my $vars     = exists($method->{vars}) ? $method->{vars} : [];
            my $seen     = $self->_resolve_args($method, \@args, $vars) // next;
            my $pos_args = _build_pos_args($method, $seen, $vars)       // next;

            return ($method, $method->{code}->(@$pos_args));
        }

        _dispatch_error($self, \@methods, \@args);
    }

    # Returns the display type string for an argument (used in the error header line).
    sub _arg_type_str {
        my ($arg) = @_;
        return
            ref($arg)     ? Sidef::normalize_type(ref($arg))
          : defined($arg) ? Sidef::normalize_type($arg)
          :                 'nil';
    }

    # Returns the display value string for an argument (used in the "invoked as" line).
    sub _arg_value_str {
        my ($arg) = @_;
        return
            ref($arg) && UNIVERSAL::can($arg, 'dump') ? $arg->dump
          : ref($arg)                                 ? Sidef::normalize_type(ref($arg))
          : defined($arg)                             ? Sidef::normalize_type($arg)
          :                                             'nil';
    }

    # Formats a single parameter's signature fragment, e.g. "*SomeType varname < SubType".
    sub _param_str {
        my ($var) = @_;
        return
            (exists($var->{slurpy}) ? '*'                                       : '')
          . (exists($var->{type})   ? Sidef::normalize_type($var->{type}) . ' ' : '')
          . $var->{name}
          . (exists($var->{subset}) ? ' < ' . Sidef::normalize_type($var->{subset}) : '');
    }

    # Formats a complete method signature string, e.g. "methodName(TypeA a, *B b)".
    sub _method_signature_str {
        my ($method) = @_;
        my @params = map { _param_str($_) } @{$method->{vars} // []};
        return $method->_name . '(' . join(', ', @params) . ')';
    }

    # Dies with a detailed message describing the failed dispatch and all candidates.
    sub _dispatch_error {
        my ($self, $methods, $args) = @_;

        my $name       = $self->_name;
        my $arg_types  = join(', ',     map { _arg_type_str($_) } @$args);
        my $arg_values = join(', ',     map { _arg_value_str($_) } @$args);
        my $candidates = join("\n    ", map { _method_signature_str($_) } @$methods);

        die "[ERROR] $self->{type} `$name` does not match $name($arg_types)"
          . ", invoked as $name($arg_values)"
          . "\n\nPossible candidates are: "
          . "\n    "
          . $candidates . "\n\n";
    }

    sub call {
        my ($block, @args) = @_;

        # Fast block call routing
        if ($block->{type} eq 'block') {
            shift @_;
            goto $block->{code};
        }

        my ($self, @objs) = $block->_multiple_dispatch(@args);

        # Check the return types
        if (exists $self->{returns}) {

            if ($#{$self->{returns}} != $#objs) {
                die sprintf("[ERROR] Wrong number of return values from %s `%s`: got %d, but expected %d\n",
                            $self->{type}, $self->_name, scalar(@objs), scalar(@{$self->{returns}}));
            }

            foreach my $i (0 .. $#{$self->{returns}}) {
                my $ret_type = $self->{returns}[$i];
                if (!(ref($objs[$i]) eq $ret_type or UNIVERSAL::isa($objs[$i], $ret_type))) {
                    die sprintf("[ERROR] Invalid return-type for value[%d] from %s `%s`: got `%s`, but expected `%s`\n",
                                $i, $self->{type}, $self->_name,
                                Sidef::normalize_type(ref($objs[$i])),
                                Sidef::normalize_type($ret_type));
                }
            }
        }

        wantarray ? @objs : $objs[-1];
    }

    {
        my $ref = \&UNIVERSAL::AUTOLOAD;

        sub get_value {
            my ($self) = @_;
            sub {
                my @args = @_;
                local *UNIVERSAL::AUTOLOAD = $ref;
                if (defined($a) or defined($b)) { push @args, $a, $b }
                elsif (defined($_)) { unshift @args, $_ }
                $self->call(map { Sidef::Types::Perl::Perl->to_sidef($_) } @args);
            };
        }
    }

    sub capture {
        my ($self) = @_;

        open my $str_h, '>:utf8', \my $str;
        if (defined(my $old_h = select($str_h))) {
            $self->run();
            close $str_h;
            select $old_h;
        }

        Sidef::Types::String::String->new($str)->decode_utf8;
    }

    *cap = \&capture;

    sub compose {
        my ($block1, $block2) = @_;
        __PACKAGE__->new(
            code => sub {
                $block1->call($block2->call(@_));
            }
        );
    }

    sub repeat {
        my ($block, $num) = @_;

        if (ref($num) eq __PACKAGE__) {
            goto &compose;
        }

        $num->times($block);
    }

    sub nest {
        my ($block, $num, $value) = @_;

        $value //= Sidef::Types::Number::Number::ZERO;

        foreach my $i (1 .. CORE::int($num)) {
            $value = $block->run($value);
        }

        $value;
    }

    sub exec {
        my ($self, @args) = @_;
        $self->run(@args);
        $self;
    }

    sub while {
        my ($self, $condition) = @_;

        while ($condition->run) {
            $self->run;
        }

        $self;
    }

    sub loop {
        my ($self) = @_;

        while (1) {
            $self->run;
        }

        $self;
    }

    sub if {
        my ($self, $bool) = @_;
        $bool ? $self->run : $bool;
    }

    sub __fdump {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        if ($ref eq 'Sidef::Types::Number::Number') {
            my ($type, $str) = $obj->_dump();
            return
              scalar {
                      dump => $type eq 'int'
                      ? "${ref}::_set_int('${str}')"
                      : "${ref}::_set_str('${type}', '${str}')"
                     };
        }

        if ($ref eq 'Sidef::Module::OO' or $ref eq 'Sidef::Module::Func') {

            my $module =
              ref($obj->{module})
              ? Data::Dump::Filtered::dump_filtered($obj->{module}, __SUB__)
              : qq{"$obj->{module}"};

            my $module_name = ref($obj->{module}) || $obj->{module};
            return scalar {dump => qq{do { use $ref; eval "require $module_name"; bless({ module => $module }, "$ref"); }}};
        }

        die "[ERROR] Blocks cannot be serialized!" if $ref eq 'Sidef::Types::Block::Block';
        return;
    }

    sub ffork {
        my ($self, @args) = @_;

        state $x = require Data::Dump::Filtered;
        open(my $fh, '+>', undef);    # an anonymous temporary file
        my $fork = Sidef::Types::Block::Fork->new(fh => $fh);

        # Try to fork
        my $pid = fork() // die "[ERROR] Cannot fork";

        if ($pid == 0) {
            srand();
            my @objs = ($self->call(@args));
            print $fh scalar Data::Dump::Filtered::dump_filtered(@objs, \&__fdump);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    *start = \&ffork;

    sub fork {
        my ($self, @args) = @_;

        my $fork = Sidef::Types::Block::Fork->new();

        my $pid = CORE::fork() // die "[ERROR] Cannot fork: $!";
        if ($pid == 0) {
            srand();
            $self->call(@args);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub thread {
        my ($self, @args) = @_;
        state $x = do {
            eval { require forks; } // require threads;
            *threads::get  = \&threads::join;
            *threads::wait = \&threads::join;
            1;
        };
        Sidef::Module::OO->__NEW__(threads->create({'context' => 'list', 'exit' => 'thread_only'}, sub { $self->call(@args) }));
    }

    *thr = \&thread;

    sub _iterate {
        my ($callback, @objs) = @_;

        foreach my $obj (@objs) {

            $obj // last;

            my $sub = (ref($obj) && UNIVERSAL::can($obj, 'iter')) || do {
                my $arr = eval { ref($obj) ? $obj->to_a : Sidef::Types::Array::Array->new($obj) };
                ref($arr) ? do { $obj = $arr; UNIVERSAL::can($obj, 'iter') } : undef;
            };

            my $break;
            my $iter = $sub ? $sub->($obj) : $obj->iter;

            while (1) {
                $break = 1;
                $callback->($iter->run // do { undef $break; last });
                undef $break;
            }
            return if $break;    # Sidef block-exit control flow
        }

        return 1;
    }

    sub time {
        my ($self) = @_;
        require Time::HiRes;
        my $t0 = [Time::HiRes::gettimeofday()];
        $self->run;
        Sidef::Types::Number::Number->new(scalar Time::HiRes::tv_interval($t0));
    }

    sub for {
        my ($self, @objs) = @_;
        _iterate($self, @objs);
        $self;
    }

    *each    = \&for;
    *foreach = \&for;

    sub map {
        my ($self, @objs) = @_;

        my @array;
        _iterate(sub { push @array, $self->run(@_) }, @objs);
        Sidef::Types::Array::Array->new(\@array);
    }

    sub grep {
        my ($self, @objs) = @_;

        my @array;
        _iterate(sub { push @array, @_ if $self->run(@_) }, @objs);
        Sidef::Types::Array::Array->new(\@array);
    }

    sub first {
        my ($self, $n, $range) = @_;

        state $inf_range = Sidef::Types::Number::Number->inf->range;

        $range //= $inf_range;

        my @array;
        my $max = CORE::int($n // 1);

        _iterate(
            sub {
                if ($self->run(@_)) {
                    push @array, @_;
                    last if (@array >= $max);
                }
            },
            $range
        );

        defined($n)
          ? Sidef::Types::Array::Array->new(\@array)
          : $array[0];
    }

    sub nth {
        my ($self, $n, $range) = @_;

        state $inf_range = Sidef::Types::Number::Number->inf->range;

        $range //= $inf_range;

        my $k   = 0;
        my $nth = undef;

        $n = CORE::int($n);
        $n > 0 or return undef;

        _iterate(
            sub {
                if ($self->run(@_) and ++$k == $n) {
                    $nth = $_[0];
                    last;
                }
            },
            $range
        );

        return $nth;
    }

    sub sum { $_[1]->sum_by($_[0]) }
    *Σ = \&sum;
    sub prod { $_[1]->prod_by($_[0]) }
    *Π = \&prod;

    sub cache {
        my ($self) = @_;
        $self->{is_cached} && return $self;
        state $x = require Memoize;
        $self->{code}      = Memoize::memoize($self->{code});
        $self->{is_cached} = 1;
        $self;
    }

    sub uncache {
        my ($self) = @_;
        $self->{is_cached} || return $self;
        state $x = require Memoize;
        if (defined(my $uncached = eval { Memoize::unmemoize($self->{code}) })) {
            $self->{code}      = $uncached;
            $self->{is_cached} = 0;
        }
        $self;
    }

    sub flush_cache {
        my ($self) = @_;
        $self->{is_cached} || return $self;
        state $x = require Memoize;
        eval { Memoize::flush_cache($self->{code}) };
        $self;
    }

    sub dump {
        Sidef::Types::String::String->new("$_[0]");
    }

    *to_s   = \&dump;
    *to_str = \&dump;

    {
        no strict 'refs';

        foreach my $name (qw(bsearch bsearch_le bsearch_ge bsearch_inverse)) {

            *{__PACKAGE__ . '::' . $name} = sub {
                my ($self, $x, $y) = @_;

                my $from = $x // Sidef::Types::Number::Number::ZERO;
                my $upto = $y // $from->inc->mul(Sidef::Types::Number::Number::TWO);

                while (1) {
                    my $k = $from->$name($upto, $self);

                    if (defined($k) and $k->is_between($from, $upto)) {
                        return $k;
                    }

                    $from = $upto->inc;
                    $upto = $from->add($from);
                }

                return Sidef::Types::Number::Number::MONE;
            };
        }

        *{__PACKAGE__ . '::' . '*'}  = \&repeat;
        *{__PACKAGE__ . '::' . '<<'} = \&for;
        *{__PACKAGE__ . '::' . '>>'} = \&map;
        *{__PACKAGE__ . '::' . '&'}  = \&grep;
        *{__PACKAGE__ . '::' . '∘'}  = \&compose;
    }
}

1;
