package Sidef::Variable::Struct {

    use 5.014;
    our $AUTOLOAD;

    sub __new {
        my (undef, $vars) = @_;
        bless {map { $_->{name} => $_ } @{$vars}}, __PACKAGE__;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, $argv) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        # Variable autovification
        if (not exists $self->{$name}) {
            $self->{$name} = Sidef::Variable::Variable->new(name => '', type => 'var', value => $argv);
        }

        Sidef::Variable::Variable->new(name => '', type => 'var', value => $self->{$name});
    }
}

1
