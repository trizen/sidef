
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Hash;

use parent qw(Sidef::Types::Hash::Hash);

sub new {
    my ( $class, $hash ) = @_;
    bless \$hash, $class;
}

1;
