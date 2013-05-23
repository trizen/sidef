
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Code {

    sub new {
        my ($class, $code) = @_;
        bless $code, $class;
    }

    sub if {
        my($self, $bool) = @_;

        if($bool->is_true){
            my $exec = Sidef::Exec->new();
            $exec->execute(struct => $self);
        }

        $self;
    }

}

1;
