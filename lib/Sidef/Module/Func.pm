
use 5.014;
use strict;
use warnings;

package Sidef::Module::Func {

    our $AUTOLOAD;

    sub _new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        my $func = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
        my $sub = \&{$self->{module} . '::' . $func};

        if (defined &$sub) {
            return $sub->(
                @arg
                ? (
                   map {
                           ref($_) =~ /^Sidef::/ && $_->can('get_value') ? $_->get_value
                         : ref($_) eq 'Sidef::Variable::Ref' ? $_->get_var->get_value
                         : $_
                     } @arg
                  )
                : ()
            );
        }
        else {
            warn qq{[WARN] Can't locate function '$func' via package "$self->{module}"!\n};
            return;
        }
    }
};

1;
