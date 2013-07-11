package Sidef::Types::Bool::While {

    use 5.014;
    use strict;
    use warnings;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub while {
        my ($self, $code) = @_;
        $self->{arg} = $code;
        $self;
    }

    sub do {
        my ($self, $code) = @_;
        $code->while($self->{arg});
    }

}

1;
