package Sidef::Eval::Eval {

    use 5.014;

    sub new {
        my (undef, $parser, $vars) = @_;
        bless {parser => $parser, ref_vars => $vars};
    }

    sub eval {
        my ($self, $string) = @_;
        local $self->{parser}{vars} = $self->{ref_vars};
        my $struct = $self->{parser}->parse_script(code => $string);
        Sidef::Types::Block::Code->new($struct)->run;
    }

};

1
