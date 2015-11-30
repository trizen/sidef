package Sidef {

    use 5.014;
    our $VERSION = '2.11';

    our $SPACES      = 0;    # the current number of spaces
    our $SPACES_INCR = 4;    # the number of spaces incrementor

    our @NAMESPACES;         # will keep track of declared modules
    our %INCLUDED;           # will keep track of included modules

    our %EVALS;              # will contain info required for eval()

    use Math::BigInt qw(try GMP);
    use Math::BigRat qw(try GMP);
    use Math::BigFloat qw(try GMP);

    sub new {
        bless {}, __PACKAGE__;
    }

    sub unpack_args {
        map {
            ref($_) && eval { $_->can('to_s') }
              ? $_->to_s
              : $_
        } @_;
    }

    sub normalize_type {
        my ($type) = @_;

        $type =~ s/^_:://;

        if (index($type, 'Sidef::') == 0) {
            $type = substr($type, rindex($type, '::') + 2);
        }

        $type;
    }

};

#
## Some UNIVERSAL magic
#

*UNIVERSAL::get_value = sub {
    ref($_[0]) eq 'Sidef::Module::OO' || ref($_[0]) eq 'Sidef::Module::Func'
      ? $_[0]->{module}
      : $_[0];
};
*UNIVERSAL::DESTROY = sub { };
*UNIVERSAL::AUTOLOAD = sub {
    my ($self, @args) = @_;

    $self = ref($self) if ref($self);

    index($self, 'Sidef::') == 0
      or die("[AUTOLOAD] Undefined method: $AUTOLOAD");

    eval { require $self =~ s{::}{/}rg . '.pm' };

    if ($@) {
        if (defined &main::__load_sidef_module__) {
            main::__load_sidef_module__($self);
        }
        else {
            die "[AUTOLOAD] $@";
        }
    }

    my $func = \&{$AUTOLOAD};
    if (defined(&$func)) {
        return $func->($self, @args);
    }

    die "[AUTOLOAD] Undefined method: $AUTOLOAD";
    return;
};

1;
