package Sidef::Deparser {

    use 5.014;
    our @ISA = qw(Sidef);

    # This module is under development...

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $self_obj = $expr->{self};

        my $ref = ref($self_obj);
        if ($ref eq 'HASH') {
            $self_obj = join(', ', $self->deparse($self_obj));
        }
        elsif ($ref eq "Sidef::Variable::Variable") {
            if ($self_obj->{type} eq 'func') {
                $self_obj = "func $self_obj->{name} " . $self->deparse_expr({self => $self_obj->{value}});
            }
        }
        elsif ($ref eq 'Sidef::Variable::Init') {
            $self_obj = 'var(' . join(', ', map { $_->{name} } @{$self_obj->{vars}}) . ')';
        }
        elsif ($ref eq 'Sidef::Variable::Ref') {
            $self_obj = '__some-var-ref__';
        }
        elsif ($ref eq 'Sidef::Types::Block::Code') {
            $self_obj = '{' . join(";\n", $self->deparse($self_obj->{code})) . '}';
        }

        if (exists $expr->{call}) {
            $self_obj .= " +some-method-call";
        }

        $self_obj;
    }

    sub deparse {
        my ($self, $struct) = @_;

        my @results;
        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, $self->deparse_expr($expr);
            }
        }

        wantarray ? @results : $results[-1];
    }
};

1
