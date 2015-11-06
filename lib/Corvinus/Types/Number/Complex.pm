package Corvinus::Types::Number::Complex {

    use utf8;
    use 5.014;

    require Math::Complex;

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload
      q{""}   => \&get_value,
      q{0+}   => \&get_value,
      q{bool} => \&get_value;

    sub new {
        my (undef, $x, $y) = @_;

        $x // return (state $_zero = bless(\Math::Complex->make(0, 0), __PACKAGE__));

        #
        ## Check X
        #
        if (ref($x) eq __PACKAGE__ or ref($x) eq 'Corvinus::Types::Number::Number') {
            $x = $$x;
        }

        if (not defined $y and ref($x) eq 'Math::Complex') {
            return bless \$x, __PACKAGE__;
        }

        if (my $rx = ref($x)) {
            if ($rx eq 'Math::BigRat' or $rx eq 'Math::BigFloat' or $rx eq 'Math::BigInt') {
                $x = $x->numify;
            }
            elsif ($rx eq 'Math::Complex') {
                $x = Math::Complex::Re($x);
            }
            else {
                $x = $x->get_value;
            }
        }

        #
        ## Check Y
        #
        if (ref($y) eq __PACKAGE__ or ref($y) eq 'Corvinus::Types::Number::Number') {
            $y = $$y;
        }

        if (my $ry = ref($y)) {
            if ($ry eq 'Math::BigRat' or $ry eq 'Math::BigFloat' or $ry eq 'Math::BigInt') {
                $y = $y->numify;
            }
            elsif ($ry eq 'Math::Complex') {
                $y = Math::Complex::Im($y);
            }
            else {
                $y = $y->get_value;
            }
        }

        bless \Math::Complex->make($x, $y), __PACKAGE__;
    }

    *call = \&new;

    sub get_value {
        ${$_[0]};
    }

    sub get_constant {
        my ($self, $name) = @_;

        state %cache;
        state $table = {
                        pi => sub { $self->new(Math::Complex::pi()) },
                        i  => sub { $self->new(Math::Complex::i()) },
                       };

        $cache{lc($name)} //= exists($table->{lc($name)}) ? $table->{lc($name)}->() : do {
            warn qq{[WARN] Inexistent Complex constant "$name"!\n};
            undef;
        };
    }

    sub i {
        my ($self) = @_;
        $self->new(Math::Complex::i());
    }

    sub cartesian {
        my ($self) = @_;
        ${$self}->display_format('cartesian');
        $self;
    }

    sub polar {
        my ($self) = @_;
        ${$self}->display_format('polar');
        $self;
    }

    sub real {
        my ($self) = @_;
        $self->new(Math::Complex::Re($$self));
    }

    *re = \&real;

    sub imaginary {
        my ($self) = @_;
        $self->new(Math::Complex::Im($$self));
    }

    *im = \&imaginary;

    sub reciprocal {
        my ($self) = @_;
        $self->new(1 / $$self);
    }

    sub inc {
        my ($self) = @_;
        $self->new($$self + 1);
    }

    sub dec {
        my ($self) = @_;
        $self->new($$self - 1);
    }

    sub cmp {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;

        state $mone = Corvinus::Types::Number::Number->new(-1);
        state $zero = Corvinus::Types::Number::Number->new(0);
        state $one  = Corvinus::Types::Number::Number->new(1);

        my $cmp = $$self <=> $arg->get_value;
        $cmp == 0 ? $zero : $cmp > 0 ? $one : $mone;
    }

    *compara = \&cmp;

    sub gt {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        Corvinus::Types::Bool::Bool->new($$self > $arg->get_value);
    }

    sub lt {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        Corvinus::Types::Bool::Bool->new($$self < $arg->get_value);
    }

    sub ge {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        Corvinus::Types::Bool::Bool->new($$self >= $arg->get_value);
    }

    sub le {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        Corvinus::Types::Bool::Bool->new($$self <= $arg->get_value);
    }

    sub eq {
        my ($self, $arg) = @_;
        Corvinus::Types::Bool::Bool->new($$self == $$arg);
    }

    sub ne {
        my ($self, $arg) = @_;
        Corvinus::Types::Bool::Bool->new($$self != $$arg);
    }

    sub abs {
        my ($self) = @_;
        $self->new($$self->abs);
    }

    *absolut = \&abs;
    *pozitiv = \&abs;

    sub factorial {
        my ($self) = @_;
        my $fac = 1;
        $fac *= $_ for (2 .. $$self);
        $self->new($fac);
    }

    *fac  = \&factorial;
    *fact = \&factorial;

    sub mul {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        $self->new($$self * $arg->get_value);
    }

    *multiplica = \&mul;
    *x = \&mul;

    sub div {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        $self->new($$self / $arg->get_value);
    }

    *imparte = \&div;

    sub add {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        $self->new($$self + $arg->get_value);
    }

    *adauga = \&add;

    sub sub {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        $self->new($$self - $arg->get_value);
    }

    *scade = \&sub;

    sub exp {
        my ($self) = @_;
        $self->new($$self->exp);
    }

    sub log {
        my ($self, $base) = @_;
        $self->new(
            defined($base)
            ? do {
                local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
                $$self->logn($base->get_value);
              }
            : $$self->log
        );
    }

    sub log10 {
        my ($self) = @_;
        $self->new($$self->log10);
    }

    sub sqrt {
        my ($self) = @_;
        $self->new($$self->sqrt);
    }

    *radical = \&sqrt;

    sub pow {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        $self->new($$self**$arg->get_value);
    }

    *la_puterea = \&pow;

    sub int {
        my ($self) = @_;
        $self->new(CORE::int($$self));
    }

    *as_int = \&int;
    *intreg = \&int;

    sub atan2 {
        my ($self, $arg) = @_;
        local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
        $self->new($$self->atan2($arg->get_value));
    }

    sub cos {
        my ($self) = @_;
        $self->new($$self->cos);
    }

    sub sin {
        my ($self) = @_;
        $self->new($$self->sin);
    }

    sub neg {
        my ($self) = @_;
        $self->new($$self->_negate);
    }

    *negate = \&neg;
    *negativ = \&neg;

    sub not {
        my ($self) = @_;
        $self->new(-$$self - 1);
    }

    *conjugated = \&not;
    *conj       = \&not;

    sub pi {
        my ($self) = @_;
        $self->new(Math::Complex::pi());
    }

    sub tan {
        my ($self) = @_;
        $self->new($$self->tan);
    }

    sub csc {
        my ($self) = @_;
        $self->new($$self->csc);
    }

    *cosec = \&csc;

    sub sec {
        my ($self) = @_;
        $self->new($$self->sec);
    }

    sub cot {
        my ($self) = @_;
        $self->new($$self->cot);
    }

    *cotan = \&cot;

    sub asin {
        my ($self) = @_;
        $self->new($$self->asin);
    }

    sub acos {
        my ($self) = @_;
        $self->new($$self->acos);
    }

    sub atan {
        my ($self) = @_;
        $self->new($$self->acos);
    }

    sub acsc {
        my ($self) = @_;
        $self->new($$self->acsc);
    }

    *acosec = \&acsc;

    sub asec {
        my ($self) = @_;
        $self->new($$self->asec);
    }

    sub acot {
        my ($self) = @_;
        $self->new($$self->acot);
    }

    *acotan = \&acot;

    sub sinh {
        my ($self) = @_;
        $self->new($$self->sinh);
    }

    sub cosh {
        my ($self) = @_;
        $self->new($$self->cosh);
    }

    sub tanh {
        my ($self) = @_;
        $self->new($$self->tanh);
    }

    sub csch {
        my ($self) = @_;
        $self->new($$self->csch);
    }

    *cosech = \&csch;

    sub sech {
        my ($self) = @_;
        $self->new($$self->sech);
    }

    sub coth {
        my ($self) = @_;
        $self->new($$self->coth);
    }

    *cotanh = \&coth;

    sub asinh {
        my ($self) = @_;
        $self->new($$self->asinh);
    }

    sub acosh {
        my ($self) = @_;
        $self->new($$self->acosh);
    }

    sub atanh {
        my ($self) = @_;
        $self->new($$self->atanh);
    }

    sub acsch {
        my ($self) = @_;
        $self->new($$self->acsch);
    }

    *acosech = \&acsch;

    sub asech {
        my ($self) = @_;
        $self->new($$self->asech);
    }

    sub acoth {
        my ($self) = @_;
        $self->new($$self->acoth);
    }

    *acotanh = \&acoth;

    sub sign {
        my ($self) = @_;
        Corvinus::Types::String::String->new($$self >= 0 ? '+' : '-');
    }

    sub is_zero {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self == 0);
    }

    *e_zero = \&is_zero;

    sub is_nan {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->false;
    }

    *is_NaN = \&is_nan;
    *nu_e_numar = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self >= 0);
    }

    *e_poz = \&is_positive;
    *e_pozitiv = \&is_positive;
    *is_pos = \&is_positive;

    sub is_negative {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self < 0);
    }

    *e_neg = \&is_negative;
    *e_negativ = \&is_negative;
    *is_neg = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self % 2 == 0);
    }

    *e_par = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self % 2 != 0);
    }

    *e_impar = \&is_odd;

    sub is_inf {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self == 'inf');
    }

    *is_infinite = \&is_inf;
    *e_infinit = \&is_inf;

    sub is_integer {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self == CORE::int($$self));
    }

    *is_int = \&is_integer;
    *e_intreg = \&is_integer;

    sub rand {
        my ($self, $max) = @_;

        my $min = $$self;
        $max = ref($max) ? $max->get_value : do { $min = 0; $$self };

        $self->new($min + CORE::rand($max - $min));
    }

    *aleatoriu = \&rand;

    sub ceil {
        my ($self) = @_;

        CORE::int($$self) == $$self
          && return $self;

        $self->new(CORE::int($$self + 1));
    }

    sub floor {
        my ($self) = @_;
        $self->new(CORE::int($$self));
    }

    sub round { ... }

    sub roundf {
        my ($self, $num) = @_;
        $self->new(sprintf "%.*f", $num->get_value * -1, $$self);
    }

    *fround = \&roundf;
    *rotunjeste_f = \&roundf;

    sub digit { ... }

    sub nok { ... }
    *binomial = \&nok;

    sub length { ... }

    *len = \&length;

    sub sstr {
        my ($self) = @_;
        Corvinus::Types::String::String->new($$self);
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Complex(' . $self->real . ', ', $self->imaginary . ')');
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
    }
};

1
