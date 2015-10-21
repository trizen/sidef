package Sidef::Deparse::Perl {

    use utf8;
    use 5.014;

    use List::Util qw(all);
    use File::Basename qw(dirname);
    use Scalar::Util qw(refaddr reftype);

    my %addr;
    my %type;
    my %const;
    my %top_add;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before      => '',
            header      => '',
            top_program => "\n",
            between     => ";\n",
            after       => ";\n",
            namespaces  => [],

            assignment_ops => {
                               '=' => '=',
                              },

            lazy_ops => {
                '?'  => '?',
                '||' => '||',
                '&&' => '&&',
                ':=' => '//=',

                # '='     => '=',
                '||='   => '||=',
                '&&='   => '&&=',
                '\\\\'  => '//',
                '\\\\=' => '//=',
                        },

            overload_methods => {
                                 to_str  => q{""},
                                 to_s    => q{""},
                                 to_bool => q{bool},
                                 to_num  => q{0+},
                                },

            special_constructs => {
                                   'Sidef::Types::Block::If'    => 1,
                                   'Sidef::Types::Block::While' => 1,
                                   'Sidef::Types::Block::For'   => 1,
                                  },

            reassign_ops => {map (("$_=" => $_), qw(+ - % * / & | ^ ** && || << >> ÷))},

            inc_dec_ops => {
                            '++' => 'inc',
                            '--' => 'dec',
                           },
            %args,
                   );

        $opts{header} .= <<"HEADER";

use utf8;
use 5.16.1;

HEADER

        %addr    = ();
        %type    = ();
        %top_add = ();
        %const   = ();

        bless \%opts, __PACKAGE__;
    }

    sub make_constant {
        my ($self, $ref, $new_method, $name, @args) = @_;

        if (not $self->{_has_constant}) {
            $self->{_has_constant} = 1;
            $self->{before} .= "use constant {\n";
        }

        '(main::' . (
            (
             $const{$ref, $#args, @args} //= [
                 $name . @args,
                 do {
                     local $" = ", ";
                     $self->{before} .= "\t$name" . @args . " => " . $ref . "->$new_method(@args),\n";
                   }
             ]
            )->[0]
              . ')'
        );
    }

    sub top_add {
        my ($self, $line) = @_;
        if (not exists $top_add{$line}) {
            undef $top_add{$line};
            $self->{top_program} .= $line;
        }
    }

    sub _dump_string {
        my ($self, $str) = @_;

        state $x = eval { require Data::Dump };
        $x || return ('"' . quotemeta($str) . '"');

        my $d = Data::Dump::quote($str);

        # Make sure that code-points between 128 and 256
        # will be stored internally as UTF-8 strings.
        if ($str =~ /[\200-\400]/) {
            return "do {state \$x = do {require Encode; Encode::decode_utf8(Encode::encode_utf8($d))}}";
        }

        $d;
    }

    sub _dump_var {
        my ($self, $var, $refaddr) = @_;
        $var->{in_use} || return 'undef';
        (
           exists($var->{array}) ? '@'
         : exists($var->{hash})  ? '%'
         :                         '$'
        )
          . $var->{name}
          . ($refaddr // refaddr($var));
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        '(' . join(', ', map { $self->_dump_var($_) } @vars) . ')';
    }

    sub _dump_init_vars {
        my ($self, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { exists($_->{value}) ? $self->deparse_expr({self => $_->{value}}) : ('undef') } @vars;

        # Ignore "undef" values
        if (all { $_ eq 'undef' } @dumped_vars) {
            @dumped_vars = ();
        }

        'my('
          . join(', ', map { $self->_dump_var($_) } @vars) . ')'
          . (@dumped_vars ? ('=(' . join(', ', @dumped_vars) . ')') : '');
    }

    sub _dump_sub_init_vars {
        my ($self, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } @vars;

        # Return when all variables are "undef" (i.e.: not in use)
        if (all { $_ eq 'undef' } @dumped_vars) {
            return '';
        }

        my $code = ' ' x $Sidef::SPACES . "my (" . join(', ', @dumped_vars) . ') = @_;' . "\n";

        foreach my $var (@vars) {

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);
                $code .= (' ' x $Sidef::SPACES) . "my \$$name = Sidef::Types::Array::Array->new(\@$name);\n";
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);
                $code .= (' ' x $Sidef::SPACES) . "my \$$name = Sidef::Types::Hash::Hash->new(\%$name);\n";
                delete $var->{hash};
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    $code .= (' ' x $Sidef::SPACES) . "\$$var->{name}" . refaddr($var) . " //= " . $value . ";\n";
                }
            }
        }

        $code;
    }

    sub _dump_array {
        my ($self, $ref, $array) = @_;
        $ref . '->new(' . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . ')';
    }

    sub _dump_indices {
        my ($self, $array) = @_;
        '[' . join(', ', map { ref($_) ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_})) : $_ } @{$array}) . ']';
    }

    sub _dump_unpacked_indices {
        my ($self, $array) = @_;
        '[' . join(
            ', ',
            map {
                '@{'
                  . (
                     ref($_)
                     ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                     : die "[ERROR] Value '$_' can't be unpacked in Array index!"
                    )
                  . '}'
              } @{$array}
          )
          . ']';
    }

    sub _dump_lookups {
        my ($self, $array) = @_;
        '{' . join(', ', map { ref($_) ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_})) : $_ } @{$array}) . '}';
    }

    sub _dump_unpacked_lookups {
        my ($self, $array) = @_;
        '{' . join(
            ', ',
            map {
                '@{'
                  . (
                     ref($_)
                     ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                     : die "[ERROR] Value '$_' can't be unpacked in Hash lookup!"
                    )
                  . '}'
              } @{$array}
          )
          . '}';
    }

    sub _dump_class_name {
        my ($self, $class) = @_;
        join('::', '_', $class->{class}, $class->{name});
    }

    sub deparse_generic {
        my ($self, $before, $sep, $after, @args) = @_;
        $before . join(
            $sep,
            map {
                    ref($_) eq 'HASH' ? $self->deparse_script($_)
                  : ref($_) ? $self->deparse_expr({self => $_})
                  : $self->_dump_string($_)
              } @args
          )
          . $after;
    }

    sub deparse_args {
        my ($self, @args) = @_;
        $self->deparse_generic('(', ', ', ')', @args);
    }

    sub deparse_block_expr {
        my ($self, @args) = @_;
        $self->deparse_generic('do{', ';', '}', @args);
    }

    sub deparse_bare_block {
        my ($self, @args) = @_;
        $self->deparse_generic("{\n" . " " x ($Sidef::SPACES + $Sidef::SPACES_INCR),
                               ";\n" . (" " x ($Sidef::SPACES + $Sidef::SPACES_INCR)),
                               "\n" . (" " x $Sidef::SPACES) . "}", @args);
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
            if ($obj->{type} eq 'var') {

                my $name = $obj->{name} . $refaddr;

                if ($obj->{name} eq 'ENV') {
                    $self->top_add("require Encode;\n");
                    $self->top_add(  qq{my \$$name = Sidef::Types::Hash::Hash->new}
                                   . qq{(map{Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);\n});
                }
                elsif ($obj->{name} eq 'ARGV') {
                    $self->top_add("require Encode;\n");
                    $self->top_add(  qq{my \$$name = Sidef::Types::Array::Array->new}
                                   . qq{(map {Sidef::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV);\n});
                }

                $code = $self->_dump_var($obj, $refaddr);
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {

                if ($addr{$refaddr}++) {
                    $code = "\$$obj->{name}$refaddr";
                }
                else {
                    my $block = $obj->{value};

                    # Anonymous function
                    if ($obj->{name} eq '') {
                        $obj->{name} = "__ANON__";
                    }

                    my $name = $obj->{name};

                    # Check for alphanumeric name
                    if (not $obj->{name} =~ /^[_\pL][_\pL\pN]*\z/) {
                        $obj->{name} = '__NONANN__';    # use this name for non-alphanumeric names
                    }

                    # The name of the function
                    $code .= "\$$obj->{name}$refaddr = ";

                    # Deparse the block of the method/function
                    {
                        local $self->{function} = refaddr($block);
                        push @{$self->{function_declarations}}, [$self->{function}, "my \$$obj->{name}$refaddr;"];
                        $code .= $self->deparse_expr({self => $block});
                    }

                    # Check to see if the method/function has kids (can do multiple dispatch)
                    if (exists $obj->{value}{kids}) {
                        die "[ERROR] Multiple dispatch is currently unsupported!";

                        # my $deparsed_block = $self->deparse_expr({self => $block});
                        #my @kids = map{$self->deparse_expr({self=>$_})}@{$obj->{value}{kids}};
                        #die join('', @kids);
                        #$code .= 'Sidef::Types::Block::MultiDispatch->new(' . join(', ',  $deparsed_block, @kids). ')';

                    }

                    # Check the return value (when "-> Type" is specified)
                    if (exists $obj->{returns}) {

                        my $obj_ref = (
                                       ref($obj->{returns})
                                       ? $self->_dump_class_name($obj->{returns})
                                       : $obj->{returns}
                                      );

                        $code =
                            "do { $code;\n"
                          . (' ' x $Sidef::SPACES)
                          . "my \$_$refaddr = \$$obj->{name}$refaddr;\n"
                          . (' ' x $Sidef::SPACES)
                          . "\$$obj->{name}$refaddr = Sidef::Types::Block::Code->new("
                          . "sub {my \$arg = \$_$refaddr->call(\@_); ref(\$arg) eq "
                          . $self->_dump_string($obj_ref)
                          . " or die q{[ERROR] Invalid return-type from $obj->{type} $self->{class_name}<<$name>>: got '}"
                          . " . ref(\$arg) . q{', but expected '${obj_ref}'}; \$arg })}";
                    }

                    # Memoize the method/function (when "is cached" trait is specified)
                    if ($obj->{cached}) {
                        $self->top_add("require Memoize;\n");
                        $code =
                            "do {$code;\n"
                          . (' ' x $Sidef::SPACES)
                          . "\$$obj->{name}$refaddr = Sidef::Types::Block::Code->new(Memoize::memoize(\$$obj->{name}${refaddr}->{code}))}";
                    }

                    if ($obj->{type} eq 'method') {

                        # Special "AUTOLOAD" method
                        if ($obj->{name} eq 'AUTOLOAD') {
                            $code .= ";\n"
                              . (' ' x $Sidef::SPACES)
                              . "our \$AUTOLOAD;\n"
                              . (' ' x $Sidef::SPACES)
                              . "sub $obj->{name} { my \$self = shift;\n"
                              . (' ' x $Sidef::SPACES)
                              . "my (\$class, \$method) = (\$AUTOLOAD =~ /^(.*[^:])::(.*)\$/);\n"
                              . (' ' x $Sidef::SPACES)
                              . "\$$obj->{name}$refaddr->call(\$self, Sidef::Types::String::String->new(\$class), Sidef::Types::String::String->new(\$method), \@_) }";
                        }

                        # Other methods
                        else {

                            ## Old way
                          # $code .= ";\n" . (' ' x $Sidef::SPACES) . "sub $obj->{name} { \$$obj->{name}$refaddr->call(\@_) }";

                            # New way
                            $code .= ";\n"
                              . (' ' x $Sidef::SPACES)
                              . "state \$_$refaddr = do { no strict 'refs'; *{"
                              . $self->_dump_string("$self->{package_name}::$name")
                              . "} = sub { \$$obj->{name}$refaddr->call(\@_) } }";
                        }

                        # Add the "overload" pragma for some special methods
                        if (exists $self->{overload_methods}{$obj->{name}}) {
                            $code .= ";\n"
                              . (' ' x $Sidef::SPACES)
                              . qq{use overload q{$self->{overload_methods}{$obj->{name}}} => }
                              . $self->_dump_string("$self->{package_name}::$obj->{name}");
                        }
                    }
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
        elsif ($ref eq 'Sidef::Variable::LocalInit') {
            $code = 'local $' . $obj->{class} . '::' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::LocalMagic') {
            $code = 'local ' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::Local') {
            $code = '$' . $obj->{class} . '::' . $obj->{name};
        }
        elsif ($ref eq 'Sidef::Variable::Global') {
            $code = '$' . $obj->{class} . '::' . $obj->{name},;
        }
        elsif ($ref eq 'Sidef::Object::Unary') {
            ## OK
        }
        elsif ($ref eq 'Sidef::Variable::Define') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . 'main::' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $self->top_add('use constant ' . $name . ' => ' . 'do {' . $self->deparse_script($obj->{expr}) . " };\n");
            }

            $code = $value;
        }
        elsif ($ref eq 'Sidef::Variable::Const') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $self->top_add("use experimental 'lexical_subs';\n");
                $code = "state sub $name() { state \$_$refaddr"
                  . (defined($obj->{expr}) ? (" = " . $self->deparse_script($obj->{expr})) : '') . " }";
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Sidef::Variable::Static') {
            my $name  = $obj->{name} . $refaddr;
            my $value = "\$$name";
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "(state \$$name" . (defined($obj->{expr}) ? (" = " . $self->deparse_script($obj->{expr})) : '') . ")";
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Sidef::Variable::ConstInit') {
            foreach my $var (@{$obj->{vars}}) {
                $code .= $self->deparse_expr({self => $var}) . ";\n";
            }
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            my @vars = @{$obj->{vars}};
            $code = $self->_dump_init_vars(@vars);
        }
        elsif ($ref eq 'Sidef::Variable::ClassInit') {
            if ($addr{$refaddr}++) {
                $code = q{'} . $self->_dump_class_name($obj) . q{'};
            }
            else {
                my $block = $obj->{__BLOCK__};

                $code = "do {package ";

                my $package_name;
                if (ref $obj->{name}) {

                    if (ref $obj->{name} eq 'HASH') {
                        die "[ERROR] Invalid class name: '$obj->{name}' inside namespace '$obj->{class}'";
                    }

                    $code .= ($package_name = ref($obj->{name}));
                }
                else {

                    if ($obj->{name} eq '') {
                        $obj->{name} = '__ANON__' . $refaddr;
                    }

                    $code .= ($package_name = $self->_dump_class_name($obj));
                }

                my $vars = $obj->{__VARS__};
                local $self->{class}        = refaddr($block);
                local $self->{class_name}   = $obj->{name};
                local $self->{package_name} = $package_name;
                local $self->{inherit}      = $obj->{inherit} if exists $obj->{inherit};
                local $self->{class_vars}   = $vars;
                local $self->{ref_class}    = 1 if ref($obj->{name});
                $code .= $self->deparse_expr({self => $block});
                $code .= '; ' . $self->_dump_string($package_name) . '}';
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::CodeInit') {
            if ($addr{$refaddr}++) {
                $code = 'Sidef::Types::Block::Code->new(__SUB__)';
            }
            else {
                if (%{$obj}) {

                    $Sidef::SPACES += $Sidef::SPACES_INCR;

                    my $is_function = exists($self->{function}) && $self->{function} == $refaddr;
                    my $is_class    = exists($self->{class})    && $self->{class} == $refaddr;

                    if ($is_class) {
                        $code = " {\n";

                        if ($is_class) {
                            local $" = " ";
                            $code .= " " x $Sidef::SPACES;
                            $code .= "use base qw("
                              . (
                                 exists($self->{inherit})
                                 ? (join(' ', map { ref($_) ? $self->_dump_class_name($_) : $_ } @{$self->{inherit}}) . ' ')
                                 : ''
                                )
                              . "Sidef::Object::Object);\n";
                        }

                        if ($is_class and exists $self->{class_vars} and not $self->{ref_class}) {

                            $code .= (" " x $Sidef::SPACES) . 'sub new {' . "\n";

                            $Sidef::SPACES += $Sidef::SPACES_INCR;

                            $code .= $self->_dump_sub_init_vars('undef', @{$self->{class_vars}});

                            $code .= " " x $Sidef::SPACES;
                            $code .= 'my $self = bless {';
                            foreach my $var (@{$self->{class_vars}}) {
                                $code .= qq{"\Q$var->{name}\E"=>} . $self->_dump_var($var) . ',';
                            }

                            $code .= '}, __PACKAGE__;' . "\n";
                            $code .= (" " x $Sidef::SPACES) . '$self->init(@_[1..$#_]) if $self->can("init");' . "\n";
                            $code .= (" " x $Sidef::SPACES) . '$self;' . "\n";

                            $Sidef::SPACES -= $Sidef::SPACES_INCR;
                            $code .= " " x $Sidef::SPACES . "}";
                            $code .= "\n" . (' ' x $Sidef::SPACES) . "*call = \\&new;\n";

                            foreach my $var (@{$self->{class_vars}}) {
                                $code .= " " x $Sidef::SPACES;
                                $code .= qq{sub $var->{name} : lvalue { \$_[0]->{"\Q$var->{name}\E"} }\n};
                            }
                        }
                    }
                    else {
                        $code = 'Sidef::Types::Block::Code->new(';
                    }

                    if ($is_class) {

                    }
                    else {
                        $code .= "\n" . (" " x ($Sidef::SPACES - $Sidef::SPACES_INCR)) . "sub {\n";

                        if (exists($obj->{init_vars}) and @{$obj->{init_vars}}) {
                            my $vars = $obj->{init_vars};
                            if (@{$obj->{init_vars}} > 1) {
                                --$#{$vars};
                            }
                            my @vars = map { @{$_->{vars}} } @{$vars}[0 .. $#{$vars}];

                            $code .= $self->_dump_sub_init_vars(@vars);

                            if ($is_function) {
                                $code .= (' ' x $Sidef::SPACES) . 'my @return;' . "\n";
                            }
                        }
                    }

                    my @statements = $self->deparse_script($obj->{code});

                    # Localize function declarations
                    if ($is_function) {
                        while (    exists($self->{function_declarations})
                               and @{$self->{function_declarations}}
                               and $self->{function_declarations}[-1][0] != $refaddr) {
                            $code .= (' ' x $Sidef::SPACES) . pop(@{$self->{function_declarations}})->[1] . "\n";
                        }
                    }

                    # Make the last statement to be the return value
                    if ($is_function && @statements) {

                        if ($statements[-1] =~ /^\@return = /) {

                            # Make a minor improvement by removing the 'goto'
                            $statements[-1] =~ s/;\h*goto END$refaddr\z//;
                            $statements[-1] =~ s/^\@return = /return/;
                        }
                        else {
                            $statements[-1] = 'return do { ' . $statements[-1] . ' }';
                        }
                    }

                    $code .=
                        (" " x $Sidef::SPACES)
                      . join(";\n" . (" " x $Sidef::SPACES), @statements)
                      . ($is_function ? (";\n" . (" " x $Sidef::SPACES) . "END$refaddr: \@return;\n") : '') . "\n"
                      . (" " x ($Sidef::SPACES -= $Sidef::SPACES_INCR))
                      . ($is_class ? '}' : '})');
                }
                else {
                    $code = 'Block';
                }
            }
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Sys::Sys') {
            $code = $self->make_constant($ref, 'new', "Sys$refaddr");
        }
        elsif ($ref eq 'Sidef::Parser') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef') {
            $code = $self->make_constant($ref, 'new', "Sidef$refaddr");
        }
        elsif ($ref eq 'Sidef::Object::Object') {
            $code = $self->make_constant($ref, 'new', "Object$refaddr");
        }
        elsif ($ref eq 'Sidef::Variable::LazyMethod') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Block::For') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Types::Block::If') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Types::Block::While') {
            ## ok
        }
        elsif ($ref eq 'Sidef::Types::Block::Given') {
            $self->top_add(qq{use experimental "smartmatch";\n});
        }
        elsif ($ref eq 'Sidef::Types::Block::When') {
            $self->top_add(qq{use experimental "smartmatch";\n});
        }
        elsif ($ref eq 'Sidef::Types::Block::Default') {
            $code = 'default' . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Sidef::Types::Block::Gather') {
            $code =
                "do {my \@_$refaddr;"
              . $self->deparse_bare_block($obj->{block}->{code})
              . "; Sidef::Types::Array::Array->new(\@_$refaddr)}";
        }
        elsif ($ref eq 'Sidef::Types::Block::Take') {
            my $raddr = refaddr($obj->{gather});
            $code = "do { push \@_$raddr," . $self->deparse_args($obj->{expr}) . "; \$_$raddr\[-1] }";
        }
        elsif ($ref eq 'Sidef::Types::Block::Try') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Bool::Ternary') {
            $code = '('
              . $self->deparse_script($obj->{cond}) . '?'
              . $self->deparse_block_expr($obj->{true}) . ':'
              . $self->deparse_block_expr($obj->{false}) . ')';
        }
        elsif ($ref eq 'Sidef::Module::OO') {
            $code = $self->make_constant($ref, '__NEW__', "MOD_OO$refaddr", $self->_dump_string($obj->{module}));
        }
        elsif ($ref eq 'Sidef::Module::Func') {
            $code = $self->make_constant($ref, '__NEW__', "MOD_F$refaddr", $self->_dump_string($obj->{module}));
        }
        elsif ($ref eq 'Sidef::Types::Block::Break') {
            if (not exists $expr->{call}) {
                $code = 'last';
            }
            else {
                die "[ERROR] Arguments and method calls for 'break' are not supported!";
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Next') {
            if (not exists $expr->{call}) {
                $code = 'next';
            }
            else {
                die "[ERROR] Arguments and method calls for 'next' are not supported!";
            }
        }
        elsif ($ref eq 'Sidef::Types::Block::Continue') {
            $code = 'continue';
        }
        elsif ($ref eq 'Sidef::Types::Block::Return') {
            if (not exists $expr->{call}) {

                if (exists $self->{function}) {
                    $code = "goto END$self->{function}";
                }
                else {
                    $code = 'return Sidef::Types::Block::Return->new';
                }
            }
        }
        elsif ($ref eq 'Sidef::Math::Math') {
            $code = $self->make_constant($ref, 'new', "Math$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = $self->make_constant($ref, 'new', "STDIN$refaddr", 'fh => \*STDIN');
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = $self->make_constant($ref, 'new', "STDOUT$refaddr", 'fh => \*STDOUT');
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = $self->make_constant($ref, 'new', "STDERR$refaddr", 'fh => \*STDERR');
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = $self->make_constant($ref, 'new', "ARGF$refaddr", 'fh => \*ARGV');
            }
            else {
                my $data = $self->_dump_string(
                                               do { seek($obj->{fh}, 0, 0); local $/; readline($obj->{fh}) }
                                              );
                $code = $self->make_constant($ref, 'new', "DATA$refaddr", qq{fh => do {open my \$fh, '<', \\$data; \$fh}});
            }
        }
        elsif ($ref eq 'Sidef::Variable::Magic') {
            $code = $obj->{name};
        }
        elsif ($ref eq 'Sidef::Types::Hash::Hash') {
            $code = $self->make_constant($ref, 'new', "Hash$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Glob::Socket') {
            $code = $self->make_constant($ref, 'new', "Socket$refaddr");
        }
        elsif ($ref eq 'Sidef::Perl::Perl') {
            $code = $self->make_constant($ref, 'new', "Perl$refaddr");
        }
        elsif ($ref eq 'Sidef::Eval::Eval') {
            $Sidef::EVALS{$refaddr} = $obj;
            $code = qq~
            eval do {
            local \$Sidef::DEPARSER->{before} = '';
            local \$Sidef::DEPARSER->{top_program} = '';
            local \$Sidef::DEPARSER->{_has_constant} = 0;
            local \$Sidef::DEPARSER->{function_declarations} = [];
            \$Sidef::DEPARSER->deparse(
            do {
                local \$Sidef::PARSER->{vars} = \$Sidef::EVALS{$refaddr}{vars};
                local \$Sidef::PARSER->{ref_vars_refs} = \$Sidef::EVALS{$refaddr}{ref_vars_refs};
                \$Sidef::PARSER->parse_script(code => \\(~ . $self->deparse_script($obj->{expr}) . qq~->get_value));
            })}~;
        }
        elsif ($ref eq 'Sidef::Time::Time') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Sys::SIG') {
            $code = $self->make_constant($ref, 'new', "Sig$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Number::Complex') {
            $code = $self->make_constant($ref, 'new', "Complex$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::Array::Pair') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Regex::Regex') {
            $code =
              $self->make_constant($ref, 'new', "Regex$refaddr",
                                   $self->_dump_string("$obj->{regex}"),
                                   $obj->{global} ? '"g"' : ());
        }
        elsif ($ref eq 'Sidef::Types::Number::Number') {
            my $value = $obj->get_value;
            $code = $self->make_constant($ref, 'new', "Number$refaddr", ref($value) ? (q{'} . $value->bstr . q{'}) : $value);
        }
        elsif ($ref eq 'Sidef::Types::Array::Array' or $ref eq 'Sidef::Types::Array::HCArray') {
            $code = $self->_dump_array('Sidef::Types::Array::Array', $obj);
        }
        elsif ($ref eq 'Sidef::Types::Nil::Nil') {
            if (not exists $expr->{call}) {
                $code = 'undef';
            }
            else {
                die "[ERROR] Arguments and method calls for 'nil' are not supported!";
            }
        }
        elsif ($ref eq 'Sidef::Types::Null::Null') {
            $code = $self->make_constant($ref, 'new', "Null$refaddr");
        }
        elsif ($ref eq 'Sidef::Types::String::String') {
            $code = $self->make_constant($ref, 'new', "String$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Bool::Bool') {
            $code = $self->make_constant($ref, 'new', ${$obj} ? ("true$refaddr", 1) : ("false$refaddr", 0));
        }
        elsif ($ref eq 'Sidef::Types::Array::MultiArray') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Sidef::Types::Glob::Backtick') {
            $code = $self->make_constant($ref, 'new', "Backtick$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Glob::File') {
            $code = $self->make_constant($ref, 'new', "File$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Glob::Dir') {
            $code = $self->make_constant($ref, 'new', "Dir$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Byte::Bytes') {
            $code = $self->_dump_array($ref, $obj);
        }
        elsif ($ref eq 'Sidef::Types::Byte::Byte') {
            $code = $self->make_constant($ref, 'new', "Byte$refaddr", $obj->get_value);
        }
        elsif ($ref eq 'Sidef::Types::Char::Chars') {
            $code = $self->_dump_array($ref, $obj);
        }
        elsif ($ref eq 'Sidef::Types::Char::Char') {
            $code = $self->make_constant($ref, 'new', "Char$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Grapheme::Graphemes') {
            $code = $self->_dump_array($ref, $obj);
        }
        elsif ($ref eq 'Sidef::Types::Grapheme::Grapheme') {
            $code = $self->make_constant($ref, 'new', "Grapheme$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Sidef::Types::Glob::Pipe') {
            $code = $self->make_constant($ref, 'new', "Pipe$refaddr", map { $self->_dump_string($_) } @{$obj});
        }

        # Array indices
        if (exists $expr->{ind}) {
            my $limit = $#{$expr->{ind}};
            foreach my $i (0 .. $limit) {
                my $ind = $expr->{ind}[$i];

                if (substr($code, -1) eq '@') {
                    $code .= $self->_dump_unpacked_indices($ind);
                }
                elsif ($#{$ind} > 0) {
                    $code = '@{' . $code . '}' . $self->_dump_indices($ind);
                }
                else {
                    $code .= '->' . $self->_dump_indices($ind);
                }

                if ($i < $limit and $#{$ind} == 0) {
                    $code = '(' . $code . ' //= Sidef::Types::Array::Array->new' . ')';
                }
            }
        }

        # Hash lookup
        if (exists $expr->{lookup}) {
            my $limit = $#{$expr->{lookup}};
            foreach my $i (0 .. $limit) {
                my $key = $expr->{lookup}[$i];

                if (substr($code, -1) eq '@') {
                    $code .= $self->_dump_unpacked_lookups($key);
                }
                elsif ($#{$key} > 0) {
                    $code = '@{' . $code . '}' . $self->_dump_lookups($key);
                }
                else {
                    $code .= '->' . $self->_dump_lookups($key);
                }

                if ($i < $limit and $#{$key} == 0) {
                    $code = '(' . $code . ' //= Sidef::Types::Hash::Hash->new' . ')';
                }
            }
        }

        my $old_code = $code;

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {

            foreach my $i (0 .. $#{$expr->{call}}) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if ($code ne '') {
                    if (not exists $self->{special_constructs}{$ref}) {
                        $code = '(' . $code . ')';
                    }
                }

                if ($ref eq 'Sidef::Types::Block::Return') {

                    if (exists $self->{function}) {
                        if (@{$call->{arg}}) {
                            $code .= '@return = ' . $self->deparse_args(@{$call->{arg}}) . ';';
                        }
                        $code .= 'goto ' . "END$self->{function}";
                    }
                    else {
                        $code .= 'return Sidef::Types::Block::Return->new' . $self->deparse_args(@{$call->{arg}});
                    }

                    next;
                }

                # !!!Experimental!!!
                #~ if ($ref eq 'Sidef::Types::Block::Break') {
                #~ $code .= 'return Sidef::Types::Block::Break->new' . $self->deparse_args(@{$call->{arg}});
                #~ next;
                #~ }
                #~ elsif ($ref eq 'Sidef::Types::Block::Next') {
                #~ $code .= 'return Sidef::Types::Block::Next->new' . $self->deparse_args(@{$call->{arg}});
                #~ next;
                #~ }

                if (defined $method) {

                    if ($ref eq 'Sidef::Variable::Ref') {    # variable refs

                        # Variable refencing
                        if ($method eq '\\' or $method eq '&') {
                            $code = '\\' . $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        # Variable dereferencing
                        elsif ($method eq '*') {
                            $code = '${' . $self->deparse_args(@{$call->{arg}}) . '}';
                            next;
                        }

                        # Prefix ++ and -- operators on variables
                        elsif (exists $self->{inc_dec_ops}{$method}) {
                            my $var = $self->deparse_args(@{$call->{arg}});
                            $code = "($var=$var\->$self->{inc_dec_ops}{$method})[0]";
                            next;
                        }
                    }

                    # Do-block
                    if ($code eq '' and $ref eq 'Sidef::Types::Block::Do') {
                        my $arg = $self->deparse_generic('', ';', '', @{$call->{arg}});

                        if ($arg =~ s/^Sidef::Types::Block::Code->new\(\s*sub\h*\{//) {
                            $arg =~ s/\}\)\z//;
                        }

                        $code = 'do { ' . $arg . '}';
                        next;
                    }

                    # Postfix ++ and -- operators on variables
                    if (exists($self->{inc_dec_ops}{$method})) {
                        $code = "do{my \$old=$code; $code=$code\->$self->{inc_dec_ops}{$method}; \$old}";
                        next;
                    }

                    if (exists($self->{lazy_ops}{$method})) {
                        $code .= $self->{lazy_ops}{$method} . $self->deparse_block_expr(@{$call->{arg}});
                        next;
                    }

                    # Variable assignment (=)
                    if (exists($self->{assignment_ops}{$method})) {
                        $code = "($code$self->{assignment_ops}{$method}" . $self->deparse_args(@{$call->{arg}}) . ")[0]";
                        next;
                    }

                    # Reasign operators, such as: +=, -=, *=, /=, etc...
                    if (exists $self->{reassign_ops}{$method}) {
                        $code =
                            "do { $code=($code->\${\\'$self->{reassign_ops}{$method}'}"
                          . $self->deparse_args(@{$call->{arg}})
                          . "); $code }";
                        next;
                    }

                    # != and == methods
                    if ($method eq '==' or $method eq '!=') {
                        $code = 'Sidef::Types::Bool::Bool->new(' . $code . 'eq' . $self->deparse_args(@{$call->{arg}}) . ')';
                        $code .= '->not' if ($method eq '!=');
                        next;
                    }

                    # <=> method
                    if ($method eq '<=>') {
                        $code =
                          'Sidef::Types::Number::Number->new(' . $code . 'cmp' . $self->deparse_args(@{$call->{arg}}) . ')';
                        next;
                    }

                    # !~ and ~~ methods
                    if ($method eq '~~' or $method eq '!~') {
                        $self->top_add(qq{use experimental "smartmatch";\n});
                        $code = 'Sidef::Types::Bool::Bool->new(' . $code . '~~' . $self->deparse_args(@{$call->{arg}}) . ')';
                        $code .= '->not' if ($method eq '!~');
                        next;
                    }

                    # ! prefix-unary
                    if ($ref eq 'Sidef::Object::Unary') {
                        if ($method eq '!') {
                            $code = 'Sidef::Types::Bool::Bool->new(!' . $self->deparse_args(@{$call->{arg}}) . ')';
                            next;
                        }

                        if ($method eq '-') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->negate';
                            next;
                        }

                        if ($method eq '+') {
                            $code = $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        if ($method eq '~') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->not';
                            next;
                        }

                        if ($method eq '√') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->sqrt';
                            next;
                        }

                        if ($method eq '>' or $method eq 'say') {
                            $code = 'Sidef::Types::Bool::Bool->new(CORE::say ' . $self->deparse_args(@{$call->{arg}}) . ')';
                            next;
                        }

                        if ($method eq '>>' or $method eq 'print') {
                            $code = 'Sidef::Types::Bool::Bool->new(CORE::print ' . $self->deparse_args(@{$call->{arg}}) . ')';
                            next;
                        }
                    }

                    if (ref($method) eq 'HASH') {
                        $code .= '->${\\do{' . $self->deparse_expr($method) . '}}';
                    }
                    elsif ($method =~ /^[\pL_]/) {

                        # Optimize the "loop {}" construct
                        if ($ref eq 'Sidef::Types::Block::CodeInit' and $method eq 'loop') {
                            my $block = $code =~ s/^\(Sidef::Types::Block::Code->new\(\s*sub\h*(?=\{)//r =~ s/\)\)\z//r;

                            if (not defined $block) {
                                die "[ERROR] Failed to optimize the 'loop {}' construct...";
                            }

                            $code = 'while (1) ' . $block;
                            next;
                        }

                        # Optimize the "n.times {}" construct
                        elsif ($ref eq 'Sidef::Types::Number::Number' and $method eq 'times' and $$obj < (-1 >> 1)) {

                            my $arg   = $self->deparse_args(@{$call->{arg}});
                            my $block = $arg =~ s/^\(Sidef::Types::Block::Code->new\(\s*sub\h*\{//r =~ s/\)\)\z//r;

                            $code = "for (1..$$obj) { local \@_ = (Sidef::Types::Number::Number->new(\$_));  " . $block;
                            next;
                        }

                        # Exclamation mark (!) at the end of a method
                        elsif (substr($method, -1) eq '!') {
                            $code = '('
                              . "$old_code=$code->"
                              . substr($method, 0, -1)
                              . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '')
                              . ", $old_code" . ')[1]';
                            next;
                        }

                        # Special case for methods without '->'
                        else {
                            $code .= '->' if $code ne '';
                            $code .= $method;
                        }
                    }
                    else {

                        # Postfix dereference method
                        if ($method eq '@' or $method eq '@*') {
                            $self->top_add(qq{use experimental 'postderef';\n});
                            $code .= '->' . $method;
                        }

                        # Operator-like method call
                        else {
                            $code .= '->${\\' . q{'} . $method . q{'} . '}';
                        }
                    }
                }

                if (exists $call->{keyword}) {
                    $code .= $call->{keyword};
                }

                if (exists $call->{arg}) {
                    if ($ref eq 'Sidef::Types::Block::For') {
                        $code .= $self->deparse_generic('(', ';', ')', @{$call->{arg}});
                    }
                    else {
                        $code .= $self->deparse_args(@{$call->{arg}});
                    }
                }

                if (exists $call->{block}) {
                    if ($ref eq 'Sidef::Types::Block::Given'
                        or ($ref eq 'Sidef::Types::Block::If' and $i == $#{$expr->{call}})) {
                        $code = "do { " . $code . $self->deparse_bare_block(@{$call->{block}}) . '}';
                    }
                    else {
                        $code .= $self->deparse_bare_block(@{$call->{block}});
                    }
                    next;
                }
            }
        }

        $code;
    }

    sub deparse_script {
        my ($self, $struct) = @_;

        my @results;

        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {

            my $max = $#{$struct->{$class}};
            foreach my $i (0 .. $max) {
                my $expr = $struct->{$class}[$i];

                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});

                if ($i > 0 and ref($struct->{$class}[$i - 1]{self}) eq 'Sidef::Variable::Label') {
                    $results[-1] = $struct->{$class}[$i - 1]{self}->{name} . ':' . $results[-1];
                }
                elsif ($i == $max and ref($expr->{self}) eq 'Sidef::Variable::Label') {
                    $results[-1] = $expr->{self}{name} . ':';
                }
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);

        (
             $self->{before}
           . ($self->{_has_constant} ? "};\n" : '')
           . (
              exists($self->{function_declarations})
                && @{$self->{function_declarations}}
              ? ("\n" . join("\n", map { $_->[1] } @{$self->{function_declarations}}) . "\n")
              : ''
             )
           . $self->{top_program} . "\n"
           . join($self->{between}, @statements)
           . $self->{after}
        ) =~ s/^\s*/$self->{header}/r;
    }
}

1;
