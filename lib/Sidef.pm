package Sidef {

    use 5.014;
    our $VERSION = '2.24';

    our $SPACES      = 0;    # the current number of spaces
    our $SPACES_INCR = 4;    # the number of spaces incrementor

    our @NAMESPACES;         # will keep track of declared modules
    our %INCLUDED;           # will keep track of included modules

    our %EVALS;              # will contain info required for eval()

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub normalize_type {
        my ($type) = @_;

        if (index($type, 'Sidef::') == 0) {
            $type = substr($type, rindex($type, '::') + 2);
        }
        else {
            $type =~ s/^(?:_::)?main:://
              or $type =~ s/^_:://;
        }

        $type =~ s/[0-9]{8,}\z//r;
    }

    sub normalize_method {
        my ($type, $method) = ($_[0] =~ /^(.*[^:])::(.*)$/);
        normalize_type($type) . ".$method";
    }

    require List::Util;

    sub jaro {
        my ($s, $t) = @_;

        my $s_len = length($s);
        my $t_len = length($t);

        my $match_distance = int(List::Util::max($s_len, $t_len) / 2) - 1;

        my @s_matches;
        my @t_matches;

        my @s = split(//, $s);
        my @t = split(//, $t);

        my $matches = 0;
        foreach my $i (0 .. $s_len - 1) {

            my $start = List::Util::max(0, $i - $match_distance);
            my $end = List::Util::min($i + $match_distance + 1, $t_len);

            foreach my $j ($start .. $end - 1) {
                $t_matches[$j] and next;
                $s[$i] eq $t[$j] or next;
                $s_matches[$i] = 1;
                $t_matches[$j] = 1;
                $matches++;
                last;
            }
        }

        return 0 if $matches == 0;

        my $k     = 0;
        my $trans = 0;

        foreach my $i (0 .. $s_len - 1) {
            $s_matches[$i] or next;
            until ($t_matches[$k]) { ++$k }
            $s[$i] eq $t[$k] or ++$trans;
            ++$k;
        }

#<<<
        (($matches / $s_len) + ($matches / $t_len)
            + (($matches - $trans / 2) / $matches)) / 3;
#>>>
    }

    sub jaro_winkler {
        my ($s, $t) = @_;

        my $distance = jaro($s, $t);

        my $prefix = 0;
        foreach my $i (0 .. List::Util::min(3, length($s), length($t))) {
            substr($s, $i, 1) eq substr($t, $i, 1) ? ++$prefix : last;
        }

        $distance + $prefix * 0.1 * (1 - $distance);
    }

    sub best_matches {
        my ($name, $set) = @_;

        my $max = 0;
        my @best;
        foreach my $elem (@$set) {
            my $dist = sprintf("%.4f", Sidef::jaro_winkler($elem, $name));
            $dist >= 0.8 or next;
            if ($dist > $max) {
                $max  = $dist;
                @best = ();
            }
            push(@best, $elem) if $dist == $max;
        }

        @best;
    }

};

#
## Some UNIVERSAL magic
#

*UNIVERSAL::get_value = sub {
    ref($_[0]) eq 'Sidef::Module::OO' || ref($_[0]) eq 'Sidef::Module::Func'
      ? $_[0]->{module}
      : $_[0];
};
*UNIVERSAL::DESTROY = sub { };
*UNIVERSAL::AUTOLOAD = sub {
    my ($self, @args) = @_;

    $self = ref($self) if ref($self);

    if (index($self, 'Sidef::') == 0 and index($self, 'Sidef::Runtime') != 0) {

        eval { require $self =~ s{::}{/}rg . '.pm' };

        if ($@) {
            if (defined &main::__load_sidef_module__) {
                main::__load_sidef_module__($self);
            }
            else {
                die "[AUTOLOAD] $@";
            }
        }

        if (defined(&$AUTOLOAD)) {
            return $AUTOLOAD->($self, @args);
        }
    }

    my @caller = caller(1);
    my $from   = Sidef::normalize_method($caller[3]);
    $from = $from eq '.' ? 'main()' : "$from()";

    my $table = \%{$self . '::'};
    my @methods = grep { !ref($table->{$_}) and defined(&{$table->{$_}}) } keys(%$table);

    my $method = Sidef::normalize_method($AUTOLOAD);
    my $name = substr($method, rindex($method, '.') + 1);

    my @candidates = Sidef::best_matches($name, \@methods);

    die(  "[AUTOLOAD] Undefined method `"
        . $method . q{'}
        . " called from $from\n"
        . (@candidates ? ("[?] Did you mean: " . join("\n" . (' ' x 18), sort @candidates) . "\n") : ''));
    return;
};

1;
