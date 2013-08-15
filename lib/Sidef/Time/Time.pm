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

        bless \$sec, __PACKAGE__;
    }

    sub time {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($$self);
    }

    sub timeNow {
        Sidef::Types::Number::Number->new(CORE::time);
    }

    *now      = \&timeNow;
    *time_now = \&timeNow;

    sub localtime {
        my ($self) = @_;
        Sidef::Time::Localtime->new($$self);
    }

    *local     = \&localtime;
    *localTime = \&localtime;

    sub gmtime {
        my ($self) = @_;
        Sidef::Time::Gmtime->new($$self);
    }

    *gmTime = \&gmtime;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Time.new(' . $$self . ')');
    }

};

1;
