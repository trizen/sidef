
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Array;

use parent qw(Sidef::Types::Array::Array);

sub new {
    my ( $class, $var ) = @_;
    bless \$var, $class;
}

1;
