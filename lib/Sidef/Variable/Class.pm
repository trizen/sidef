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

        if (exists $self->{functions}{$name}) {
            @args || (@args = rand);
            return $self->{functions}{$name}->call($self, @args);
        }
        elsif (exists $self->{functions}{'AUTOLOAD'}) {
            return $self->{functions}{'AUTOLOAD'}->call($self, $name, @args);
        }
        else {
            warn "No method `$name' for class: $self->{name}\n";
        }

        return;
    }

};

1
