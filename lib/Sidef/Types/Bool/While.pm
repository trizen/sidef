package Sidef::Types::Bool::While {

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
        $code->while($self->{arg}, $self);
    }

    sub else {
        my ($self, $code) = @_;
        $self->{did_while} // $code->run;
        undef $self->{did_while};
        $self;
    }

}

1;
