package Sidef::Variable::Class {

    use 5.014;
    our $AUTOLOAD;

    sub __new__ {
        my (undef, $name) = @_;
        bless {name => $name}, __PACKAGE__;
    }

    sub __name__ {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{name});
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        $] < 5.018 && do {    # bug fixed in perl 5.18 (or 5.16)
            utf8::decode($name);
        };

        if (exists $self->{__VARS__}{$name}) {
            if (@args) {
                return $self->{__VARS__}{$name} = $args[-1];
            }
            return Sidef::Variable::ClassVar->__new__(class => $self, name => $name);
        }

        if (exists $self->{method}{$name}) {

            if (exists $self->{method}{'CHECK'}) {
                $self->{method}{'CHECK'}->call($self, Sidef::Types::String::String->new($name), @args)
                  || return;
            }

            return $self->{method}{$name}->call($self, @args);
        }
        elsif (exists $self->{method}{'AUTOLOAD'}) {
            return $self->{method}{'AUTOLOAD'}->call($self, Sidef::Types::String::String->new($name), @args);
        }
        elsif (exists $self->{index_access}) {
            return Sidef::Variable::ClassVar->__new__(class => $self, name => $name);
        }
        else {
            warn "[WARN] Can't find method `$name' for class: $self->{name}\n";
        }

        return;
    }

};

1
