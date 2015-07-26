package Sidef::Variable::Struct {

    use 5.014;
    our $AUTOLOAD;

    sub __new__ {
        my (undef, $name, $vars) = @_;
        bless {
               __NAME__ => $name,
               map { $_->{name} => $_ } @{$vars}
              },
          __PACKAGE__;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, $arg) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        # Variable autovification
        if (not exists $self->{$name}) {
            return $self->{$name} = Sidef::Variable::Variable->new(name => '', type => 'var', value => $arg);
        }

        $self->{$name};
    }
}

1
