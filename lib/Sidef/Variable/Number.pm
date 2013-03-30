
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Number;

use parent qw(Sidef::Types::Number::Number);

sub new {
    my ( $class, $var ) = @_;
    bless \$var, $class;
}

1;
