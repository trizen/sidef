
use 5.014;
use strict;
use warnings;

package Sidef::Types::Block::Do {

    use parent qw(Sidef);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub do {
        my ($self, $code) = @_;

        $self->_is_code($code) || do {
            $self->{do_block} = 0;
            return $self;
        };

        if ($self->{do_block}) {
            if (ref($code->run) eq 'Sidef::Types::Block::Continue') {
                $self->{do_block} = 0;
                return $self;
            }
            return Sidef::Types::Black::Hole->new();
        }

        return $self;
    }

};

1;
