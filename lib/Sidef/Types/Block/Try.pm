package Sidef::Types::Block::Try {

    use 5.014;

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub catch {
        my ($self, $code) = @_;

        $self->{catch}
          ? $code->run(Sidef::Types::String::String->new($self->{type}),
                       Sidef::Types::String::String->new($self->{msg} =~ s/^\[.*?\]\h*//r)->chomp)
          : $self->{val};
    }

};

1
