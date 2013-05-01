
use 5.014;
use strict;
use warnings;

package Sidef::Variable::Variable {

    sub new {
        my ($class, $var, $type) = @_;
        bless {
               name  => $var,
               type => $type,
              }, $class;
    }

    sub get_name {
        my ($self) = @_;
        return $self->{name};
    }

    sub set_value {
        my ($self, $value) = @_;
        $self->{value} = $value;
    }

    sub get_value {
        my ($self) = @_;
        return $self->{value};
    }
    
     sub get_type {
        my ($self) = @_;
        return $self->{type};
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '='} = sub {
            my ($self, $obj) = @_;
            if ($self->{type} eq "const") {
				if ( not defined $self->{value} ) {
					return $self->set_value($obj);
				}      
				warn "Constant $self->{name} cannot be changed.\n";
			} elsif ($self->{type} eq "var") {
				return $self->set_value($obj);
			} else {
				warn "Invalid type: $self->{type}.\n";
			}
        };

    }

};

1;
