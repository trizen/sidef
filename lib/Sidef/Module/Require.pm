package Sidef::Module::Require {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub require {
        my ($self, $module) = @_;

        $self->{module_name} = $module->get_value;
        ($self->{module} = $self->{module_name} . '.pm') =~ s{::}{/}g;

        eval { require $self->{module} };

        if ($@) {
            warn substr($@, 0, rindex($@, ' at ')), "\n";
            return Sidef::Types::Nil::Nil->new;
        }

        Sidef::Module::Caller->_new(module => $self->{module_name});
    }
}

1;
