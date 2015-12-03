package Corvinus {

    use 5.014;
    our $VERSION = '2.00';

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

    sub normalize_type {
        my ($type) = @_;

        state $trans = {
                        Number    => 'Numar',
                        String    => 'Text',
                        Array     => 'Lista',
                        Hash      => 'Dict',
                        Pair      => 'Pereche',
                        Pipe      => 'Proces',
                        Byte      => 'Octet',
                        Bytes     => 'Octeti',
                        File      => 'Fisier',
                        Dir       => 'Dosar',
                        Backtick  => 'Comanda',
                        Time      => 'Timp',
                        Char      => 'Caracter',
                        Chars     => 'Caractere',
                        Grapheme  => 'Grafem',
                        Graphemes => 'Grafeme',
                       };

        if (index($type, 'Corvinus::') == 0) {
            $type = substr($type, rindex($type, '::') + 2);

            if (exists $trans->{$type}) {
                $type = $trans->{$type};
            }
        }
        else {
            $type =~ s/^_:://;
        }

        $type;
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
