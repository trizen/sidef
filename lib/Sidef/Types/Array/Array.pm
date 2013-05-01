
use 5.014;
use strict;
use warnings;

package Sidef::Types::Array::Array {
	
	use parent qw(Sidef::Convert::Convert);

    sub new {
        my ($class) = @_;
        bless [], $class;
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '-'} = sub {
            my ($array_1, $array_2) = @_;
            
				my $new_array = __PACKAGE__->new();
				#push @{$new_array}, grep { not $_ ~~ $array_2 } @{$array_1};
				foreach my $item(@{$array_1}){
					my $exists = 0;
					foreach my $min_item(@{$array_2}){
						if($$min_item eq $$item){
							$exists = 1;
							last;
						}
					}
					push @{$new_array}, $item if not $exists;
				}
				
				return $new_array;
        };
    }

    sub pop {
        my ($self) = @_;
        pop @{$self};
    }
}

1;
