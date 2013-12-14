package Sidef::Time::Time {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        my (undef, $sec) = @_;

        if (defined($sec)) {
            if ((my $ref = ref($sec)) ne '') {
                if ($ref eq 'Sidef::Types::Number::Number') {
                    $sec = $sec->get_value;
                }
                else {
                    warn "[WARN] Time.new(): invalid argument: expected a number, but got '", ref($sec), "'\n";
                    return;
                }
            }
            elsif ($sec eq '__INIT__') {
                undef $sec;
            }
        }
        else {
            $sec = time;
        }

        bless \$sec, __PACKAGE__;
    }

    sub get_value {
        ${$_[0]} // CORE::time;
    }

    sub time {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($self->get_value);
    }

    sub timeNow {
        Sidef::Types::Number::Number->new(CORE::time);
    }

    *now      = \&timeNow;
    *time_now = \&timeNow;

    sub microTime {
        my ($self) = @_;
        require Time::HiRes;
        Sidef::Types::Number::Number->new(scalar Time::HiRes::gettimeofday());
    }

    *micro         = \&microTime;
    *micro_sec     = \&microTime;
    *microSec      = \&microTime;
    *microSeconds  = \&microTime;
    *micro_seconds = \&microTime;

    sub localtime {
        my ($self) = @_;
        Sidef::Time::Localtime->new($self->get_value);
    }

    *local     = \&localtime;
    *localTime = \&localtime;

    sub gmtime {
        my ($self) = @_;
        Sidef::Time::Gmtime->new($self->get_value);
    }

    *gmTime = \&gmtime;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Time.new(' . $$self . ')');
    }

};

1;
