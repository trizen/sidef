
use 5.014;
use strict;
use warnings;

package Sidef::Module::Require {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub require {
        my ($self, $module) = @_;

        $self->{module_name} = $module->get_value;
        ($self->{module} = $self->{module_name} . '.pm') =~ s{::}{/};

        eval { require $self->{module} };

        if ($@) {
            warn substr($@, 0, rindex($@, ' at ')), "\n";
            return;
        }

        Sidef::Module::Caller->_new(module => $self->{module_name});
    }
}

1;
