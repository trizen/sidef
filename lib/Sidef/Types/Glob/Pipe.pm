package Sidef::Types::Glob::Pipe {

    use 5.014;

    our @ISA = qw(
      Sidef
      Sidef::Convert::Convert
      );

    sub new {
        my (undef, @command) = @_;
        bless \@command, __PACKAGE__;
    }

    sub get_value {
        [map { $_->get_value } @{$_[0]}];
    }

    sub command {
        my ($self) = @_;

        $#{$self} == 0
          ? $self->[0]
          : Sidef::Types::Array::Array->new(@{$self});
    }

    sub open {
        my ($self, $mode, $var_ref) = @_;

        ref($mode)
          ? $self->is_string($mode, 1)
              ? do { $mode = $$mode }
              : return
          : ();

        my $pid = open(my $pipe_h, $mode, @{$self});
        my $pipe_obj = Sidef::Types::Glob::PipeHandle->new(pipe_h => $pipe_h, pipe => $self);

        if (ref($var_ref) eq 'Sidef::Variable::Ref') {
            $var_ref->get_var->set_value($pipe_obj);

            return defined($pid)
              ? Sidef::Types::Number::Number->new($pid)
              : ();
        }
        elsif (defined($pid)) {
            return $pipe_obj;
        }

        return;
    }

    sub open_r {
        my ($self, $var_ref) = @_;
        $self->open('-|', $var_ref);
    }

    *openR     = \&open_r;
    *openRead  = \&open_r;
    *open_read = \&open_r;

    sub open_w {
        my ($self, $var_ref) = @_;
        $self->open('|-', $var_ref);
    }

    *openW      = \&open_w;
    *openWrite  = \&open_w;
    *open_write = \&open_w;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new('Pipe.new(' . join(', ', map { $_->dump } @{$self}) . ')');
    }
}

1;
