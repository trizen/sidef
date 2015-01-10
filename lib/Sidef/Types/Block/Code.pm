package Sidef::Types::Block::Code {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    require Sidef::Exec;
    my $exec = Sidef::Exec->new();

    sub new {
        $#_ == 1
          ? (bless {code => $_[1]}, __PACKAGE__)
          : do {
            my (undef, %hash) = @_;
            bless \%hash, __PACKAGE__;
          };
    }

    sub dump {
        my ($self) = @_;
        require Data::Dump;
        Sidef::Types::String::String->new('Sys.eval(' . Sidef::Types::String::String->new(Data::Dump::pp($self))->dump . ')');
    }

    sub _execute {
        my ($self) = @_;
        $exec->execute($self->{code});
    }

    sub get_value {
        my ($self) = @_;
        sub {
            if (defined($a) || defined($b)) { push @_, $a, $b }
            elsif (defined($_)) { push @_, $_ }
            $self->call(@_);
        };
    }

    sub copy {
        my ($self) = @_;
        state $code = eval { require Data::Dump; \&Data::Dump::pp } // do {
            print STDERR "** Data::Dump is not installed!\n";
            return $self;
        };
        eval $code->($self);
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeat;
    }

    sub capture {
        my ($self) = @_;

        open my $str_h, '>:utf8', \my $str;
        if (defined(my $old_h = select($str_h))) {
            $self->run;
            close $str_h;
            select $old_h;
        }

        Sidef::Types::String::String->new($str)->decode_utf8;
    }

    *cap = \&capture;

    sub repeat {
        my ($self, $num) = @_;

        $num =
            defined($num)
          ? $self->_is_number($num)
              ? $$num
              : return ()
          : 1;

        return if $num < 1;

        my ($var) = $self->init_block_vars();

        if ($num > (-1 >> 1)) {
            for (my $i = 1 ; $i <= $num ; $i++) {
                $var->set_value(Sidef::Types::Number::Number->new($i));

                if (defined(my $res = $self->_run_code)) {
                    $self->pop_stack();
                    return $res;
                }
            }
        }
        else {
            foreach my $i (1 .. $num) {
                $var->set_value(Sidef::Types::Number::Number->new($i));

                if (defined(my $res = $self->_run_code)) {
                    $self->pop_stack();
                    return $res;
                }
            }
        }

        $self->pop_stack();
        $self;
    }

    sub to_hash {
        my ($self) = @_;
        Sidef::Types::Hash::Hash->new($self->_execute);
    }

    *toHash = \&to_hash;
    *to_h   = \&to_hash;

    sub to_array {
        my ($self) = @_;
        Sidef::Types::Array::Array->new($self->_execute);
    }

    *toArray = \&to_array;

    sub _run_code {
        my ($self) = @_;
        my $result = $self->run;
        ref($result) eq 'Sidef::Types::Block::Return'
          ? $result
          : ref($result) eq 'Sidef::Types::Block::Break' ? --$result->{depth} <= 0
              ? $self
              : $result
          : ();
    }

    sub run {
        my ($self) = @_;
        my $result = ($self->_execute)[-1];
        my $ref    = ref($result);
        if ($ref eq 'Sidef::Variable::Variable' or $ref eq 'Sidef::Variable::ClassVar') {
            $result = $result->get_value;
        }
        $self->pop_stack() if exists($self->{vars});
        $result;
    }

    sub exec {
        my ($self) = @_;
        $self->_execute;
        $self;
    }

    *do = \&exec;

    sub while {
        my ($self, $condition, $old_self) = @_;

        {
            if (Sidef::Types::Block::Code->new($condition)->run) {
                defined($old_self) && ($old_self->{did_while} //= 1);
                if (defined(my $res = $self->_run_code)) {
                    $self->pop_stack();
                    return (ref($res) eq __PACKAGE__ && defined($old_self) ? $old_self : $res);
                }
                redo;
            }
        }

        $self->pop_stack();
        $old_self // $self;
    }

    sub loop {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;

        while (1) {
            if (defined(my $res = $code->_run_code)) {
                $code->pop_stack();
                return $res;
            }
        }

        $code->pop_stack();
        $code;
    }

    sub init_block_vars {
        my ($self, @args) = @_;

        my $check_type = sub {
            my ($var, $value) = @_;

            my ($r1, $r2) = (ref($var->{value}), ref($value));
            foreach my $item ([\$r1, $var->{value}], [\$r2, $value]) {
                if (${$item->[0]} eq 'Sidef::Variable::Class' or ${$item->[0]} eq 'Sidef::Variable::ClassInit') {
                    ${$item->[0]} = $item->[1]->{name};
                }
            }
            $r1 eq $r2
              || die "[ERROR] Type mismatch error in variable '$var->{name}': got '", $r2,
              "', but expected '", $r1, "'!\n";
        };

        # varName => value
        my %named_vars;

        # Init the arguments
        my $last = $#{$self->{init_vars}};
        foreach my $i (0 .. $last) {
            my $var = $self->{init_vars}[$i];
            if (ref $args[$i] eq 'Sidef::Types::Array::Pair') {
                $named_vars{$args[$i][0]->get_value} = $args[$i][1]->get_value;
            }
            else {
                my $v = $var->{vars}[0];
                exists($v->{in_use}) || next;
                exists($v->{multi}) && do {
                    $var->set_value(@args[$i .. $#args]);
                    next;
                };
                exists($v->{def_value}) && exists($args[$i]) && $check_type->($v, $args[$i]);
                $i == $last
                  ? $var->set_value(Sidef::Types::Array::Array->new(@args[$i .. $#args]))
                  : $var->set_value(exists($args[$i]) ? $args[$i] : ());
            }
        }

        foreach my $init_var (@{$self->{init_vars}}) {
            my $var = $init_var->{vars}[0];
            if (exists $named_vars{$var->{name}}) {
                exists($var->{def_value}) && $check_type->($var, $named_vars{$var->{name}});
                $init_var->set_value(delete($named_vars{$var->{name}}));
            }
        }

        foreach my $key (keys %named_vars) {
            warn "[WARN] No such named argument: '$key'\n";
        }

        $last == 0
          ? @{$self->{init_vars}}
          : @{$self->{init_vars}}[0 .. $last - 1];
    }

    sub pop_stack {
        my ($self) = @_;

        require List::Util;
        my @stack_vars =
          grep { ref($_) eq 'Sidef::Variable::Variable' && exists $_->{stack} } @{$self->{vars}};
        my $max_depth = List::Util::max(map { $#{$_->{stack}} } @stack_vars);

        foreach my $var (@stack_vars) {
            if ($#{$var->{stack}} == $max_depth) {
                pop @{$var->{stack}};
            }
        }
    }

    sub call {
        my ($self, @args) = @_;
        $self->init_block_vars(@args);

        my $result = $self->run;
        if (ref($result) eq 'Sidef::Types::Block::Return') {
            $result = $result->{obj};
        }

        $result;
    }

    sub if {
        my ($self, $bool) = @_;

        if (defined($bool) && $bool->get_value) {
            return $self->run;
        }

        $bool;
    }

    sub given {
        my ($self) = @_;
        Sidef::Types::Block::Switch->new($self->run);
    }

    sub fork {
        my ($self) = @_;

        state $can_dump = eval { require Data::Dump };
        $can_dump // return $self->thread;

        require File::Temp;
        my ($fh, $result) = File::Temp::tempfile(SUFFIX => '.rst');

        require Sidef::Types::Block::Fork;
        my $fork = Sidef::Types::Block::Fork->new(result => $result);

        my $pid;
        {
            $pid = fork() // die "[FATAL ERROR]: cannot fork";
            if ($pid == 0) {
                print {$fh} scalar Data::Dump::pp(scalar $self->run);
                close $fh;
                exit 0;
            }
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub thread {
        my ($self) = @_;
        require threads;
        state $aliases = do {
            *threads::get  = \&threads::join;
            *threads::wait = \&threads::join;
            1;
        };
        threads->create(sub { $self->run });
    }

    *thr = \&thread;

    sub for {
        my ($self, $arg, @rest) = @_;

        $self->_is_array($arg, 1, 1)
          && return $arg->each($self);

        if (ref $arg eq 'HASH') {
            my $counter = 0;
            {
                foreach my $class (keys %{$arg}) {

                    if ($counter++ == 0) {
                        $exec->execute_expr($arg->{$class}[0]);
                    }

                    if ($exec->execute_expr($arg->{$class}[1])) {
                        if (defined(my $res = $self->_run_code)) {
                            return $res;
                        }
                        $exec->execute_expr($arg->{$class}[2]);
                        redo;
                    }

                    last;
                }
            }
        }
        else {
            my ($var_ref) = $self->init_block_vars();
            foreach my $item ($arg, @rest) {
                $var_ref->set_value($item);
                if (defined(my $res = $self->_run_code)) {
                    return $res;
                }
            }
        }

        $self;
    }
};

1;
