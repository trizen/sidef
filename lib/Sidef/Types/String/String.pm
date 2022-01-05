package Sidef::Types::String::String {

    use utf8;
    use 5.016;

    use parent qw(Sidef::Object::Object);

    use overload
      q{bool} => \&get_value,
      q{0+}   => \&get_value,
      q{""}   => \&get_value,
      q{@{}}  => \&chars;

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    sub new {
        my (undef, $str) = @_;
        if (@_ > 2) {
            shift(@_);
            $str = CORE::join('', @_);
        }
        bless \"$str";
    }

    *call = \&new;

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
        (my $strlen = CORE::int(length($$self) / CORE::int($num))) < 1 and return $self->chars;
        Sidef::Types::Array::Array->new([map { bless \$_ } unpack "(a$strlen)*", $$self]);
    }

    sub lt {
        my ($self, $string) = @_;
        $$self lt "$string"
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub gt {
        my ($self, $string) = @_;
        $$self gt "$string"
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub le {
        my ($self, $string) = @_;
        $$self le "$string"
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ge {
        my ($self, $string) = @_;
        $$self ge "$string"
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub diff {
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

        if ((my $ind = CORE::index($$self, "$obj")) != -1) {
            return $self->new(CORE::substr($$self, 0, $ind) . CORE::substr($$self, $ind + CORE::length("$obj")));
        }
        $self;
    }

    sub match {
        my ($self, $regex, $pos) = @_;
        $regex->run($self, (defined($pos) ? $pos : ()));
    }

    sub gmatch {
        my ($self, $regex, $pos) = @_;
        local $regex->{global} = 1;
        $regex->run($self, (defined($pos) ? $pos : ()));
    }

    sub to {
        my ($from, $to, $step) = @_;
        Sidef::Types::Range::RangeString->call($from, $to, $step // Sidef::Types::Number::Number::ONE);
    }

    *upto = \&to;

    sub downto {
        my ($from, $to, $step) = @_;
        Sidef::Types::Range::RangeString->call($from, $to, defined($step) ? $step->neg : Sidef::Types::Number::Number::MONE);
    }

    sub range {
        my ($from, $to, $step) = @_;
        Sidef::Types::Range::RangeString->call($from, $to, $step);
    }

    sub cmp {
        my ($self, $string) = @_;
        my $cmp = $$self cmp "$string";
            $cmp == 0 ? (Sidef::Types::Number::Number::ZERO)
          : $cmp > 0  ? (Sidef::Types::Number::Number::ONE)
          :             (Sidef::Types::Number::Number::MONE);
    }

    sub xor {
        my ($self, $str) = @_;
        $self->new($$self ^ "$str");
    }

    sub or {
        my ($self, $str) = @_;
        $self->new($$self | "$str");
    }

    sub and {
        my ($self, $str) = @_;
        $self->new($$self & "$str");
    }

    sub not {
        my ($self) = @_;
        $self->new(~$$self);
    }

    sub mul {
        my ($self, $num) = @_;
        $self->new($$self x $num);
    }

    sub repeat {
        my ($self, $num) = @_;
        $self->times($num // (Sidef::Types::Number::Number::ONE));
    }

    sub eq {
        my ($self, $arg) = @_;
        $$self eq $$arg
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub ne {
        my ($self, $arg) = @_;
        $$self ne $$arg
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub append {
        my ($self, $string) = @_;
        $self->new($$self . "$string");
    }

    *add    = \&append;
    *concat = \&append;

    sub prepend {
        my ($self, $string) = @_;
        $self->new("$string" . $$self);
    }

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

    sub uc {
        my ($self) = @_;
        $self->new(CORE::uc $$self);
    }

    *upcase = \&uc;
    *upper  = \&uc;

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
        my ($self, $num) = @_;
        bless \(my $t = CORE::substr($$self, 0, defined($num) ? CORE::int($num) : 1));
    }

    sub last {
        my ($self, $num) = @_;
        bless \(my $t = CORE::substr($$self, defined($num) ? -(CORE::int($num) || return $self->new('')) : -1));
    }

    sub char {
        my ($self, $pos) = @_;
        bless \(my $t = CORE::substr($$self, CORE::int($pos), 1));
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

        bless \$string;
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
        $self->new(crypt($$self, "$salt"));
    }

    sub bin {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self, 2);
    }

    sub oct {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self, 8);
    }

    sub hex {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self, 16);
    }

    sub hexlify {
        my ($self) = @_;
        my $r = CORE::unpack("H*", $$self);
        bless \$r;
    }

    *ascii2hex = \&hexlify;

    sub unhexlify {
        my ($self) = @_;
        my $r = CORE::pack("H*", $$self);
        bless \$r;
    }

    *hex2ascii = \&unhexlify;

    sub ascii2bin {
        my ($self) = @_;
        my $r = CORE::unpack("B*", $$self);
        bless \$r;
    }

    sub bin2ascii {
        my ($self) = @_;
        my $r = CORE::pack("B*", $$self);
        bless \$r;
    }

    sub decode_base64 {
        state $x = require MIME::Base64;
        bless \MIME::Base64::decode_base64(${$_[0]});
    }

    *base64_decode = \&decode_base64;

    sub encode_base64 {
        state $x = require MIME::Base64;
        bless \MIME::Base64::encode_base64(${$_[0]});
    }

    *base64_encode = \&encode_base64;

    sub md5 {
        state $x = require Digest::MD5;
        bless \Digest::MD5::md5_hex(${$_[0]});
    }

    sub sha1 {
        state $x = require Digest::SHA;
        bless \Digest::SHA::sha1_hex(${$_[0]});
    }

    sub sha256 {
        state $x = require Digest::SHA;
        bless \Digest::SHA::sha256_hex(${$_[0]});
    }

    sub sha512 {
        state $x = require Digest::SHA;
        bless \Digest::SHA::sha512_hex(${$_[0]});
    }

    sub parse_quotewords {
        my ($self, $delim, $keep) = @_;
        state $x = require Text::ParseWords;
        my @words = map { bless \$_ } Text::ParseWords::parse_line("$delim", ($keep ? 1 : 0), $$self);
        Sidef::Types::Array::Array->new(\@words);
    }

    sub extract_bracketed {
        my ($self, $brackets) = @_;
        state $x = require Text::Balanced;
        my @results = Text::Balanced::extract_bracketed($$self, "$brackets");
        map { bless \$_ } @results;
    }

    sub extract_delimited {
        my ($self, $delim) = @_;
        state $x = require Text::Balanced;
        my @results = Text::Balanced::extract_delimited($$self, "$delim");
        map { bless \$_ } @results;
    }

    sub extract_codeblock {
        my ($self, $delim) = @_;
        state $x = require Text::Balanced;
        my @results = Text::Balanced::extract_codeblock($$self, "$delim");
        map { bless \$_ } @results;
    }

    sub extract_quotelike {
        my ($self) = @_;
        state $x = require Text::Balanced;
        my @results = Text::Balanced::extract_quotelike($$self);
        map { bless \$_ } @results;
    }

    sub extract_tagged {
        my ($self) = @_;
        state $x = require Text::Balanced;
        my @results = Text::Balanced::extract_tagged($$self);
        map { bless \$_ } @results;
    }

    sub substr {
        my ($self, $offs, $len) = @_;
        bless \(
                my $t = (
                         defined($len)
                         ? CORE::substr($$self, CORE::int($offs), CORE::int($len))
                         : CORE::substr($$self, CORE::int($offs))
                        )
               );
    }

    *substring = \&substr;

    sub ft {
        my ($self, $from, $to) = @_;

        my $max = CORE::length($$self);

        $from = defined($from) ? CORE::int($from) : 0;
        $to   = defined($to)   ? CORE::int($to)   : $max;

        if (abs($from) > $max) {
            return state $x = bless \(my $str = '');
        }

        if ($to < 0) {
            $to += $max;
        }

        if ($from < 0) {
            $from += $max;
        }

        __PACKAGE__->new($to < $from ? '' : CORE::substr($$self, $from, $to - $from + 1));
    }

    *slice = \&ft;

    sub insert {
        my ($self, $string, $pos, $len) = @_;
        my $copy_str = "$$self";
        CORE::substr($copy_str, CORE::int($pos), (defined($len) ? CORE::int($len) : 0), "$string");
        bless \$copy_str;
    }

    sub join {
        my ($self, @rest) = @_;
        bless \CORE::join($$self, @rest);
    }

    sub clear {
        state $x = bless \(my $str = '');
    }

    sub is_empty {
        my ($self) = @_;
        ($$self eq '')
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_lowercase {
        my ($self) = @_;
        ($$self =~ /^[[:lower:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_lc = \&is_lowercase;

    sub is_uppercase {
        my ($self) = @_;
        ($$self =~ /^[[:upper:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_uc = \&is_uppercase;

    sub is_ascii {
        my ($self) = @_;
        ($$self =~ /^[[:ascii:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_space {
        my ($self) = @_;
        ($$self =~ /^[[:space:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_word {
        my ($self) = @_;
        ($$self =~ /^[[:word:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_punctuation {
        my ($self) = @_;
        ($$self =~ /^[[:punct:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_punct = \&is_punctuation;

    sub is_digit {
        my ($self) = @_;
        ($$self =~ /^[[:digit:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_alpha {
        my ($self) = @_;
        ($$self =~ /^[[:alpha:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_alphanum {
        my ($self) = @_;
        ($$self =~ /^[[:alnum:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_alnum = \&is_alphanum;

    sub index {
        my ($self, $substr, $pos) = @_;
        Sidef::Types::Number::Number::_set_int(
                                               defined($pos)
                                               ? CORE::index($$self, "$substr", CORE::int($pos))
                                               : CORE::index($$self, "$substr")
                                              );
    }

    sub rindex {
        my ($self, $substr, $pos) = @_;
        Sidef::Types::Number::Number::_set_int(
                                               defined($pos)
                                               ? CORE::rindex($$self, "$substr", CORE::int($pos))
                                               : CORE::rindex($$self, "$substr")
                                              );
    }

    sub ord {
        my ($self) = @_;
        $$self eq ''
          ? undef
          : Sidef::Types::Number::Number::_set_int(CORE::ord($$self));
    }

    sub reverse {
        my ($self) = @_;
        $self->new(scalar CORE::reverse($$self));
    }

    *flip = \&reverse;

    sub printf {
        my ($self, @arguments) = @_;
        printf($$self, @arguments)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub printlnf {
        my ($self, @arguments) = @_;
        printf($$self . "\n", @arguments)
          ? Sidef::Types::Bool::Bool::TRUE
          : Sidef::Types::Bool::Bool::FALSE;
    }

    sub sprintf {
        my ($self, @arguments) = @_;
        $self->new(CORE::sprintf $$self, @arguments);
    }

    sub sprintlnf {
        my ($self, @arguments) = @_;
        $self->new(CORE::sprintf($$self . "\n", @arguments));
    }

    sub _string_or_regex {
        my ($obj) = @_;

        if (ref($obj) eq 'Sidef::Types::Regex::Regex') {
            return $obj->{regex};
        }

        CORE::quotemeta("$obj");
    }

    sub sub {
        my ($self, $regex, $str) = @_;

        ref($str) eq 'Sidef::Types::Block::Block'
          && return $self->esub($regex, $str);

        my $search = _string_or_regex($regex);
        my $value  = "$str";

        $self->new($$self =~ s{$search}{$value}r);
    }

    *replace = \&sub;

    sub gsub {
        my ($self, $regex, $str) = @_;

        ref($str) eq 'Sidef::Types::Block::Block'
          && return $self->gesub($regex, $str);

        my $search = _string_or_regex($regex);
        my $value  = "$str";
        $self->new($$self =~ s{$search}{$value}gr);
    }

    *replace_all = \&gsub;

    sub _get_captures {
        my ($string) = @_;
        map { bless \(my $t = CORE::substr($string, $-[$_], $+[$_] - $-[$_])) } 1 .. $#{-};
    }

    sub esub {
        my ($self, $regex, $code) = @_;

        my $search = _string_or_regex($regex);

        if (ref($code) eq 'Sidef::Types::Block::Block') {
            return $self->new($$self =~ s{$search}{$code->run(_get_captures($$self))}er);
        }

        $self->new($$self =~ s{$search}{"$code"}eer);
    }

    sub gesub {
        my ($self, $regex, $code) = @_;

        my $search = _string_or_regex($regex);

        if (ref($code) eq 'Sidef::Types::Block::Block') {
            my $value = $$self;
            return $self->new($value =~ s{$search}{$code->run(_get_captures($value))}ger);
        }

        my $value = "$code";
        $self->new($$self =~ s{$search}{$value}geer);
    }

    sub glob {
        my ($self) = @_;
        state $x = require Encode;
        Sidef::Types::Array::Array->new([map { bless \Encode::decode_utf8($_) } CORE::glob($$self)]);
    }

    sub quotemeta {
        my ($self) = @_;
        $self->new(CORE::quotemeta($$self));
    }

    *escape = \&quotemeta;

    sub scan {
        my ($self, $regex) = @_;
        my $str = $$self;
        Sidef::Types::Array::Array->new([map { bless \$_ } $str =~ /$regex->{regex}/g]);
    }

    sub collect {
        my ($self, $regex) = @_;
        my $str = $$self;
        my @matches;
        while ($str =~ /$regex->{regex}/g) {
            push @matches, Sidef::Types::Array::Array->new([_get_captures($str)]);
        }
        Sidef::Types::Array::Array->new(\@matches);
    }

    *findall  = \&collect;
    *find_all = \&collect;

    sub split {
        my ($self, $sep, $size) = @_;

        $size = defined($size) ? CORE::int($size) : 0;

        if (!defined($sep)) {
            return
              Sidef::Types::Array::Array->new(
                                              [map { bless \$_ }
                                                 split(' ', $$self, $size)
                                              ]
                                             );
        }

        if (ref($sep) eq 'Sidef::Types::Number::Number') {
            return Sidef::Types::Array::Array->new([map { bless \$_ } unpack '(a' . CORE::int($sep) . ')*', $$self]);
        }

        $sep = _string_or_regex($sep);
        Sidef::Types::Array::Array->new([map { bless \$_ } split(/$sep/, $$self, $size)]);
    }

    sub sort {
        my ($self, $block) = @_;

        if (defined $block) {
            return $self->chars->sort($block)->join;
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

        bless \$acc;
    }

    sub words {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } CORE::split(' ', $$self)]);
    }

    sub each_word {
        my ($self, $code) = @_;

        foreach my $word (CORE::split(' ', $$self)) {
            $code->run(bless \$word);
        }

        $self;
    }

    sub numbers {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                                        [map  { Sidef::Types::Number::Number->new($_) }
                                         grep { Scalar::Util::looks_like_number($_) } CORE::split(' ', $$self)
                                        ]
                                       );
    }

    *nums = \&numbers;

    sub integers {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                                        [map  { Sidef::Types::Number::Number->new($_)->int }
                                         grep { Scalar::Util::looks_like_number($_) } CORE::split(' ', $$self)
                                        ]
                                       );
    }

    *ints = \&integers;

    sub digits {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                             [map { Sidef::Types::Number::Number::_set_int($_) } grep { /^[0-9]\z/ } CORE::split(//, $$self)]);
    }

    sub each_number {
        my ($self, $code) = @_;

        foreach my $num (CORE::split(' ', $$self)) {
            $code->run(Sidef::Types::Number::Number->new($num));
        }

        $self;
    }

    *each_num = \&each_number;

    sub bytes {
        my ($self) = @_;
        my $string = $$self;
        require bytes;
        Sidef::Types::Array::Array->new(
            [
             map {
                 Sidef::Types::Number::Number::_set_int(CORE::ord(bytes::substr($string, $_, 1)))
               } 0 .. bytes::length($string) - 1
            ]
        );
    }

    sub each_byte {
        my ($self, $code) = @_;

        my $string = $$self;

        require bytes;
        foreach my $i (0 .. bytes::length($string) - 1) {
            $code->run(Sidef::Types::Number::Number::_set_int(CORE::ord bytes::substr($string, $i, 1)));
        }

        $self;
    }

    sub chars {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } CORE::split(//, $$self)]);
    }

    sub iter {
        my ($self) = @_;

        my @chars = split(//, $$self);

        my $i   = -1;
        my $end = $#chars;

        Sidef::Types::Block::Block->new(
            code => sub {
                ++$i <= $end or return undef;
                bless \(my $chr = $chars[$i]);
            }
        );
    }

    sub each_char {
        my ($self, $code) = @_;

        foreach my $char (CORE::split(//, $$self)) {
            $code->run(bless \$char);
        }

        $self;
    }

    *each = \&each_char;

    sub graphemes {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } $$self =~ /(\X)/g]);
    }

    *graphs = \&graphemes;

    sub each_grapheme {
        my ($self, $code) = @_;

        my $str = $$self;
        while ($str =~ /(\X)/g) {
            $code->run(bless \(my $str = $1));
        }

        $self;
    }

    *each_graph = \&each_grapheme;

    sub lines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } CORE::split(/\R/, $$self)]);
    }

    sub each_line {
        my ($self, $code) = @_;

        foreach my $line (CORE::split(/\R/, $$self)) {
            $code->run(bless \$line);
        }

        $self;
    }

    sub pipe {
        my ($self) = @_;
        Sidef::Types::Glob::Pipe->new($$self);
    }

    sub backtick {
        my ($self) = @_;
        Sidef::Types::Glob::Backtick->new($$self);
    }

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

    sub center {
        my ($self, $size, $char) = @_;

        my $string = $$self;

        $size = defined($size) ? CORE::int($size) : 0;
        $char = defined($char) ? "$char"          : ' ';

        if (CORE::length($char) > 1) {
            $char = CORE::substr($char, 0, 1);
        }

        my $len = CORE::length($string);

        $size <= $len
          && return $self;

        my $padlen = $size - $len;
        my $lpad   = $padlen >> 1;
        my $rpad   = $padlen - $lpad;

        $self->new(($char x $lpad) . $string . ($char x $rpad));
    }

    sub trim {
        my ($self, $arg) = @_;

        if (defined($arg)) {

            my $regex;

            if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
                $regex = qr/(?:$arg->{regex})/;
            }
            else {
                my @chars = split('', "$arg");
                $regex = qr/(?:[@chars]+)/;
            }

            return $self->new(($$self =~ s/^$regex//r) =~ s/$regex\z//r);
        }

        $self->new(unpack('A*', $$self) =~ s/^\s+//r);
    }

    *strip = \&trim;

    sub strip_beg {
        my ($self, $arg) = @_;

        if (defined($arg)) {

            my $regex;

            if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
                $regex = qr/^(?:$arg->{regex})/;
            }
            else {
                my @chars = split('', "$arg");
                $regex = qr/^(?:[@chars]+)/;
            }

            return $self->new($$self =~ s/$regex//r);
        }

        $self->new($$self =~ s/^\s+//r);
    }

    *lstrip     = \&strip_beg;
    *ltrim      = \&strip_beg;
    *trim_beg   = \&strip_beg;
    *strip_left = \&strip_beg;
    *trim_left  = \&strip_beg;

    sub strip_end {
        my ($self, $arg) = @_;

        if (defined($arg)) {

            my $regex;

            if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
                $regex = qr/(?:$arg->{regex})\z/;
            }
            else {
                my @chars = split('', "$arg");
                $regex = qr/(?:[@chars]+)\z/;
            }

            return $self->new($$self =~ s/$regex//r);
        }

        $self->new(unpack('A*', $$self));
    }

    *rstrip      = \&strip_end;
    *rtrim       = \&strip_end;
    *trim_end    = \&strip_end;
    *strip_right = \&strip_end;
    *trim_right  = \&strip_end;

    sub trans {
        my ($self, $orig, $repl) = @_;

        my %map;
        if (!defined($repl) and defined($orig)) {    # assume an array of pairs
            foreach my $pair (@{$orig}) {
                $map{"$pair->[0]"} = "$pair->[1]";
            }
        }
        else {
            @map{@{$orig}} = @{$repl};
        }

        my $tries = (
                     CORE::join('|', map { CORE::quotemeta($_) }
                                  sort { length($b) <=> length($a) } CORE::keys(%map))
                    );

        $self->new($$self =~ s{($tries)}{$map{$1}}gr);
    }

    sub translit {
        my ($self, $orig, $repl, $modes) = @_;

        UNIVERSAL::isa($orig, 'ARRAY') && return $self->trans($orig, $repl);
        $self->new(
                       eval qq{"\Q${\$$self}\E"=~tr/}
                     . "$orig" =~ s{([/\\])}{\\$1}gr . "/"
                     . "$repl" =~ s{([/\\])}{\\$1}gr . "/r"
                     . (
                        defined($modes)
                        ? "$modes"
                        : ''
                       )
                  );
    }

    *tr = \&translit;

    sub unpack {
        my ($self, $arg) = @_;
        my @values = map { bless \$_ } CORE::unpack($$self, "$arg");
        @values > 1 ? @values : $values[0];
    }

    sub pack {
        my ($self, @list) = @_;
        $self->new(CORE::pack($$self, @list));
    }

    sub chars_length {
        Sidef::Types::Number::Number::_set_int(CORE::length(${$_[0]}));
    }

    *len       = \&chars_length;
    *length    = \&chars_length;
    *chars_len = \&chars_length;
    *size      = \&chars_length;

    sub graphs_length {
        Sidef::Types::Number::Number::_set_int(scalar(() = ${$_[0]} =~ /\X/g));
    }

    *graphs_len = \&graphs_length;

    sub bytes_length {
        my ($self) = @_;

        require bytes;
        Sidef::Types::Number::Number::_set_int(bytes::length($$self));
    }

    *bytes_len = \&bytes_length;

    sub levenshtein {
        my ($self, $arg) = @_;

        my @s = split(//, $$self);
        my @t = split(//, "$arg");

        my $len1 = scalar(@s);
        my $len2 = scalar(@t);

        require List::Util;

        my @d = ([0 .. $len2], map { [$_] } 1 .. $len1);
        foreach my $i (1 .. $len1) {
            foreach my $j (1 .. $len2) {
                $d[$i][$j] =
                    $s[$i - 1] eq $t[$j - 1]
                  ? $d[$i - 1][$j - 1]
                  : List::Util::min($d[$i - 1][$j], $d[$i][$j - 1], $d[$i - 1][$j - 1]) + 1;
            }
        }

        Sidef::Types::Number::Number::_set_int($d[-1][-1]);
    }

    *lev   = \&levenshtein;
    *leven = \&levenshtein;

    sub jaro_distance {
        my ($s, $t, $winkler) = @_;

        $s = $$s;
        $t = "$t";

        my $s_len = length($s);
        my $t_len = length($t);

        if ($s_len == 0 and $t_len == 0) {
            return 1;
        }

        require List::Util;

        my $match_distance = int(List::Util::max($s_len, $t_len) / 2) - 1;

        my @s_matches;
        my @t_matches;

        my @s = split(//, $s);
        my @t = split(//, $t);

        my $matches = 0;
        foreach my $i (0 .. $#s) {

            my $start = List::Util::max(0, $i - $match_distance);
            my $end   = List::Util::min($i + $match_distance + 1, $t_len);

            foreach my $j ($start .. $end - 1) {
                $t_matches[$j] and next;
                $s[$i] eq $t[$j] or next;
                $s_matches[$i] = 1;
                $t_matches[$j] = 1;
                $matches++;
                last;
            }
        }

        return Sidef::Types::Number::Number::ZERO if $matches == 0;

        my $k              = 0;
        my $transpositions = 0;

        foreach my $i (0 .. $#s) {
            $s_matches[$i] or next;
            until ($t_matches[$k]) { ++$k }
            $s[$i] eq $t[$k] or ++$transpositions;
            ++$k;
        }

        my $jaro = (($matches / $s_len) + ($matches / $t_len) + (($matches - $transpositions / 2) / $matches)) / 3;

        $winkler || return Sidef::Types::Number::Number->new($jaro);    # return the Jaro distance instead of Jaro-Winkler

        my $prefix = 0;
        foreach my $i (0 .. List::Util::min(3, $#t, $#s)) {
            $s[$i] eq $t[$i] ? ++$prefix : last;
        }

        Sidef::Types::Number::Number->new($jaro + $prefix * 0.1 * (1 - $jaro));
    }

    sub contains {
        my ($self, $arg, $start_pos) = @_;

        $start_pos = defined($start_pos) ? CORE::int($start_pos) : 0;

        if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
            my $regex = $arg->{regex};
            my $s     = $$self;
            pos($s) = $start_pos;
            return (
                      (scalar $s =~ /$regex/g)
                    ? (Sidef::Types::Bool::Bool::TRUE)
                    : (Sidef::Types::Bool::Bool::FALSE)
                   );
        }

        if ($start_pos < 0) {
            $start_pos = CORE::length($$self) + $start_pos;
        }

        CORE::index($$self, "$arg", $start_pos) != -1
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *has      = \&contains;
    *contain  = \&contains;
    *include  = \&contains;
    *includes = \&contains;

    sub rotate {
        my ($self, $n) = @_;
        $n = (CORE::int($n) % (CORE::length($$self) || return $self)) || return $self;
        $self->new(CORE::substr($$self, $n) . CORE::substr($$self, 0, $n));
    }

    sub count {
        my ($self, $arg) = @_;

        my $s       = $$self;
        my $counter = 0;

        if (ref($arg) eq 'Sidef::Types::Regex::Regex') {
            my $regex = $arg->{regex};
            ++$counter while $s =~ /$regex/g;
            return Sidef::Types::Number::Number::_set_int($counter);
        }
        elsif (ref($arg) eq 'Sidef::Types::Block::Block') {
            foreach my $char (split //, $s) {
                ++$counter if $arg->run(bless \$char);
            }
            return Sidef::Types::Number::Number::_set_int($counter);
        }

        my $ss = "$arg";
        ++$counter while $s =~ /\Q$ss\E/g;
        Sidef::Types::Number::Number::_set_int($counter);
    }

    sub overlaps {
        my ($self, $arg) = @_;
        CORE::index($$self ^ "$arg", "\0") != -1
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub begins_with {
        my ($self, $string) = @_;

        $string = "$string";

        CORE::length($$self) < (my $len = CORE::length($string))
          && return (Sidef::Types::Bool::Bool::FALSE);

        CORE::substr($$self, 0, $len) eq $string
          && return (Sidef::Types::Bool::Bool::TRUE);

        Sidef::Types::Bool::Bool::FALSE;
    }

    *starts_with = \&begins_with;

    sub ends_with {
        my ($self, $string) = @_;

        $string = "$string";

        CORE::length($$self) < (my $len = CORE::length($string))
          && return (Sidef::Types::Bool::Bool::FALSE);

        CORE::substr($$self, -$len) eq $string
          && return (Sidef::Types::Bool::Bool::TRUE);

        Sidef::Types::Bool::Bool::FALSE;
    }

    sub looks_like_number {
        my ($self) = @_;
        Scalar::Util::looks_like_number($$self)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    *is_numeric = \&looks_like_number;

    sub is_palindrome {
        my ($self) = @_;
        $$self eq CORE::reverse(${$self})
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
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

        require Encode;
        $self->new(Encode::encode("$enc", $$self));
    }

    sub decode {
        my ($self, $enc) = @_;

        require Encode;
        $self->new(Encode::decode("$enc", $$self));
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

    sub run {
        my ($method, $self, @args) = @_;
        $self->$$method(@args);
    }

    sub unescape {
        my ($self) = @_;
        $self->new($$self =~ s{\\(.)}{$1}grs);
    }

    sub apply_escapes {
        my ($self, $parser) = @_;

        $$self =~ /\\|#\{/ || return $self;    # return faster

        require Encode;
        require List::Util;

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
                elsif ($char =~ /^[0-7]/) {

                    my $max = List::Util::min($i + 3, $#chars);
                    my $str = CORE::join('', @chars[$i + 1 .. $max]);

                    if ($str =~ /^(0[0-7]{1,2}|[0-7]{1,2})/) {
                        splice @chars, $i, 1 + $+[0], CORE::chr(CORE::oct($1));
                    }
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

                        my $max = List::Util::min($i + 2048, $#chars);
                        my $str = CORE::join('', @chars[$i + 2 .. $max]);

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

                        my $max = List::Util::min($i + 64, $#chars);
                        my $str = CORE::join('', @chars[$i + 2 .. $max]);

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

                        my $max = List::Util::min($i + 64, $#chars);
                        my $str = CORE::join('', @chars[$i + 2 .. $max]);

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
                elsif ($char eq 'c') {
                    if (exists $chars[$i + 2]) {    # bug for: "\c\\"
                        splice(@chars, $i, 3, chr((CORE::ord(CORE::uc($chars[$i + 2])) + 64) % 128));
                    }
                    else {
                        CORE::warn "[WARNING] Missing control char name in \\c, within string\n";
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
                    my $code  = 'do' . CORE::join('', @chars[$i + 1 .. $#chars]);
                    my $block = $parser->parse_expr(code => \$code);
                    push @inline_expressions, [$i, $block];
                    splice(@chars, $i--, 1 + pos($code) - 2);
                }
                else {
                    # Can't eval #{} at runtime!
                }
            }

            if ($spec ne 'E' and defined($chars[$i])) {
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

            state %cache;
            my $type = (ref($self) =~ s/::Types::/::DataTypes::/r);
            my $dt   = ($cache{$type} //= bless({}, $type));

            my $expr = {
                        $parser->{class} => [
                                             {
                                              self => $dt,
                                              call => [{method => 'interpolate'}]
                                             }
                                            ]
                       };

            my $append_arg = sub {
                push @{$expr->{$parser->{class}}[0]{call}[-1]{arg}}, $_[0];
            };

            my $string = '';
            foreach my $char (@chars) {
                if (ref($char)) {
                    my $block = $char;

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
        $i = CORE::int($i);
        $i = $len if $i > $len;
        $self->new(CORE::substr($$self, $i));
    }

    *drop_left = \&shift_left;

    sub shift_right {
        my ($self, $i) = @_;
        $i = CORE::int($i);
        $self->new(CORE::substr($$self, 0, -$i));
    }

    *drop_right = \&shift_right;

    sub to_str {
        $_[0];
    }

    *to_s = \&to_str;

    sub to_int {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self)->int;
    }

    *to_i = \&to_int;

    sub to_num {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self);
    }

    *num  = \&to_num;
    *to_n = \&to_num;

    {
        my %esc = (
                   "\a"    => "\\a",
                   "\b"    => "\\b",
                   "\t"    => "\\t",
                   "\n"    => "\\n",
                   "\f"    => "\\f",
                   "\r"    => "\\r",
                   "\e"    => "\\e",
                   chr(11) => "\\v",
                  );

        # Function by Gisle Aas, copied from `Data::Dump` (thanks).
        sub dump {
            my $str = "${$_[0]}";

            $str =~ s/([\\\"]|#\{)/\\$1/g;
            $str =~ /[^\040-\176]/ or return bless \qq("$str");

            $str =~ s/([\a\b\t\n\f\r\e\13])/$esc{$1}/g;
            $str =~ s/([\0-\037])(?!\d)/CORE::sprintf('\\%o',CORE::ord($1))/eg;

            $str =~ s/([\0-\037\177-\377])/CORE::sprintf('\\x%02X',CORE::ord($1))/eg;
            $str =~ s/([^\040-\176])/CORE::sprintf('\\x{%X}',CORE::ord($1))/eg;

            bless \qq("$str");
        }
    }

    *inspect = \&dump;

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '=~'}  = \&match;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '+'}   = \&append;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '-'}   = \&diff;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'}   = \&ne;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'}   = \&ge;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'}   = \&le;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '÷'}   = \&div;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '..'}  = \&to;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '%'}   = \&sprintf;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
    }
};

1
