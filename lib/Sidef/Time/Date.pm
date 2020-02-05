package Sidef::Time::Date {

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

    sub new {
        my (undef, $sec) = @_;

        if (defined $sec) {
            $sec = CORE::int($sec) if ref($sec);
        }
        else {
            $sec = CORE::time;
        }

        bless {time => Time::Piece->new($sec),};
    }

    *call = \&new;

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
        my ($self) = @_;
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

    sub add_months {
        my ($self, $months) = @_;
        bless {time => scalar $self->{time}->add_months(CORE::int($months))};
    }

    sub add_years {
        my ($self, $years) = @_;
        bless {time => scalar $self->{time}->add_years(CORE::int($years))};
    }

    sub cmp {
        my ($this, $that) = @_;
        Sidef::Types::Number::Number->new(CORE::int($this) <=> CORE::int($that));
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
};

1;
