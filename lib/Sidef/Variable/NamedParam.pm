package Sidef::Variable::NamedParam {

    use utf8;
    use 5.016;
    use overload q{""} => \&dump;

    use parent qw(
      Sidef::Types::Hash::Hash
      );

    use Sidef::Types::Array::Array;

    sub new {
        my (undef, $name, @args) = @_;
        bless {
               name  => "$name",
               value => bless(\@args, 'Sidef::Types::Array::Array'),
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub name {
        my ($self) = @_;
        Sidef::Types::String::String->new($self->{name});
    }

    sub value {
        my ($self) = @_;
        (@{$self->{value}});
    }

    sub get_value {
        my ($self) = @_;
        map { $_->get_value } @{$self->{value}};
    }

    sub dump {
        my ($self) = @_;
        my ($name, $args) = ($self->{name}, $self->{value});
        my $value = substr("$args", 1, -1);
        Sidef::Types::String::String->new(qq{NamedParam("\Q$name\E", $value)});
    }
}

1;
