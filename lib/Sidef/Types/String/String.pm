package Sidef::Types::String::String {

    use utf8;
    use 5.014;

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

    sub unroll_operator {
        my ($self, $operator, $arg) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(//, $$self))->unroll_operator(

            # The operator, followed by...
            $operator,

            # ...an optional argument
            defined($arg)
            ? $self->_is_string($arg)
                  ? Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(//, $$arg))
                  : return
            : ()

        )->join;
    }

    sub reduce_operator {
        my ($self, $operator) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(//, $$self))->reduce_operator($operator);
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
            if (exists $obj->{global}) {
                return $self->new($$self =~ s/$obj->{regex}//gr);
            }
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
        $self->_is_string($string, 1, 1)
          || return (Sidef::Types::Bool::Bool->true);
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
        if (length($$self) == 1 and length($$string) == 1) {
            return Sidef::Types::Array::Array->new(map { $self->new(chr($_)) } ord($$self) .. ord($$string));
        }
        Sidef::Types::Array::Array->new(map { $self->new($_) } $$self .. $$string);
    }

    *upto = \&to;
    *upTo = \&to;

    sub downto {
        my ($self, $string) = @_;
        $string->to($self)->reverse;
    }

    *downTo = \&downto;

    sub range_to {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Array::Range->new(from => $$self, to => $$string, type => 'string', direction => 'up');
    }

    sub range_downto {
        my ($self, $string) = @_;
        $self->_is_string($string) || return;
        Sidef::Types::Array::Range->new(from => $$self, to => $$string, type => 'string', direction => 'down');
    }

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

    sub not {
        my ($self) = @_;
        $self->new(~$$self);
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
        $self->_is_string($string, 1, 1)
          || return (Sidef::Types::Bool::Bool->false);
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

        __PACKAGE__->new(
                         defined($len)
                         ? CORE::substr($$self, $$offs, $$len)
                         : CORE::substr($$self, $$offs)
                        );
    }

    *ft        = \&substr;
    *substring = \&substr;

    sub insert {
        my ($self, $string, $pos, $len) = @_;

        $self->_is_string($string) || return;
        $self->_is_number($pos)    || return;

        $len = defined($len) ? $self->_is_number($len) ? $$len : (return) : 0;

        CORE::substr(my $copy_str = $$self, $$pos, $len, $$string);
        __PACKAGE__->new($copy_str);
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

        if (@arguments == 1 and ref($arguments[0]) eq 'Sidef::Types::Array::Array') {
            @arguments = map { $_->get_value } @{$arguments[0]};
        }

        __PACKAGE__->new(CORE::sprintf $$self, @arguments);
    }

    sub sprintlnf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(CORE::sprintf($$self . "\n", @arguments));
    }

    sub _string_or_regex {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            return $obj->{regex};
        }

        $self->_is_string($obj) || return;
        CORE::quotemeta($$obj);
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        $self->_is_code($str, 1, 1)
          && return $self->esub($regex, $str);

        $str //= __PACKAGE__->new('');
        $self->_is_string($str) || return;
        $regex = $self->_string_or_regex($regex);

        $self->new($$self =~ s{$regex}{$$str}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        $self->_is_code($str, 1, 1)
          && return $self->gesub($regex, $str);

        $str //= __PACKAGE__->new('');
        $self->_is_string($str) || return;
        $regex = $self->_string_or_regex($regex);

        $self->new($$self =~ s{$regex}{$$str}gr);
    }

    *gReplace = \&gsub;

    sub _get_captures {
        my ($string) = @_;
        map { __PACKAGE__->new(CORE::substr($string, $-[$_], $+[$_] - $-[$_])) } 1 .. $#{-};
    }

    sub esub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        $regex = $self->_string_or_regex($regex);

        if ($self->_is_string($code, 1, 1)) {
            return __PACKAGE__->new($$self =~ s{$regex}{$$code}eer);
        }

        $self->_is_code($code) || return;
        __PACKAGE__->new($$self =~ s{$regex}{$code->call(_get_captures($$self))}er);
    }

    sub gesub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        $regex = $self->_string_or_regex($regex);

        if ($self->_is_string($code, 1, 1)) {
            return __PACKAGE__->new($$self =~ s{$regex}{$$code}geer);
        }

        $self->_is_code($code) || return;
        __PACKAGE__->new($$self =~ s{$regex}{$code->call(_get_captures($$self))}ger);
    }

    sub glob {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::glob($$self));
    }

    sub quotemeta {
        my ($self) = @_;
        __PACKAGE__->new(CORE::quotemeta($$self));
    }

    *escape = \&quotemeta;

    sub scan {
        my ($self, $regex) = @_;
        $self->_is_regex($regex) || return;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } $$self =~ /$regex->{regex}/g);
    }

    sub split {
        my ($self, $sep, $size) = @_;

        $size =
          defined($size) && ($self->_is_number($size) || return) ? $$size : 0;

        if (ref($sep) eq '') {
            return
              Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                                split(' ', $$self, $size));
        }
        elsif ($self->_is_number($sep, 1, 1)) {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } unpack "(a$$sep)*", $$self);
        }

        $sep = $self->_string_or_regex($sep);
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                          split(/$sep/, $$self, $size));
    }

    sub sort {
        my ($self, $block) = @_;

        if (defined $block) {
            $self->_is_code($block) || return;
            return $self->to_chars->sort($block)->join;
        }

        $self->new(CORE::join('', sort(CORE::split(//, $$self))));
    }

    sub format {
        my ($self) = @_;
        CORE::chomp(my $text = 'format __MY_FORMAT__ = ' . "\n" . $$self);
        eval($text . "\n.");

        open my $str_h, '>', \my $acc;
        my $old_h = select($str_h);
        local $~ = '__MY_FORMAT__';
        write;
        select($old_h);
        close $str_h;

        Sidef::Types::String::String->new($acc);
    }

    sub each_word {
        my ($self, $obj) = @_;
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(' ', $$self));
        $obj // return $array;
        $self->_is_code($obj) || return;
        $array->each($obj);
    }

    *words    = \&each_word;
    *eachWord = \&each_word;

    sub bytes {
        my ($self) = @_;
        $self->to_bytes;
    }

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
                $code->pop_stack();
                return $res;
            }
        }

        $code->pop_stack();
        $self;
    }

    *each_char = \&each;
    *eachChar  = \&each;

    sub each_line {
        my ($self, $obj) = @_;
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(/\R/, $$self));
        $obj // return $array;
        $self->_is_code($obj) || return;
        $array->each($obj);
    }

    *lines    = \&each_line;
    *eachLine = \&each_line;

    sub open_r {
        my ($self, @rest) = @_;
        require Encode;
        my $string = Encode::encode_utf8($$self);
        Sidef::Types::Glob::File->new(\$string)->open_r(@rest);
    }

    sub open {
        my ($self, @rest) = @_;
        require Encode;
        my $string = Encode::encode_utf8($$self);
        Sidef::Types::Glob::File->new(\$string)->open(@rest);
    }

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
        if (CORE::not defined($repl) and defined($orig)) {    # assume an array of pairs
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

        my $tries = CORE::join('|', map { CORE::quotemeta($_) }
                                 sort { length($b) <=> length($a) } CORE::keys(%map));
        $self->new($$self =~ s{($tries)}{$map{$1}}gr);
    }

    sub translit {
        my ($self, $orig, $repl, $modes) = @_;

        $self->_is_array($orig, 1, 1) && return $self->trans($orig, $repl);
        ($self->_is_string($orig) && $self->_is_string($repl)) || return;
        $self->new(
                       eval qq{"\Q$$self\E"=~tr/}
                     . $$orig =~ s{([/\\])}{\\$1}gr . "/"
                     . $$repl =~ s{([/\\])}{\\$1}gr . "/r"
                     . (
                          defined($modes)
                        ? $self->_is_string($modes)
                              ? $$modes
                              : return
                        : ''
                       )
                  );
    }

    *tr = \&translit;

    sub unpack {
        my ($self, $argv) = @_;
        $self->_is_string($argv) || return;
        my @parts = CORE::unpack($$self, $$argv);
        $#parts == 0
          ? __PACKAGE__->new($parts[0])
          : Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } @parts);
    }

    sub pack {
        my ($self, @list) = @_;
        __PACKAGE__->new(CORE::pack($$self, @list));
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::length($$self));
    }

    *len = \&length;

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
        require Encode;
        $self->new(Encode::encode($$enc, $$self));
    }

    sub decode {
        my ($self, $enc) = @_;
        $self->_is_string($enc) || return;
        require Encode;
        $self->new(Encode::decode($$enc, $$self));
    }

    sub encode_utf8 {
        my ($self) = @_;
        require Encode;
        $self->new(Encode::encode_utf8($$self));
    }

    sub decode_utf8 {
        my ($self) = @_;
        require Encode;
        $self->new(Encode::decode_utf8($$self));
    }

    sub unescape {
        my ($self) = @_;
        $self->new($$self =~ s{\\(.)}{$1}grs);
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
                      s => ' ',
                      v => chr(11),
                     };

        my @inline_expressions;
        my @chars = split(//, $str);

        my $spec = 'E';
        for (my $i = 0 ; $i <= $#chars ; $i++) {

            if ($chars[$i] eq '\\' and exists $chars[$i + 1]) {
                my $char = $chars[$i + 1];

                if (exists $esc->{$char}) {
                    splice(@chars, $i--, 2, $esc->{$char});
                    next;
                }
                elsif (   $char eq 'L'
                       or $char eq 'U'
                       or $char eq 'E'
                       or $char eq 'Q') {
                    $spec = $char;
                    splice(@chars, $i--, 2);
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
                elsif ($char eq 'N') {
                    if (exists $chars[$i + 2] and $chars[$i + 2] eq '{') {
                        my $str = CORE::join('', @chars[$i + 2 .. $#chars]);
                        if ($str =~ /^\{(.*?)\}/) {
                            require charnames;
                            my $char = charnames::string_vianame($1);
                            if (defined $char) {
                                splice(@chars, $i--, 2 + $+[0], $char);
                                next;
                            }
                        }
                        else {
                            CORE::warn("Missing right brace on \\N{, within string!\n");
                        }
                    }
                    else {
                        CORE::warn("Missing braces on \\N{}, within string!\n");
                    }
                    splice(@chars, $i, 1);
                }
                elsif ($char eq 'x') {
                    if (exists $chars[$i + 2]) {
                        my $str = CORE::join('', @chars[$i + 2 .. $#chars]);
                        if ($str =~ /^\{([[:xdigit:]]+)\}/) {
                            splice(@chars, $i, 2 + $+[0], chr(hex($1)));
                            next;
                        }
                        elsif ($str =~ /^([[:xdigit:]]{1,2})/) {
                            splice(@chars, $i, 2 + $+[0], chr(hex($1)));
                            next;
                        }
                    }
                    splice(@chars, $i, 1);
                }
                elsif ($char eq 'o') {
                    if (exists $chars[$i + 2] and $chars[$i + 2] eq '{') {
                        my $str = CORE::join('', @chars[$i + 2 .. $#chars]);
                        if ($str =~ /^\{(.*?)\}/) {
                            splice(@chars, $i--, 2 + $+[0], chr(oct($1)));
                            next;
                        }
                        else {
                            CORE::warn("Missing right brace on \\o{, within string!\n");
                        }
                    }
                    else {
                        CORE::warn("Missing braces on \\o{}, within string!\n");
                    }
                    splice(@chars, $i, 1);
                }
                elsif ($char =~ /^[0-7]/) {
                    my $str = CORE::join('', @chars[$i + 1 .. $#chars]);
                    if ($str =~ /^(0[0-7]{1,2}|[0-7]{1,2})/) {
                        splice @chars, $i, 1 + $+[0], chr(oct($1));
                    }
                }
                elsif ($char eq 'd') {
                    splice(@chars, $i - 1, 3);
                }
                elsif ($char eq 'c') {
                    if (exists $chars[$i + 2]) {    # bug for: "\c\\"
                        splice(@chars, $i, 3, chr((CORE::ord(CORE::uc($chars[$i + 2])) + 64) % 128));
                    }
                    else {
                        CORE::warn "[WARN] Missing control char name in \\c, within string\n";
                        splice(@chars, $i, 2);
                    }
                }
                else {
                    splice(@chars, $i, 1);
                }
            }
            elsif (    $chars[$i] eq '#'
                   and exists $chars[$i + 1]
                   and $chars[$i + 1] eq '{') {
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
                if ($spec eq 'U') {
                    $chars[$i] = CORE::uc($chars[$i]);
                }
                elsif ($spec eq 'L') {
                    $chars[$i] = CORE::lc($chars[$i]);
                }
                elsif ($spec eq 'Q') {
                    $chars[$i] = CORE::quotemeta($chars[$i]);
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
                    my $block = {
                                 $parser->{class} => [
                                                      {
                                                       self => $char,
                                                       call => [{method => 'run'}, {method => 'to_s'}]
                                                      }
                                                     ]
                                };

                    if (CORE::not defined $expr) {
                        $expr = {
                                 $parser->{class} => [
                                                      {
                                                       self => $string eq ''
                                                       ? $block
                                                       : $self->new($string),
                                                       call => []
                                                      }
                                                     ]
                                };

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

    sub inspect {
        my ($self) = @_;

        require Data::Dump;
        local $Data::Dump::TRY_BASE64 = 0;

        my $copy = $$self;
        $self->new(Data::Dump::pp($copy));
    }

    sub dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $$self =~ s{([\\'])}{\\$1}gr . q{'});
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
        *{__PACKAGE__ . '::' . '...'} = \&range_to;
        *{__PACKAGE__ . '::' . '..^'} = \&range_to;
        *{__PACKAGE__ . '::' . '^..'} = \&range_downto;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '^^'}  = \&begins_with;
        *{__PACKAGE__ . '::' . '$$'}  = \&ends_with;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '%'}   = \&sprintf;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
    }
};

1
