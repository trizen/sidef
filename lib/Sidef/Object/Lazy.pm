package Sidef::Object::Lazy;

use utf8;
use 5.016;
##use overload q{""} => \&to_a;
use Sidef::Types::Block::Block;
use Sidef::Types::Array::Array;
use Sidef::Types::Number::Number;

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

  ITEM: for (; ;) {
        my @arg = ($iter->run() // last);
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

sub _fast_reduce {
    my ($self, $method, $result, $callback) = @_;

    my @list;
    my $count = 0;
    my $index = 0;

    $self->_xs(
        sub {
            CORE::push(@list, $callback->($index++, @_));

            if (++$count > 1e5) {
                $count  = 0;
                $result = $result->$method(CORE::splice(@list));
            }
            0;    # keep looping
        }
    );

    if (@list) {
        $result = $result->$method(CORE::splice(@list));
    }

    $result;
}

sub reduce_by {
    my ($self, $block, $result) = @_;

    $self->_xs(
        sub {
            if (defined($result)) {
                $result = $block->run($result, @_);
            }
            else {
                $result = $_[0];
            }
            0;    # keep looping
        }
    );

    return $result;
}

sub reduce {
    my ($self, $operator, $result) = @_;

    if (ref($operator) eq 'Sidef::Types::Block::Block') {
        goto &reduce_by;
    }

    $operator = "$operator";
    $self->_xs(
        sub {
            if (defined($result)) {
                $result = $result->$operator(@_);
            }
            else {
                $result = $_[0];
            }
            0;    # keep looping
        }
    );
    return $result;
}

sub sum {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_fast_reduce('sum', Sidef::Types::Number::Number::ZERO, sub { $block->run($_[1]) });
}

*sum_by = \&sum;

sub prod {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_fast_reduce('prod', Sidef::Types::Number::Number::ONE, sub { $block->run($_[1]) });
}

*prod_by = \&prod;

sub sum_kv {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_fast_reduce(
        'sum',
        Sidef::Types::Number::Number::ZERO,
        sub {
            $block->run(Sidef::Types::Number::Number::_set_int($_[0]), $_[1]);
        }
    );
}

sub prod_kv {
    my ($self, $block) = @_;
    $block //= Sidef::Types::Block::Block::IDENTITY;
    $self->_fast_reduce('prod', Sidef::Types::Number::Number::ONE, sub { $block->run(Sidef::Types::Number::Number::_set_int($_[0]), $_[1]) });
}

sub iter {
    my ($self) = @_;

    my $iter = $self->{obj}->iter;

    Sidef::Types::Block::Block->new(
        code => sub {
          ITEM: {
                my $item = $iter->run() // return undef;
                my @arg  = ($item);
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

    if (!defined($n)) {
        my @arr;
        $self->_xs(sub { push(@arr, @_); 1; });
        return $arr[0];
    }

    if (ref($n) eq 'Sidef::Types::Block::Block') {
        return $self->first_by($n);
    }

    $n = CORE::int($n);
    $n > 0 || return Sidef::Types::Array::Array->new([]);

    my @arr;

    $self->_xs(
        sub {
            push @arr, @_;
            @arr >= $n;
        }
    );

    Sidef::Types::Array::Array->new(\@arr);
}

sub nth {
    my ($self, $n) = @_;

    my @arr;
    $n = CORE::int($n);
    $n > 0 || return undef;

    $self->_xs(
        sub {
            push @arr, @_;
            @arr >= $n;
        }
    );

    $arr[$n - 1];
}

sub first_by {
    my ($self, $block) = @_;
    $self->grep($block)->first(1)->[0];
}

#
## Functional methods
#

sub grep {
    my ($self, $block) = @_;
    __PACKAGE__->new(
        obj   => $self->{obj},
        calls => [
            @{$self->{calls}},
            sub {
                $block->run($_[0]) ? $_[0] : ();
            },
        ],
    );
}

*select = \&grep;

sub while {
    my ($self, $block) = @_;

    my @arr;

    $self->_xs(
        sub {
            $block->run(@_) ? do { push(@arr, @_); 0 } : 1;
        }
    );

    Sidef::Types::Array::Array->new(\@arr);
}

sub map {
    my ($self, $block) = @_;
    __PACKAGE__->new(
        obj   => $self->{obj},
        calls => [
            @{$self->{calls}},
            sub {
                $block->run($_[0]);
            }
        ],
    );
}

*collect = \&map;

sub drop {
    my ($self, $n) = @_;
    $n = CORE::int($n);
    my $count = 0;
    __PACKAGE__->new(
        obj   => $self->{obj},
        calls => [
            @{$self->{calls}},
            sub {
                if ($count < $n) { ++$count; return (); }
                ($_[0]);
            },
        ],
    );
}

sub uniq {
    my ($self) = @_;
    my %seen;
    __PACKAGE__->new(
        obj   => $self->{obj},
        calls => [
            @{$self->{calls}},
            sub {
                my $key = "$_[0]";
                $seen{$key}++ ? () : ($_[0]);
            },
        ],
    );
}

sub take {
    my ($self, $n) = @_;
    $n = CORE::int($n);
    my $orig      = $self->{obj};
    my $remaining = $n;
    my $limited = bless {
                         obj => $orig,
                         n   => $n,
                        },
      'Sidef::Object::Lazy::_Take';

    {
        no strict 'refs';
        *{'Sidef::Object::Lazy::_Take::iter'} = sub {
            my ($lim)     = @_;
            my $inner     = $lim->{obj}->iter;
            my $remaining = $lim->{n};
            Sidef::Types::Block::Block->new(
                code => sub {
                    $remaining > 0 or return undef;
                    --$remaining;
                    $inner->run();
                }
            );
        };
    }

    __PACKAGE__->new(obj => $limited, calls => [@{$self->{calls}}]);
}

sub lazy {
    my ($self) = @_;
    $self;
}

1;
