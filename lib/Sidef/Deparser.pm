package Sidef::Deparser {

    use 5.014;
    our @ISA = qw(Sidef);
    use Scalar::Util qw(refaddr);

    # This module is under development...

    sub new {
        my (undef, %opts) = @_;
        bless \%opts, __PACKAGE__;
    }

    my %addr;

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $self_obj = $expr->{self};

        # Self obj
        my $ref = ref($self_obj);
        if ($ref eq 'HASH') {
            $self_obj = join(', ', $self->deparse($self_obj));
        }
        elsif ($ref eq "Sidef::Variable::Variable") {
            if ($self_obj->{type} eq 'func') {
                if ($addr{refaddr($self_obj)}++) {
                    $self_obj = $self_obj->{name};
                }
                else {
                    $self_obj = ("func $self_obj->{name} " . $self->deparse_expr({self => $self_obj->{value}}));
                }
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

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $call (@{$expr->{call}}) {
                if ($call->{method} eq 'HASH') {

                }
                elsif ($call->{method} =~ /^[[:alpha:]_]/) {
                    $self_obj .= ".$call->{method}";
                }
                else {
                    $self_obj .= "$call->{method}";
                }

                if (exists $call->{arg}) {
                    $self_obj .= " +some-arguments";
                }
            }
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
