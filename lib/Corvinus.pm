package Corvinus {

    use 5.014;
    our $VERSION = '0.01';

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
};

#
## Some UNIVERSAL magic
#

*UNIVERSAL::get_value = sub {
    ref($_[0]) eq 'Corvinus::Module::OO' || ref($_[0]) eq 'Corvinus::Module::Func'
      ? $_[0]->{module}
      : $_[0];
};
*UNIVERSAL::DESTROY = sub { };
*UNIVERSAL::AUTOLOAD = sub {
    my ($self, @args) = @_;

    $self = ref($self) if ref($self);

    index($self, 'Corvinus::') == 0
      or die("[AUTOLOAD] Undefined method: $AUTOLOAD");

    eval { require $self =~ s{::}{/}rg . '.pm' };

    if ($@) {
        if (defined &main::__load_corvinus_module__) {
            main::__load_corvinus_module__($self);
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
