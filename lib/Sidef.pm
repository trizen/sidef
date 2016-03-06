package Sidef {

    use 5.014;
    our $VERSION = '2.23';

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

        $type;
    }

    sub normalize_method {
        my ($type, $method) = ($_[0] =~ /^(.*[^:])::(.*)$/);
        normalize_type($type) . ".$method";
    }

    require List::Util;

    sub jaro {
        my ($s, $t) = @_;

        my $len1 = length($s);
        my $len2 = length($t);

        ($s, $len1, $t, $len2) = ($t, $len2, $s, $len1)
          if $len1 > $len2;

        $len1 || return 0;

        my $match_window = $len2 > 3 ? int($len2 / 2) - 1 : 0;

        my @s_matches;
        my @t_matches;

        my @s = split(//, $s);
        my @t = split(//, $t);

        foreach my $i (0 .. $#s) {

            my $window_start = List::Util::max(0, $i - $match_window);
            my $window_end = List::Util::min($i + $match_window + 1, $len2);

            foreach my $j ($window_start .. $window_end - 1) {
                if (not exists($t_matches[$j]) and $s[$i] eq $t[$j]) {
                    $s_matches[$i] = $s[$i];
                    $t_matches[$j] = $t[$j];
                    last;
                }
            }
        }

        (@s_matches = grep { defined } @s_matches) || return 0;
        @t_matches = grep { defined } @t_matches;

        my $transpositions = 0;
        foreach my $i (0 .. $#s_matches) {
            $s_matches[$i] eq $t_matches[$i] or ++$transpositions;
        }

        my $num_matches = @s_matches;
        (($num_matches / $len1) + ($num_matches / $len2) + ($num_matches - int($transpositions / 2)) / $num_matches) / 3;
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

    my $max = 0;
    my @candidates;
    foreach my $meth (@methods) {
        my $dist = sprintf("%.4f", Sidef::jaro_winkler($meth, $name));
        $dist >= 0.8 or next;
        if ($dist > $max) {
            $max        = $dist;
            @candidates = ();
        }
        push(@candidates, $meth) if $dist == $max;
    }

    die(  "[AUTOLOAD] Undefined method `"
        . $method . q{'}
        . " called from $from\n"
        . (@candidates ? ("[?] Did you mean: " . join("\n" . (' ' x 18), sort @candidates) . "\n") : ''));
    return;
};

1;
