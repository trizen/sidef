package Sidef::Variable::GetOpt {

    use utf8;
    use 5.016;
    require Getopt::Long;

    sub new {
        my (undef, $argv, $block) = @_;

        foreach my $func ($block, (exists($block->{kids}) ? @{$block->{kids}} : ())) {

            my @types;
            my $slurpy;
            my @argv = @$argv;

            foreach my $v (@{$func->{vars}}) {
                if (exists $v->{type}) {
                    if ($v->{type} eq 'Sidef::Types::Number::Number') {
                        push @types, "$v->{name}=f";
                    }
                    elsif ($v->{type} eq 'Sidef::Types::Bool::Bool') {
                        push @types, "$v->{name}!";
                    }
                    else {
                        push @types, "$v->{name}=s";
                    }
                }
                elsif ($v->{slurpy}) {
                    $slurpy //= $v->{name};
                }
                else {
                    push @types, "$v->{name}=s";
                }
            }

            my %opt;
            do {
                local $SIG{__WARN__} = sub { };
                Getopt::Long::GetOptionsFromArray(\@argv, \%opt, @types) || next;
            };

            my @params;
            foreach my $key (keys %opt) {
                my $var   = $func->{vars}[$func->{table}{$key} // die "[ERROR] unknown command-line argument <<<$key>>>"];
                my $value = $opt{$key};

                if (exists $var->{type}) {
                    $value = $var->{type}->new($value);
                }
                else {
                    $value = Sidef::Types::String::String->new($value);
                }

                push @params, Sidef::Variable::NamedParam->new($key => $value,);
            }

            if (defined($slurpy) and @argv) {
                push @params, Sidef::Variable::NamedParam->new($slurpy, map { Sidef::Types::String::String->new($_) } @argv);
            }

            return $func->call(@params);
        }

        $block->call(map { Sidef::Types::String::String->new($_) } @$argv);
    }

};

1
