package Sidef::Object::Lazy {

    use 5.014;
    ##use overload q{""} => \&to_a;

    sub new {
        my (undef, %opt) = @_;
        bless {
               calls => [],
               %opt,
              },
          __PACKAGE__;
    }

    sub _xs {
        my ($self, $callback) = @_;

        my $iter = $self->{obj}->iter;

      ITEM: while (defined(my $item = $iter->())) {
            my @arg = ($item);
            foreach my $call (@{$self->{calls}}) {
                @arg = $call->(@arg);
                @arg || next ITEM;
            }
            last if $callback->(@arg);
        }
    }

    sub to_a {
        my ($self) = @_;
        my @arr;
        $self->_xs(sub { push @arr, @_; 0 });
        Sidef::Types::Array::Array->new(\@arr);
    }

    sub each {
        my ($self, $block) = @_;
        $self->_xs(sub { $block->run(@_); 0 });
        $self;
    }

    sub iter {
        my ($self) = @_;

        my $iter = $self->{obj}->iter;

        Sidef::Types::Block::Block->new(
            code => sub {
              ITEM: {
                    my $item = $iter->() // return undef;
                    my @arg = ($item);
                    foreach my $call (@{$self->{calls}}) {
                        @arg = $call->(@arg);
                        @arg || redo ITEM;
                    }
                    $arg[0];
                }
            }
        );
    }

    sub first {
        my ($self, $n) = @_;

        $n = CORE::int($n);
        $n > 0 || return Sidef::Types::Array::Array->new([]);

        my @arr;

        $self->_xs(
            sub {
                push @arr, @_;
                @arr >= $n ? 1 : 0;
            }
        );

        Sidef::Types::Array::Array->new(\@arr);
    }

    #
    ## Functional methods
    #

    sub grep {
        my ($self, $block) = @_;
        push @{$self->{calls}}, sub {
            $block->run($_[0]) ? $_[0] : ();
        };
        $self;
    }

    *select = \&grep;

    sub map {
        my ($self, $block) = @_;
        push @{$self->{calls}}, sub {
            $block->run($_[0]);
        };
        $self;
    }

    #
    ## AUTOLOAD
    #

    sub DESTROY { }

    our $AUTOLOAD;

    sub AUTOLOAD {
        my ($self, @arg) = @_;
        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        $self->to_a->$method(@arg);
    }

}

1;
