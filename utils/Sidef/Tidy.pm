package Sidef::Tidy {

    use utf8;
    use 5.014;
    use strict;
    use warnings;

    require Exporter;
    our @ISA       = qw(Exporter);
    our @EXPORT_OK = qw/sf_beautify/;

    my (@input, @output, @modes);
    my (
        $token_text,     $last_type,            $last_text,  $last_last_text,   $last_word,
        $current_mode,   $indent_string,        $parser_pos, $in_case,          $prefix,
        $token_type,     $do_block_just_closed, $var_line,   $var_line_tainted, $if_line_flag,
        $wanted_newline, $just_added_newline
       );

    my @whitespace = split('', "\n\r\t ");
    my @wordchar   = split('', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_:$');
    my @digits     = split('', '0123456789');

    my @punct = qw(
      ===
      =>
      ||= ||
      &&= &&

      <?=
      >?=
      <=?=
      >=?=
      ^^?=
      $$?=

      ?<==
      ?<=
      ?>==
      ?>=
      ?^^=
      ?$$=

      %%
      ->
      <=>
      <<= >>=
      << >>
      |= |
      &= &
      == =~
      := =
      ^^ $$
      <= ≤ >= ≥ < >
      ++ --
      += +
      -= -
      /= / ÷= ÷
      **= **
      %= %
      ^= ^
      *= *
      ...
      != ≠ ..
      \\\\
      ?:
      ?? ?
      ! \\
      : »
      ~ √
      );

    # words which should always start on new line.
    my @line_starter = qw(
      try
      throw
      if elsif else
      switch given
      case when
      default
      for
      while
      func
      enum
      define
      );

    my ($opt_indent_level, $opt_indent_size, $opt_indent_character, $opt_preserve_newlines, $opt_space_after_anon_function);

    sub sf_beautify {
        my ($sf_source_code, $opts) = @_;

        $opt_indent_size      = $opts->{indent_size}      || 4;
        $opt_indent_character = $opts->{indent_character} || ' ';
        $opt_preserve_newlines = exists $opts->{preserve_newlines} ? $opts->{preserve_newlines} : 1;
        $opt_indent_level = $opts->{indent_level} ||= 0;
        $opt_space_after_anon_function = exists $opts->{space_after_anon_function} ? $opts->{space_after_anon_function} : 0;

        # -------------------------------------
        $just_added_newline = 0;
        $indent_string      = '';
        while ($opt_indent_size--) {
            $indent_string .= $opt_indent_character;
        }
        @input = split('', $sf_source_code);

        $last_word      = '';                 # last 'TK_WORD' passed
        $last_type      = 'TK_START_EXPR';    # last token type
        $last_text      = '';                 # last token text
        $last_last_text = '';                 # pre-last token text
        @output         = ();

        $do_block_just_closed = 0;
        $var_line             = 0;
        $var_line_tainted     = 0;

        # states showing if we are currently in expression (i.e. "if" case) - 'EXPRESSION',
        # or in usual block (like, procedure), 'BLOCK'.
        # some formatting depends on that.
        $current_mode = 'BLOCK';
        @modes        = ($current_mode);

        $parser_pos = 0;    # parser position
        $in_case    = 0;    # flag for parser that case/default has been processed, and next colon needs special attention
        while (1) {
            my $t = get_next_token($parser_pos);
            $token_text = $t->[0];
            $token_type = $t->[1];
            if ($token_type eq 'TK_EOF') {
                last;
            }

            if ($token_type eq 'TK_START_EXPR') {
                $var_line = 0;

                if ($token_text eq '[') {
                    if ($last_type eq 'TK_WORD' || $last_text eq ')') {

                        # this is array index specifier, break immediately
                        # a[x], fn()[x]
                        set_mode('(EXPRESSION)');
                        print_token();
                        $last_last_text = $last_text;
                        $last_type      = $token_type;
                        $last_text      = $token_text;
                        next;
                    }
                    if ($current_mode eq '[EXPRESSION]' || $current_mode eq '[INDENTED-EXPRESSION]') {
                        if ($last_last_text eq ']' && $last_text eq ',') {

                            # ], [ goes to new line
                            indent();
                            print_newline();
                            set_mode('[INDENTED-EXPRESSION]');
                        }
                        elsif ($last_text eq '[') {
                            indent();
                            print_newline();
                            set_mode('[INDENTED-EXPRESSION]');
                        }
                        else {
                            set_mode('[EXPRESSION]');
                        }
                    }
                    else {
                        set_mode('[EXPRESSION]');
                    }
                }
                else {
                    set_mode('(EXPRESSION)');
                }

                if ($last_text eq ';' || $last_type eq 'TK_START_BLOCK') {
                    print_newline();
                }
                elsif ($last_type eq 'TK_END_EXPR' || $last_type eq 'TK_START_EXPR') {

                    # do nothing on (( and )( and ][ and ]( ..
                }
                elsif ($last_type ne 'TK_WORD' && $last_type ne 'TK_OPERATOR') {

                    #print_space();
                }
                elsif ($last_word eq 'function') {

                    # function() vs function ()
                    if ($opt_space_after_anon_function) {
                        print_space();
                    }
                }
                elsif (grep { $last_word eq $_ } @line_starter) {
                    print_space();
                }
                print_token();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_END_EXPR') {
                if ($token_text eq ']' && $current_mode eq '[INDENTED-EXPRESSION]') {
                    unindent();
                }
                restore_mode();
                print_token();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_START_BLOCK') {
                if ($last_word eq 'do') {
                    set_mode('DO_BLOCK');
                }
                else {
                    set_mode('BLOCK');
                }
                if ($last_type ne 'TK_OPERATOR' && $last_type ne 'TK_START_EXPR') {
                    if ($last_type eq 'TK_START_BLOCK') {
                        print_newline();
                    }
                    else {
                        print_space();
                    }
                }
                print_token();
                indent();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_END_BLOCK') {
                if ($last_type eq 'TK_START_BLOCK') {

                    # nothing
                    if ($just_added_newline) {
                        remove_indent();

                        #  {
                        #
                        #  }
                    }
                    else {
                        #  {}
                        trim_output();
                    }
                    unindent();
                }
                else {
                    unindent();
                    print_newline();    # newline before '}'
                }
                print_token();
                restore_mode();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_WORD') {

                # no, it's not you. even I have problems understanding how this works
                # and what does what.
                if ($do_block_just_closed) {
                    print_space();
                    print_token();
                    print_space();
                    $do_block_just_closed = 0;
                    $last_last_text       = $last_text;
                    $last_type            = $token_type;
                    $last_text            = $token_text;
                    next;
                }
                if ($token_text eq 'case' || $token_text eq 'default') {
                    if ($last_text eq ':') {

                        # switch cases following one another
                        remove_indent();
                    }
                    else {
                        # case statement starts in the same line where switch
                        unindent();
                        print_newline();
                        indent();
                    }
                    print_token();
                    $in_case        = 1;
                    $last_last_text = $last_text;
                    $last_type      = $token_type;
                    $last_text      = $token_text;
                    next;
                }
                $prefix = 'NONE';
                if ($last_type eq 'TK_END_BLOCK') {
                    if (not(grep { lc($token_text) eq $_ } ('else', 'catch'))) {
                        $prefix = 'NEWLINE';
                    }
                    else {
                        $prefix = 'SPACE';
                        print_space();
                    }
                }
                elsif ($last_type eq 'TK_SEMICOLON' && ($current_mode eq 'BLOCK' || $current_mode eq 'DO_BLOCK')) {
                    $prefix = 'NEWLINE';
                }
                elsif ($last_type eq 'TK_SEMICOLON' && is_expression($current_mode)) {
                    $prefix = 'SPACE';
                }
                elsif ($last_type eq 'TK_STRING') {
                    $prefix = 'NEWLINE';
                }
                elsif ($last_type eq 'TK_WORD') {
                    $prefix = 'SPACE';
                }
                elsif ($last_type eq 'TK_START_BLOCK') {
                    $prefix = 'NEWLINE';
                }
                elsif ($last_type eq 'TK_END_EXPR') {
                    print_space();
                    $prefix = 'NEWLINE';
                }

                if ($last_type ne 'TK_END_BLOCK' && (grep { lc($token_text) eq $_ } ('else', 'catch', 'elsif'))) {
                    print_newline();
                }
                elsif ((grep { $token_text eq $_ } @line_starter) || $prefix eq 'NEWLINE') {
                    if ($last_text eq 'elsif' || $last_text eq 'else') {

                        # no need to force newline on else break
                        print_space();
                    }
                    elsif (($last_type eq 'TK_START_EXPR' || $last_text eq '=' || $last_text eq ',') && $token_text eq 'func')
                    {

                        # no need to force newline on 'function': (function
                        # DONOTHING
                    }
                    elsif ($last_text eq 'return' || $last_text eq 'throw') {

                        # no newline between 'return nnn'
                        print_space();
                    }
                    elsif ($last_type ne 'TK_END_EXPR') {
                        if (($last_type ne 'TK_START_EXPR' || $token_text ne 'var') && $last_text ne ':') {

                            # no need to force newline on 'var': for (var x = 0...)
                            if ($token_text eq 'elsif' && $last_text ne '{') {

                                # no newline for } else if {
                                print_space();
                            }
                            else {
                                print_newline();
                            }
                        }
                    }
                    else {
                        if ((grep { $token_text eq $_ } @line_starter) && $last_text ne ')') {
                            print_newline();
                        }
                    }
                }
                elsif ($prefix eq 'SPACE') {
                    print_space();
                }
                print_token();
                $last_word = $token_text;
                if ($token_text eq 'var') {
                    $var_line         = 1;
                    $var_line_tainted = 0;
                }
                if ($token_text eq 'if' || $token_text eq 'else' || $token_text eq 'elsif') {
                    $if_line_flag = 1;
                }
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_SEMICOLON') {
                print_token();
                $var_line       = 0;
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_STRING') {
                if ($last_type eq 'TK_START_BLOCK' || $last_type eq 'TK_END_BLOCK' || $last_type eq 'TK_SEMICOLON') {
                    print_newline();
                }
                elsif ($last_type eq 'TK_WORD') {
                    print_space();
                }
                print_token();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_OPERATOR') {
                my $start_delim = 1;
                my $end_delim   = 1;
                if ($var_line && $token_text ne ',') {
                    $var_line_tainted = 1;
                    if ($token_text eq ':') {
                        $var_line = 0;
                    }
                }
                if ($var_line && $token_text eq ',' && is_expression($current_mode)) {

                    # do not break on comma, for(var a = 1, b = 2)
                    $var_line_tainted = 0;
                }
                if ($token_text eq ':' && $in_case) {
                    print_token();    # colon really asks for separate treatment
                    print_newline();
                    $in_case        = 0;
                    $last_last_text = $last_text;
                    $last_type      = $token_type;
                    $last_text      = $token_text;
                    next;
                }
                if ($token_text eq '::') {

                    # no spaces around exotic namespacing syntax operator
                    print_token();
                    $last_last_text = $last_text;
                    $last_type      = $token_type;
                    $last_text      = $token_text;
                    next;
                }

                if ($token_text eq ',') {
                    if ($var_line) {
                        if ($var_line_tainted) {
                            print_token();
                            print_newline();
                            $var_line_tainted = 0;
                        }
                        else {
                            print_token();
                            print_space();
                        }
                    }
                    elsif ($last_type eq 'TK_END_BLOCK') {
                        print_token();
                        print_newline();
                    }
                    else {
                        if ($current_mode eq 'BLOCK') {
                            print_token();

                            # print_newline();
                        }
                        else {
                            # EXPR or DO_BLOCK
                            print_token();
                            print_space();
                        }
                    }
                    $last_last_text = $last_text;
                    $last_type      = $token_type;
                    $last_text      = $token_text;
                    next;
                }
                elsif (   $token_text eq '--'
                       || $token_text eq '++'
                       || $token_text eq '&'
                       || $token_text eq '\\'
                       || $token_text eq '*'
                       || $token_text eq '/'
                       || $token_text eq '%') {
                    if ($last_text eq ';') {
                        if ($current_mode eq 'BLOCK') {

                            # { foo; --i }
                            print_newline();
                            $start_delim = 1;
                            $end_delim   = 0;
                        }
                        else {
                            # space for (;; ++i)
                            $start_delim = 1;
                            $end_delim   = 0;
                        }
                    }
                    else {
                        if ($last_text eq '{') {

                            # {--i
                            print_newline();
                        }
                        $start_delim = 0;
                        $end_delim   = 0;
                    }
                }

                #  elsif (($token_text eq '!' || $token_text eq '+' || $token_text eq '-')) {
                #     $start_delim = 0;
                #       $end_delim   = 0;
                #   }
                elsif (($token_text eq '!' || $token_text eq '+' || $token_text eq '-') && $last_type eq 'TK_START_EXPR') {

                    # special case handling: if (!a)
                    $start_delim = 0;
                    $end_delim   = 0;
                }
                elsif ($last_type eq 'TK_OPERATOR') {
                    $start_delim = 0;
                    $end_delim   = 0;
                }
                elsif ($last_type eq 'TK_END_EXPR') {
                    $start_delim = 1;
                    $end_delim   = 1;
                }
                elsif ($token_text eq '.') {

                    # decimal digits or object.property
                    $start_delim = 0;
                    $end_delim   = 0;
                }
                elsif ($token_text eq ':') {
                    if (is_ternary_op()) {
                        $start_delim = 1;
                    }
                    else {
                        $start_delim = 0;
                    }
                }
                if ($start_delim) {
                    print_space();
                }
                print_token();
                if ($end_delim) {
                    print_space();
                }
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_BLOCK_COMMENT') {
                print_newline();
                print_token();
                print_newline();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_COMMENT') {

                print_newline();
                print_space();
                print_token();
                print_newline();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            elsif ($token_type eq 'TK_UNKNOWN') {
                print_token();
                $last_last_text = $last_text;
                $last_type      = $token_type;
                $last_text      = $token_text;
                next;
            }
            $last_type = $token_type;
            $last_text = $token_text;
        }

        my $output = join('', @output);
        $output =~ s/\n+$//;
        return $output;
    }

    sub trim_output {
        while (scalar @output && ($output[scalar @output - 1] eq ' ' || $output[scalar @output - 1] eq $indent_string)) {
            pop @output;
        }
    }

    sub print_newline {
        my ($ignore_repeated) = @_;
        $ignore_repeated = 1 unless defined $ignore_repeated;
        $if_line_flag = 0;
        trim_output();

        if (not scalar @output) {
            return;    # no newline on start of file
        }

        if ($output[scalar @output - 1] ne "\n" || !$ignore_repeated) {
            $just_added_newline = 1;
            push @output, "\n";
        }
        foreach my $i (0 .. $opt_indent_level - 1) {
            push @output, $indent_string;
        }
    }

    sub print_space {
        my $last_output = ' ';
        $last_output = $output[scalar @output - 1] if scalar @output;
        if ($last_output ne ' ' && $last_output ne "\n" && $last_output ne $indent_string)
        {    # prevent occassional duplicate space
            push @output, ' ';
        }
    }

    sub print_token {
        $just_added_newline = 0;
        push @output, $token_text;
    }

    sub indent {
        $opt_indent_level++;
    }

    sub unindent {
        if ($opt_indent_level) {
            $opt_indent_level--;
        }
    }

    sub remove_indent {
        if (scalar @output && $output[scalar @output - 1] eq $indent_string) {
            pop @output;
        }
    }

    sub set_mode {
        my $mode = shift;
        push @modes, $current_mode;
        $current_mode = $mode;
    }

    sub is_expression {
        my $mode = shift;
        return ($mode eq '[EXPRESSION]' || $mode eq '[INDENTED-EXPRESSION]' || $mode eq '(EXPRESSION)') ? 1 : 0;
    }

    sub restore_mode {
        $do_block_just_closed = ($current_mode eq 'DO_BLOCK') ? 1 : 0;
        $current_mode = pop @modes;
    }

    # Walk backwards from the colon to find a '?' (colon is part of a ternary op)
    # or a '{' (colon is part of a class literal). Along the way, keep track of
    # the blocks and expressions we pass so we only trigger on those chars in our
    # own level, and keep track of the colons so we only trigger on the matching '?'.
    sub is_ternary_op {
        my $level       = 0;
        my $colon_count = 0;
        foreach my $o (reverse @output) {
            if ($o eq ':') {
                if ($level == 0) {
                    $colon_count++;
                }
                next;
            }
            elsif ($o eq '?') {
                if ($level == 0) {
                    if ($colon_count == 0) {
                        return 1;
                    }
                    else {
                        $colon_count--;
                    }
                }
                next;
            }
            elsif ($o eq '{') {
                if ($level == 0) {
                    return 0;
                }
                $level--;
                next;
            }
            if ($o eq '(' or $o eq '[') {
                $level--;
                next;
            }
            elsif ($o eq ')' or $o eq ']' or $o eq '}') {
                $level++;
                next;
            }
        }
    }

    sub get_next_token {
        my $n_newlines = 0;

        if ($parser_pos >= scalar @input) {
            return ['', 'TK_EOF'];
        }

        my $c = $input[$parser_pos];
        $parser_pos++;

        while (grep { $_ eq $c } @whitespace) {
            if ($parser_pos >= scalar @input) {
                return ['', 'TK_EOF'];
            }
            if ($c eq "\n") {
                $n_newlines += 1;
            }
            $c = $input[$parser_pos];
            $parser_pos++;
        }
        $wanted_newline = 0;
        if ($opt_preserve_newlines) {
            if ($n_newlines > 1) {
                foreach my $i (0 .. 1) {
                    my $flag = ($i == 0) ? 1 : 0;
                    print_newline($flag);
                }
            }
            $wanted_newline = ($n_newlines == 1) ? 1 : 0;
        }
        if (grep { $c eq $_ } @wordchar) {
            if ($parser_pos < scalar @input) {
                while (grep { $input[$parser_pos] eq $_ } @wordchar) {
                    $c .= $input[$parser_pos];
                    $parser_pos++;
                    if ($parser_pos == scalar @input) {
                        last;
                    }
                }
            }

            # small and surprisingly unugly hack for 1E-10 representation
            if (   $parser_pos != scalar @input
                && $c =~ /^[0-9]+[Ee]$/
                && ($input[$parser_pos] eq '-' || $input[$parser_pos] eq '+')) {
                my $sign = $input[$parser_pos];
                $parser_pos++;
                my $t = get_next_token($parser_pos);
                $c .= $sign . $t->[0];
                return [$c, 'TK_WORD'];
            }
            if ($wanted_newline && $last_type ne 'TK_OPERATOR' && not $if_line_flag) {
                print_newline();
            }
            return [$c, 'TK_WORD'];
        }
        if ($c eq '(' || $c eq '[') {
            return [$c, 'TK_START_EXPR'];
        }
        if ($c eq ')' || $c eq ']') {
            return [$c, 'TK_END_EXPR'];
        }
        if ($c eq '{') {
            return [$c, 'TK_START_BLOCK'];
        }
        if ($c eq '}') {
            return [$c, 'TK_END_BLOCK'];
        }
        if ($c eq ';') {
            return [$c, 'TK_SEMICOLON'];
        }
        if ($c eq '#') {
            my $comment = $c;
            while ($input[$parser_pos] ne "\x0d" && $input[$parser_pos] ne "\x0a") {
                $comment .= $input[$parser_pos];
                $parser_pos++;
                if ($parser_pos >= scalar @input) {
                    last;
                }
            }
            $parser_pos++;
            if ($wanted_newline) {
                print_newline();
            }
            return [$comment, 'TK_COMMENT'];
        }
        if ($c eq '/') {
            my $comment;

            # peek for comment /* ... */
            if ($input[$parser_pos] eq '*') {
                $parser_pos++;
                if ($parser_pos < scalar @input) {
                    while (not($input[$parser_pos] eq '*' && $input[$parser_pos + 1] && $input[$parser_pos + 1] eq '/')
                           && $parser_pos < scalar @input) {
                        $comment .= $input[$parser_pos];
                        $parser_pos++;
                        if ($parser_pos >= scalar @input) {
                            last;
                        }
                    }
                }
                $parser_pos += 2;
                return ['/*' . $comment . '*/', 'TK_BLOCK_COMMENT'];
            }
        }
        if (
            $c eq "'" ||    # string
            $c eq '"' ||    # string
            (
             $c eq '/'
             && (
                 ($last_type eq 'TK_WORD' && $last_text eq 'return')
                 || (   $last_type eq 'TK_START_EXPR'
                     || $last_type eq 'TK_START_BLOCK'
                     || $last_type eq 'TK_END_BLOCK'
                     || $last_type eq 'TK_OPERATOR'
                     || $last_type eq 'TK_EOF'
                     || $last_type eq 'TK_SEMICOLON')
                )
            )
          ) {    # regexp
            my $sep              = $c;
            my $esc              = 0;
            my $resulting_string = $c;
            if ($parser_pos < scalar @input) {
                if ($sep eq '/') {

                    # handle regexp separately...
                    my $in_char_class = 0;
                    while ($esc || $in_char_class || $input[$parser_pos] ne $sep) {
                        $resulting_string .= $input[$parser_pos];
                        if (not $esc) {
                            $esc = ($input[$parser_pos] eq '\\') ? 1 : 0;
                            if ($input[$parser_pos] eq '[') {
                                $in_char_class = 1;
                            }
                            elsif ($input[$parser_pos] eq ']') {
                                $in_char_class = 0;
                            }
                        }
                        else {
                            $esc = 0;
                        }
                        $parser_pos++;
                        if ($parser_pos >= scalar @input) {

                            # incomplete string/rexp when end-of-file reached.
                            # bail out with what had been received so far.
                            return [$resulting_string, 'TK_STRING'];
                        }
                    }

                }
                else {
                    # and handle string also separately
                    while ($esc || $input[$parser_pos] ne $sep) {
                        $resulting_string .= $input[$parser_pos];
                        if (not $esc) {
                            $esc = ($input[$parser_pos] eq '\\') ? 1 : 0;
                        }
                        else {
                            $esc = 0;
                        }
                        $parser_pos++;
                        if ($parser_pos >= scalar @input) {

                            # incomplete string/rexp when end-of-file reached.
                            # bail out with what had been received so far.
                            return [$resulting_string, 'TK_STRING'];
                        }
                    }
                }
            }
            $parser_pos++;
            $resulting_string .= $sep;
            if ($sep eq '/') {

                # regexps may have modifiers /regexp/MOD , so fetch those, too
                while ($parser_pos < scalar @input && (grep { $input[$parser_pos] eq $_ } @wordchar)) {
                    $resulting_string .= $input[$parser_pos];
                    $parser_pos++;
                }
            }
            return [$resulting_string, 'TK_STRING'];
        }

        if (grep { $c eq $_ } @punct) {
            while ($parser_pos < scalar @input && (grep { $c . $input[$parser_pos] eq $_ } @punct)) {
                $c .= $input[$parser_pos];
                $parser_pos++;
                last if ($parser_pos >= scalar @input);
            }
            return [$c, 'TK_OPERATOR'];
        }
        return [$c, 'TK_UNKNOWN'];
    }
}

1;
__END__

=head1 NAME

Sidef::Tidy - Sidef beautifier

=head1 SYNOPSIS

    use Sidef::Tidy qw/sf_beautify/;

    my $pretty_sf = sf_beautify( $sf_source_code, {
        indent_size => 4,
        indent_character => ' ',
    } );

=head1 DESCRIPTION

This module is mostly a Perl-rewrite of L<http://github.com/einars/js-beautify/tree/master/beautify.js>

You can check it through L<http://jsbeautifier.org/>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
