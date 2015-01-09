package Sidef::Types::String::String {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, $str) = @_;
        $str //= '';
        bless \$str, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub unroll_operator {
        my ($self, $operator, $arg) = @_;
        $self->to_chars->unroll_operator(

            # The operator, followed by...
            $operator,

            # ...an optional argument
            defined($arg)
            ? $arg->to_chars
            : ()

        )->join;
    }

    sub reduce_operator {
        my ($self, $operator) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(//, $self->get_value))->reduce_operator($operator);
    }

    sub inc {
        my ($self) = @_;
        my $copy = $self->get_value;
        $self->new(++$copy);
    }

    sub div {
        my ($self, $num) = @_;
        (my $strlen = int(length($self->get_value) / $num->get_value)) < 1 && return;
        Sidef::Types::Array::Array->new(map { $self->new($_) } unpack "(a$strlen)*", $self->get_value);
    }

    *divide = \&div;

    sub lt {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value lt $string->get_value);
    }

    sub gt {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value gt $string->get_value);
    }

    sub le {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value le $string->get_value);
    }

    sub ge {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value ge $string->get_value);
    }

    sub subtract {
        my ($self, $obj) = @_;

        if ($self->_is_regex($obj)) {
            if (exists $obj->{global}) {
                return $self->new($self->get_value =~ s/$obj->{regex}//gr);
            }
            if ($self->get_value =~ /$obj->{regex}/) {
                return $self->new(CORE::substr($self->get_value, 0, $-[0]) . CORE::substr($self->get_value, $+[0]));
            }
            return $self;
        }

        if ((my $ind = CORE::index($self->get_value, $obj->get_value)) != -1) {
            return $self->new(  CORE::substr($self->get_value, 0, $ind)
                              . CORE::substr($self->get_value, $ind + CORE::length($obj->get_value)));
        }
        $self;
    }

    sub ne {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value ne $string->get_value);
    }

    sub match {
        my ($self, $regex, @rest) = @_;
        $regex->match($self, @rest);
    }

    *matches = \&match;

    sub gmatch {
        my ($self, $regex, @rest) = @_;
        $regex->gmatch($self, @rest);
    }

    *gmatches = \&gmatch;

    sub to {
        my ($self, $string) = @_;

        if (length($self->get_value) == 1 and length($string->get_value) == 1) {
            return Sidef::Types::Array::Array->new(map { $self->new(chr($_)) }
                                                   ord($self->get_value) .. ord($string->get_value));
        }
        Sidef::Types::Array::Array->new(map { $self->new($_) } $self->get_value .. $string->get_value);
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
        Sidef::Types::Array::Range->new(
                                        from      => $self->get_value,
                                        to        => $string->get_value,
                                        type      => 'string',
                                        direction => 'up'
                                       );
    }

    sub range_downto {
        my ($self, $string) = @_;
        Sidef::Types::Array::Range->new(
                                        from      => $self->get_value,
                                        to        => $string->get_value,
                                        type      => 'string',
                                        direction => 'down'
                                       );
    }

    sub cmp {
        my ($self, $string) = @_;

        Sidef::Types::Number::Number->new($self->get_value cmp $string->get_value);
    }

    sub xor {
        my ($self, $str) = @_;
        $self->new($self->get_value ^ $str->get_value);
    }

    sub or {
        my ($self, $str) = @_;
        $self->new($self->get_value | $str->get_value);
    }

    sub and {
        my ($self, $str) = @_;
        $self->new($self->get_value & $str->get_value);
    }

    sub not {
        my ($self) = @_;
        $self->new(~$self->get_value);
    }

    sub times {
        my ($self, $num) = @_;
        $self->new($self->get_value x $num->get_value);
    }

    *multiply = \&times;

    sub repeat {
        my ($self, $num) = @_;
        $num //= Sidef::Types::Number::Number->new(1);
        $self->times($num);
    }

    sub uc {
        my ($self) = @_;
        $self->new(CORE::uc $self->get_value);
    }

    *toUpperCase = \&uc;
    *upcase      = \&uc;
    *upCase      = \&uc;
    *upper       = \&uc;

    sub equals {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value eq $string->get_value);
    }

    *eq = \&equals;
    *is = \&equals;

    sub append {
        my ($self, $string) = @_;
        __PACKAGE__->new($self->get_value . $string->get_value);
    }

    *concat = \&append;

    sub ucfirst {
        my ($self) = @_;
        $self->new(CORE::ucfirst $self->get_value);
    }

    *tc         = \&ucfirst;
    *titleCase  = \&ucfirst;
    *title_case = \&ucfirst;

    sub lc {
        my ($self) = @_;
        $self->new(CORE::lc $self->get_value);
    }

    *toLowerCase = \&lc;
    *downcase    = \&lc;
    *downCase    = \&lc;
    *lower       = \&lc;

    sub lcfirst {
        my ($self) = @_;
        $self->new(CORE::lcfirst $self->get_value);
    }

    sub charAt {
        my ($self, $pos) = @_;
        Sidef::Types::Char::Char->new(CORE::substr($self->get_value, $pos->get_value, 1));
    }

    *char_at = \&charAt;

    sub wordcase {
        my ($self) = @_;

        my $string = $1
          if ($self->get_value =~ /\G(\s+)/gc);

        while ($self->get_value =~ /\G(\S++)(\s*+)/gc) {
            $string .= CORE::ucfirst(CORE::lc($1)) . $2;
        }

        $self->new($string);
    }

    *wc       = \&wordcase;
    *wordCase = \&wordcase;

    sub capitalize {
        my ($self) = @_;
        $self->new(CORE::ucfirst(CORE::lc($self->get_value)));
    }

    *tclc = \&capitalize;

    sub chop {
        my ($self) = @_;
        $self->new(CORE::substr($self->get_value, 0, -1));
    }

    sub pop {
        my ($self) = @_;
        $self->new(CORE::substr($self->get_value, -1));
    }

    sub chomp {
        my ($self) = @_;

        if (substr($self->get_value, -1) eq "\n") {
            return $self->chop;
        }

        $self;
    }

    sub crypt {
        my ($self, $salt) = @_;
        $self->new(crypt($self->get_value, $salt->get_value));
    }

    sub substr {
        my ($self, $offs, $len) = @_;
        __PACKAGE__->new(
                         defined($len)
                         ? CORE::substr($self->get_value, $offs->get_value, $len->get_value)
                         : CORE::substr($self->get_value, $offs->get_value)
                        );
    }

    *ft        = \&substr;
    *substring = \&substr;

    sub insert {
        my ($self, $string, $pos, $len) = @_;
        CORE::substr(my $copy_str = $self->get_value, $pos->get_value,
                     (defined($len) ? $len->get_value : 0), $string->get_value);
        __PACKAGE__->new($copy_str);
    }

    sub join {
        my ($self, $delim, @rest) = @_;
        __PACKAGE__->new(CORE::join($delim->get_value, $self->get_value, @rest));
    }

    sub clear {
        my ($self) = @_;
        $self->new('');
    }

    sub is_empty {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($self->get_value eq '');
    }

    *isEmpty = \&is_empty;

    sub index {
        my ($self, $substr, $pos) = @_;
        Sidef::Types::Number::Number->new(
                                          defined($pos)
                                          ? CORE::index($self->get_value, $substr->get_value, $pos->get_value)
                                          : CORE::index($self->get_value, $substr->get_value)
                                         );
    }

    *indexOf = \&index;

    sub ord {
        my ($self) = @_;
        Sidef::Types::Byte::Byte->new(CORE::ord($self->get_value));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(scalar CORE::reverse($self->get_value));
    }

    sub say {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(CORE::say($self->get_value));
    }

    *println = \&say;

    sub print {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(print $self->get_value);
    }

    sub printf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf $self->get_value, @arguments);
    }

    sub printlnf {
        my ($self, @arguments) = @_;
        Sidef::Types::Bool::Bool->new(printf($self->get_value . "\n", @arguments));
    }

    sub sprintf {
        my ($self, @arguments) = @_;

        if (@arguments == 1 and $self->_is_array($arguments[0])) {
            @arguments = map { $_->get_value } @{$arguments[0]};
        }

        __PACKAGE__->new(CORE::sprintf $self->get_value, @arguments);
    }

    sub sprintlnf {
        my ($self, @arguments) = @_;
        __PACKAGE__->new(CORE::sprintf($self->get_value . "\n", @arguments));
    }

    sub _string_or_regex {
        my ($self, $obj) = @_;

        if ($self->_is_regex($obj)) {
            return $obj->{regex};
        }

        CORE::quotemeta($obj->get_value);
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        $self->_is_code($str)
          && return $self->esub($regex, $str);

        $str //= __PACKAGE__->new('');

        if ($self->_is_regex($regex)) {
            $regex->match($self)->to_bool or return $self;
        }

        my $search = $self->_string_or_regex($regex);
        $self->new($self->get_value =~ s{$search}{${\$str->get_value}}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        $self->_is_code($str, 1, 1)
          && return $self->gesub($regex, $str);

        $str //= __PACKAGE__->new('');

        if ($self->_is_regex($regex)) {
            $regex->match($self)->to_bool or return $self;
        }

        my $search = $self->_string_or_regex($regex);
        $self->new($self->get_value =~ s{$search}{${\$str->get_value}}gr);
    }

    *gReplace = \&gsub;

    sub _get_captures {
        my ($string) = @_;
        map { __PACKAGE__->new(CORE::substr($string, $-[$_], $+[$_] - $-[$_])) } 1 .. $#{-};
    }

    sub esub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if ($self->_is_regex($regex)) {
            $regex->match($self)->to_bool or return $self;
        }

        if ($self->_is_string($code)) {
            return __PACKAGE__->new($self->get_value =~ s{$search}{$code->get_value}eer);
        }

        __PACKAGE__->new($self->get_value =~ s{$search}{$code->call(_get_captures($self->get_value))}er);
    }

    sub gesub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if ($self->_is_regex($regex)) {
            $regex->match($self)->to_bool or return $self;
        }

        if ($self->_is_string($code)) {
            return __PACKAGE__->new($self->get_value =~ s{$search}{$code->get_value}geer);
        }

        __PACKAGE__->new($self->get_value =~ s{$search}{$code->call(_get_captures($self->get_value))}ger);
    }

    sub glob {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::glob($self->get_value));
    }

    sub quotemeta {
        my ($self) = @_;
        __PACKAGE__->new(CORE::quotemeta($self->get_value));
    }

    *escape = \&quotemeta;

    sub scan {
        my ($self, $regex) = @_;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } $self->get_value =~ /$regex->{regex}/g);
    }

    sub split {
        my ($self, $sep, $size) = @_;

        $size = defined($size) ? $size->get_value : 0;

        if (CORE::not defined $sep) {
            return
              Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                                split(' ', $self->get_value, $size));
        }

        if ($self->_is_number($sep)) {
            return
              Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } unpack '(a' . $sep->get_value . ')*',
                                              $self->get_value);
        }

        $sep = $self->_string_or_regex($sep);
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                          split(/$sep/, $self->get_value, $size));
    }

    sub sort {
        my ($self, $block) = @_;

        if (defined $block) {
            return $self->to_chars->sort($block)->join;
        }

        $self->new(CORE::join('', sort(CORE::split(//, $self->get_value))));
    }

    sub format {
        my ($self) = @_;
        CORE::chomp(my $text = 'format __MY_FORMAT__ = ' . "\n" . $self->get_value);
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
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(' ', $self->get_value));
        $obj // return $array;
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
        Sidef::Types::Char::Chars->new(map { Sidef::Types::Char::Char->new($_) } CORE::split(//, $self->get_value));
    }

    sub each {
        my ($self, $code) = @_;

        my ($var_ref) = $code->init_block_vars();

        foreach my $char (CORE::split(//, $self->get_value)) {
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
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(/\R/, $self->get_value));
        $obj // return $array;
        $array->each($obj);
    }

    *lines    = \&each_line;
    *eachLine = \&each_line;

    sub open_r {
        my ($self, @rest) = @_;
        require Encode;
        my $string = Encode::encode_utf8($self->get_value);
        Sidef::Types::Glob::File->new(\$string)->open_r(@rest);
    }

    sub open {
        my ($self, @rest) = @_;
        require Encode;
        my $string = Encode::encode_utf8($self->get_value);
        Sidef::Types::Glob::File->new(\$string)->open(@rest);
    }

    sub trim {
        my ($self) = @_;
        $self->new(unpack('A*', $self->get_value) =~ s/^\s+//r);
    }

    *strip = \&trim;

    sub strip_beg {
        my ($self) = @_;
        $self->new($self->get_value =~ s/^\s+//r);
    }

    *trim_beg = \&strip_beg;
    *trimBeg  = \&strip_beg;
    *stripBeg = \&strip_beg;

    sub strip_end {
        my ($self) = @_;
        $self->new(unpack('A*', $self->get_value));
    }

    *trim_end = \&strip_end;
    *trimEnd  = \&strip_end;
    *stripEnd = \&strip_end;

    sub trans {
        my ($self, $orig, $repl) = @_;

        my %map;
        if (CORE::not defined($repl) and defined($orig)) {    # assume an array of pairs
            foreach my $pair (map { $_->get_value } @{$orig}) {
                $map{$pair->first} = $pair->second->get_value;
            }
        }
        else {
            @map{@{$orig}} = map { $_->get_value } @{$repl};
        }

        my $tries = CORE::join('|', map { CORE::quotemeta($_) }
                                 sort { length($b) <=> length($a) } CORE::keys(%map));
        $self->new($self->get_value =~ s{($tries)}{$map{$1}}gr);
    }

    sub translit {
        my ($self, $orig, $repl, $modes) = @_;

        $self->_is_array($orig) && return $self->trans($orig, $repl);
        $self->new(
                       eval qq{"\Q${\$self->get_value}\E"=~tr/}
                     . $orig->get_value =~ s{([/\\])}{\\$1}gr . "/"
                     . $repl->get_value =~ s{([/\\])}{\\$1}gr . "/r"
                     . (
                        defined($modes)
                        ? $modes->get_value
                        : ''
                       )
                  );
    }

    *tr = \&translit;

    sub unpack {
        my ($self, $argv) = @_;
        my @parts = CORE::unpack($self->get_value, $argv->get_value);
        $#parts == 0
          ? __PACKAGE__->new($parts[0])
          : Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } @parts);
    }

    sub pack {
        my ($self, @list) = @_;
        __PACKAGE__->new(CORE::pack($self->get_value, @list));
    }

    sub length {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::length($self->get_value));
    }

    *len = \&length;

    sub contains {
        my ($self, $string, $start_pos) = @_;

        $start_pos =
          defined($start_pos)
          ? $start_pos->get_value
          : 0;

        if ($start_pos < 0) {
            $start_pos = CORE::length($self->get_value) + $start_pos;
        }

        Sidef::Types::Bool::Bool->new(CORE::index($self->get_value, $string->get_value, $start_pos) != -1);
    }

    *include = \&contains;

    sub count {
        my ($self, $substr) = @_;

        my $pos     = -1;
        my $counter = 0;
        while (($pos = CORE::index($self->get_value, $substr->get_value, $pos + 1)) != -1) {
            ++$counter;
        }

        Sidef::Types::Number::Number->new($counter);
    }

    sub overlaps {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new(CORE::index($self->get_value ^ $arg->get_value, "\0") != -1);
    }

    sub begins_with {
        my ($self, $string) = @_;

        CORE::length($self->get_value) < (my $len = CORE::length($string->get_value))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($self->get_value, 0, $len) eq $string->get_value
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *starts_with = \&begins_with;
    *startsWith  = \&begins_with;
    *beginsWith  = \&begins_with;

    sub ends_with {
        my ($self, $string) = @_;

        CORE::length($self->get_value) < (my $len = CORE::length($string->get_value))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($self->get_value, -$len) eq $string->get_value
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *endsWith = \&ends_with;

    sub warn {
        my ($self) = @_;
        warn $self->get_value;
    }

    sub die {
        my ($self) = @_;
        die $self->get_value;
    }

    sub encode {
        my ($self, $enc) = @_;

        require Encode;
        $self->new(Encode::encode($enc->get_value, $self->get_value));
    }

    sub decode {
        my ($self, $enc) = @_;

        require Encode;
        $self->new(Encode::decode($enc->get_value, $self->get_value));
    }

    sub encode_utf8 {
        my ($self) = @_;
        require Encode;
        $self->new(Encode::encode_utf8($self->get_value));
    }

    sub decode_utf8 {
        my ($self) = @_;
        require Encode;
        $self->new(Encode::decode_utf8($self->get_value));
    }

    sub unescape {
        my ($self) = @_;
        $self->new($self->get_value =~ s{\\(.)}{$1}grs);
    }

    sub apply_escapes {
        my ($self, $parser) = @_;
        my $str = $self->get_value;

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

            my $expr = {
                        $parser->{class} => [
                                             {
                                              self => $self->new,
                                              call => [{method => 'super_join'}]
                                             }
                                            ]
                       };

            my $append_arg = sub {
                push @{$expr->{$parser->{class}}[0]{call}[-1]{arg}}, $_[0];
            };

            my $string = '';
            foreach my $char (@chars) {
                if (ref($char) eq 'Sidef::Types::Block::Code') {
                    my $block = {
                                 $parser->{class} => [
                                                      {
                                                       self => $char,
                                                       call => [{method => 'run'}]
                                                      }
                                                     ]
                                };

                    if ($string ne '') {
                        $append_arg->($string);
                        $string = '';
                    }
                    $append_arg->($block);
                }
                else {
                    $string .= $char;
                }
            }

            if ($string ne '') {
                $append_arg->($string);
            }

            return $expr;
        }

        $self->new(CORE::join('', @chars));
    }

    *applyEscapes = \&apply_escapes;

    sub shift_left {
        my ($self, $i) = @_;
        my $len = CORE::length($self->get_value);
        $i = $i->get_value > $len ? $len : $i->get_value;
        $self->new(CORE::substr($self->get_value, $i));
    }

    *dropLeft  = \&shift_left;
    *drop_left = \&shift_left;
    *shiftLeft = \&shift_left;

    sub shift_right {
        my ($self, $i) = @_;
        $self->new(CORE::substr($self->get_value, 0, -$i->get_value));
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

        my $copy = $self->get_value;
        $self->new(Data::Dump::pp($copy));
    }

    sub dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $self->get_value =~ s{([\\'])}{\\$1}gr . q{'});
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
