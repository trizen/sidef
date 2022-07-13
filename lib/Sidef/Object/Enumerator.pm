package Sidef::Object::Enumerator {

    use utf8;
    use 5.016;
    ##use overload q{""} => \&to_a;

    sub new {
        my (undef, $block) = @_;
        bless {block => $block}, __PACKAGE__;
    }

    *call = \&new;

    sub first {
        my ($self, $n, $block) = @_;

        $n = CORE::int($n);

        my @arr;
        my $count = 0;

        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    if (defined($block) ? $block->run(@_) : 1) {
                        push @arr, @_;
                        if (++$count >= $n) {
                            goto RETURN;
                        }
                    }
                }
            )
        );

      RETURN: Sidef::Types::Array::Array->new(\@arr);
    }

    sub nth {
        my ($self, $n, $block) = @_;

        $n = CORE::int($n);

        my @arr;
        my $count = 0;

        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    if (defined($block) ? $block->run(@_) : 1) {
                        if (++$count >= $n) {
                            push @arr, @_;
                            goto RETURN;
                        }
                    }
                }
            )
        );

      RETURN: $arr[0];
    }

    sub while {
        my ($self, $block) = @_;

        my @arr;

        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    if ($block->run(@_)) {
                        push @arr, @_;
                    }
                    else {
                        goto RETURN;
                    }
                }
            )
        );

      RETURN: Sidef::Types::Array::Array->new(\@arr);
    }

    sub to_a {
        my ($self) = @_;

        my @arr;
        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    push @arr, @_;
                },
            )
        );

        Sidef::Types::Array::Array->new(\@arr);
    }

    sub each {
        my ($self, $block) = @_;
        $self->{block}->run($block);
        $self;
    }

    sub map {
        my ($self, $block) = @_;

        my @arr;
        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    push @arr, map { $block->run($_) } @_;
                },
            )
        );

        Sidef::Types::Array::Array->new(\@arr);
    }

    *collect = \&map;

    sub grep {
        my ($self, $block) = @_;

        my @arr;
        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    push @arr, grep { $block->run($_) } @_;
                },
            )
        );

        Sidef::Types::Array::Array->new(\@arr);
    }

    *select = \&grep;

    sub count {
        my ($self, $block) = @_;

        my $count = 0;

        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    ++$count if $block->run(@_);
                },
            )
        );

        Sidef::Types::Number::Number::_set_int($count);
    }

    *count_by = \&count;

    sub length {
        my ($self) = @_;

        my $count = 0;
        $self->{block}->run(
            Sidef::Types::Block::Block->new(
                code => sub {
                    ++$count;
                },
            )
        );

        Sidef::Types::Number::Number::_set_int($count);
    }

    *len  = \&length;    # alias
    *size = \&length;

#<<<
    #~ #
    #~ ## AUTOLOAD
    #~ #

    #~ sub DESTROY { }

    #~ our $AUTOLOAD;

    #~ sub AUTOLOAD {
        #~ my ($self, @arg) = @_;
        #~ my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);
        #~ $self->to_a->$method(@arg);
    #~ }
#>>>
};

1
