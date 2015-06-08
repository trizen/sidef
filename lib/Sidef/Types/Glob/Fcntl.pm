package Sidef::Types::Glob::Fcntl {

    use 5.014;
    our $AUTOLOAD;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub DESTROY { }

    {
        my %CACHE;

        sub AUTOLOAD {
            my ($self) = @_;

            my ($sub) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

            if (exists $CACHE{$sub}) {
                return $CACHE{$sub};
            }

            state $x = require Fcntl;
            my $call = \&{'Fcntl' . '::' . $sub};

            if (defined(&$call)) {
                return $CACHE{$sub} = Sidef::Types::Number::Number->new($call->());
            }

            warn qq{[WARN] Inexistent Fcntl method "$sub"!\n};
            return;
        }
    }

};

1
