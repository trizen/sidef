package Sidef::Types::String::String {

    use utf8;
    use 5.014;

    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{bool} => \&get_value,
      q{0+}   => sub { 0 + ${$_[0]} },
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

    sub to_s {
        $_[0];
    }

    *to_str = \&to_s;

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
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } split(//, $$self))->reduce_operator($operator);
    }

    sub inc {
        my ($self) = @_;
        my $copy = $$self;
        $self->new(++$copy);
    }

    sub div {
        my ($self, $num) = @_;
        (my $strlen = int(length($$self) / $num->get_value)) < 1 && return;
        Sidef::Types::Array::Array->new(map { $self->new($_) } unpack "(a$strlen)*", $$self);
    }

    *divide = \&div;

    sub lt {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($$self lt $string->get_value);
    }

    sub gt {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($$self gt $string->get_value);
    }

    sub le {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($$self le $string->get_value);
    }

    sub ge {
        my ($self, $string) = @_;
        Sidef::Types::Bool::Bool->new($$self ge $string->get_value);
    }

    sub subtract {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {

            my $str = $$self;
            if (exists $obj->{global}) {
                return $self->new($str =~ s/$obj->{regex}//gr);
            }

            if ($str =~ /$obj->{regex}/) {
                return $self->new(CORE::substr($str, 0, $-[0]) . CORE::substr($str, $+[0]));
            }

            return $self;
        }

        if ((my $ind = CORE::index($$self, $obj->get_value)) != -1) {
            return $self->new(CORE::substr($$self, 0, $ind) . CORE::substr($$self, $ind + CORE::length($obj->get_value)));
        }
        $self;
    }

    sub match {
        my ($self, $regex, @rest) = @_;
        $regex->match($self, @rest);
    }

    sub gmatch {
        my ($self, $regex, @rest) = @_;
        $regex->gmatch($self, @rest);
    }

    sub array_to {
        my ($self, $string) = @_;

        my ($s1, $s2) = ($$self, $string->get_value);

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
        Sidef::Types::Range::RangeString->__new__(
                                                  from => $$self,
                                                  to   => $string->get_value,
                                                  asc  => 1,
                                                 );
    }

    *up_to = \&to;
    *upto  = \&to;

    sub downto {
        my ($self, $string) = @_;
        Sidef::Types::Range::RangeString->__new__(
                                                  from => $$self,
                                                  to   => $string->get_value,
                                                  asc  => 0,
                                                 );
    }

    *down_to = \&downto;

    sub range {
        my ($self, $to, $step) = @_;

        state $from = $self->new('a');

        defined($to)
          ? $self->to($to, $step)
          : $from->to($self);
    }

    sub cmp {
        my ($self, $string) = @_;

        state $mone = Sidef::Types::Number::Number->new(-1);
        state $zero = Sidef::Types::Number::Number->new(0);
        state $one  = Sidef::Types::Number::Number->new(1);

        my $cmp = $$self cmp $string->get_value;
        $cmp == 0 ? $zero : $cmp > 0 ? $one : $mone;
    }

    sub xor {
        my ($self, $str) = @_;
        $self->new($$self ^ $str->get_value);
    }

    sub or {
        my ($self, $str) = @_;
        $self->new($$self | $str->get_value);
    }

    sub and {
        my ($self, $str) = @_;
        $self->new($$self & $str->get_value);
    }

    sub not {
        my ($self) = @_;
        $self->new(~$$self);
    }

    sub times {
        my ($self, $num) = @_;
        $self->new($$self x $num->get_value);
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

    *upcase = \&uc;
    *upper  = \&uc;

    sub equals {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new($$self eq $$arg);
    }

    *eq = \&equals;
    *is = \&equals;

    sub ne {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new($$self ne $$arg);
    }

    sub append {
        my ($self, $string) = @_;
        __PACKAGE__->new($$self . $string->get_value);
    }

    *concat = \&append;

    sub ucfirst {
        my ($self) = @_;
        $self->new(CORE::ucfirst $$self);
    }

    *tc        = \&ucfirst;
    *titlecase = \&ucfirst;

    sub lc {
        my ($self) = @_;
        $self->new(CORE::lc $$self);
    }

    *downcase = \&lc;
    *lower    = \&lc;

    sub fc {
        my ($self) = @_;
        $self->new(CORE::fc $$self);
    }

    *foldcase = \&fc;

    sub lcfirst {
        my ($self) = @_;
        $self->new(CORE::lcfirst $$self);
    }

    sub first {
        my ($self) = @_;
        __PACKAGE__->new(CORE::substr($$self, 0, 1));
    }

    sub last {
        my ($self) = @_;
        __PACKAGE__->new(CORE::substr($$self, -1));
    }

    sub char {
        my ($self, $pos) = @_;
        __PACKAGE__->new(CORE::substr($$self, $pos->get_value, 1));
    }

    *char_at = \&char;

    sub wordcase {
        my ($self) = @_;

        my $str    = $$self;
        my $string = '';

        if ($str =~ /\G(\s+)/gc) {
            $string = $1;
        }

        while ($str =~ /\G(\S++)(\s*+)/gc) {
            $string .= CORE::ucfirst(CORE::lc($1)) . $2;
        }

        $self->new($string);
    }

    *wc = \&wordcase;

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
        $self->new(crypt($$self, $salt->get_value));
    }

    sub hex {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::hex($$self));
    }

    sub oct {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::oct($$self));
    }

    sub bin {
        my ($self) = @_;
        my $value = $$self;
        Sidef::Types::Number::Number->new(CORE::oct(index($value, '0b') == 0 ? $value : ('0b' . $value)));
    }

    sub num {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self);
    }

    *dec = \&num;

    sub substr {
        my ($self, $offs, $len) = @_;
        __PACKAGE__->new(
                         defined($len)
                         ? CORE::substr($$self, $offs->get_value, $len->get_value)
                         : CORE::substr($$self, $offs->get_value)
                        );
    }

    *substring = \&substr;

    sub ft {
        my ($self, $from, $to) = @_;

        my $max = CORE::length($$self);

        $from = defined($from) ? $from->get_value : 0;
        $to   = defined($to)   ? $to->get_value   : $max;

        if (abs($from) > $max) {
            return __PACKAGE__->new('');
        }

        if ($to < 0) {
            $to += $max;
        }

        if ($from < 0) {
            $from += $max;
        }

        __PACKAGE__->new($to < $from ? '' : CORE::substr($$self, $from, $to - $from + 1));
    }

    sub insert {
        my ($self, $string, $pos, $len) = @_;
        CORE::substr(my $copy_str = $$self, $pos->get_value, (defined($len) ? $len->get_value : 0), $string->get_value);
        __PACKAGE__->new($copy_str);
    }

    sub join {
        my ($self, @rest) = @_;
        __PACKAGE__->new(CORE::join($$self, map { $_->get_value } @rest));
    }

    sub clear {
        my ($self) = @_;
        $self->new('');
    }

    sub is_empty {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new($$self eq '');
    }

    sub index {
        my ($self, $substr, $pos) = @_;
        Sidef::Types::Number::Number->new(
                                          defined($pos)
                                          ? CORE::index($$self, $substr->get_value, $pos->get_value)
                                          : CORE::index($$self, $substr->get_value)
                                         );
    }

    sub rindex {
        my ($self, $substr, $pos) = @_;
        Sidef::Types::Number::Number->new(
                                          defined($pos)
                                          ? CORE::rindex($$self, $substr->get_value, $pos->get_value)
                                          : CORE::rindex($$self, $substr->get_value)
                                         );
    }

    sub ord {
        my ($self) = @_;
        Sidef::Types::Number::Number->new(CORE::ord($$self));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(scalar CORE::reverse($$self));
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
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            return $obj->{regex};
        }

        CORE::quotemeta($obj->get_value);
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        ref($str) eq 'Sidef::Types::Block::Code'
          && return $self->esub($regex, $str);

        $str //= __PACKAGE__->new('');

        my $search = $self->_string_or_regex($regex);
        my $value  = $str->get_value;

        $self->new($$self =~ s{$search}{$value}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        ref($str) eq 'Sidef::Types::Block::Code'
          && return $self->gesub($regex, $str);

        $str //= __PACKAGE__->new('');

        my $search = $self->_string_or_regex($regex);
        my $value  = $str->get_value;
        $self->new($$self =~ s{$search}{$value}gr);
    }

    sub _get_captures {
        my ($string) = @_;
        map { __PACKAGE__->new(CORE::substr($string, $-[$_], $+[$_] - $-[$_])) } 1 .. $#{-};
    }

    sub esub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if (ref($code) eq 'Sidef::Types::Block::Code') {
            return __PACKAGE__->new($$self =~ s{$search}{$code->run(_get_captures($$self))}er);
        }

        __PACKAGE__->new($$self =~ s{$search}{$code->get_value}eer);
    }

    sub gesub {
        my ($self, $regex, $code) = @_;

        $code //= __PACKAGE__->new('');
        my $search = $self->_string_or_regex($regex);

        if (ref($code) eq 'Sidef::Types::Block::Code') {
            my $value = $$self;
            return __PACKAGE__->new($value =~ s{$search}{$code->run(_get_captures($value))}ger);
        }

        my $value = $code->get_value;
        __PACKAGE__->new($$self =~ s{$search}{$value}geer);
    }

    sub glob {
        my ($self) = @_;
        state $x = require Encode;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new(Encode::decode_utf8($_)) } CORE::glob($$self));
    }

    sub quotemeta {
        my ($self) = @_;
        __PACKAGE__->new(CORE::quotemeta($$self));
    }

    *escape = \&quotemeta;

    sub scan {
        my ($self, $regex) = @_;
        my $str = $$self;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } $str =~ /$regex->{regex}/g);
    }

    sub split {
        my ($self, $sep, $size) = @_;

        $size = defined($size) ? $size->get_value : 0;

        if (CORE::not defined $sep) {
            return
              Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                                split(' ', $$self, $size));
        }

        if (ref($sep) eq 'Sidef::Types::Number::Number') {
            return Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } unpack '(a' . $sep->get_value . ')*', $$self);
        }

        $sep = $self->_string_or_regex($sep);
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) }
                                          split(/$sep/, $$self, $size));
    }

    sub sort {
        my ($self, $block) = @_;

        if (defined $block) {
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

        __PACKAGE__->new($acc);
    }

    sub each_word {
        my ($self, $obj) = @_;
        my $array = Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(' ', $$self));
        $obj // return $array;
        $array->each($obj);
    }

    *words = \&each_word;

    sub bytes {
        my ($self) = @_;
        Sidef::Types::Byte::Bytes->call($$self);
    }

    *to_bytes = \&bytes;

    sub each_byte {
        my ($self, $code) = @_;

        my $string = $$self;

        state $x = require bytes;
        foreach my $i (0 .. bytes::length($string) - 1) {
            if (defined(my $res = $code->_run_code(Sidef::Types::Byte::Byte->new(CORE::ord bytes::substr($string, $i, 1))))) {
                return $res;
            }
        }

        $self;
    }

    sub chars {
        my ($self) = @_;
        Sidef::Types::Char::Chars->call($$self);
    }

    *to_chars = \&chars;

    sub each_char {
        my ($self, $code) = @_;

        foreach my $char (CORE::split(//, $$self)) {
            if (defined(my $res = $code->_run_code(Sidef::Types::Char::Char->new($char)))) {
                return $res;
            }
        }

        $self;
    }

    *each = \&each_char;

    sub graphemes {
        my ($self) = @_;
        Sidef::Types::Grapheme::Graphemes->call($$self);
    }

    *graphs       = \&graphemes;
    *to_graphemes = \&graphemes;
    *to_graphs    = \&graphemes;

    sub each_grapheme {
        my ($self, $code) = @_;

        my $str = $$self;
        while ($str =~ /(\X)/g) {
            if (defined(my $res = $code->_run_code(Sidef::Types::Grapheme::Grapheme->new($1)))) {
                return $res;
            }
        }

        $self;
    }

    *each_graph = \&each_grapheme;

    sub lines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(map { __PACKAGE__->new($_) } CORE::split(/\R/, $$self));
    }

    sub each_line {
        my ($self, $code) = @_;

        foreach my $line (CORE::split(/\R/, $$self)) {
            if (defined(my $res = $code->_run_code(__PACKAGE__->new($line)))) {
                return $res;
            }
        }

        $self;
    }

    sub open_r {
        my ($self, @rest) = @_;
        state $x = require Encode;
        my $string = Encode::encode_utf8($$self);
        Sidef::Types::Glob::File->new(\$string)->open_r(@rest);
    }

    sub open {
        my ($self, @rest) = @_;
        state $x = require Encode;
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

    sub strip_end {
        my ($self) = @_;
        $self->new(unpack('A*', $$self));
    }

    *trim_end = \&strip_end;

    sub trans {
        my ($self, $orig, $repl) = @_;

        my %map;
        if (CORE::not defined($repl) and defined($orig)) {    # assume an array of pairs
            foreach my $pair (@{$orig}) {
                $map{$pair->first} = $pair->second->get_value;
            }
        }
        else {
            @map{@{$orig}} = @{$repl};
        }

        my $tries = (
                     CORE::join(
                                '|', map { CORE::quotemeta($_) }
                                  sort { length($b) <=> length($a) } CORE::keys(%map)
                               )
                    );

        $self->new($$self =~ s{($tries)}{$map{$1}}gr);
    }

    sub translit {
        my ($self, $orig, $repl, $modes) = @_;

        $orig->isa('ARRAY') && return $self->trans($orig, $repl);
        $self->new(
                       eval qq{"\Q${\$$self}\E"=~tr/}
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
        my ($self, $arg) = @_;
        my @values = map { __PACKAGE__->new($_) } CORE::unpack($$self, $arg->get_value);
        @values > 1 ? @values : $values[0];
    }

    sub pack {
        my ($self, @list) = @_;
        __PACKAGE__->new(CORE::pack($$self, @list));
    }

    sub chars_length {
        Sidef::Types::Number::Number->new(CORE::length(${$_[0]}));
    }

    *len       = \&chars_length;
    *length    = \&chars_length;
    *chars_len = \&chars_length;

    sub graphs_length {
        Sidef::Types::Number::Number->new(scalar(() = ${$_[0]} =~ /\X/g));
    }

    *graphs_len = \&graphs_length;

    sub bytes_length {
        my ($self) = @_;

        state $x = require bytes;
        Sidef::Types::Number::Number->new(bytes::length($$self));
    }

    *bytes_len = \&bytes_length;

    sub levenshtein {
        my ($self, $arg) = @_;

        my @s = split(//, $$self);
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

    sub jaro_distance {
        my ($string1, $string2, $winkle) = @_;

        $string1 = $$string1;
        $string2 = $string2->get_value;

        my $len1 = length($string1);
        my $len2 = length($string2);

        ($string1, $len1, $string2, $len2) = ($string2, $len2, $string1, $len1)
          if $len1 > $len2;

        $len1 || return Sidef::Types::Number::Number->new(0);

        my $match_window = $len2 > 3 ? int($len2 / 2) - 1 : 0;

        my @string1_matches;
        my @string2_matches;

        my @chars1 = split(//, $string1);
        my @chars2 = split(//, $string2);

        state $x = require List::Util;

        foreach my $i (0 .. $#chars1) {

            my $window_start = List::Util::max(0, $i - $match_window);
            my $window_end = List::Util::min($i + $match_window + 1, $len2);

            foreach my $j ($window_start .. $window_end - 1) {
                if (CORE::not exists($string2_matches[$j]) and $chars1[$i] eq $chars2[$j]) {
                    $string1_matches[$i] = $chars1[$i];
                    $string2_matches[$j] = $chars2[$j];
                    last;
                }
            }
        }

        (@string1_matches = grep { defined } @string1_matches) || return Sidef::Types::Number::Number->new(0);
        @string2_matches = grep { defined } @string2_matches;

        my $transpositions = 0;
        foreach my $i (0 .. $#string1_matches) {
            $string1_matches[$i] eq $string2_matches[$i] or ++$transpositions;
        }

        my $num_matches = @string1_matches;
        my $jaro =
          (($num_matches / $len1) + ($num_matches / $len2) + ($num_matches - int($transpositions / 2)) / $num_matches) / 3;

        $winkle || return Sidef::Types::Number::Number->new($jaro);    # return the Jaro distance instead of Jaro-Winkle

        my $prefix = 0;
        foreach my $i (0 .. $#chars1) {
            $chars1[$i] eq $chars2[$i] ? ++$prefix : last;
        }

        Sidef::Types::Number::Number->new($jaro + List::Util::min($prefix, 4) * 0.1 * (1 - $jaro));
    }

    sub contains {
        my ($self, $arg, $start_pos) = @_;

        $start_pos =
          defined($start_pos)
          ? $start_pos->get_value
          : 0;

        if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
            my $regex = $arg->{regex};
            my $s     = $$self;

            if ($start_pos != 0) {
                pos($s) = $start_pos;
            }

            return Sidef::Types::Bool::Bool->new(scalar $s =~ /$regex/g);
        }

        if ($start_pos < 0) {
            $start_pos = CORE::length($$self) + $start_pos;
        }

        Sidef::Types::Bool::Bool->new(CORE::index($$self, $arg->get_value, $start_pos) != -1);
    }

    *include = \&contains;

    sub count {
        my ($self, $arg) = @_;

        my $s       = $$self;
        my $counter = 0;

        if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
            my $regex = $arg->{regex};
            $counter += CORE::length($1) while $s =~ /($regex)/g;
            return Sidef::Types::Number::Number->new($counter);
        }
        elsif (ref($arg) eq 'Sidef::Types::Block::Code') {
            foreach my $char (split //, $s) {
                ++$counter if $arg->run(__PACKAGE__->new($char));
            }
            return $counter;
        }

        my $ss = $arg->get_value;
        ++$counter while $s =~ /\Q$ss\E/g;
        Sidef::Types::Number::Number->new($counter);
    }

    sub overlaps {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new(CORE::index($$self ^ $arg->get_value, "\0") != -1);
    }

    sub begins_with {
        my ($self, $string) = @_;

        CORE::length($$self) < (my $len = CORE::length($string->get_value))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($$self, 0, $len) eq $string->get_value
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    *starts_with = \&begins_with;

    sub ends_with {
        my ($self, $string) = @_;

        CORE::length($$self) < (my $len = CORE::length($string->get_value))
          && return Sidef::Types::Bool::Bool->false;

        CORE::substr($$self, -$len) eq $string->get_value
          && return Sidef::Types::Bool::Bool->true;

        Sidef::Types::Bool::Bool->false;
    }

    sub looks_like_number {
        my ($self) = @_;
        state $x = require Scalar::Util;
        Sidef::Types::Bool::Bool->new(Scalar::Util::looks_like_number($$self));
    }

    sub is_palindrome {
        my ($self) = @_;
        Sidef::Types::Bool::Bool->new(${$self} eq CORE::reverse(${$self}));
    }

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

        state $x = require Encode;
        $self->new(Encode::encode($enc->get_value, $$self));
    }

    sub decode {
        my ($self, $enc) = @_;

        state $x = require Encode;
        $self->new(Encode::decode($enc->get_value, $$self));
    }

    sub encode_utf8 {
        my ($self) = @_;
        state $x = require Encode;
        $self->new(Encode::encode_utf8($$self));
    }

    sub decode_utf8 {
        my ($self) = @_;
        state $x = require Encode;
        $self->new(Encode::decode_utf8($$self));
    }

    sub _require {
        my ($self) = @_;

        my $name = $$self;
        eval { require(($name . '.pm') =~ s{::}{/}gr) };

        if ($@) {
            CORE::die CORE::substr($@, 0, CORE::rindex($@, ' at ')), "\n";
        }

        $name;
    }

    sub require {
        my ($self) = @_;
        Sidef::Module::OO->__NEW__($self->_require);
    }

    sub frequire {
        my ($self) = @_;
        Sidef::Module::Func->__NEW__($self->_require);
    }

    sub unescape {
        my ($self) = @_;
        $self->new($$self =~ s{\\(.)}{$1}grs);
    }

    sub apply_escapes {
        my ($self, $parser) = @_;

        $$self =~ /\\|#\{/ || return $self;    # fast exit

        state $x = require Encode;
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
                            splice(@chars, $i--, 2 + $+[0], CORE::chr(CORE::oct($1)));
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
                        splice @chars, $i, 1 + $+[0], CORE::chr(CORE::oct($1));
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

    sub shift_left {
        my ($self, $i) = @_;
        my $len = CORE::length($$self);
        $i = $i->get_value > $len ? $len : $i->get_value;
        $self->new(CORE::substr($$self, $i));
    }

    *drop_left = \&shift_left;

    sub shift_right {
        my ($self, $i) = @_;
        $self->new(CORE::substr($$self, 0, -$i->get_value));
    }

    *drop_right = \&shift_right;

    sub pair_with {
        Sidef::Types::Array::Pair->new($_[0], $_[1]);
    }

    sub basic_dump {
        my ($self) = @_;
        __PACKAGE__->new(q{'} . $$self =~ s{([\\'])}{\\$1}gr . q{'});
    }

    sub dump {
        my ($self) = @_;

        state $x = eval { require Data::Dump };
        $x || return $self->basic_dump;

        local $Data::Dump::TRY_BASE64 = 0;
        $self->new(Data::Dump::quote($$self) =~ s<(#\{)>{\\$1}gr);
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
