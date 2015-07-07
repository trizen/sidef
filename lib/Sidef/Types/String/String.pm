package Sidef::Types::String::String {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{bool} => \&get_value,
      q{""}   => \&get_value;

    sub new {
        my (undef, $str) = @_;
        if (@_ > 2) {
            $str = CORE::join('', map { ref($_) ? $_->to_s->get_value : $_ } @_[1 .. $#_]);
        }
        elsif (ref $str) {
            return $str->to_s;
        }
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

            $obj->match($self)->to_bool or return $self;

            my $str = $self->get_value;
            if (exists $obj->{global}) {
                return $self->new($str =~ s/$obj->{regex}//gr);
            }

            if ($str =~ /$obj->{regex}/) {
                return $self->new(CORE::substr($str, 0, $-[0]) . CORE::substr($str, $+[0]));
            }

            return $self;
        }

        if ((my $ind = CORE::index($self->get_value, $obj->get_value)) != -1) {
            return $self->new(  CORE::substr($self->get_value, 0, $ind)
                              . CORE::substr($self->get_value, $ind + CORE::length($obj->get_value)));
        }
        $self;
    }

    {
        my %cache;

        sub match {
            my ($self, $regex, @rest) = @_;
            (
             $self->_is_regex($regex) ? $regex : do {
                 state $x = require Scalar::Util;
                 $cache{Scalar::Util::refaddr($regex)} //= Sidef::Types::Regex::Regex->new($regex);
               }
            )->match($self, @rest);
        }
    }

    *matches = \&match;

    {
        my %cache;

        sub gmatch {
            my ($self, $regex, @rest) = @_;
            (
             $self->_is_regex($regex) ? $regex : do {
                 state $x = require Scalar::Util;
                 $cache{Scalar::Util::refaddr($regex)} //=
                   Sidef::Types::Regex::Regex->new($regex);
               }
            )->gmatch($self, @rest);
        }
    }

    *gmatches = \&gmatch;

    sub array_to {
        my ($self, $string) = @_;

        my ($s1, $s2) = ($self->get_value, $string->get_value);

        if (length($s1) == 1 and length($s2) == 1) {
            return Sidef::Types::Array::Array->new(map { $self->new(chr($_)) } ord($s1) .. ord($s2));
        }
        Sidef::Types::Array::Array->new(map { $self->new($_) } $s1 .. $s2);
    }

    *arr_to = \&array_to;

    sub array_downto {
        my ($self, $string) = @_;
        $string->array_to($self)->reverse;
    }

    *arr_downto = \&array_downto;

    sub to {
        my ($self, $string) = @_;
        Sidef::Types::Array::Range->new(
                                        from      => $self->get_value,
                                        to        => $string->get_value,
                                        type      => 'string',
                                        direction => 'up'
                                       );
    }

    *upto = \&to;
    *upTo = \&to;

    sub downto {
        my ($self, $string) = @_;
        Sidef::Types::Array::Range->new(
                                        from      => $self->get_value,
                                        to        => $string->get_value,
                                        type      => 'string',
                                        direction => 'down'
                                       );
    }

    *downTo = \&downto;

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
        my ($self, $arg) = @_;
        my $value = $arg->get_value;
        Sidef::Types::Bool::Bool->new(defined($value) ? $self->get_value eq $value : 0);
    }

    *eq = \&equals;
    *is = \&equals;

    sub ne {
        my ($self, $arg) = @_;
        my $value = $arg->get_value;
        Sidef::Types::Bool::Bool->new(defined($value) ? $self->get_value ne $value : 1);
    }

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

        my $str    = $self->get_value;
        my $string = '';

        if ($str =~ /\G(\s+)/gc) {
            $string = $1;
        }

        while ($str =~ /\G(\S++)(\s*+)/gc) {
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

    sub hex {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::hex($self->get_value));
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
        my ($self, @rest) = @_;
        __PACKAGE__->new(CORE::join($self->get_value, map { $_->get_value } @rest));
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
        Sidef::Types::Number::Number->new(CORE::ord($self->get_value));
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
            $regex->match($self)->{matched} or return $self;
        }

        my $search = $self->_string_or_regex($regex);
        my $value  = $str->get_value;

        $self->new($self->get_value =~ s{$search}{$value}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        $self->_is_code($str)
          && return $self->gesub($regex, $str);

        $str //= __PACKAGE__->new('');

        if ($self->_is_regex($regex)) {
            $regex->match($self)->{matched} or return $self;
        }

        my $search = $self->_string_or_regex($regex);
        my $value  = $str->get_value;
        $self->new($self->get_value =~ s{$search}{$value}gr);
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
            $regex->match($self)->{matched} or return $self;
        }

        if ($self->_is_string($code)) {
            return __PACKAGE__->new($self->get_value =~ s{$search}{$code->get_value}eer);
        }

        __PACKAGE__->new($self->get_value =~ s{$search}{$code->run(_get_captures($self->get_value))}er);
    }

    sub gesub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if ($self->_is_regex($regex)) {
            $regex->match($self)->{matched} or return $self;
        }

        if ($self->_is_string($code)) {
            return __PACKAGE__->new($self->get_value =~ s{$search}{$code->get_value}geer);
        }

        my $value = $self->get_value;
        __PACKAGE__->new($value =~ s{$search}{$code->run(_get_captures($value))}ger);
    }

    sub glob {
        my ($self) = @_;
        state $x = require Encode;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new(Encode::decode_utf8($_)) } CORE::glob($self->get_value));
    }

    sub quotemeta {
        my ($self) = @_;
        __PACKAGE__->new(CORE::quotemeta($self->get_value));
    }

    *escape = \&quotemeta;

    sub scan {
        my ($self, $regex) = @_;
        my $str = $self->get_value;
        Sidef::Types::Array::Array->new(map { Sidef::Types::String::String->new($_) } $str =~ /$regex->{regex}/g);
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

        foreach my $char (CORE::split(//, $self->get_value)) {
            if (defined(my $res = $code->_run_code(__PACKAGE__->new($char)))) {
                return $res;
            }
        }

        $self;
    }

    *each_char = \&each;
    *eachChar  = \&each;

    sub lines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(/\R/, $self->get_value));
    }

    sub each_line {
        my ($self, $obj) = @_;
        $self->lines->each($obj);
    }

    *eachLine = \&each_line;

    sub open_r {
        my ($self, @rest) = @_;
        state $x = require Encode;
        my $string = Encode::encode_utf8($self->get_value);
        Sidef::Types::Glob::File->new(\$string)->open_r(@rest);
    }

    sub open {
        my ($self, @rest) = @_;
        state $x = require Encode;
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

    sub graphs {
        my ($self) = @_;
        my $str = $self->get_value;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } $str =~ /\X/g);
    }

    *graphemes    = \&graphs;
    *to_graphemes = \&graphs;

    sub levenshtein {
        my ($self, $arg) = @_;

        my @s = split(//, $self->get_value);
        my @t = split(//, $arg->get_value);

        my $len1 = scalar(@s);
        my $len2 = scalar(@t);

        state $x = require List::Util;

        my @d = ([0 .. $len2], map { [$_] } 1 .. $len1);
        foreach my $i (1 .. $len1) {
            foreach my $j (1 .. $len2) {
                $d[$i][$j] =
                    $s[$i - 1] eq $t[$j - 1]
                  ? $d[$i - 1][$j - 1]
                  : List::Util::min($d[$i - 1][$j], $d[$i][$j - 1], $d[$i - 1][$j - 1]) + 1;
            }
        }

        Sidef::Types::Number::Number->new($d[-1][-1]);
    }

    *lev   = \&levenshtein;
    *leven = \&levenshtein;

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

        my $s  = $self->get_value;
        my $ss = $substr->get_value;

        my $counter = 0;
        ++$counter while $s =~ /\Q$ss\E/g;
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

        state $x = require Encode;
        $self->new(Encode::encode($enc->get_value, $self->get_value));
    }

    sub decode {
        my ($self, $enc) = @_;

        state $x = require Encode;
        $self->new(Encode::decode($enc->get_value, $self->get_value));
    }

    sub encode_utf8 {
        my ($self) = @_;
        state $x = require Encode;
        $self->new(Encode::encode_utf8($self->get_value));
    }

    sub decode_utf8 {
        my ($self) = @_;
        state $x = require Encode;
        $self->new(Encode::decode_utf8($self->get_value));
    }

    sub unescape {
        my ($self) = @_;
        $self->new($self->get_value =~ s{\\(.)}{$1}grs);
    }

    sub apply_escapes {
        my ($self, $parser) = @_;

        state $x = require Encode;
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
                            state $x = require charnames;
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
                            splice(@chars, $i, 2 + $+[0], chr(CORE::hex($1)));
                            next;
                        }
                        elsif ($str =~ /^([[:xdigit:]]{1,2})/) {
                            splice(@chars, $i, 2 + $+[0], chr(CORE::hex($1)));
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
                    my $block = $parser->parse_block(code => \$code);
                    if (@{$block->{vars}} == 1) {
                        $block = $block->{code};
                    }
                    push @inline_expressions, [$i, $block];
                    splice(@chars, $i--, 1 + pos($code));
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
                if (ref($char)) {
                    my $block =
                      ref($char) eq 'HASH'
                      ? $char
                      : {
                         $parser->{class} => [
                                              {
                                               self => $char,
                                               call => [{method => 'run'}]
                                              }
                                             ]
                        };

                    if ($string ne '') {
                        $append_arg->(Encode::decode_utf8(Encode::encode_utf8($string)));
                        $string = '';
                    }
                    $append_arg->($block);
                }
                else {
                    $string .= $char;
                }
            }

            if ($string ne '') {
                $append_arg->(Encode::decode_utf8(Encode::encode_utf8($string)));
            }

            return $expr;
        }

        $self->new(Encode::decode_utf8(Encode::encode_utf8(CORE::join('', @chars))));
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

    sub basic_dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $self->get_value =~ s{([\\'])}{\\$1}gr . q{'});
    }

    sub dump {
        my ($self) = @_;

        state $x = eval { require Data::Dump };
        $x || return $self->basic_dump;

        local $Data::Dump::TRY_BASE64 = 0;
        $self->new(Data::Dump::quote($self->get_value) =~ s<(#\{)>{\\$1}gr);
    }

    *inspect = \&dump;

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
        *{__PACKAGE__ . '::' . '..'}  = \&array_to;
        *{__PACKAGE__ . '::' . '...'} = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&to;
        *{__PACKAGE__ . '::' . '^..'} = \&downto;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '%'}   = \&sprintf;
        *{__PACKAGE__ . '::' . ':'}   = \&pair_with;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
    }
};

1
