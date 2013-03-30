
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Regex;

use parent qw(Sidef::Types::Regex::Regex);

sub new {
    my ( $class, $var ) = @_;
    bless \$var, $class;
}

1;
