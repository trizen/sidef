package Sidef::Math::Math {

    use utf8;
    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use Sidef::Types::Number::Number;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub get_constant {
        my ($self, $name) = @_;

        state %cache;
        state $table = {
                        "e"       => sub { Sidef::Types::Number::Number->e },
                        "pi"      => sub { Sidef::Types::Number::Number->pi },
                        "PI"      => sub { Sidef::Types::Number::Number->pi },
                        "π"      => sub { Sidef::Types::Number::Number->pi },
                        "tau"     => sub { Sidef::Types::Number::Number->tau },
                        "τ"      => sub { Sidef::Types::Number::Number->tau },
                        "phi"     => sub { Sidef::Types::Number::Number->phi },
                        "Φ"      => sub { Sidef::Types::Number::Number->phi },
                        "ln2"     => sub { Sidef::Types::Number::Number->ln2 },
                        "G"       => sub { Sidef::Types::Number::Number->G },
                        "Y"       => sub { Sidef::Types::Number::Number->Y },
                        "γ"      => sub { Sidef::Types::Number::Number->Y },
                        "catalan" => sub { Sidef::Types::Number::Number->G },
                        "euler"   => sub { Sidef::Types::Number::Number->Y },
                       };

        my $key = "$name";
        $cache{$key} //= exists($table->{$key}) ? $table->{$key}->() : do {
            die qq{[ERROR] Inexistent Math constant "$name"!\n};
        };
    }

    sub gcd {
        my ($self, @list) = @_;

        my $gcd = $list[0];
        foreach my $i (1 .. $#list) {
            last if ($gcd->is_one);
            $gcd = $gcd->gcd($list[$i]);
        }

        $gcd;
    }

    sub lcm {
        my ($self, @list) = @_;

        my $lcm = $list[0];
        foreach my $i (1 .. $#list) {
            $lcm = $lcm->lcm($list[$i]);
        }

        $lcm;
    }

    sub sum {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::_new_int(0);
        foreach my $n (@list) {
            $sum = $sum->add($n);
        }

        $sum;
    }

    sub max {
        my ($self, @list) = @_;

        my $max = $list[0];
        foreach my $i (1 .. $#list) {
            $max = $max->max($list[$i]);
        }

        $max;
    }

    sub min {
        my ($self, @list) = @_;

        my $min = $list[0];
        foreach my $i (1 .. $#list) {
            $min = $min->min($list[$i]);
        }

        $min;
    }

    sub avg {
        my ($self, @list) = @_;

        my $sum = Sidef::Types::Number::Number::_new_int(0);
        foreach my $n (@list) {
            $sum = $sum->add($n);
        }

        my $n = Sidef::Types::Number::Number->new(scalar(@list));
        $sum->div($n);
    }

    sub range_sum {
        my ($self, $from, $to, $step) = @_;
        $step //= Sidef::Types::Number::Number::ONE;
        state $two = Sidef::Types::Number::Number::_new_uint(2);
        ($from->add($to))->mul($to->sub($from)->div($step)->add(Sidef::Types::Number::Number::ONE))->div($two);
    }

    sub map {
        my ($self, $value, $in_min, $in_max, $out_min, $out_max) = @_;
        ($value->sub($in_min))->mul($out_max->sub($out_min))->div($in_max->sub($in_min))->add($out_min);
    }

    sub map_range {
        my ($self, $amount, $from, $to) = @_;
        Sidef::Types::Range::RangeNumber->new($from, $to, $to->sub($from)->div($amount),);
    }

    sub number_to_percentage {
        my ($self, $num, $from, $to) = @_;

        my $sum  = $to->sub($from)->abs;
        my $dist = $num->sub($to)->abs;

        state $hundred = Sidef::Types::Number::Number::_new_uint(100);
        ($sum->sub($dist))->div($sum)->mul($hundred);
    }

    *num2percent = \&number_to_percentage;

    our $AUTOLOAD;

    sub AUTOLOAD {
        my ($self, $x, @args) = @_;
        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        defined($x) ? $x->$method(@args) : 'Sidef::Types::Number::Number'->$method;
    }

}

1
