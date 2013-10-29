package Sidef::Types::Block::Return {

    use 5.014;
    use strict;
    use warnings;

    our $AUTOLOAD;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub return {
        my ($self, $obj) = @_;
        $self->{obj} = $obj;
        $self;
    }

    sub _get_obj {
        $_[0]->{obj};
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my @results;

        #if (@{$self->{vars}} && ($self->{vars}[0]->can($method) || $self->{vars}[0]->can('AUTOLOAD'))) {
        if (defined($self->{obj}) && ($self->{obj}->can($method) || $self->{obj}->can('AUTOLOAD'))) {
            return $self->{obj}->$method(@args);

            # push @results, $var->$method(shift @args);
        }
        else {
            warn sprintf(qq{Can't locate object method "%s" for object "%s"\n}, $method, ref($self->{vars}[0]));
        }

        $results[0];
    }
}

1;
