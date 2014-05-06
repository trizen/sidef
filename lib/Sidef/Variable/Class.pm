package Sidef::Variable::Class {

    use 5.014;
    use strict;
    use warnings;

    our $AUTOLOAD;

    sub __new {
        my (undef, $name) = @_;
        bless {name => $name}, __PACKAGE__;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        if (exists $self->{__NAMES__}{$name}) {
            if (@args) {
                return $self->{__NAMES__}{$name} = $args[0];
            }
            else {
                return $self->{__NAMES__}{$name};
            }
        }

        if (exists $self->{method}{$name}) {

            if (exists $self->{method}{'CHECK'}) {
                $self->{method}{'CHECK'}->call($self, Sidef::Types::String::String->new($name), @args) || return;
            }

            return $self->{method}{$name}->call($self, @args);
        }
        elsif (exists $self->{method}{'AUTOLOAD'}) {
            return $self->{method}{'AUTOLOAD'}->call($self, Sidef::Types::String::String->new($name), @args);
        }
        else {
            warn "Can't find method `$name' for class: $self->{name}\n";
        }

        return;
    }

};

1
