package Sidef::Eval::Eval {

    use 5.014;

    sub new {
        my (undef, $parser, $vars, $ref_vars_refs) = @_;
        bless {parser => $parser, vars => $vars, ref_vars_refs => $ref_vars_refs}, __PACKAGE__;
    }

    sub eval {
        my ($self, $string) = @_;
        local $self->{parser}{vars}          = $self->{vars};
        local $self->{parser}{ref_vars_refs} = $self->{ref_vars_refs};
        my $struct = $self->{parser}->parse_script(code => $string);
        Sidef::Types::Block::Code->new($struct)->run;
    }

};

1
