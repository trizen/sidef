package Sidef::Types::Block::For {

    use 5.014;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub for {
        my ($self, @args) = @_;

        if ($#args == 1 and eval { $args[0]->can('each') }) {
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
