
use 5.014;
use strict;
use warnings;

package Sidef::Module::Func {

    our $AUTOLOAD;

    sub _new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;

        return if $AUTOLOAD =~ /::DESTROY$/;
        (my $func = $AUTOLOAD) =~ s/.*:://;

        my $sub = \&{$self->{module} . '::' . $func};

        if (defined &$sub) {
            return $sub->(
                @arg
                ? (
                   map {
                       ref($_) && ref($_) =~ /^Sidef::/ && eval { $_->can('get_value') }
                         ? $_->get_value
                         : $_
                     } @arg
                  )
                : ()
            );

        }
        else {
            warn "[WARN] Can't find function '$func' for object '$self->{module}'!\n";
            return;
        }
    }
};

1;
