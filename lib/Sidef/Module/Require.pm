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
            die substr($@, 0, rindex($@, ' at ')), "\n";
        }

        Sidef::Module::Caller->__NEW__(module => $module_name);
    }

    sub frequire {
        my ($self, $module) = @_;
        my $caller = $self->require($module);
        Sidef::Module::Func->__NEW__(module => $caller->{module});
    }
}

1;
