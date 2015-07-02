package Sidef::Variable::Class {

    use 5.014;
    our $AUTOLOAD;

    use overload q{""} => sub {
        eval {
            local $SIG{__WARN__} = sub { };
            $_[0]->to_s;
        } // $_[0];
      },
      q{bool} => sub {
        eval {
            local $SIG{__WARN__} = sub { };
            $_[0]->to_bool;
        } // $_[0];
      };

    sub __new__ {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub __name__ {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{name});
    }

    sub __class__ {
        my ($self) = @_;
        $self->{class};
    }

    sub def_method {
        my ($self, $name, $block) = @_;
        $self->{method}{$name} = $block;
    }

    sub has_method {
        my ($self, $name) = @_;
        Sidef::Types::Bool::Bool->new(exists $self->{method}{$name});
    }

    sub get_value {
        my $self = shift;
        $AUTOLOAD = __PACKAGE__ . '::' . 'get_value';
        $self->AUTOLOAD(@_);
    }

    sub is_a {
        my ($self, $arg) = @_;
        Sidef::Types::Bool::Bool->new(
                                      ref($arg) eq 'Sidef::Variable::ClassInit' || ref($arg) eq 'Sidef::Variable::Class'
                                      ? $self->{name} eq $arg->{name}
                                      : 0
                                     );
    }

    *is_an = \&is_a;

    sub dump {
        my ($self) = @_;
        Sidef::Types::String::String->new(
            $self->{name} . '(' . join(
                ", ",
                map {
                    my $val = $self->{__VARS__}{$_};
                    "$_: " . (eval { $val->can('dump') } ? ${$val->dump} : $val)
                  } @{$self->{__PARAMS__}}
              )
              . ')'
        );
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my ($self, @args) = @_;

        my ($name) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        $] < 5.018 && do {    # bug fixed in perl 5.18 (or 5.16)
            utf8::decode($name);
        };

        if (exists $self->{__VARS__}{$name} or exists $self->{index_access}) {
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
        else {
            die "[ERROR] Can't find method `$name' for class: $self->{name}\n";
        }

        return;
    }

};

1
