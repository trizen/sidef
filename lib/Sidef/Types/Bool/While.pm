package Sidef::Types::Bool::While {

    sub new {
        bless {}, __PACKAGE__;
    }

    sub while {
        my ($self, $condition, $block) = @_;

        if (exists($condition->{_special_stack_vars}) and not exists($block->{_specialized})) {
            $block->{_specialized} = 1;
            push @{$block->{vars}}, @{$condition->{_special_stack_vars}};
        }

        while ($condition->run) {
            $self->{did_while} //= 1;
            if (defined(my $res = $block->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    sub else {
        my ($self, $code) = @_;
        $self->{did_while} // $code->run;
        undef $self->{did_while};
        $self;
    }

}

1;
