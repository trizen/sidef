package Sidef::Time::Time {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      Sidef::Convert::Convert
      );

    use overload
      q{""}   => \&get_value,
      q{bool} => \&get_value;

    sub new {
        my (undef, $sec) = @_;

        if (defined($sec)) {
            if (ref($sec)) {
                $sec = $sec->get_value;
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

    *call = \&new;

    sub get_value {
        ${$_[0]} // CORE::time;
    }

    sub time {
        my ($self) = @_;
        Sidef::Types::Number::Number->new($self->get_value);
    }

    *sec = \&time;

    sub timeNow {
        Sidef::Types::Number::Number->new(CORE::time);
    }

    *now      = \&timeNow;
    *time_now = \&timeNow;

    sub microTime {
        my ($self) = @_;
        state $x = require Time::HiRes;
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
        Sidef::Types::String::String->new('Time.new(' . $self->get_value . ')');
    }

};

1;
