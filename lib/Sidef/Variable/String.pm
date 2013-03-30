
use 5.014;
use strict;
use warnings;

package Sidef::Variable::String;

use parent qw(Sidef::Types::String::String);

sub new {
    my($class, $var) = @_;
    bless \$var, $class;
}

1;
