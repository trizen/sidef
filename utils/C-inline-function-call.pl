#!/usr/bin/perl

#
## This file is a concept.
#

# In one day, maybe, Sidef will use 'Inline C' in Sidef::Exec
# to make things a little bit faster... :)

use 5.010;
use strict;
use warnings;

use Inline 'C';

package Test {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub add_value {
        my ($self) = @_;
        say "@_ ($#_)";
        say $self->{one} + $self->{two};
    }
}

my $obj = Test->new(one => 12, two => 3);

my $method = 'add_value';
my $func   = ref($obj) . '::' . $method;
c_call($obj, $func);

__DATA__
__C__

void c_call(SV *obj, char *f) {
     dSP;

     ENTER;
     SAVETMPS;

     //XPUSHs(sv_2mortal(newSVpvf(obj)));
     //PUTBACK;

     call_pv(f, G_DISCARD);

     FREETMPS;
     LEAVE;
}
