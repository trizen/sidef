package Sidef {

    use 5.014;
    our $VERSION = '2.22';

    our $SPACES      = 0;    # the current number of spaces
    our $SPACES_INCR = 4;    # the number of spaces incrementor

    our @NAMESPACES;         # will keep track of declared modules
    our %INCLUDED;           # will keep track of included modules

    our %EVALS;              # will contain info required for eval()

    use Sidef::Types::Bool::Bool;
    use Sidef::Types::Number::Number;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub normalize_type {
        my ($type) = @_;

        if (index($type, 'Sidef::') == 0) {
            $type = substr($type, rindex($type, '::') + 2);
        }
        else {
            $type =~ s/^(?:_::)?main:://
              or $type =~ s/^_:://;
        }

        $type;
    }

    sub normalize_method {
        my ($type, $method) = ($_[0] =~ /^(.*[^:])::(.*)$/);
        normalize_type($type) . ".$method";
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
      or die("[AUTOLOAD] Undefined method `" . Sidef::normalize_method($AUTOLOAD) . q{'});

    eval { require $self =~ s{::}{/}rg . '.pm' };

    if ($@) {
        if (defined &main::__load_sidef_module__) {
            main::__load_sidef_module__($self);
        }
        else {
            die "[AUTOLOAD] $@";
        }
    }

    if (defined(&$AUTOLOAD)) {
        return $AUTOLOAD->($self, @args);
    }

    my @caller = caller(1);
    my $from   = Sidef::normalize_method($caller[3]);
    $from = $from eq '.' ? 'main()' : "$from()";
    die("[AUTOLOAD] Undefined method `" . Sidef::normalize_method($AUTOLOAD) . q{'} . " called from $from\n");
    return;
};

1;
