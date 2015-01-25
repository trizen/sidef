package Sidef::Module::Require {

    use 5.014;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub require {
        my ($self, $module) = @_;

        my $module_name = $module->get_value;
        ($module = $module_name . '.pm') =~ s{::}{/}g;

        eval { require $module };

        if ($@) {
            warn substr($@, 0, rindex($@, ' at ')), "\n";
            return;
        }

        Sidef::Module::Caller->_new(module => $module_name);
    }
}

1;
