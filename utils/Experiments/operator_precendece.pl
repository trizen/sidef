#!/usr/bin/perl

# Experimental operator-precedence support

# 1. Rename the sub "parse_obj" to "parse_group" inside the parser.
# 2. Copy-pase this code inside the parser.

sub level_0 {
    my ($self, %opt) = @_;

    (($self->parse_whitespace(code => $opt{code}))[1] || /\G(?=;|->)/) && return $opt{obj};
    local *_ = $opt{code};

    my %struct = (
                  $self->{class} => [
                                     {
                                      self => $opt{obj}
                                     }
                                    ]
                 );

    if (/\G(\*\*)/gc) {
        my $operator = $1;
        my $obj = $self->parse_group(code => $opt{code});
        push @{$struct{$self->{class}}[-1]{call}},
          {method => $operator, arg => [$self->level_0(obj => $obj, code => $opt{code}) // $obj]};
        return \%struct;
    }

    return;
}

sub level_1 {
    my ($self, %opt) = @_;

    (($self->parse_whitespace(code => $opt{code}))[1] || /\G(?=;|->)/) && return $opt{obj};
    local *_ = $opt{code};

    my %struct = (
                  $self->{class} => [
                                     {
                                      self => $opt{obj}
                                     }
                                    ]
                 );

    my $match;
    while (/\G(\*|\/)/gc) {
        my $operator = $1;
        my $obj = $self->parse_group(code => $opt{code});
        push @{$struct{$self->{class}}[-1]{call}},
          {method => $operator, arg => [$self->level_0(obj => $obj, code => $opt{code}) // $obj]};
        $match //= 1;
    }

    $match ? \%struct : undef;
}

sub level_2 {
    my ($self, %opt) = @_;

    (($self->parse_whitespace(code => $opt{code}))[1] || /\G(?=;|->)/) && return $opt{obj};
    local *_ = $opt{code};

    my %struct = (
                  $self->{class} => [
                                     {
                                      self => $opt{obj}
                                     }
                                    ]
                 );

    my $match;
    while (/\G(\+|-)/gc) {
        my $operator = $1;
        my $obj = $self->parse_group(code => $opt{code});
        push @{$struct{$self->{class}}[-1]{call}},
          {
            method => $operator,
            arg => [$self->level_0(obj => $obj, code => $opt{code}) // $self->level_1(obj => $obj, code => $opt{code}) // $obj]
          };
        $match //= 1;
    }

    $match ? \%struct : undef;
}

sub parse_obj {
    my ($self, %opt) = @_;

    my $obj = $self->parse_group(code => $opt{code}) // return;

    local *_ = $opt{code};
    (($self->parse_whitespace(code => $opt{code}))[1] || /\G(?=;|->)/) && return $obj;

    return ($self->level_0(obj => $obj, code => $opt{code}) // $self->level_1(obj => $obj, code => $opt{code})
            // $self->level_2(obj => $obj, code => $opt{code}) // $obj);

    return $obj;
}

__END__
say (2 + 2 ** 3 + 2);   # 12
say (2 ** 3 + 2);       # 10
say (2 + 2 * 3 + 2);    # 10
say (2 ** 3 ** 4 * 2);  # 4835703278458516698824704
say (2 + 4 - 1);        # 5
say (4 * 3 / 2);        # 6
say (4 / 3 * 2);        # 2.66666
say (12 / 4 * 2);       # 6

say (12 + 3 * 2);       # 18
say (1+2 * 3+4);        # 21 or 11

say (1 + ++2);          # 4
