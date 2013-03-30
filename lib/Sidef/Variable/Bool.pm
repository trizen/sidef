
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Bool;

use parent qw(Sidef::Types::Bool::Bool);

sub new {
    my ( $class, $var ) = @_;
    bless \$var, $class;
}

1;
