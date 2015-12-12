package Sidef::Sys::Sig {

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        foreach my $key (keys(%SIG), '__WARN__', '__DIE__') {
            *{__PACKAGE__ . '::' . $key} = sub {
                my (undef, $signal) = @_;

                if (ref $signal) {
                    return $SIG{$key} = $signal->get_value;
                }

                $SIG{$key};
            };
        }
    }

};

1
