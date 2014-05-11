package Sidef::Types::String::String {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, $str) = @_;
        $str //= '';
        bless \$str, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]};
    }

    sub inc {
        my ($self) = @_;
        my $copy = $$self;
        $self->new(++$copy);
    }

    sub div {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        (my $strlen = int(length($$self) / $$num)) < 1 && return;
        Sidef::Types::Array::Array->new(map { $self->new($_) } unpack "(a$strlen)*", $$self);
    }

    *divide = \&div;

    sub lt {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Bool::Bool->new($$self lt $$string);
    }

    sub gt {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Bool::Bool->new($$self gt $$string);
    }

    sub le {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Bool::Bool->new($$self le $$string);
    }

    sub ge {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Bool::Bool->new($$self ge $$string);
    }

    sub subtract {
        my ($self, $obj) = @_;

        if (ref $obj eq 'Sidef::Types::Regex::Regex') {
            if ($$self =~ /$obj->{regex}/) {
                return $self->new(CORE::substr($$self, 0, $-[0]) . CORE::substr($$self, $+[0]));
            }
            return $self;
        }

        $self->_is_string($obj) || return;
        if ((my $ind = CORE::index($$self, $$obj)) != -1) {
            return $self->new(CORE::substr($$self, 0, $ind) . CORE::substr($$self, $ind + CORE::length($$obj)));
        }
        $self;
    }

    sub ne {
        my ($self, $string) = @_;
        $self->_is_string($string, 1, 1) || return (Sidef::Types::Bool::Bool->true);
        Sidef::Types::Bool::Bool->new($$self ne $$string);
    }

    sub match {
        my ($self, $regex, @rest) = @_;
        $self->_is_regex($regex) || return;
        $regex->match($self, @rest);
    }

    *matches = \&match;

    sub gmatch {
        my ($self, $regex, @rest) = @_;
        $self->_is_regex($regex) || return;
        $regex->gmatch($self, @rest);
    }

    *gmatches = \&gmatch;

    sub to {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Array::Array->new(map { $self->new($_) } $$self .. $$string);
    }

    *upto = \&to;
    *upTo = \&to;

    sub downto {
        my ($self, $string) = @_;
        $string->to($self)->reverse;
    }

    *downTo = \&downto;

    sub cmp {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Number::Number->new($$self cmp $$string);
    }

    sub xor {
        my ($self, $str) = @_;
        $self->_is_string($str) || return;
        $self->new($$self ^ $$str);
    }

    sub or {
        my ($self, $str) = @_;
        $self->_is_string($str) || return;
        $self->new($$self | $$str);
    }

    sub and {
        my ($self, $str) = @_;
        $self->_is_string($str) || return;
        $self->new($$self & $$str);
    }

    sub times {
        my ($self, $num) = @_;
        $self->_is_number($num) || return;
        $self->new($$self x $$num);
    }

    *multiply = \&times;

    sub repeat {
        my ($self, $num) = @_;
        $num //= Sidef::Types::Number::Number->new(1);
        $self->times($num);
    }

    sub uc {
        my ($self) = @_;
        $self->new(CORE::uc $$self);
    }

    *toUpperCase = \&uc;
    *upcase      = \&uc;
    *upCase      = \&uc;
    *upper       = \&uc;

    sub equals {
        my ($self, $string) = @_;
        $self->_is_string($string, 1, 1) || return (Sidef::Types::Bool::Bool->false);
        Sidef::Types::Bool::Bool->new($$self eq $$string);
    }

    *eq = \&equals;
    *is = \&equals;

    sub append {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        __PACKAGE__->new($$self . $$string);
    }

    *concat = \&append;

    sub ucfirst {
        my ($self) = @_;
        $self->new(CORE::ucfirst $$self);
    }

    *tc         = \&ucfirst;
    *titleCase  = \&ucfirst;
    *title_case = \&ucfirst;

    sub lc {
        my ($self) = @_;
        $self->new(CORE::lc $$self);
    }

    *toLowerCase = \&lc;
    *downcase    = \&lc;
    *downCase    = \&lc;
    *lower       = \&lc;

    sub lcfirst {
        my ($self) = @_;
        $self->new(CORE::lcfirst $$self);
    }

    sub charAt {
        my ($self, $pos) = @_;
        $self->_is_number($pos) || return;
        Sidef::Types::Char::Char->new(CORE::substr($$self, $$pos, 1));
    }

    *char_at = \&charAt;

    sub wordcase {
        my ($self) = @_;

        my $string = $1
          if ($$self =~ /\G(\s+)/gc);

        while ($$self =~ /\G(\S++)(\s*+)/gc) {
            $string .= CORE::ucfirst(CORE::lc($1)) . $2;
        }

        $self->new($string);
    }

    *wc       = \&wordcase;
    *wordCase = \&wordcase;

    sub capitalize {
        my ($self) = @_;
        $self->new(CORE::ucfirst(CORE::lc($$self)));
    }

    *tclc = \&capitalize;

    sub chop {
        my ($self) = @_;
        $self->new(CORE::substr($$self, 0, -1));
    }

    sub pop {
        my ($self) = @_;
        $self->new(CORE::substr($$self, -1));
    }

    sub chomp {
        my ($self) = @_;

        if (substr($$self, -1) eq "\n") {
            return $self->chop;
        }

        $self;
    }

    sub crypt {
        my ($self, $salt) = @_;
        $self->_is_string($salt) || return;
        $self->new(crypt($$self, $$salt));
    }

    sub substr {
        my ($self, $offs, $len) = @_;

        $self->_is_number($offs) || return;

        my @str = CORE::split(//, $$self);
        my $str_len = $#str;

        $offs = $$offs;

        if (defined $len) {
            $self->_is_number($len) || return;
            $len = $$len;
        }

        $offs = 1 + $str_len + $offs if $offs < 0;
        $len = defined $len ? $len < 0 ? $str_len + $len : $offs + $len - 1 : $str_len;

        __PACKAGE__->new(CORE::join('', grep { defined } @str[$offs .. $len]));
    }

    *ft        = \&substr;
    *substring = \&substr;

    sub insert {
        my ($self, $string, $pos, $len) = @_;

        ($self->_is_string($string) && $self->_is_number($pos))
          || return;

        if (defined $len) {
            $self->_is_number($len) || return;
        }
        else {
            $len = Sidef::Types::Number::Number->new(0);
        }

        my $new_str = $self->new($$self);
        CORE::substr($$new_str, $$pos, $$len, $$string);
        return $new_str;
    }

    sub join {
        my ($self, $delim, @rest) = @_;
        $self->_is_string($delim) || return;
        __PACKAGE__->new(CORE::join($$delim, $$self, @rest));
    }

    sub clear {
        my ($self) = @_;
        $self->new('');
    }

    sub is_empty {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self eq '');
    }

    *isEmpty = \&is_empty;

    sub index {
        my ($self, $substr, $pos) = @_;
        $self->_is_string($substr) || return;

        if (defined($pos)) {
            $self->_is_number($pos) || return;
        }

        Sidef::Types::Number::Number->new(
                                          defined($pos)
                                          ? CORE::index($$self, $$substr, $$pos)
                                          : CORE::index($$self, $$substr)
                                         );
    }

    *indexOf = \&index;

    sub ord {
        my ($self) = @_;
        Sidef::Types::Byte::Byte->new(CORE::ord($$self));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(scalar CORE::reverse($$self));
    }

    sub say {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::say($$self));
    }

    *println = \&say;

    sub print {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(print $$self);
    }

    sub printf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf $$self, @arguments);
    }

    sub printlnf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf($$self . "\n", @arguments));
    }

    sub sprintf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(CORE::sprintf $$self, @arguments);
    }

    sub sprintlnf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(CORE::sprintf($$self . "\n", @arguments));
    }

    sub _string_or_regex {
        my ($regex) = @_;

        if (ref($regex) ne 'Sidef::Types::Regex::Regex') {
            if ($regex->can('quotemeta')) {
                return $regex->quotemeta;
            }
        }

        return $regex->get_value;
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        $str //= __PACKAGE__->new('');
        $self->_is_string($str) || return;
        $regex = _string_or_regex($regex);

        $self->new($$self =~ s{$regex}{$$str}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        $str //= __PACKAGE__->new('');
        $self->_is_string($str) || return;
        $regex = _string_or_regex($regex);

        $self->new($$self =~ s{$regex}{$$str}gr);
    }

    *gReplace = \&gsub;

    sub esub {
        my ($self, $regex, $str) = @_;

        $str //= __PACKAGE__->new('');
        $self->_is_string($str) || return;
        $regex = _string_or_regex($regex);

        $self->new($$self =~ s{$regex}{$$str}eer);
    }

    sub gesub {
        my ($self, $regex, $str) = @_;

        $str //= __PACKAGE__->new('');
        $self->_is_string($str) || return;
        $regex = _string_or_regex($regex);

        $self->new($$self =~ s{$regex}{$$str}geer);
    }

    sub glob {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::glob($$self));
    }

    sub quotemeta {
        my ($self) = @_;
        __PACKAGE__->new(CORE::quotemeta($$self));
    }

    sub split {
        my ($self, $sep, $size) = @_;

        $size = defined($size) && ($self->_is_number($size) || return) ? $$size : 0;

        if (ref($sep) eq '') {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(' ', $$self, $size));
        }
        elsif ($self->_is_number($sep, 1, 1)) {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } unpack "(a$$sep)*", $$self);
        }

        $sep = _string_or_regex($sep);
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(/$sep/, $$self, $size));
    }

    sub sort {
        my ($self, $block) = @_;

        if (defined $block) {
            $self->_is_code($block) || return;
            return $self->to_chars->sort($block)->join;
        }

        $self->new(CORE::join('', sort(CORE::split(//, $$self))));
    }

    sub each_word {
        my ($self, $obj) = @_;
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(' ', $$self));
        $obj // return $array;
        $self->_is_code($obj) || return;
        $obj->for($array);
    }

    *words    = \&each_word;
    *eachWord = \&each_word;

    sub chars {
        my ($self) = @_;
        Sidef::Types::Char::Chars->new(map { Sidef::Types::Char::Char->new($_) } CORE::split(//, $$self));
    }

    sub each {
        my ($self, $code) = @_;

        $self->_is_code($code) || return;
        my ($var_ref) = $code->init_block_vars();

        foreach my $char (CORE::split(//, $$self)) {
            $var_ref->set_value(__PACKAGE__->new($char));
            if (defined(my $res = $code->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    *each_char = \&each;
    *eachChar  = \&each;

    sub each_line {
        my ($self, $obj) = @_;
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(/\R/, $$self));
        $obj // return $array;
        $self->_is_code($obj) || return;
        $obj->for($array);
    }

    *lines    = \&each_line;
    *eachLine = \&each_line;

    sub trim {
        my ($self) = @_;
        $self->new(unpack('A*', $$self) =~ s/^\s+//r);
    }

    *strip = \&trim;

    sub strip_beg {
        my ($self) = @_;
        $self->new($$self =~ s/^\s+//r);
    }

    *trim_beg = \&strip_beg;
    *trimBeg  = \&strip_beg;
    *stripBeg = \&strip_beg;

    sub strip_end {
        my ($self) = @_;
        $self->new(unpack('A*', $$self));
    }

    *trim_end = \&strip_end;
    *trimEnd  = \&strip_end;
    *stripEnd = \&strip_end;

    sub trans {
        my ($self, $orig, $repl) = @_;

        my %map;
        if (not defined($repl) and defined($orig)) {    # assume an array of pairs
            $self->_is_array($orig) || return;
            foreach my $pair (map { $_->get_value } @{$orig}) {
                $self->_is_pair($pair) || return;
                $map{$pair->first} = $pair->second->get_value;
            }
        }
        else {
            ($self->_is_array($orig) && $self->_is_array($repl)) || return;

            $#{$orig} == $#{$repl} || do {
                warn "[WARN] String.trans(): the arguments must have the same length! ($#{$orig} != $#{$repl})\n";
                return;
            };

            @map{@{$orig}} = (map { $_->get_value } @{$repl});
        }

        my $tries = CORE::join('|', map { CORE::quotemeta($_) } sort { length($b) <=> length($a) } CORE::keys(%map));
        $self->new($$self =~ s{($tries)}{$map{$1}}gr);
    }

    sub translit {
        my ($self, $orig, $repl, $modes) = @_;

        $self->_is_array($orig, 1, 1) && return $self->trans($orig, $repl);
        ($self->_is_string($orig) && $self->_is_string($repl)) || return;
        $self->new(
                   eval qq{"\Q$$self\E"=~tr/} . $$orig =~ s{([/\\])}{\\$1}gr . "/" . $$repl =~
                     s{([/\\])}{\\$1}gr . "/r" . (defined($modes) ? $self->_is_string($modes) ? $$modes : return : ''));
    }

    *tr = \&translit;

    sub unpack {
        my ($self, $format) = @_;
        $self->_is_string($format) || return;
        my @parts = CORE::unpack($$format, $$self);
        $#parts == 0 ? __PACKAGE__->new($parts[0]) : Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } @parts);
    }

    sub pack {
        my ($self, $format) = @_;
        $self->_is_string($format) || return;
        __PACKAGE__->new(CORE::pack($$format, $$self));
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::length($$self));
    }

    *len = \&length;

    sub parse {
        my ($self, $code) = @_;

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, __PACKAGE__->new($_[0]) };

        my $parser = Sidef::Parser->new(script_name => '/eval/');
        my $struct = eval { $parser->parse_script(code => $$self) } // {};

        if ($@ || @warnings) {
            my $error = $@;

            if (defined($code)) {
                $self->_is_code($code) || return;
                $code->call(Sidef::Types::Array::Array->new(@warnings), __PACKAGE__->new($error));
            }

            return if $error;
        }

        Sidef::Types::Block::Code->new($struct);
    }

    sub eval {
        my ($self, $code) = @_;

        my $block = $self->parse($code) // return;

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, __PACKAGE__->new($_[0]) };

        my $result = eval { $block->run };

        if ($@ || @warnings) {
            my $error = $@;

            if (defined($code)) {
                $self->_is_code($code) || return;
                $code->call(Sidef::Types::Array::Array->new(@warnings), __PACKAGE__->new($error));
            }

            return if $error;
        }

        $result;
    }

    sub contains {
        my ($self, $string, $start_pos) = @_;

        $self->_is_string($string) || return;
        $start_pos = (
                        defined($start_pos)
                      ? $self->_is_number($start_pos)
                            ? ($$start_pos)
                            : (return)
                      : (0)
                     );

        if ($start_pos < 0) {
            $start_pos = CORE::length($$self) + $start_pos;
        }

        Sidef::Types::Bool::Bool->new(CORE::index($$self, $$string, $start_pos) != -1);
    }

    *include = \&contains;

    sub count {
        my ($self, $substr) = @_;
        $self->_is_string($substr) || return;

        my $pos     = -1;
        my $counter = 0;
        while (($pos = CORE::index($$self, $$substr, $pos + 1)) != -1) {
            ++$counter;
        }

        Sidef::Types::Number::Number->new($counter);
    }

    sub overlaps {
        my ($self, $arg) = @_;
        $self->_is_string($arg) || return;
        Sidef::Types::Bool::Bool->new(CORE::index($$self ^ $$arg, "\0") != -1);
    }

    sub begins_with {
        my ($self, $string) = @_;

        $self->_is_string($string)
          || return;

        CORE::length($$self) < (my $len = CORE::length($$string))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($$self, 0, $len) eq $$string
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *starts_with = \&begins_with;
    *startsWith  = \&begins_with;
    *beginsWith  = \&begins_with;

    sub ends_with {
        my ($self, $string) = @_;

        $self->_is_string($string)
          || return;

        CORE::length($$self) < (my $len = CORE::length($$string))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($$self, -$len) eq $$string
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *endsWith = \&ends_with;

    sub warn {
        my ($self) = @_;
        warn $$self;
    }

    sub die {
        my ($self) = @_;
        die $$self;
    }

    sub encode {
        my ($self, $enc) = @_;
        $self->_is_string($enc) || return;
        $self->new(Encode::encode($$enc, $$self));
    }

    sub decode {
        my ($self, $enc) = @_;
        $self->_is_string($enc) || return;
        $self->new(Encode::decode($$enc, $$self));
    }

    sub encode_utf8 {
        my ($self) = @_;
        $self->new(Encode::encode_utf8($$self));
    }

    sub decode_utf8 {
        my ($self) = @_;
        $self->new(Encode::decode_utf8($$self));
    }

    sub unescape {
        my ($self) = @_;
        $self->new($$self =~ s{\\(\W)}{$1}gsr);
    }

    sub apply_escapes {
        my ($self, $parser) = @_;
        my $str = $$self;

        state $esc = {
                      a => "\a",
                      b => "\b",
                      e => "\e",
                      f => "\f",
                      n => "\n",
                      r => "\r",
                      t => "\t",
                     };

        my @inline_expressions;
        my @chars = split(//, $str);

        ## Known bug: "hell\Uo" returns "hello" instead of "hellO"
        ##                 /\
        ##                  `--  in this particular case, "\u" should be used instead!

        my $spec = 'E';
        for (my $i = 0 ; $i <= $#chars - 1 ; $i++) {

            if ($chars[$i] eq '\\') {
                my $char = $chars[$i + 1];

                if (exists $esc->{$char}) {
                    splice(@chars, $i--, 2, $esc->{$char});
                }
                elsif ($char eq 'L' or $char eq 'U' or $char eq 'E') {
                    $spec = $char;
                    splice(@chars, $i, 2);
                    $char ne 'Q' && ($i--);
                    next;
                }
                elsif ($char eq 'l') {
                    if (exists $chars[$i + 2]) {
                        splice(@chars, $i, 3, CORE::lc($chars[$i + 2]));
                        next;
                    }
                    else {
                        splice(@chars, $i, 2);
                    }
                }
                elsif ($char eq 'u') {
                    if (exists $chars[$i + 2]) {
                        splice(@chars, $i, 3, CORE::uc($chars[$i + 2]));
                        next;
                    }
                    else {
                        splice(@chars, $i, 2);
                    }
                }
                elsif ($char =~ /^[0-7]/) {
                    splice(@chars, $i, 2, chr($char));
                }
                elsif ($char eq 'd') {
                    splice(@chars, $i - 1, 3);
                }
                elsif ($char eq 'c') {
                    if (exists $chars[$i + 2]) {    # bug for: "\c\\"
                        splice(@chars, $i, 3, chr((CORE::ord(CORE::uc($chars[$i + 2])) + 64) % 128));
                    }
                    else {
                        CORE::warn "Missing control char name in \\c, within string\n";
                        splice(@chars, $i, 2);
                    }
                }
                else {
                    splice(@chars, $i, 1);
                }
            }
            elsif ($chars[$i] eq '#' and exists $chars[$i + 1] and $chars[$i + 1] eq '{') {
                if (ref $parser eq 'Sidef::Parser') {
                    my $code = CORE::join('', @chars[$i + 1 .. $#chars]);
                    my ($block, $pos) = $parser->parse_block(code => $code);

                    push @inline_expressions, [$i, $block];
                    splice(@chars, $i--, 1 + $pos);
                }
                else {
                    # Can't eval #{} at runtime!
                }
            }

            if ($spec ne 'E') {
                foreach my $j ($i, ($i == $#chars - 1) ? ($i + 1) : ()) {
                    if ($spec eq 'U') {
                        $chars[$j] = CORE::uc($chars[$j]);
                    }
                    elsif ($spec eq 'L') {
                        $chars[$j] = CORE::lc($chars[$j]);
                    }
                }
            }
        }

        if (@inline_expressions) {

            foreach my $i (0 .. $#inline_expressions) {
                my $pair = $inline_expressions[$i];
                splice @chars, $pair->[0] + $i, 0, $pair->[1];
            }

            my $expr;
            my $append_arg = sub {
                push @{$expr->{$parser->{class}}[0]{call}}, {arg => [$_[0]], method => '+'};
            };

            my $string = '';
            foreach my $char (@chars) {
                if (ref($char) eq 'Sidef::Types::Block::Code') {
                    my $block = {$parser->{class} => [{self => $char, call => [{method => 'run'}, {method => 'to_s'}]}]};

                    if (not defined $expr) {
                        $expr = {$parser->{class} => [{self => $string eq '' ? $block : $self->new($string), call => []}]};

                        next if $string eq '';
                        $append_arg->($block);
                        $string = '';
                        next;
                    }

                    $append_arg->($string eq '' ? $block : $self->new($string));

                    next if $string eq '';
                    $append_arg->($block);
                    $string = '';
                    next;
                }

                $string .= $char;
            }

            if ($string ne '') {
                $append_arg->($self->new($string));
            }

            return $expr;
        }

        $self->new(CORE::join('', @chars));
    }

    *applyEscapes = \&apply_escapes;

    sub shift_left {
        my ($self, $i) = @_;

        $self->_is_number($i) || return;

        my $len = CORE::length($$self);
        $i = $$i > $len ? $len : $$i;
        $self->new(CORE::substr($$self, $i));
    }

    *dropLeft  = \&shift_left;
    *drop_left = \&shift_left;
    *shiftLeft = \&shift_left;

    sub shift_right {
        my ($self, $i) = @_;
        $self->_is_number($i) || return;
        $self->new(CORE::substr($$self, 0, -$$i));
    }

    *dropRight  = \&shift_right;
    *drop_right = \&shift_right;
    *shiftRight = \&shift_right;

    sub pair_with {
        Sidef::Types::Array::Pair->new($_[0], $_[1]);
    }

    *pairWith = \&pair_with;

    sub dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $$self =~ s{'}{\\'}gr . q{'});
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '=~'}  = \&match;
        *{__PACKAGE__ . '::' . '*'}   = \&times;
        *{__PACKAGE__ . '::' . '+'}   = \&append;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '-'}   = \&subtract;
        *{__PACKAGE__ . '::' . '=='}  = \&equals;
        *{__PACKAGE__ . '::' . '='}   = \&equals;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '..'}  = \&to;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '^^'}  = \&begins_with;
        *{__PACKAGE__ . '::' . '$$'}  = \&ends_with;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '%'}   = \&sprintf;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
    }
};

1
