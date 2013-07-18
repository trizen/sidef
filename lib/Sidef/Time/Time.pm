package Sidef::Time::Time {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, $sec) = @_;

        if (ref($sec)) {

            if (ref($sec) ne 'Sidef::Types::Number::Number') {
                warn "[WARN] Time.new(): invalid argument: not a number!\n";
                return;
            }

            $sec = $$sec;
        }

        $sec //= time;

        bless {sec => $sec}, __PACKAGE__;
    }

    sub time {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($self->{sec});
    }

    sub timeNow {
        Sidef::Types::Number::Number->new(CORE::time);
    }

    *time_now = \&timeNow;

    sub localtime {
        my ($self) = @_;
        Sidef::Time::Localtime->new($self->{sec});
    }

    *local     = \&localtime;
    *localTime = \&localtime;

    sub gmtime {
        my ($self) = @_;
        Sidef::Time::Gmtime->new($self->{sec});
    }

    *gm     = \&gmtime;
    *gmTime = \&gmtime;

};

1;
