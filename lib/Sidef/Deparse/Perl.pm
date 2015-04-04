package Sidef::Deparse::Perl {

    use utf8;
    use 5.014;

    our @ISA = qw(Sidef);
    use Scalar::Util qw(refaddr reftype);
    use File::Basename qw(dirname);

    # This module is under development...

    my %addr;
    my %type;
    my %const;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before         => '',
            between        => ";\n",
            after          => ";\n",
            namespaces     => [],
            obj_with_block => {
                               'Sidef::Types::Bool::While' => {
                                                               while => 1,
                                                              },
                              },
            lazy_ops => {
                         '?'     => '?',
                         '||'    => '||',
                         '&&'    => '&&',
                         ':='    => '//=',
                         '='     => '=',
                         '||='   => '||=',
                         '&&='   => '&&=',
                         '\\\\'  => '//',
                         '\\\\=' => '//=',
                        },

            reassign_ops => {map (("$_=" => $_), qw(+ - % * / & | ^ ** && || << >> ÷))},

            inc_dec_ops => {
                            '++' => 'inc',
                            '--' => 'dec',
                           },
            %args,
                   );

        $opts{before} .= qq<BEGIN {unshift \@INC, "> . quotemeta(dirname($INC{'Sidef.pm'})) . qq<"}\n>;
        $opts{before} .= <<'HEADER';

use utf8;
use Sidef;
use Sidef::Types::Number::Number;
use Sidef::Types::Number::NumberFast;

binmode(STDIN,  ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8") if $^P == 0;    # to work under Devel::* modules

use 5.014;
no if $] >= 5.018, warnings => 'experimental::lexical_topic';

package Sidef::Variable::PerlVar {

    use 5.014;

    sub new {
        my (undef, $var) = @_;
        bless {var => $var}, __PACKAGE__;
    }

    sub set_value {
        my ($self, $arg) = @_;
        ${$self->{var}} = $arg;
    }
};

package Sidef::Variable::PerlVarRef {

    use 5.014;

    sub new {
        my (undef, $var) = @_;
        bless {var => $var}, __PACKAGE__;
    }

    sub get_var {
        my ($self) = @_;
        Sidef::Variable::PerlVar->new($self->{var});
    }

    sub set_value {
        my ($self, $arg) = @_;
        ${$self->{var}} = $arg;
    }
};

package Sidef::Types::Block::PerlCode {

    use 5.014;
    use parent qw(
      Sidef::Types::Block::Code
      );

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub _execute {
        my ($self, @args) = @_;
        $self->{code}->(@args);
    }

    sub repeat {
        my ($self, $num) = @_;
        my $value = $num->get_value;
        for(my $i = 1; $i <= $value; $i++) {
            $self->_execute(Sidef::Types::Number::Number->new($i));
        }
        $self;
    }

    sub init_block_vars {
        my ($self) = @_;
        map {Sidef::Variable::PerlVar->new($_)} @{$self->{vars}};
    }

    sub run {
        my ($self) = @_;
        $self->_execute;
    }

    sub call {
        my ($self, @args) = @_;
        $self->_execute(@args);
    }

    sub pop_stack { }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeat;
    }
};

HEADER

        %addr  = ();
        %type  = ();
        %const = ();

        bless \%opts, __PACKAGE__;
    }

    sub make_constant {
        my ($self, $ref, $name, @args) = @_;
        $const{$name} //= do {
            local $" = ", ";
            $self->{before} .= "use constant $name => " . $ref . "->new(@args);\n";
        };
        "main::$name";
    }

    sub _dump_var {
        my ($self, $var) = @_;
        exists($var->{multi}) ? '@' : '$' . $var->{name};
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        '(' . join(', ', map { $self->_dump_var($_) } @vars) . ')';
    }

    sub _dump_init_vars {
        my ($self, @vars) = @_;
        'my('
          . join(', ', map { $self->_dump_var($_) } @vars) . ')=('
          . join(', ', map { $self->deparse_expr({self => $_->{value}}); } @vars) . ')';
    }

    sub _dump_array {
        my ($self, $array) = @_;
        'Sidef::Types::Array::Array->new('
          . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_->get_value}) } @{$array}) . ')';
    }

    sub _dump_indices {
        my ($self, $array) = @_;
        '['
          . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_->get_value}) . '->get_value' } @{$array})
          . ']';
    }

    sub _dump_class_name {
        my ($self, $name) = @_;
        ref($name) ? $self->deparse_expr({self => $name}) : $name;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code    = '';
        my $obj     = $expr->{self};
        my $refaddr = refaddr($obj);

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', $self->deparse_script($obj));
        }
        elsif ($ref eq 'Sidef::Variable::Variable') {
            if ($obj->{type} eq 'var' or $obj->{type} eq 'static' or $obj->{type} eq 'const') {
                $code = '$' . $obj->{name};
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{$refaddr}++) {
                    $type{$refaddr} = 'sub';
                    $code = $obj->{name} eq '' ? do { $self->{before} .= "use 5.016;\n"; '__SUB__' } : $obj->{name};
                }
                else {
                    my $block = $obj->{value};
                    $code = "sub $obj->{name}" if $obj->{name} ne '';
                    local $self->{function} = refaddr($block) if $obj->{name} ne '';
                    $code .= $self->deparse_expr({self => $block});
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Struct') {
            if ($addr{$refaddr}++) {
                $code = $obj->{__NAME__};
            }
            else {
                my @vars;
                foreach my $key (sort keys %{$obj}) {
                    next if $key eq '__NAME__';
                    push @vars, $obj->{$key};
                }
                $code = "struct $obj->{__NAME__} {" . $self->_dump_vars(@vars) . '}';
            }
        }
        elsif ($ref eq 'Sidef::Variable::InitMy') {
            $code = "my $obj->{name}";
        }
        elsif ($ref eq 'Sidef::Variable::My') {
            $code = "$obj->{name}";
        }
        elsif ($ref eq 'Sidef::Object::Unary') {
            $code = qq{'$ref'};
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            my @vars = @{$obj->{vars}};
            $code = $self->_dump_init_vars(@vars);
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($addr{$refaddr}++) {
                $code = q{'} . $self->_dump_class_name($obj->{name}) . q{'};
            }
            else {
                my $block = $obj->{__BLOCK__};
                $code = "package ";
                if (ref $obj->{name}) {
                    my $class_obj =
                      Sidef::Types::Block::Code->new(ref($obj->{name}) eq 'HASH' ? $obj->{name} : {self => $obj->{name}})
                      ->_execute_expr;
                    $code .= ref($class_obj);
                }
                else {
                    $code .= $self->_dump_class_name($obj->{name});
                }
                my $vars = $obj->{__VARS__};
                local $self->{class}      = refaddr($block);
                local $self->{inherit}    = $obj->{inherit} if exists $obj->{inherit};
                local $self->{class_vars} = $vars;
                $code .= $self->deparse_expr({self => $block});
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            if ($addr{$refaddr}++) {
                $code = %{$obj} ? do { $self->{before} .= "use 5.016;\n"; '__SUB__' } : 'Block';
            }
            else {
                if (%{$obj}) {

                    $Sidef::SPACES += $Sidef::SPACES_INCR;

                    my $is_function = exists($self->{function}) && $self->{function} == refaddr($obj);
                    my $is_class    = exists($self->{class})    && $self->{class} == refaddr($obj);

                    if ($is_function || $is_class) {
                        $code = '{';

                        if ($is_class and exists($self->{inherit})) {
                            local $" = " ";
                            $code .= "\n";
                            $code .= " " x $Sidef::SPACES;
                            $code .= "our \@ISA = qw(@{$self->{inherit}});\n";
                        }

                        if ($is_class and exists $self->{class_vars}) {

                            $code .= "\n";
                            $code .= " " x $Sidef::SPACES;
                            $code .= 'sub init {';
                            $code .= "\n";

                            $Sidef::SPACES += $Sidef::SPACES_INCR;

                            if (@{$self->{class_vars}}) {
                                $code .= " " x $Sidef::SPACES;
                                $code .= $self->_dump_init_vars(@{$self->{class_vars}}) . ";\n";
                            }

                            foreach my $i (0 .. $#{$self->{class_vars}}) {
                                my $var = $self->{class_vars}[$i];
                                my $j   = $i + 1;
                                $code .= " " x $Sidef::SPACES . $self->_dump_var($var) . "=\$_[$j] if exists \$_[$j];\n";
                            }

                            $code .= " " x $Sidef::SPACES;
                            $code .= 'bless {';
                            foreach my $var (@{$self->{class_vars}}) {
                                $code .= qq{"\Q$var->{name}\E"=>} . $self->_dump_var($var) . ',';
                            }

                            $code .= '}, __PACKAGE__' . "\n";
                            $Sidef::SPACES -= $Sidef::SPACES_INCR;
                            $code .= " " x $Sidef::SPACES . "}";

                            foreach my $var (@{$self->{class_vars}}) {
                                $code .= "\n";
                                $code .= " " x $Sidef::SPACES;
                                $code .=
qq{sub $var->{name} { \$_[0]->{"\Q$var->{name}\E"} = \$_[1] if exists \$_[1]; \$_[0]->{"\Q$var->{name}\E"} }};
                            }
                        }
                    }
                    else {
                        $code = 'Sidef::Types::Block::PerlCode->new(do {';
                    }

                    $code .= "\n";

                    if (exists($obj->{init_vars}) and @{$obj->{init_vars}}) {
                        my $vars = $obj->{init_vars};
                        if (@{$obj->{init_vars}} > 1) {
                            --$#{$vars};
                        }
                        my @vars = map { @{$_->{vars}} } @{$vars}[0 .. $#{$vars}];

                        if (not $is_class) {
                            $code .= ' ' x $Sidef::SPACES . $self->_dump_init_vars(@vars) . ";\n";
                        }

                        if ($is_function || $is_class) {

                        }
                        else {
                            $code .=
                                ' ' x $Sidef::SPACES
                              . 'vars => ['
                              . join(', ', map { '\\' . $self->_dump_var($_) } @vars)
                              . "], code => sub {\n";
                        }

                        if (not $is_class) {
                            if ($#vars == 0 and $vars[0]{name} eq '_') {
                                $code .= ' ' x $Sidef::SPACES . "\$_ = Sidef::Types::Array::Array->new(\@_) if \@_;\n";
                            }
                            else {
                                foreach my $i (0 .. $#{vars}) {
                                    my $var = $vars[$i];
                                    $code .= ' ' x $Sidef::SPACES . $self->_dump_var($var) . "=\$_[$i] if exists \$_[$i];\n";
                                }
                            }
                        }
                    }
                    else {
                        if ($is_function || $is_class) {

                        }
                        else {
                            $code .= ' ' x $Sidef::SPACES . "code => sub {\n";
                        }
                    }

                    my @statements = $self->deparse_script($obj->{code});

                    $code .=
                        (" " x $Sidef::SPACES)
                      . join(";\n" . (" " x $Sidef::SPACES), @statements) . "\n"
                      . (" " x ($Sidef::SPACES -= $Sidef::SPACES_INCR))
                      . ($is_function || $is_class ? '}' : '}})');
                }
                else {
                    $code = 'Block';
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = exists($obj->{file_name}) ? '' : $self->make_constant($ref, 'Sys');
        }
        elsif ($ref eq 'Sidef::Parser') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Variable::LazyMethod') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Glob::Fcntl') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Block::For') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Bool::If') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Block::Break') {
            if (not exists $expr->{call}) {
                $code = 'last';
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Next') {
            $code = 'next';
        }
        elsif ($ref eq 'Sidef::Types::Block::Continue') {
            $code = 'continue';
        }
        elsif ($ref eq 'Sidef::Types::Block::Return') {
            if (not exists $expr->{call}) {
                $code = 'return';
            }
        }
        elsif ($ref eq 'Sidef::Types::Bool::While') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Math::Math') {
            $code = $self->make_constant($ref, 'Math');
        }
        elsif ($ref eq 'Sidef::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = $ref . '->new(fh => \*STDIN)';
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = $ref . '->new(fh => \*STDOUT)';
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = $ref . '->new(fh => \*STDERR)';
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = $ref . '->new(fh => \*ARGV)';
            }
            else {
                $code = $ref . '->new(fh => \*DATA)';
            }
        }
        elsif ($ref eq 'Sidef::Variable::Magic') {

            state $magic_vars = {
                                 \$.  => '$.',
                                 \$?  => '$?',
                                 \$$  => '$$',
                                 \$^T => '$^T',
                                 \$|  => '$|',
                                 \$!  => '$!',
                                 \$"  => '$"',
                                 \$\  => '$\\',
                                 \$/  => '$/',
                                 \$;  => '$;',
                                 \$,  => '$,',
                                 \$^O => '$^O',
                                 \$^X => '$^X',
                                 \$0  => '$0',
                                 \$(  => '$(',
                                 \$)  => '$)',
                                 \$<  => '$<',
                                 \$>  => '$>',
                                };

            if (exists $magic_vars->{$obj->{ref}}) {
                $code = $magic_vars->{$obj->{ref}};
            }
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Glob::Socket') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Perl::Perl') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Time::Time') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Sys::SIG') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {
            $code = reftype($obj) eq 'HASH' ? 'Complex' : "Complex.new(" . $obj->get_value . ")";
        }
        elsif ($ref eq 'Sidef::Types::Array::Pair') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Regex::Regex') {
            $code = $ref . '->new(' . Sidef::Types::String::String->new("$obj->{regex}")->dump->get_value . ')';
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            my $value = $obj->get_value;
            $code =
                $ref
              . '->new('
              . (ref($value) ? ref($value) eq 'Math::BigRat' ? $value->numify : (q{'} . $value->bstr . q{'}) : $value) . ')';
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code = $self->_dump_array($obj);
        }
        elsif ($ref eq 'Sidef::Types::Nil::Nil') {
            $code = $self->make_constant($ref, 'nil');
        }
        elsif ($ref eq 'Sidef::Types::String::String') {
            $code = $ref . '->new(' . $obj->dump->get_value . ')';
        }
        elsif ($ref eq 'Sidef::Types::Bool::Bool') {
            $code = $self->make_constant($ref, ${$obj} ? ('true', 1) : ('false', 0));
        }
        elsif ($ref eq 'Sidef::Types::Array::MultiArray') {
            $code = $ref . '->new';
        }
        elsif ($obj->can('dump')) {
            $code = $obj->dump->get_value;

            if ($ref eq 'Sidef::Types::Glob::Backtick') {
                if (${$obj} eq '') {
                    $code = 'Backtick';
                }
            }
            elsif ($ref eq 'Sidef::Types::Glob::File') {
                if (${$obj} eq '') {
                    $code = 'File';
                }
            }
            elsif ($ref eq 'Sidef::Types::Glob::Dir') {
                if (${$obj} eq '') {
                    $code = 'Dir';
                }
            }
            elsif ($ref eq 'Sidef::Types::Char::Char') {
                if (${$obj} eq '') {
                    $code = 'Char';
                }
            }
            elsif ($ref eq 'Sidef::Types::String::String') {
                if (${$obj} eq '') {
                    $code = 'String';
                }
            }
            elsif ($ref eq 'Sidef::Types::Array::MultiArray') {
                if ($#{$obj} == -1) {
                    $code = 'MultiArr';
                }
            }
            elsif ($ref eq 'Sidef::Types::Glob::Pipe') {
                if ($#{$obj} == -1) {
                    $code = 'Pipe';
                }
            }
        }

        # Indices
        if (exists $expr->{ind}) {
            my $limit = $#{$expr->{ind}};
            foreach my $i (0 .. $limit) {
                my $ind = $expr->{ind}[$i];
                $code .= '->' . $self->_dump_indices($ind);
                if ($i == $limit) {
                    my $nil = $self->make_constant('Sidef::Types::Nil::Nil', 'nil');
                    $code = "($code // $nil)";
                    if (not $self->{is_var_ref}) {
                        $code .= '->get_value';
                    }
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $i (0 .. $#{$expr->{call}}) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if (exists $type{$refaddr} and $type{$refaddr} eq 'sub') {
                    ## no parents around sub calls
                }
                elsif ($code ne '') {
                    $code = '(' . $code . ')';
                }

                if ($code eq 'Hash' and $method eq ':') {
                    $method = 'new';
                }
                elsif ($code =~ /\.\w+\z/ && $method =~ /^[?!:]/) {

                    #$code = '(' . $code . ')';
                }
                elsif ($code =~ /^\w+\z/ and $method eq ':') {

                    #$code = '(' . $code . ')';
                }

                my $deparse_args = sub {
                    my (@args) = @_;
                    '(' . join(
                        ', ',
                        map {
                            ref($_) eq 'HASH' ? $self->deparse_script($_)
                              : exists($self->{obj_with_block}{$ref})
                              && exists($self->{obj_with_block}{$ref}{$method}) ? $self->deparse_expr({self => $_})
                              : $ref eq 'Sidef::Types::Block::For'
                              && $#{$call->{arg}} == 2
                              && ref($_) eq 'Sidef::Types::Block::Code' ? $self->deparse_expr({self => $_})
                              : ref($_)                                 ? $self->deparse_expr({self => $_})
                              : Sidef::Types::String::String->new($_)->dump
                          } @args
                      )
                      . ')';
                };

                if ($method eq '?') {    # ternary operator (special case)
                    $code .= '?' . $deparse_args->($call->{arg}[0]) . ':' . $deparse_args->($expr->{call}[$i + 1]{arg}[0]);
                    last;
                }

                if ($ref eq 'Sidef::Variable::Ref') {    # variable refs
                    if ($method eq '\\' or $method eq '&') {
                        local $self->{is_var_ref} = 1;
                        $code = 'Sidef::Variable::PerlVarRef->new(' . '\\' . $deparse_args->($call->{arg}[0]) . ')';
                        next;
                    }
                    elsif ($method eq '*') {
                        $code = '${' . $deparse_args->($call->{arg}[0]) . '->{var}}';
                        next;
                    }
                    elsif (exists $self->{inc_dec_ops}{$method}) {
                        my $var = $deparse_args->($call->{arg}[0]);
                        $code = "do{$var=$var\->$self->{inc_dec_ops}{$method};$var}";
                        next;
                    }
                }

                if (exists($self->{inc_dec_ops}{$method}) and $ref eq 'Sidef::Variable::Variable') {
                    $code = "do{my \$old=$code;$code=$code\->$self->{inc_dec_ops}{$method};\$old}";
                    next;
                }

                if (exists $self->{reassign_ops}{$method}) {
                    $code = "$code=($code->\${\\'$self->{reassign_ops}{$method}'}" . $deparse_args->(@{$call->{arg}}) . ')';
                    next;
                }

                if (ref($method) eq 'HASH') {
                    $code .= '->${\\(' . $self->deparse_expr($method) . ')}';
                }
                elsif ($method =~ /^[[:alpha:]_]/) {
                    if (exists $type{$refaddr} and $type{$refaddr} eq 'sub') {
                        ## no methods for subs
                    }
                    else {
                        $code .= '->' if $code ne '';
                        $code .= $method;
                    }
                }
                else {
                    $code .=
                      exists($self->{lazy_ops}{$method})
                      ? $self->{lazy_ops}{$method}
                      : '->${\\' . q{'} . $method . q{'} . '}';
                }

                if (exists $call->{arg}) {
                    $code .= $deparse_args->(@{$call->{arg}});
                }
            }
        }
        else {
            if (exists($type{$refaddr}) and $type{$refaddr} eq 'sub' and $code =~ /^\w+\z/) {
                $code = '\\&' . $code;
            }
        }

        $code;
    }

    sub deparse_script {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);
        $self->{before} . "\n" . join($self->{between}, @statements) . $self->{after};
    }
};

1
