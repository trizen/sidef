package Sidef::Types::Block::Block {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use List::Util qw();

    use overload
      q{bool} => sub { 1 },
      q{&{}}  => sub { $_[0]->{code} },
      q{""}   => sub {
        my ($self) = @_;

        state $x = require Scalar::Util;

        my $name = Sidef::normalize_type($self->{name});
        my $addr = Scalar::Util::refaddr($self->{code});
        my @vars = map { ($_->{slurpy} ? '*' : '') . Sidef::normalize_type($_->{name}) . ($_->{has_value} ? '=(nil)' : '') }
          @{$_[0]->{vars}};

        (
         $self->{type} eq 'block'
         ? ('{' . (@vars ? ('|' . join(',', @vars) . '|') : ''))
         : ('func (' . join(',', @vars) . ') {')
        )
          . " #`($name|$addr) ... }";
      };

    sub new {
        my (undef, %opt) = @_;

        bless {
               name => '__BLOCK__',
               type => 'block',
               %opt
              },
          __PACKAGE__;
    }

    sub run {
        $_[0]{code}->(@_[1 .. $#_]);
    }

    *do = \&run;

    sub _multiple_dispatch {
        my ($self, @args) = @_;

      OUTER: foreach my $method ($self, (exists($self->{kids}) ? @{$self->{kids}} : ())) {

            if ($method->{type} eq 'block') {
                return ($method, $method->{code}(@args));
            }

            my $table = $self->{table};

            my %seen;
            my @left_args;
            my @vars = exists($method->{vars}) ? @{$method->{vars}} : ();

            foreach my $arg (@args) {
                if (ref($arg) eq 'Sidef::Variable::NamedParam') {
                    if (exists $table->{$arg->[0]}) {
                        my $info = $vars[$table->{$arg->[0]}];
                        if (exists $info->{slurpy}) {
                            $seen{$arg->[0]} = $arg->[1];
                        }
                        else {
                            $seen{$arg->[0]} = $arg->[1][-1];
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
                            $var->{subset}->SUPER::isa(ref($value)) || next OUTER;

                            if (exists($var->{where_block})) {
                                $var->{where_block}($value) || next OUTER;
                            }
                            elsif (exists $var->{where_expr}) {
                                $value eq $var->{where_expr} or next OUTER;
                            }

                            if (exists $var->{subset_blocks}) {
                                (List::Util::all { $_->($value) } @{$var->{subset_blocks}}) || next OUTER;
                            }
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

                        if (exists $var->{subset_blocks}) {
                            (List::Util::all { $_->($value) } @{$var->{subset_blocks}}) || next OUTER;
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

        my $name = Sidef::normalize_type($self->{name} // '__FUNC__');

        die "[ERROR] $self->{type} `$name` does not match $name("
          . join(', ',
                 map { ref($_) ? Sidef::normalize_type(ref($_)) : defined($_) ? Sidef::normalize_type($_) : 'nil' } @args)
          . "), invoked as "
          . $name . '('
          . join(
            ', ',
            map {
                    ref($_) && defined(UNIVERSAL::can($_, 'dump')) ? $_->dump
                  : ref($_)     ? Sidef::normalize_type(ref($_))
                  : defined($_) ? Sidef::normalize_type($_)
                  : 'nil'
              } @args
          )
          . ')'
          . "\n\nPossible candidates are: "
          . "\n    $name("
          . join(
            ")\n    $name(",
            map {
                join(
                    ', ',
                    map {
                            (exists($_->{slurpy}) ? '*' : '')
                          . (exists($_->{type}) ? (Sidef::normalize_type($_->{type}) . ' ') : '')
                          . $_->{name}
                          . (exists($_->{subset}) ? (' < ' . Sidef::normalize_type($_->{subset})) : '')
                      } @{$_->{vars}}
                    )
              } ($self, (exists($self->{kids}) ? @{$self->{kids}} : ()))
          )
          . ")\n\n ";
    }

    sub call {
        my ($block, @args) = @_;

        # Handle block calls
        if ($block->{type} eq 'block') {
            return $block->{code}->(@args);
        }

        my ($self, @objs) = $block->_multiple_dispatch(@args);

        # Check the return types
        if (exists $self->{returns}) {

            if ($#{$self->{returns}} != $#objs) {
                die qq{[ERROR] Wrong number of return values from $self->{type} }
                  . (defined($self->{class}) ? Sidef::normalize_type($self->{class}) . '.' : '')
                  . qq{$self->{name}\(): got }
                  . @objs
                  . ", but expected "
                  . @{$self->{returns}};
            }

            foreach my $i (0 .. $#{$self->{returns}}) {
                if (not(ref($objs[$i]) eq ($self->{returns}[$i]) or UNIVERSAL::isa($objs[$i], $self->{returns}[$i]))) {
                    die qq{[ERROR] Invalid return-type from $self->{type} }
                      . (defined($self->{class}) ? Sidef::normalize_type($self->{class}) . '.' : '')
                      . qq{$self->{name}\(): got `}
                      . Sidef::normalize_type(ref($objs[$i]))
                      . qq{`, but expected `}
                      . Sidef::normalize_type($self->{returns}[$i]) . "`";
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

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeat;
    }

    sub capture {
        my ($self) = @_;

        open my $str_h, '>:utf8', \my $str;
        if (defined(my $old_h = select($str_h))) {
            $self->{code}->();
            close $str_h;
            select $old_h;
        }

        Sidef::Types::String::String->new($str)->decode_utf8;
    }

    *cap = \&capture;

    sub repeat {
        my ($block, $num) = @_;
        $num->times($block);
    }

    sub exec {
        my ($self) = @_;
        $self->{code}->();
        $self;
    }

    sub while {
        my ($self, $condition) = @_;

        my $block = $self->{code};
        $condition = $condition->{code};

        while ($condition->()) {
            $block->();
        }

        $self;
    }

    sub loop {
        my ($self) = @_;

        my $code = $self->{code};

        while (1) {
            $code->();
        }

        $self;
    }

    sub if {
        my ($self, $bool) = @_;
        $bool ? $self->{code}->() : $bool;
    }

    sub __fdump {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

        if ($ref eq 'Sidef::Types::Number::Number') {
            return scalar {dump => ($ref . "->_set_str('" . $obj->_get_frac() . "')"),};
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {
            my ($re, $im) = $obj->reals();
            return scalar {dump => $ref . "->new('$re', '$im')",};
        }
        elsif ($ref eq 'Sidef::Types::Number::Inf') {
            return scalar {dump => "$ref->new",};
        }
        elsif ($ref eq 'Sidef::Types::Number::Ninf') {
            return scalar {dump => "$ref->new",};
        }
        elsif ($ref eq 'Sidef::Types::Number::Nan') {
            return scalar {dump => "$ref->new",};
        }

        return;
    }

    sub ffork {
        my ($self, @args) = @_;

        state $x = require Data::Dump::Filtered;
        open(my $fh, '+>', undef);    # an anonymous temporary file
        my $fork = Sidef::Types::Block::Fork->new(fh => $fh);

        # Prevent the destruction of Math::GMPq objects
        #local *Math::GMPq::DESTROY;

        # Try to fork
        my $pid = fork() // die "[ERROR]: Cannot fork";

        if ($pid == 0) {
            srand();
            my $obj = $self->call(@args);
            print $fh scalar Data::Dump::Filtered::dump_filtered($obj, \&__fdump);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

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

    sub for {
        my ($self, @args) = @_;

        if (@args == 1 and defined(UNIVERSAL::can($args[0], 'each'))) {
            $args[0]->each($self);
        }
        else {
            my $code = $self->{code};
            foreach my $item (@args) {
                $code->($item);
            }
            $self;
        }
    }

    *foreach = \&for;

    sub dump {
        Sidef::Types::String::String->new("$_[0]");
    }
}

1;
