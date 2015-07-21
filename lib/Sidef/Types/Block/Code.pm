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
        my $deparser = Sidef::Deparse::Sidef->new(namespaces => [@Sidef::Exec::NAMESPACES]);
        Sidef::Types::String::String->new($deparser->deparse_expr({self => $self}));
    }

    sub _execute {
        my ($self) = @_;
        $exec->execute($self->{code});
    }

    sub _execute_expr {
        my ($self) = @_;
        $exec->execute_expr($self->{code});
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

        state $x = require Storable;
        Storable::dclone($self);
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

        $num = defined($num) ? $num->get_value : 1;

        return $self if $num < 1;

        if ($num > (-1 >> 1)) {
            for (my $i = 1 ; $i <= $num ; $i++) {
                if (defined(my $res = $self->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        else {
            foreach my $i (1 .. $num) {
                if (defined(my $res = $self->_run_code(Sidef::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }

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
        my ($self, @args) = @_;
        my $result = $self->run(@args);

        ref($result) eq 'Sidef::Types::Block::Return'
          ? $result
          : ref($result) eq 'Sidef::Types::Block::Break' ? --$result->{depth} <= 0
              ? $self
              : $result
          : ref($result) eq 'Sidef::Types::Block::Next' ? --$result->{depth} <= 0
              ? ()
              : $result
          : ();
    }

    sub run {
        my ($self, @args) = @_;

        if (@args) {
            $self->fast_init_block_vars(@args);
        }

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
        $self->run;
        $self;
    }

    *do = \&exec;

    sub while {
        my ($self, $condition, $old_self) = @_;

        while ($condition->run) {
            defined($old_self) && ($old_self->{did_while} //= 1);
            if (defined(my $res = $self->_run_code)) {
                return (ref($res) eq ref($self) && defined($old_self) ? $old_self : $res);
            }
        }

        $old_self // $self;
    }

    sub loop {
        my ($self) = @_;

        while (1) {
            if (defined(my $res = $self->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    sub try {
        my ($self) = @_;

        my $try = Sidef::Types::Block::Try->new();

        my $error = 0;
        local $SIG{__WARN__} = sub { $try->{type} = 'warning'; $try->{msg} = $_[0]; $error = 1 };
        local $SIG{__DIE__}  = sub { $try->{type} = 'error';   $try->{msg} = $_[0]; $error = 1 };

        $try->{val} = eval { $self->run };

        if ($@ || $error) {
            $try->{catch} = 1;
        }

        $try;
    }

    {
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

        sub init_block_vars {
            my ($self, @args) = @_;

            # varName => value
            my %named_vars;

            # Init the arguments
            my $last = $#{$self->{init_vars}};
            for (my $i = 0 ; $i <= $last ; $i++) {
                my $var = $self->{init_vars}[$i];
                if (ref $args[$i] eq 'Sidef::Types::Array::Pair') {
                    $named_vars{$args[$i][0]->get_value} = $args[$i][1]->get_value;
                    splice(@args, $i--, 1);
                }
                else {
                    my $v = $var->{vars}[0];
                    exists($v->{in_use}) || next;
                    (exists($v->{array}) || exists($v->{hash})) && do {
                        $var->set_value(@args[$i .. $#args]);
                        next;
                    };
                    exists($v->{has_value}) && exists($args[$i]) && $check_type->($v, $args[$i]);
                    $i == $last
                      ? $var->set_value(Sidef::Types::Array::Array->new(@args[$i .. $#args]))
                      : $var->set_value(exists($args[$i]) ? $args[$i] : ());
                }
            }

            foreach my $init_var (@{$self->{init_vars}}) {
                my $var = $init_var->{vars}[0];
                if (exists $named_vars{$var->{name}}) {
                    exists($var->{has_value}) && $check_type->($var, $named_vars{$var->{name}});
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
    }

    sub fast_init_block_vars {
        my ($self, @args) = @_;

        my $nargs = $#args;
        my $last  = $#{$self->{init_vars}};

        foreach my $i (0 .. $last) {
            my $var = $self->{init_vars}[$i];

            my $v = $var->{vars}[0];
            exists($v->{in_use}) || next;

            $nargs > 0 && $i == $last
              ? $var->set_value(Sidef::Types::Array::Array->new(@args[$i .. $nargs]))
              : $var->set_value(exists($args[$i]) ? $args[$i] : ());
        }

        $last == 0
          ? @{$self->{init_vars}}
          : @{$self->{init_vars}}[0 .. $last - 1];
    }

    sub pop_stack {
        my ($self) = @_;

        my @stack_vars = grep { exists $_->{stack} } @{$self->{vars}};

        state $x = require List::Util;
        my $max_depth = @stack_vars ? List::Util::max(map { $#{$_->{stack}} } @stack_vars) : return;

        if ($max_depth > -1) {
            foreach my $var (@stack_vars) {
                if ($#{$var->{stack}} == $max_depth) {
                    pop @{$var->{stack}};
                }
            }
        }
    }

    sub _check_function {
        my ($self, @args) = @_;

        my @candidates;
        my @possible_candidates;
        foreach my $f ($self, map { $_->get_value } @{$self->{kids}}) {
            if ($#{$f->{init_vars}} - 1 == $#args) {
                push @candidates, $f;
            }
            else {
                push @possible_candidates, $f;
            }
        }

        foreach my $f (@candidates, @possible_candidates) {
            eval { $f->init_block_vars(@args) };
            !$@ && return $f;
        }

        $self->init_block_vars(@args);
        $self;
    }

    sub call {
        my ($self, @args) = @_;

        if (exists $self->{kids}) {
            $self = $self->_check_function(@args);
        }
        else {
            $self->init_block_vars(@args);
        }

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

        state $x = do {
            require Storable;
            require File::Temp;
        };

        my ($fh, $filename) = File::Temp::tempfile(SUFFIX => '.rst');
        my $fork = Sidef::Types::Block::Fork->new(result => $filename);

        my $pid = fork() // die "[FATAL ERROR]: cannot fork";
        if ($pid == 0) {
            srand();
            Storable::store($self->run, $filename);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub pfork {
        my ($self) = @_;

        my $fork = Sidef::Types::Block::Fork->new();

        my $pid = fork() // die "[FATAL ERROR]: cannot fork";
        if ($pid == 0) {
            srand();
            $self->run;
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub thread {
        my ($self) = @_;
        state $x = do {
            require threads;
            *threads::get  = \&threads::join;
            *threads::wait = \&threads::join;
            1;
        };
        threads->create(sub { $self->run });
    }

    *thr = \&thread;

    sub for {
        my ($self, $arg, @rest) = @_;

        if (    $#_ == 3
            and ref($_[1]) eq __PACKAGE__
            and ref($_[2]) eq __PACKAGE__
            and ref($_[3]) eq __PACKAGE__) {
            my ($one, $two, $three) = ($_[1], $_[2], $_[3]);
            for ($one->_execute_expr ; $two->_execute_expr ; $three->_execute_expr) {
                if (defined(my $res = $self->_run_code)) {
                    return $res;
                }
            }
            $self;
        }
        elsif ($#_ == 1 and $arg->can('each')) {
            $arg->each($self);
        }
        else {
            foreach my $item ($arg, @rest) {
                if (defined(my $res = $self->_run_code($item))) {
                    return $res;
                }
            }
            $self;
        }
    }
};

1;
