package Sidef::Time::Date;

use utf8;
use 5.016;
use parent qw(
  Sidef::Object::Object
);

require Time::Piece;

use overload
  q{""}   => \&ctime,
  q{0+}   => sub { $_[0]->{time}->epoch },
  q{bool} => sub { $_[0]->{time} };

use Sidef::Types::String::String;
use Sidef::Types::Number::Number;

my @_DATE_AUTO_FORMATS = ('%Y-%m-%d %H:%M:%S', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d', '%Y/%m/%d', '%d-%m-%Y', '%m/%d/%Y',);

sub _parse_auto {
    my ($str) = @_;
    foreach my $format (@_DATE_AUTO_FORMATS) {
        my $t = eval { Time::Piece->strptime($str, $format) };
        defined($t) and return $t;
    }

    my $tried = join(', ', @_DATE_AUTO_FORMATS);
    die "[ERROR] Date: unable to parse date string '$str' (tried: $tried)\n";
}

sub new {
    my (undef, @args) = @_;

    # No arguments: current moment
    if (!@args) {
        return bless {time => Time::Piece->new(CORE::time)};
    }

    # Single argument: epoch seconds, a Date to copy, or a date string to auto-parse
    if (@args == 1) {
        my ($arg) = @args;

        if (ref($arg) eq __PACKAGE__) {
            return bless {time => Time::Piece->new($arg->{time}->epoch)};
        }

        if (ref($arg) eq 'Sidef::Types::Number::Number' or (ref($arg) eq '' and $arg =~ /^[0-9]+\z/)) {
            return bless {time => Time::Piece->new(CORE::int($arg))};
        }

        return bless {time => _parse_auto("$arg")};
    }

    # Two or more arguments: calendar components
    __PACKAGE__->from_ymd(@args);
}

*call = \&new;

sub from_ymd {
    my (undef, $year, $month, $day, $hour, $min, $sec) = @_;

    # Safely pad missing components to their POD-specified defaults
    my $str = CORE::sprintf(
                            '%04d-%02d-%02d %02d:%02d:%02d',
                            CORE::int($year  // 0),
                            CORE::int($month // 1),
                            CORE::int($day   // 1),
                            CORE::int($hour  // 0),
                            CORE::int($min   // 0),
                            CORE::int($sec   // 0)
                           );

    bless {time => Time::Piece->strptime($str, '%Y-%m-%d %H:%M:%S')};
}

sub from_string {
    my (undef, $str, $format) = @_;

    defined($format)
      ? (bless {time => Time::Piece->strptime("$str", "$format")})
      : (bless {time => _parse_auto("$str")});
}

sub get_value {
    $_[0]->{time} // Time::Piece->new(CORE::time);
}

{
    no strict 'refs';

    foreach my $name (qw(sec min hour mon year yy epoch wday mday yday isdst julian_day week month_last_day)) {
        *{__PACKAGE__ . '::' . $name} = sub {
            my ($self) = @_;
            Sidef::Types::Number::Number->new($self->{time}->$name);
        };
    }

    *day              = \&mday;
    *month            = \&mon;
    *minute           = \&min;
    *second           = \&sec;
    *month_day        = \&mday;
    *week_day         = \&wday;
    *year_day         = \&yday;
    *is_dst           = \&isdst;
    *daylight_savings = \&isdst;

    foreach my $name (qw(monname fullmonth wdayname date)) {
        *{__PACKAGE__ . '::' . $name} = sub {
            my ($self) = @_;
            Sidef::Types::String::String->new($self->{time}->$name);
        };
    }

    foreach my $name (qw(ymd mdy dmy)) {
        *{__PACKAGE__ . '::' . $name} = sub {
            my ($self, $sep) = @_;
            Sidef::Types::String::String->new($self->{time}->$name(defined($sep) ? "$sep" : ()));
        };
    }

    foreach my $name ("year", "quarter", "month", "day", "hour", "minute", "second") {
        *{__PACKAGE__ . '::' . "truncate_to_" . $name} = sub {
            my ($self) = @_;
            bless {time => scalar $self->{time}->truncate(to => $name)};
        };
    }
}

sub today {
    __PACKAGE__->new(time);
}

*now = \&today;

sub time {
    my ($self) = @_;
    Sidef::Time::Time->new(scalar $self->{time}->epoch);
}

sub localtime {
    my ($self, $sec) = @_;
    $sec //= $self->{time}->epoch;
    bless {time => scalar Time::Piece::localtime($sec)};
}

*local = \&localtime;

sub gmtime {
    my ($self, $sec) = @_;
    $sec //= $self->{time}->epoch;
    bless {time => scalar Time::Piece::gmtime($sec)};
}

*gmt = \&gmtime;

sub ctime {
    my ($self) = @_;
    Sidef::Types::String::String->new(scalar $self->{time}->cdate);
}

*to_s   = \&ctime;
*to_str = \&ctime;
*cdate  = \&ctime;

sub strftime {
    my ($self, $format) = @_;
    Sidef::Types::String::String->new(scalar $self->{time}->strftime("$format"));
}

*format = \&strftime;

sub strptime {
    my ($self, $string, $format) = @_;
    __PACKAGE__->new(Time::Piece->strptime("$string", "$format")->epoch);
}

*parse = \&strptime;

sub valid_date {
    my ($self, $string, $format) = @_;

    $format = "$format";
    $string = "$string";

    eval { Time::Piece->strptime($string, $format)->strftime($format) eq $string }
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

*valid = \&valid_date;

sub add_seconds {
    my ($self, $sec) = @_;
    bless {time => scalar $self->{time}->add(CORE::int($sec))};
}

*add = \&add_seconds;

sub subtract {
    my ($this, $that) = @_;

    if (ref($that) eq __PACKAGE__) {
        return Sidef::Types::Number::Number->new(scalar $this->{time}->subtract($that->{time}));
    }

    bless {time => scalar $this->{time}->subtract(CORE::int($that))};
}

*sub = \&subtract;

sub add_days {
    my ($self, $days) = @_;
    $self->add_seconds(86400 * CORE::int($days));
}

sub add_weeks {
    my ($self, $weeks) = @_;
    $self->add_days(7 * CORE::int($weeks));
}

sub add_months {
    my ($self, $months) = @_;
    bless {time => scalar $self->{time}->add_months(CORE::int($months))};
}

sub add_years {
    my ($self, $years) = @_;
    bless {time => scalar $self->{time}->add_years(CORE::int($years))};
}

sub is_today {
    my ($self) = @_;
    my $today = __PACKAGE__->today;
    ($self->{time}->ymd eq $today->{time}->ymd)
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub is_leap_year {
    my ($self) = @_;
    my $y = $self->{time}->year;
    (($y % 4 == 0 and $y % 100 != 0) or $y % 400 == 0)
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub is_weekend {
    my ($self) = @_;
    my $wday = $self->{time}->wday;
    ($wday == 1 or $wday == 7)    # 1 = Sunday, 7 = Saturday
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub is_weekday {
    my ($self) = @_;
    my $wday = $self->{time}->wday;
    ($wday == 1 or $wday == 7)
      ? Sidef::Types::Bool::Bool::FALSE
      : Sidef::Types::Bool::Bool::TRUE;
}

sub is_future {
    my ($self) = @_;
    ($self->{time}->epoch > CORE::time)
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub is_past {
    my ($self) = @_;
    ($self->{time}->epoch < CORE::time)
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub is_between {
    my ($self, $start, $end) = @_;
    ($self->{time}->epoch >= $start->{time}->epoch and $self->{time}->epoch <= $end->{time}->epoch)
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub days_until {
    my ($self, $other) = @_;
    state $day_sec = Sidef::Types::Number::Number::_set_int(86400);
    Sidef::Types::Number::Number->new($self->{time}->subtract($other->{time}))->div($day_sec)->int->neg;
}

sub is_same_day {
    my ($self, $other) = @_;
    ($self->{time}->ymd eq $other->{time}->ymd)
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub end_of_month {
    my ($self) = @_;
    my $last_day = $self->{time}->month_last_day;
    bless {time => scalar $self->{time}->truncate(to => 'day')->add(($last_day - $self->{time}->mday) * 86400)};
}

sub age {
    my ($self) = @_;
    my $now    = Time::Piece->new(CORE::time);
    my $years  = $now->year - $self->{time}->year;
    if ($now->mon < $self->{time}->mon
        or ($now->mon == $self->{time}->mon and $now->mday < $self->{time}->mday)) {
        --$years;
    }
    Sidef::Types::Number::Number::_set_int($years);
}

sub quarter {
    my ($self) = @_;
    Sidef::Types::Number::Number::_set_int(CORE::int(($self->{time}->mon - 1) / 3) + 1);
}

sub cmp {
    my ($this, $that) = @_;
    Sidef::Types::Number::Number::_set_int(CORE::int($this) <=> CORE::int($that));
}

sub eq {
    my ($this, $that) = @_;
    (CORE::int($this) <=> CORE::int($that)) == 0
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub ne {
    my ($this, $that) = @_;
    (CORE::int($this) <=> CORE::int($that)) != 0
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub lt {
    my ($this, $that) = @_;
    (CORE::int($this) <=> CORE::int($that)) < 0
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub le {
    my ($this, $that) = @_;
    (CORE::int($this) <=> CORE::int($that)) <= 0
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub gt {
    my ($this, $that) = @_;
    (CORE::int($this) <=> CORE::int($that)) > 0
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub ge {
    my ($this, $that) = @_;
    (CORE::int($this) <=> CORE::int($that)) >= 0
      ? Sidef::Types::Bool::Bool::TRUE
      : Sidef::Types::Bool::Bool::FALSE;
}

sub dump {
    my ($self) = @_;
    Sidef::Types::String::String->new('Date(' . CORE::int($self) . ')');
}

{
    no strict 'refs';

    *{__PACKAGE__ . '::' . '+'}   = \&add;
    *{__PACKAGE__ . '::' . '-'}   = \&subtract;
    *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
    *{__PACKAGE__ . '::' . '=='}  = \&eq;
    *{__PACKAGE__ . '::' . '!='}  = \&ne;
    *{__PACKAGE__ . '::' . '<'}   = \&lt;
    *{__PACKAGE__ . '::' . '>'}   = \&gt;
    *{__PACKAGE__ . '::' . '<='}  = \&le;
    *{__PACKAGE__ . '::' . '>='}  = \&ge;
}

1
