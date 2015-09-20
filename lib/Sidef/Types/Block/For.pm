package Sidef::Types::Block::For {

    use 5.014;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, @args) = @_;

        if (    $#args == 3
            and ref($args[0]) eq 'Sidef::Types::Block::Code'
            and ref($args[1]) eq 'Sidef::Types::Block::Code'
            and ref($args[2]) eq 'Sidef::Types::Block::Code') {
            my ($one, $two, $three) = @args[0 .. 2];
            for ($one->_execute_expr ; $two->_execute_expr ; $three->_execute_expr) {
                if (defined(my $res = $args[3]->_run_code)) {
                    return $res;
                }
            }
            $args[-1];
        }
        elsif ($#args == 1 and $args[0]->can('each')) {
            $args[0]->each($args[1]);
        }
        else {
            my $block = pop @args;
            foreach my $item (@args) {
                if (defined(my $res = $block->_run_code($item))) {
                    return $res;
                }
            }
            $block;
        }
    }

    *foreach = \&for;
};

1
