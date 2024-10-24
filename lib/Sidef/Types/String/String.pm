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

    *repeat = \&mul;

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

    *downcase  = \&lc;
    *lower     = \&lc;
    *lowercase = \&lc;

    sub uc {
        my ($self) = @_;
        $self->new(CORE::uc $$self);
    }

    *upcase    = \&uc;
    *upper     = \&uc;
    *uppercase = \&uc;

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

    *head = \&first;

    sub last {
        my ($self, $num) = @_;
        bless \(my $t = CORE::substr($$self, defined($num) ? -(CORE::int($num) || return $self->new('')) : -1));
    }

    *tail = \&last;

    sub char {
        my ($self, $pos) = @_;
        bless \(my $t = CORE::substr($$self, CORE::int($pos), 1) // '');
    }

    *char_at = \&char;

    sub byte {
        my ($self, $pos) = @_;

        require bytes;

        $pos = CORE::int($pos);

        if ($pos >= bytes::length($$self)) {
            return undef;
        }

        my $char = bytes::substr($$self, $pos, 1) // return undef;
        Sidef::Types::Number::Number::_set_int(CORE::ord($char));
    }

    *byte_at = \&byte;

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
        Sidef::Types::Number::Number->new($$self || '0', 2);
    }

    sub oct {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self || '0', 8);
    }

    sub hex {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self || '0', 16);
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

    sub ascii2bits {
        my ($self) = @_;
        Sidef::Types::Array::Array->new(
                      [map { $_ ? Sidef::Types::Number::Number::ONE : Sidef::Types::Number::Number::ZERO } CORE::split(//, scalar CORE::unpack("B*", $$self))]);
    }

    sub decode_base64 {
        state $x = require MIME::Base64;
        bless \(my $value = MIME::Base64::decode_base64(${$_[0]}));
    }

    *base64_decode = \&decode_base64;

    sub encode_base64 {
        state $x = require MIME::Base64;
        bless \(my $value = MIME::Base64::encode_base64(${$_[0]}));
    }

    *base64_encode = \&encode_base64;

    sub md5 {
        state $x = require Digest::MD5;
        bless \(my $value = Digest::MD5::md5_hex(${$_[0]}));
    }

    sub sha1 {
        state $x = require Digest::SHA;
        bless \(my $value = Digest::SHA::sha1_hex(${$_[0]}));
    }

    sub sha256 {
        state $x = require Digest::SHA;
        bless \(my $value = Digest::SHA::sha256_hex(${$_[0]}));
    }

    sub sha512 {
        state $x = require Digest::SHA;
        bless \(my $value = Digest::SHA::sha512_hex(${$_[0]}));
    }

    sub parse_quotewords {
        my ($self, $delim, $keep) = @_;
        $delim //= ' ';
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
    *slice     = \&substr;

    sub insert {
        my ($self, $string, $pos, $len) = @_;
        my $copy_str = "$$self";
        CORE::substr($copy_str, CORE::int($pos), (defined($len) ? CORE::int($len) : 0), "$string");
        bless \$copy_str;
    }

    sub join {
        my ($self, @rest) = @_;
        bless \(my $value = CORE::join($$self, @rest));
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

    sub is_blank {
        my ($self) = @_;
        ($$self =~ /^[[:blank:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_graph {
        my ($self) = @_;
        ($$self =~ /^[[:graph:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_control {
        my ($self) = @_;
        ($$self =~ /^[[:cntrl:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_printable {
        my ($self) = @_;
        ($$self =~ /^[[:print:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

    sub is_xdigit {
        my ($self) = @_;
        ($$self =~ /^[[:xdigit:]]+\z/)
          ? (Sidef::Types::Bool::Bool::TRUE)
          : (Sidef::Types::Bool::Bool::FALSE);
    }

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

    *sayf = \&printlnf;

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
        my ($self, $regex, $block) = @_;

        my $search = _string_or_regex($regex);

        if (ref($block) eq 'Sidef::Types::Block::Block') {
            return $self->new($$self =~ s{$search}{$block->run(_get_captures($$self))}er);
        }

        $self->new($$self =~ s{$search}{"$block"}eer);
    }

    sub gesub {
        my ($self, $regex, $block) = @_;

        my $search = _string_or_regex($regex);

        if (ref($block) eq 'Sidef::Types::Block::Block') {
            my $value = $$self;
            return $self->new($value =~ s{$search}{$block->run(_get_captures($value))}ger);
        }

        my $value = "$block";
        $self->new($$self =~ s{$search}{$value}geer);
    }

    sub glob {
        my ($self) = @_;
        state $x = require Encode;
        Sidef::Types::Array::Array->new([map { bless \(my $value = Encode::decode_utf8($_)) } CORE::glob($$self)]);
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

    sub slices {
        my ($self, $n) = @_;
        $n = CORE::int($n);
        $n > 0 or return Sidef::Types::Array::Array->new;
        Sidef::Types::Array::Array->new([map { bless \$_ } unpack('(a' . $n . ')*', $$self)]);
    }

    sub each_slice {
        my ($self, $n, $block) = @_;

        $n = CORE::int($n);
        $n > 0 or return $self;

        my $len = length($$self);
        for (my $i = 0 ; $i < $len ; $i += $n) {
            $block->run(bless \(my $str = CORE::substr($$self, $i, $n)));
        }

        $self;
    }

    sub cons {
        my ($self, $n) = @_;
        $n = CORE::int($n);
        $n > 0 or return Sidef::Types::Array::Array->new;
        my @strings;
        foreach my $i (0 .. CORE::length($$self) - $n) {
            push @strings, bless \(my $str = CORE::substr($$self, $i, $n));
        }
        Sidef::Types::Array::Array->new(\@strings);
    }

    sub each_cons {
        my ($self, $n, $block) = @_;

        $n = CORE::int($n);
        $n > 0 or return $self;

        foreach my $i (0 .. CORE::length($$self) - $n) {
            $block->run(bless \(my $str = CORE::substr($$self, $i, $n)));
        }

        $self;
    }

    sub split {
        my ($self, $sep, $size) = @_;

        $size = defined($size) ? CORE::int($size) : 0;

        if (!defined($sep)) {
            return Sidef::Types::Array::Array->new([map { bless \$_ } split(' ', $$self, $size)]);
        }

        if (ref($sep) eq 'Sidef::Types::Number::Number') {
            return $self->slices($sep);
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

    sub unique {
        my ($self) = @_;
        require List::Util;
        $self->new(CORE::join('', List::Util::uniq(CORE::split(//, $$self))));
    }

    *uniq     = \&unique;
    *distinct = \&unique;

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
        my ($self, $block) = @_;

        foreach my $word (CORE::split(' ', $$self)) {
            $block->run(bless \$word);
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
                                        [map  { Sidef::Types::Number::Number::_set_int($_) }
                                         grep { /^-?[0-9]+\z/ } CORE::split(' ', $$self)
                                        ]
                                       );
    }

    *ints = \&integers;

    sub digits {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::Number::Number::_set_int($_) } grep { /^[0-9]\z/ } CORE::split(//, $$self)]);
    }

    sub each_number {
        my ($self, $block) = @_;

        foreach my $num (CORE::split(' ', $$self)) {
            $block->run(Sidef::Types::Number::Number->new($num));
        }

        $self;
    }

    *each_num = \&each_number;

    sub bytes {
        my ($self) = @_;
        my $string = $$self;
        require bytes;
        Sidef::Types::Array::Array->new(
                                    [map { Sidef::Types::Number::Number::_set_int(CORE::ord(bytes::substr($string, $_, 1))) } 0 .. bytes::length($string) - 1]);
    }

    sub each_byte {
        my ($self, $block) = @_;

        my $string = $$self;

        require bytes;
        foreach my $i (0 .. bytes::length($string) - 1) {
            $block->run(Sidef::Types::Number::Number::_set_int(CORE::ord bytes::substr($string, $i, 1)));
        }

        $self;
    }

    sub chars {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } CORE::split(//, $$self)]);
    }

    sub code_points {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { Sidef::Types::Number::Number::_set_int($_) } unpack('C*', $$self)]);
    }

    *codes = \&code_points;

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
        my ($self, $block) = @_;

        foreach my $char (CORE::split(//, $$self)) {
            $block->run(bless \$char);
        }

        $self;
    }

    *each = \&each_char;

    sub each_kv {
        my ($self, $block) = @_;

        my @chars = CORE::split(//, $$self);

        foreach my $i (0 .. $#chars) {
            my $char = $chars[$i];
            $block->run(Sidef::Types::Number::Number::_set_int($i), (bless \$char));
        }

        $self;
    }

    sub graphemes {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } $$self =~ /(\X)/g]);
    }

    *graphs = \&graphemes;

    sub each_grapheme {
        my ($self, $block) = @_;

        my $str = $$self;
        while ($str =~ /(\X)/g) {
            $block->run(bless \(my $str = $1));
        }

        $self;
    }

    *each_graph = \&each_grapheme;

    sub lines {
        my ($self) = @_;
        Sidef::Types::Array::Array->new([map { bless \$_ } CORE::split(/\R/, $$self)]);
    }

    sub each_line {
        my ($self, $block) = @_;

        foreach my $line (CORE::split(/\R/, $$self)) {
            $block->run(bless \$line);
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
        my ($self, $mode) = @_;
        $mode //= 'utf8';
        my $str = $$self;
        open(my $fh, "<:$mode", \$str) or return undef;
        Sidef::Types::Glob::FileHandle->new($fh);
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

    sub jaro {
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

        $winkler || return Sidef::Types::Number::Number->new($jaro);    # return the Jaro similarity instead of Jaro-Winkler

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
        state $x = require Encode;
        $self->new(Encode::encode("$enc", $$self));
    }

    sub decode {
        my ($self, $enc) = @_;
        state $x = require Encode;
        $self->new(Encode::decode("$enc", $$self));
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

    sub deflate {
        my ($self) = @_;
        state $x = require IO::Compress::RawDeflate;
        my $input = $$self;
        IO::Compress::RawDeflate::rawdeflate(\$input => \my $output)
          or CORE::die("String.deflate failed: $IO::Compress::RawDeflate::RawDeflateError");
        bless \$output;
    }

    sub inflate {
        my ($self) = @_;
        state $x = require IO::Uncompress::RawInflate;
        my $input = $$self;
        IO::Uncompress::RawInflate::rawinflate(\$input => \my $output)
          or CORE::die("String.inflate failed: $IO::Uncompress::RawInflate::RawInflateError");
        bless \$output;
    }

    sub gzip {
        my ($self) = @_;
        state $x = require IO::Compress::Gzip;
        my $input = $$self;
        IO::Compress::Gzip::gzip(\$input => \my $output)
          or CORE::die("String.gzip failed: $IO::Compress::Gzip::GzipError");
        bless \$output;
    }

    sub gunzip {
        my ($self) = @_;
        state $x = require IO::Uncompress::Gunzip;
        my $input = $$self;
        IO::Uncompress::Gunzip::gunzip(\$input => \my $output)
          or CORE::die("String.gunzip failed: $IO::Uncompress::Gunzip::GunzipError");
        bless \$output;
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

    sub use {
        my ($self) = @_;
        eval("use $$self");
        $@ ? Sidef::Types::Bool::Bool::FALSE : Sidef::Types::Bool::Bool::TRUE;
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
        my ($self, $base) = @_;
        Sidef::Types::Number::Number->new($$self, (defined($base) ? $base : ()));
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
            $str =~ /[^\040-\176]/ or return bless \(my $value = qq("$str"));

            $str =~ s/([\a\b\t\n\f\r\e\13])/$esc{$1}/g;
            $str =~ s/([\0-\037])(?!\d)/CORE::sprintf('\\%o',CORE::ord($1))/eg;

            $str =~ s/([\0-\037\177-\377])/CORE::sprintf('\\x%02X',CORE::ord($1))/eg;
            $str =~ s/([^\040-\176])/CORE::sprintf('\\x{%X}',CORE::ord($1))/eg;

            bless \(my $value2 = qq("$str"));
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
