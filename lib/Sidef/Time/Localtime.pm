package Sidef::Time::Localtime {

    use 5.014;
    use strict;
    use warnings;

    our @ISA = qw(Sidef);

    sub new {
        my (undef, $sec) = @_;

        bless {
               sec  => $sec,
               time => [map { Sidef::Types::Number::Number->new($_) } localtime($sec)],
              },
          __PACKAGE__;
    }

    {
        # The order matters!
        my @names = qw(sec min hour mday mon year wday yday isdst);

        no strict 'refs';
        foreach my $i (0 .. $#names) {
            *{__PACKAGE__ . '::' . $names[$i]} = sub {
                $_[0]{time}[$i];
            };
        }

        *day   = \&mday;
        *month = \&mon;
    }

    sub ctime {
        my ($self) = @_;
        Sidef::Types::String::String->new(scalar localtime($self->{sec}));
    }

    *strftime = \&{Sidef::Time::Gmtime::strftime};
};

1;
