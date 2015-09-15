package Sidef::Time::Gmtime {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    use overload
      q{""}   => \&ctime,
      q{bool} => sub { $_[0]->{sec} };

    sub new {
        my (undef, $sec) = @_;

        bless {
               sec  => $sec,
               time => [map { Sidef::Types::Number::Number->new($_) } gmtime($sec)],
              },
          __PACKAGE__;
    }

    {
        no strict 'refs';

        # The order matters!
        my @names = qw(sec min hour mday mon year wday yday);

        foreach my $i (0 .. $#names) {
            *{__PACKAGE__ . '::' . $names[$i]} = sub {
                $_[0]{time}[$i];
            };
        }

        *day       = \&mday;
        *month     = \&mon;
        *minute    = \&min;
        *second    = \&sec;
        *month_day = \&mday;
        *week_day  = \&wday;
        *year_day  = \&yday;
    }

    sub ctime {
        my ($self) = @_;
        Sidef::Types::String::String->new(scalar gmtime($self->{sec}));
    }

    sub strftime {
        my ($self, $format) = @_;

        state $x = require POSIX;
        Sidef::Types::String::String->new(POSIX::strftime($format->get_value, @{$self->{time}}));
    }

    *format = \&strftime;
    *strf   = \&strftime;

};

1;
