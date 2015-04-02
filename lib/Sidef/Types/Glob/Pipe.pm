package Sidef::Types::Glob::Pipe {

    use 5.014;
    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, @command) = @_;
        bless \@command, __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        join(' ', @{$_[0]});
    }

    sub command {
        my ($self) = @_;

        $#{$self} == 0
          ? $self->[0]
          : Sidef::Types::Array::Array->new(@{$self});
    }

    sub open {
        my ($self, $mode, $var_ref) = @_;

        if (ref $mode) {
            $mode = $mode->get_value;
        }

        my $pid = open(my $pipe_h, $mode, @{$self});
        my $pipe_obj = Sidef::Types::Glob::PipeHandle->new(pipe_h => $pipe_h, pipe => $self);

        if (defined($var_ref)) {
            $var_ref->get_var->set_value($pipe_obj);

            return defined($pid)
              ? Sidef::Types::Number::Number->new($pid)
              : ();
        }

        defined($pid) ? $pipe_obj : ();
    }

    sub open_r {
        my ($self, $var_ref) = @_;
        $self->open('-|:utf8', $var_ref);
    }

    *openR     = \&open_r;
    *openRead  = \&open_r;
    *open_read = \&open_r;

    sub open_w {
        my ($self, $var_ref) = @_;
        $self->open('|-:utf8', $var_ref);
    }

    *openW      = \&open_w;
    *openWrite  = \&open_w;
    *open_write = \&open_w;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
                      'Pipe.new(' . join(', ', map { Sidef::Types::String::String->new($_)->dump->get_value } @{$self}) . ')');
    }
}

1;
