
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
            my $result = $code->run;
            if (ref($result) eq 'Sidef::Types::Block::Continue') {
                $self->{do_block} = 0;
                return $self;
            }
            elsif (ref($result) eq 'Sidef::Types::Block::Return') {
                return $result;
            }
            return Sidef::Types::Black::Hole->new();
        }

        return $self;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . ':'} = \&do;
    }

};

1;
