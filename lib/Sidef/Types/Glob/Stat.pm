package Sidef::Types::Glob::Stat {

    use parent qw(
      Sidef::Object::Object
      );

    sub new {
        my (undef, %opt) = @_;

        bless {
               obj  => $opt{obj},
               stat => [map { Sidef::Types::Number::Number->new($_) } @{$opt{stat}}],
              },
          __PACKAGE__;
    }

    {
        # The order matters!
        my @names = qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks);

        foreach my $i (0 .. $#names) {
            *{__PACKAGE__ . '::' . $names[$i]} = sub {
                $_[0]{stat}[$i];
            };
        }
    }

    sub all {
        Sidef::Types::Array::Array->new(@{$_[0]{stat}});
    }

    sub parent {
        $_[0]{obj};
    }

    sub stat {
        my ($self, $arg, $obj) = @_;
        $self->new(stat => [stat($arg)], obj => $obj);
    }

    sub lstat {
        my ($self, $arg, $obj) = @_;
        $self->new(stat => [lstat($arg)], obj => $obj);
    }

};

1
