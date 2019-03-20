package Sidef::Sys::Sig {

    use utf8;
    use 5.016;

    sub new {
        bless {}, __PACKAGE__;
    }

    {
        no strict 'refs';
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
