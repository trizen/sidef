package Sidef::Object::Class;

use utf8;
use 5.016;

use mro          ();
use Scalar::Util qw(refaddr);

use Sidef::Types::Block::Block;
use Sidef::Types::Array::Array;
use Sidef::Types::Hash::Hash;

# ---------------------------------------------------------------------------
# Sidef::Object::Class
#
# The run-time part of the Sidef classes.
#
# The Perl deparser (Sidef::Deparse::Perl) turns every `class` declaration into a
# single call of declare(), which receives only declarative information:
#
#   key       => unique key of this declaration (the registry key)
#   package   => the Perl package that holds the methods of the class
#   name      => the name of the class (used in error messages)
#   parents   => the keys of the declarations of the parent classes
#   params    => the constructor parameters (the descriptors used by Sidef::Types::Block::Block)
#   attrs     => the names of the `has` attributes
#   defaults  => sub ($self, $own) { ... }  evaluates the default values of the parameters
#   build     => sub ($self, $own) { ... }  evaluates the `has` attributes
#
# This module is responsible for everything else: the inheritance (C3 linearization),
# the resolution of the fields, the constructor, the accessors and the install of `@ISA`.
#
# The model:
#
#  * Every declaration is a node of the inheritance graph. Redefining a class (declaring it again
#    with the same name) creates a new declaration, which inherits from the previous one
#    and lives in the same Perl package.
#
#  * The declarations are linearized with C3 (the most derived first). A field is *owned* by the
#    first declaration that declares it, therefore the most derived declaration wins, whether
#    it declares the field as a constructor parameter or as an attribute (`has`).
#
#  * The constructor parameters are the fields declared as parameters by their owners, ordered
#    with the parents first, from left to right (the inherited ones first).
#
#  * An object is created in four steps:
#       1. the arguments are bound to the parameters (done by Sidef::Types::Block::Block)
#       2. the default values of the parameters are evaluated (most derived class first)
#       3. the attributes are evaluated (most derived class first, for the same reason)
#       4. the `init` method is called, if defined
# ---------------------------------------------------------------------------

my %REGISTRY;    # key => declaration

sub _error {
    my ($decl, $message) = @_;
    my $name = (ref($decl) && exists $decl->{name}) ? $decl->{name} : 'unknown';
    die "[ERROR] class `$name`: $message\n";
}

# Returns the declaration with the given key
sub lookup {
    my ($class, $key) = @_;
    return $REGISTRY{$key};
}

# Declares a new class. Returns the declaration (a blessed hash-ref).
sub declare {
    my ($class, %opt) = @_;

    my $decl = bless(
                     {
                      key      => $opt{key},
                      package  => $opt{package},
                      name     => $opt{name},
                      type     => $opt{type}   // 'class',
                      params   => $opt{params} // [],
                      attrs    => $opt{attrs}  // [],
                      defaults => $opt{defaults},
                      build    => $opt{build},
                     },
                     $class
                    );

    foreach my $key (@{$opt{parents} // []}) {
        my $parent = $REGISTRY{$key} // _error($decl, "unknown parent class declaration `$key`");
        push @{$decl->{parents}}, $parent;
    }

    $decl->{parents} //= [];

    $REGISTRY{$decl->{key}} = $decl;

    $decl->_resolve;
    $decl->_install_isa;
    $decl->_install_accessors;
    $decl->_install_constructor;

    return $decl;
}

# C3 linearization of the declarations: the most derived first
sub linearize {
    my ($self) = @_;

    return @{$self->{mro}} if $self->{mro};

    my @seqs = ((map { [$_->linearize] } @{$self->{parents}}), [@{$self->{parents}}]);
    my @mro  = ($self);

    while (1) {
        @seqs = grep { @$_ } @seqs;
        @seqs or last;

        my $candidate;
        foreach my $seq (@seqs) {
            my $head      = $seq->[0];
            my $head_addr = refaddr($head);

            # a good head does not appear in the tail of any other sequence
            if (
                not grep {
                    my $s = $_;
                    grep { refaddr($_) == $head_addr } @{$s}[1 .. $#$s]
                } @seqs
              ) {
                $candidate = $head;
                last;
            }
        }

        defined($candidate)
          or _error($self, "inconsistent class hierarchy (can't linearize the parent classes)");

        push @mro, $candidate;
        my $candidate_addr = refaddr($candidate);
        foreach my $seq (@seqs) {
            shift(@$seq) if refaddr($seq->[0]) == $candidate_addr;
        }
    }

    $self->{mro} = \@mro;
    return @mro;
}

# Resolves the fields: who owns each field, and the parameters of the constructor
sub _resolve {
    my ($self) = @_;

    my @mro = $self->linearize;

    # The owner of a field is the first declaration (in the order of the MRO) that declares it
    my %owner;
    foreach my $decl (@mro) {
        foreach my $param (@{$decl->{params}}) {
            $owner{$param->{name}} //= [$decl, 'param'];
        }
        foreach my $name (@{$decl->{attrs}}) {
            $owner{$name} //= [$decl, 'attr'];
        }
    }

    # What each declaration owns: used by the initializers
    my %owned;
    foreach my $name (keys %owner) {
        $owned{refaddr($owner{$name}[0])}{$name} = 1;
    }

    # The constructor parameters: the parents first (from left to right), then the class itself
    my @order = $self->_parents_first;

    my @params;
    foreach my $decl (@order) {
        my $decl_addr = refaddr($decl);
        foreach my $param (@{$decl->{params}}) {
            my $name = $param->{name};
            if (refaddr($owner{$name}[0]) == $decl_addr and $owner{$name}[1] eq 'param') {
                push @params, $param;
            }
        }
    }

    # A slurpy parameter must be the last one (all the parameters are inherited)
    foreach my $i (0 .. $#params - 1) {
        if ($params[$i]{slurpy}) {
            _error($self, "the slurpy parameter `$params[$i]{name}` must be the last parameter of the constructor");
        }
    }

    $self->{owner}  = \%owner;
    $self->{owned}  = \%owned;
    $self->{ctor_p} = \@params;
    $self->{order}  = \@order;

    return;
}

# The declarations in the order of the construction: every declaration comes after its parents
# (the parents are visited from left to right, and every declaration is visited once)
sub _parents_first {
    my ($self, $seen, $out) = @_;

    $seen //= {};
    $out  //= [];

    $seen->{refaddr($self)}++ and return @$out;

    foreach my $parent (@{$self->{parents}}) {
        $parent->_parents_first($seen, $out);
    }

    push @$out, $self;
    return @$out;
}

# The fields that are owned by a declaration
sub owned_by {
    my ($self, $decl) = @_;
    return ($self->{owned}{refaddr($decl)} //= {});
}

# Sets @ISA and the method resolution order of the Perl package
sub _install_isa {
    my ($self) = @_;

    my $package = $self->{package};

    no strict 'refs';
    my $isa = \@{$package . '::ISA'};

    # The base class of all the objects must be the last one
    my $base = 'Sidef::Object::Object';
    my %seen = ($package => 1, $base => 1);

    @$isa = grep { !$seen{$_}++ } @$isa, map { $_->{package} } @{$self->{parents}};
    push @$isa, $base if $package ne $base;

    # C3 is the right order for multiple inheritance; fall back to the default (DFS) order when the
    # hierarchy is inconsistent in terms of packages (a package-level cycle, for example)
    mro::set_mro($package, 'c3');
    if (not eval { mro::get_linear_isa($package); 1 }) {
        mro::set_mro($package, 'dfs');
    }

    return;
}

# Adds parents to a built-in class (its methods are extended in place)
sub extend {
    my ($class, $package, @parents) = @_;

    no strict 'refs';
    my $isa = \@{$package . '::ISA'};

    my %seen = map { $_ => 1 } @$isa, $package;
    push @$isa, grep { !$seen{$_}++ } @parents;

    return;
}

# Accessors: `obj.name` and `obj.name = value`
sub _install_accessors {
    my ($self) = @_;

    my $package = $self->{package};

    no strict 'refs';
    no warnings 'redefine';

    foreach my $name ((map { $_->{name} } @{$self->{params}}), @{$self->{attrs}}) {
        *{$package . '::' . $name} = sub : lvalue { $_[0]->{$name} };
    }

    return;
}

# The constructor: Class.new(...) and Class(...)
sub _install_constructor {
    my ($self) = @_;

    my @vars = @{$self->{ctor_p}};
    my $key  = $self->{key};

    my $ctor = Sidef::Types::Block::Block->new(
        type  => $self->{type},
        name  => $self->{name},
        vars  => \@vars,
        table => {map { $vars[$_]{name} => $_ } 0 .. $#vars},
        code  => sub {
            return $self->instantiate(@_);
        },
    );

    $self->{ctor} = $ctor;

    no strict 'refs';
    no warnings 'redefine';

    *{$self->{package} . '::new'} = *{$self->{package} . '::call'} = sub {
        CORE::shift(@_);
        $ctor->call(@_);
    };

    return;
}

# Creates an object. The arguments are the values of the constructor parameters (in order).
sub instantiate {
    my ($self, @args) = @_;

    my @vars = @{$self->{ctor_p}};
    my %self;

    foreach my $var (@vars) {
        my $name = $var->{name};
        if ($var->{slurpy}) {
            my @rest = splice(@args);
            $self{$name} = (
                            $var->{array}
                            ? CORE::bless([@rest], 'Sidef::Types::Array::Array')
                            : CORE::bless({@rest}, 'Sidef::Types::Hash::Hash')
                           );
        }
        else {
            $self{$name} = shift(@args);
        }
    }

    my $obj = CORE::bless(\%self, $self->{package});
    my @mro = $self->linearize;

    # The default values of the parameters: the most derived class first
    foreach my $decl (@mro) {
        $decl->{defaults} // next;
        $decl->{defaults}->($obj, $self->owned_by($decl));
    }

    # The attributes: the most derived class first, because the initializers of a class read the
    # fields that may be overridden by the classes that inherit from it
    foreach my $decl (@mro) {
        $decl->{build} // next;
        $decl->{build}->($obj, $self->owned_by($decl));
    }

    if (defined(my $init = UNIVERSAL::can($obj, 'init'))) {
        $init->($obj);
    }

    return $obj;
}

1;
