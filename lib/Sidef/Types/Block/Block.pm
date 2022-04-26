package Sidef::Types::Block::Block {

    use utf8;
    use 5.016;
    use parent qw(Sidef::Object::Object);

    use List::Util qw();
    use Sidef::Types::Number::Number;

    use overload
      q{bool} => sub { 1 },
      q{&{}}  => sub { $_[0]->{code} },
      q{""}   => sub {
        my ($self) = @_;

        my $name = $self->_name;
        my $addr = Scalar::Util::refaddr($self);

        my @vars = map {
                (defined($_->{type}) ? (Sidef::normalize_type($_->{type}) . ' ') : '')
              . ($_->{slurpy}        ? ($_->{array} ? '*' : ':')                 : '')
              . Sidef::normalize_type($_->{name})
              . (defined($_->{subset}) ? (' < ' . Sidef::normalize_type($_->{subset})) : '')
              . ($_->{has_value}       ? ' = nil'                                      : '')
        } @{$self->{vars}};

        (
         $self->{type} eq 'block'
         ? ('{' . (@vars ? ('|' . join(',', @vars) . '|') : ''))
         : ('func (' . join(', ', @vars) . ') {')
        )
          . " #`($name|$addr) ... }";
      };

    sub _name {
        my ($self) = @_;
        $self->{_name} //= Sidef::normalize_type(
                                                 (
                                                    exists($self->{class})     ? ($self->{class} . '.')
                                                  : exists($self->{namespace}) ? ($self->{namespace} . '::')
                                                  :                              ''
                                                 )
                                                 . ($self->{name} // '__FUNC__')
                                                );
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

    sub _multiple_dispatch {
        my ($self, @args) = @_;

#<<<
        my @methods = (
            $self,
            (exists($self->{kids})     ? @{$self->{kids}}  : ()),
            (exists($self->{fallback}) ? $self->{fallback} : ())
        );
#>>>

        if (defined($self->{class}) and defined($self->{name})) {

            my $limit = 4096;

            sub {
                my ($block) = @_;

                my $name = $block->{name};

                my @isa = do {
                    no strict 'refs';
                    @{$block->{class} . '::' . 'ISA'};
                };

                foreach my $class (@isa) {

                    (substr($class, 0, 14) eq 'Sidef::Runtime')
                      || next;

                    my $method = do {
                        no strict 'refs';
                        ${$class . '::' . '__SIDEF_CLASS_METHODS__'}{$name};
                    };

                    if (defined($method)) {
                        push @methods, $method;

                        if (exists($method->{kids})) {
                            push @methods, @{$method->{kids}};
                        }

                        if (exists($method->{fallback})) {
                            push @methods, $method->{fallback};
                        }

                        if (--$limit == 0) {
                            die "[ERROR] Too deep or cyclic class inheritance!";
                        }

                        __SUB__->($method);
                    }
                }
              }
              ->($self);
        }

      OUTER: foreach my $method (@methods) {

            if ($method->{type} eq 'block') {
                return ($method, $method->{code}(@args));
            }

            my $table = $self->{table};

            my %seen;
            my @left_args;
            my @vars = exists($method->{vars}) ? @{$method->{vars}} : ();

            foreach my $arg (@args) {
                if (ref($arg) eq 'Sidef::Variable::NamedParam') {
                    if (exists $table->{$arg->{name}}) {
                        my $info = $vars[$table->{$arg->{name}}];
                        if (exists $info->{slurpy}) {
                            $seen{$arg->{name}} = $arg->{value};
                        }
                        else {
                            $seen{$arg->{name}} = $arg->{value}[-1];
                        }
                    }
                    else {
                        next OUTER;
                    }
                }
                else {
                    push @left_args, $arg;
                }
            }

            foreach my $var (@vars) {
                exists($seen{$var->{name}}) && next;
                @left_args || last;
                if (exists($var->{slurpy})) {
                    $seen{$var->{name}} = [splice(@left_args)];
                    last;
                }
                else {
                    $seen{$var->{name}} = shift(@left_args);
                }
            }

            @left_args && next;

            my @pos_args;
            foreach my $var (@vars) {
                if (exists($var->{type}) or exists($var->{subset})) {

                    if (exists $seen{$var->{name}}) {
                        my $value = $seen{$var->{name}};

                        if (exists($var->{type})) {
                            (ref($value) eq $var->{type} or UNIVERSAL::isa($value, $var->{type})) || next OUTER;

                            if (exists($var->{where_block})) {
                                $var->{where_block}($value) || next OUTER;
                            }
                            elsif (exists $var->{where_expr}) {
                                $value eq $var->{where_expr} or next OUTER;
                            }
                        }

                        if (exists($var->{subset})) {

                            if (UNIVERSAL::isa($var->{subset}, 'Sidef::Object::Object')) {
                                UNIVERSAL::isa($var->{subset}, ref($value)) || next OUTER;
                            }

                            if (exists($var->{where_block})) {
                                $var->{where_block}($value) || next OUTER;
                            }
                            elsif (exists $var->{where_expr}) {
                                $value eq $var->{where_expr} or next OUTER;
                            }

                            my $sub = UNIVERSAL::can($var->{subset}, '__subset_validation__');
                            ($sub ? $sub->($value) : 1) || next OUTER;
                        }

                        push @pos_args, $value;
                    }
                    elsif (exists $var->{has_value}) {
                        push @pos_args, undef;
                    }
                    else {
                        next OUTER;
                    }
                }
                elsif (exists $seen{$var->{name}}) {
                    if (exists($var->{where_block}) or exists($var->{subset_blocks})) {

                        my $value =
                          exists($var->{slurpy})
                          ? Sidef::Types::Array::Array->new([@{$seen{$var->{name}}}])
                          : $seen{$var->{name}};

                        if (exists $var->{where_block}) {
                            $var->{where_block}($value) || next OUTER;
                        }
                    }
                    elsif (exists $var->{where_expr}) {
                        $var->{where_expr} eq $seen{$var->{name}} or next OUTER;
                    }

                    push @pos_args, exists($var->{slurpy}) ? @{$seen{$var->{name}}} : $seen{$var->{name}};
                }
                elsif (exists $var->{slurpy}) {
                    ## ok
                }
                elsif (exists $var->{has_value}) {
                    push @pos_args, undef;
                }
                else {
                    next OUTER;
                }
            }

            return ($method, $method->{code}->(@pos_args));
        }

        my $name = $self->_name;

        die "[ERROR] $self->{type} `$name` does not match $name("
          . join(', ',
                 map { ref($_) ? Sidef::normalize_type(ref($_)) : defined($_) ? Sidef::normalize_type($_) : 'nil' } @args)
          . "), invoked as "
          . $name . '('
          . join(
            ', ',
            map {
                    ref($_) && defined(UNIVERSAL::can($_, 'dump')) ? $_->dump
                  : ref($_)                                        ? Sidef::normalize_type(ref($_))
                  : defined($_)                                    ? Sidef::normalize_type($_)
                  : 'nil'
              } @args
          )
          . ')'
          . "\n\nPossible candidates are: "
          . "\n    "
          . join(
            "\n    ",
            map {
                $_->_name . '(' . join(
                    ', ',
                    map {
                            (exists($_->{slurpy}) ? '*'                                       : '')
                          . (exists($_->{type})   ? (Sidef::normalize_type($_->{type}) . ' ') : '')
                          . $_->{name}
                          . (exists($_->{subset}) ? (' < ' . Sidef::normalize_type($_->{subset})) : '')
                    } @{$_->{vars}}
                  )
                  . ')'
              } @methods
          )
          . "\n\n";
    }

    sub call {
        my ($block, @args) = @_;

        # Handle block calls
        if ($block->{type} eq 'block') {
            shift @_;
            goto $block->{code};
        }

        my ($self, @objs) = $block->_multiple_dispatch(@args);

        # Check the return types
        if (exists $self->{returns}) {

            if ($#{$self->{returns}} != $#objs) {
                die qq{[ERROR] Wrong number of return values from $self->{type} `}
                  . $self->_name
                  . "`: got "
                  . scalar(@objs)
                  . ", but expected "
                  . scalar(@{$self->{returns}}) . "\n";
            }

            foreach my $i (0 .. $#{$self->{returns}}) {
                if (not(ref($objs[$i]) eq ($self->{returns}[$i]) or UNIVERSAL::isa($objs[$i], $self->{returns}[$i]))) {
                    die qq{[ERROR] Invalid return-type for value[$i] from $self->{type} `}
                      . $self->_name
                      . "`: got `"
                      . Sidef::normalize_type(ref($objs[$i]))
                      . qq{`, but expected `}
                      . Sidef::normalize_type($self->{returns}[$i]) . "`\n";
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
                if (defined($a) || defined($b)) { push @args, $a, $b }
                elsif (defined($_)) { unshift @args, $_ }
                $self->call(map { Sidef::Perl::Perl->to_sidef($_) } @args);
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

            if ($type eq 'int') {
                return scalar {dump => ($ref . "::_set_int('${str}')")};
            }

            return scalar {dump => ($ref . "::_set_str('${type}', '${str}')")};
        }

        if ($ref eq 'Sidef::Module::OO' or $ref eq 'Sidef::Module::Func') {

            my $module = (
                          ref($obj->{module})
                          ? Data::Dump::Filtered::dump_filtered($obj->{module}, __SUB__)
                          : qq{"$obj->{module}"}
                         );

            my $module_name = ref($obj->{module}) || $obj->{module};

            my $code = {
                dump => qq{
                    do {
                        use $ref;
                        eval "require $module_name";
                        bless({ module => $module }, "$ref");
                    }
                }
            };

            return $code;
        }

        if ($ref eq 'Sidef::Types::Block::Block') {
            die "[ERROR] Blocks cannot be serialized!";
        }

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
        threads->create(
                        {
                         'context' => 'list',
                         'exit'    => 'thread_only'
                        },
                        sub { $self->call(@args) }
                       );
    }

    *thr = \&thread;

    sub _iterate {
        my ($callback, @objs) = @_;

        foreach my $obj (@objs) {

            $obj // last;

            my $sub = UNIVERSAL::can($obj, 'iter') // do {
                my $arr = eval { $obj->to_a };
                ref($arr) ? do { $obj = $arr; UNIVERSAL::can($obj, 'iter') } : ();
            };

            my $break;
            my $iter = defined($sub) ? $sub->($obj) : $obj->iter;

            while (1) {
                $break = 1;
                $callback->(
                            $iter->run // do { undef $break; last }
                           );
                undef $break;
            }

            return if $break;
        }

        return 1;
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

        _iterate(
            sub {
                push @array, $self->run(@_);
            },
            @objs
        );

        Sidef::Types::Array::Array->new(\@array);
    }

    sub grep {
        my ($self, @objs) = @_;

        my @array;

        _iterate(
            sub {
                if ($self->run(@_)) {
                    push @array, @_;
                }
            },
            @objs
        );

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
        $n > 0 || return undef;

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

    sub sum {
        my ($self, $range) = @_;
        $range->sum_by($self);
    }

    *Σ = \&sum;

    sub prod {
        my ($self, $range) = @_;
        $range->prod_by($self);
    }

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
        *{__PACKAGE__ . '::' . '*'}  = \&repeat;
        *{__PACKAGE__ . '::' . '<<'} = \&for;
        *{__PACKAGE__ . '::' . '>>'} = \&map;
        *{__PACKAGE__ . '::' . '&'}  = \&grep;
        *{__PACKAGE__ . '::' . '∘'}  = \&compose;
    }
}

1;
