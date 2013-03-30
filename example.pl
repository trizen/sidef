

# =>> Pure-Perl

*{__PACKAGE__ . '::' . '-'} = sub {
    my ($array_1, $array_2) = @_;
    [grep { not $_ ~~ $array_2 } @{$array_1}];
};

use Data::Dumper;

my $array = \&{'-'};
print Dumper $array->(['Paris', 'Madrid', 'Atena', 'Londra'], ['Madrid', 'Londra']);


# =>> Unknown language

my $code = "['Paris', 'Madrid', 'Atena', 'Londra'] - ['Madrid', 'Londra']";

if($code =~ m{\[(.*?)\]\s*(\S+)\s*\[(.*?)\]}){
    my($items_1, $operator, $items_2) = ($1, $2, $3);

    my $array_1 = [split(/\s*,\s*/, $items_1)];
    my $array_2 = [split(/\s*,\s*/, $items_2)];

    print Dumper $operator->($array_1, $array_2);
}
