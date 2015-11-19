package Corvinus::Types::Number::Number {

    use utf8;
    use 5.014;

    our $GET_PERL_VALUE = 0;

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload
      q{bool} => sub { ${$_[0]} != 0 },
      q{0+}   => sub { ${$_[0]}->numify },
      q{""}   => sub { ${$_[0]}->bstr };

    my %cache;

    sub new {
        my (undef, $num) = @_;

        ref($num) eq 'Math::BigFloat' || ref($num) eq 'Math::BigRat'
          ? (bless \$num => __PACKAGE__)
          : (
            ref($num) || (length($num) > 5) ? (
               bless \do {
                   eval { Math::BigFloat->new($num) } // Math::BigFloat->new(Math::BigInt->new($num));
                 }
                 => __PACKAGE__
              )
            : (
               $cache{$num} //= (
                   bless \do {
                       eval { Math::BigFloat->new($num) } // Math::BigFloat->new(Math::BigInt->new($num));
                     }
                     => __PACKAGE__
               )
              )
            );
    }

    *call = \&new;

    sub get_value {
        $GET_PERL_VALUE ? ${$_[0]}->numify : ${$_[0]};
    }

    sub mod {
        my ($self, $num) = @_;
        $self->new($$self % $num->get_value);
    }

    sub modpow {
        my ($self, $y, $mod) = @_;
        $self->new($$self->copy->bmodpow($y->get_value, $mod->get_value));
    }

    *expmod = \&modpow;

    sub pow {
        my ($self, $num) = @_;
        $self->new($$self->copy->bpow($num->get_value));
    }

    *la_puterea = \&pow;
    *putere     = \&pow;

    sub inc {
        my ($self) = @_;
        $self->new($$self->copy->binc);
    }

    sub dec {
        my ($self) = @_;
        $self->new($$self->copy->bdec);
    }

    sub and {
        my ($self, $num) = @_;
        $self->new($$self->as_int->band($num->get_value->as_int));
    }

    sub or {
        my ($self, $num) = @_;
        $self->new($$self->as_int->bior($num->get_value->as_int));
    }

    sub xor {
        my ($self, $num) = @_;
        $self->new($$self->as_int->bxor($num->get_value->as_int));
    }

    sub eq {
        my ($self, $arg) = @_;
        Corvinus::Types::Bool::Bool->new($$self->bcmp($$arg) == 0);
    }

    *equals = \&eq;
    *este   = \&eq;

    sub ne {
        my ($self, $arg) = @_;
        Corvinus::Types::Bool::Bool->new($$self->bcmp($$arg) != 0);
    }

    *nu_este = \&ne;

    sub cmp {
        my ($self, $num) = @_;

        state $mone = Corvinus::Types::Number::Number->new(-1);
        state $zero = Corvinus::Types::Number::Number->new(0);
        state $one  = Corvinus::Types::Number::Number->new(1);

        my $cmp = $$self->bcmp($num->get_value);
        $cmp == 0 ? $zero : $cmp > 0 ? $one : $mone;
    }

    *compara = \&cmp;

    sub acmp {
        my ($self, $num) = @_;

        state $mone = Corvinus::Types::Number::Number->new(-1);
        state $zero = Corvinus::Types::Number::Number->new(0);
        state $one  = Corvinus::Types::Number::Number->new(1);

        my $cmp = $$self->bacmp($num->get_value);
        $cmp == 0 ? $zero : $cmp > 0 ? $one : $mone;
    }

    *acompara = \&acmp;

    sub gt {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($$self->bcmp($num->get_value) > 0);
    }

    sub lt {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($$self->bcmp($num->get_value) < 0);
    }

    sub ge {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($$self->bcmp($num->get_value) >= 0);
    }

    sub le {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($$self->bcmp($num->get_value) <= 0);
    }

    sub sub {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->bsub($num->get_value));
    }

    *scade = \&sub;

    sub add {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->badd($num->get_value));
    }

    *adauga = \&add;

    sub mul {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->bmul($num->get_value));
    }

    *multiplica = \&mul;
    *x          = \&mul;

    sub div {
        my ($self, $num) = @_;
        $self->new(scalar $$self->copy->bdiv($num->get_value));
    }

    *imparte = \&div;

    sub divmod {
        my ($self, $num) = @_;
        ($self->div($num)->int, $self->mod($num));
    }

    sub factorial {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bfac);
    }

    *fac  = \&factorial;
    *fact = \&factorial;

    sub array_to {
        my ($self, $num, $step) = @_;

        $step = defined($step) ? $step->get_value : 1;

        my @array;
        my $to = $num->get_value;

        if ($step == 1) {

            # Unpack limit
            $to = $to->bstr if ref($to);

            foreach my $i ($$self .. $to) {
                push @array, $self->new($i);
            }
        }
        else {
            for (my $i = $$self ; $i <= $to ; $i += $step) {
                push @array, $self->new($i);
            }
        }

        Corvinus::Types::Array::Array->new(@array);
    }

    *arr_to = \&array_to;

    sub array_downto {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;

        my @array;
        my $downto = $num->get_value;

        for (my $i = $$self ; $i >= $downto ; $i -= $step) {
            push @array, $self->new($i);
        }

        Corvinus::Types::Array::Array->new(@array);
    }

    *lista_coboara_la = \&array_downto;
    *arr_downto       = \&array_downto;

    sub to {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;
        Corvinus::Types::Range::RangeNumber->__new__(
                                                     from => $$self,
                                                     to   => $num->get_value,
                                                     step => $step,
                                                    );
    }

    *upto    = \&to;
    *up_to   = \&to;
    *pana_la = \&to;

    sub downto {
        my ($self, $num, $step) = @_;
        $step = defined($step) ? $step->get_value : 1;
        Corvinus::Types::Range::RangeNumber->__new__(
                                                     from => $$self,
                                                     to   => $num->get_value,
                                                     step => -$step,
                                                    );
    }

    *coboara_la = \&downto;
    *down_to    = \&downto;

    sub range {
        my ($self, $to, $step) = @_;

        state $from = $self->new(0);

        defined($to)
          ? $self->to($to, $step)
          : $from->to($self);
    }

    *sir = \&range;

    sub sqrt {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bsqrt);
    }

    *radical = \&sqrt;

    sub root {
        my ($self, $n) = @_;
        $self->new(scalar $$self->copy->broot($n->get_value));
    }

    *radacina = \&root;

    sub troot {
        my ($self) = @_;

        state $two   = Math::BigFloat->new(2);
        state $eight = Math::BigFloat->new(8);

        $self->new(scalar $$self->copy->bmul($eight)->binc->bsqrt->bdec->bdiv($two));
    }

    *radacina_tr = \&troot;

    sub abs {
        my ($self) = @_;
        $self->new(scalar $$self->copy->babs);
    }

    *absolut  = \&abs;
    *pozitiv  = \&abs;
    *pos      = \&abs;
    *positive = \&abs;

    sub hex {
        my ($self) = @_;
        $self->new(Math::BigInt->new("0x$$self"));
    }

    *from_hex = \&hex;

    sub oct {
        my ($self) = @_;
        $self->new(Math::BigInt->from_oct($$self));
    }

    *from_oct = \&oct;

    sub bin {
        my ($self) = @_;
        $self->new(Math::BigInt->new("0b$$self"));
    }

    *from_bin = \&bin;

    sub exp {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bexp);
    }

    sub int {
        my ($self) = @_;
        $self->new($$self->as_int);
    }

    *as_int = \&int;
    *to_i   = \&int;
    *intreg = \&int;

    sub max {
        my ($self, $arg) = @_;
        $$self->bcmp($arg->get_value) >= 0 ? $self : $arg;
    }

    *maxim = \&max;

    sub min {
        my ($self, $arg) = @_;
        $$self->bcmp($arg->get_value) <= 0 ? $self : $arg;
    }

    *minim = \&min;

    sub cos {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bcos);
    }

    sub sin {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bsin);
    }

    sub atan {
        my ($self) = @_;
        $self->new(scalar $$self->copy->batan);
    }

    sub atan2 {
        my ($self, $y) = @_;
        $self->new(scalar $$self->copy->batan2($y->get_value));
    }

    sub log {
        my ($self, $base) = @_;
        $self->new(scalar $$self->copy->blog(defined($base) ? $base->get_value : ()));
    }

    sub ln {
        my ($self) = @_;
        $self->new(scalar $$self->copy->blog);
    }

    sub log10 {
        my ($self) = @_;
        state $ten = Math::BigFloat->new(10);
        $self->new(scalar $$self->copy->blog($ten));
    }

    sub log2 {
        my ($self) = @_;
        state $two = Math::BigFloat->new(2);
        $self->new(scalar $$self->copy->blog($two));
    }

    sub inf {
        my ($self, $sign) = @_;
        $self->new(Math::BigInt->binf(defined($sign) ? $sign->get_value : ()));
    }

    sub neg {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bneg);
    }

    *negate  = \&neg;
    *negativ = \&neg;

    sub not {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bnot);
    }

    sub sign {
        my ($self) = @_;
        Corvinus::Types::String::String->new($$self->sign);
    }

    sub nan {
        my ($self) = @_;
        $self->new(Math::BigFloat->bnan);
    }

    *NaN = \&nan;

    sub chr {
        my ($self) = @_;
        Corvinus::Types::String::String->new(CORE::chr($$self->numify));
    }

    sub npow2 {
        my ($self) = @_;
        state $two = Math::BigInt->new(2);
        $self->new(scalar $two->copy->blsft($$self->as_int->blog($two)));
    }

    sub npow {
        my ($self, $num) = @_;
        $num = $num->get_value;
        return $self->new(scalar $num->copy->bpow($$self->copy->blog($num)->binc->as_int));
    }

    sub is_zero {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_zero);
    }

    *e_zero = \&is_zero;

    sub is_one {
        my ($self, $sign) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_one(defined($sign) ? $sign->get_value : ('+')));
    }

    *e_unu = \&is_one;

    sub is_nan {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_nan);
    }

    *is_NaN     = \&is_nan;
    *nu_e_numar = \&is_nan;

    sub is_positive {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_pos);
    }

    *e_poz     = \&is_positive;
    *is_pos    = \&is_positive;
    *e_pozitiv = \&is_positive;

    sub is_negative {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_neg);
    }

    *e_neg     = \&is_negative;
    *e_negativ = \&is_negative;
    *is_neg    = \&is_negative;

    sub is_even {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->as_int->is_even);
    }

    *e_par = \&is_even;

    sub is_odd {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->as_int->is_odd);
    }

    *e_impar = \&is_odd;

    sub is_inf {
        my ($self, $sign) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_inf(defined($sign) ? $sign->get_value : ()));
    }

    *e_infinit   = \&is_inf;
    *is_infinite = \&is_inf;

    sub is_integer {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new($$self->is_int);
    }

    *e_intreg = \&is_integer;
    *is_int   = \&is_integer;

    sub rand {
        my ($self, $max) = @_;
        defined($max)
          ? $self->new($$self + CORE::rand($max->get_value - $$self))
          : $self->new(CORE::rand($$self));
    }

    *aleatoriu = \&rand;

    sub ceil {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bceil);
    }

    sub floor {
        my ($self) = @_;
        $self->new(scalar $$self->copy->bfloor);
    }

    sub round {
        my ($self, $places) = @_;
        $self->new(
                   $$self->copy->bround(
                                        defined($places)
                                        ? $places->get_value
                                        : ()
                                       )
                  );
    }

    *rotunjeste = \&round;

    sub roundf {
        my ($self, $places) = @_;
        $self->new(
                   $$self->copy->bfround(
                                         defined($places)
                                         ? $places->get_value
                                         : ()
                                        )
                  );
    }

    *rotunjeste_f = \&roundf;

    *fround = \&roundf;

    sub length {
        my ($self) = @_;
        $self->new($$self->length);
    }

    *lungime = \&length;
    *len     = \&length;

    sub digit {
        my ($self, $n) = @_;
        $self->new(scalar $$self->as_int->digit($n->get_value));
    }

    *cifra = \&digit;

    sub digits {
        my ($self) = @_;

        my $len = $$self->length;
        my $int = $$self->as_int;

        my @digits;
        foreach my $i (0 .. $len - 1) {
            unshift @digits, $self->new($int->digit($i));
        }
        Corvinus::Types::Array::Array->new(@digits);
    }

    *cifre    = \&digits;
    *ca_cifre = \&digits;

    sub nok {
        my ($self, $k) = @_;
        $self->new(scalar $$self->as_int->bnok($k->get_value));
    }

    *binomial = \&nok;

    sub of {
        my ($self, $obj) = @_;

        if (ref($obj) eq 'Corvinus::Types::Block::Code') {
            return Corvinus::Types::Array::Array->new(map { $obj->run($self->new($_)) } 1 .. $$self);
        }

        Corvinus::Types::Array::Array->new(($obj) x $$self);
    }

    *de = \&of;

    sub times {
        my ($self, $obj) = @_;
        $obj->repeat($self);
    }

    *ori = \&times;

    sub to_bin {
        my ($self) = @_;
        Corvinus::Types::String::String->new(substr(Math::BigInt->new($$self)->as_bin, 2));
    }

    *as_bin = \&to_bin;
    *ca_bin = \&to_bin;

    sub to_oct {
        my ($self) = @_;
        Corvinus::Types::String::String->new(substr(Math::BigInt->new($$self)->as_oct, 1));
    }

    *as_oct = \&to_oct;
    *ca_oct = \&to_oct;

    sub to_hex {
        my ($self) = @_;
        Corvinus::Types::String::String->new(substr(Math::BigInt->new($$self)->as_hex, 2));
    }

    *as_hex = \&to_hex;
    *ca_hex = \&to_hex;

    sub is_div {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new($$self->copy->bmod($num->get_value)->is_zero);
    }

    *e_div       = \&is_div;
    *e_divizibil = \&is_div;

    sub divides {
        my ($self, $num) = @_;
        Corvinus::Types::Bool::Bool->new(Math::BigFloat->new($num->get_value)->bmod($$self)->is_zero);
    }

    *divide = \&divides;

    sub commify {
        my ($self) = @_;

        my $n = $$self;
        $n = $n->bstr if ref($n);

        my $x   = $n;
        my $neg = $n =~ s{^-}{};
        $n =~ /\.|$/;

        if ($-[0] > 3) {

            my $l = $-[0] - 3;
            my $i = ($l - 1) % 3 + 1;

            $x = substr($n, 0, $i) . ',';

            while ($i < $l) {
                $x .= substr($n, $i, 3) . ',';
                $i += 3;
            }

            $x .= substr($n, $i);
        }

        Corvinus::Types::String::String->new(($neg ? '-' : '') . $x);
    }

    sub rat {
        my ($self) = @_;
        $self->new(Math::BigRat->new($$self));
    }

    *rational = \&rat;

    sub numerator {
        my ($self) = @_;
        $self->new($$self->numerator);
    }

    sub denominator {
        my ($self) = @_;
        $self->new($$self->denominator);
    }

    sub parts {
        my ($self) = @_;
        map { $self->new($_) } $$self->parts;
    }

    *nude = \&parts;

    sub rdiv {
        my ($self, $arg) = @_;
        $self->new(scalar Math::BigRat->new($$self)->bdiv($$arg));
    }

    *rat_div = \&rdiv;

    sub as_float {
        my ($self) = @_;
        $self->new($$self->as_float);
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new($$self->bstr);
    }

    *to_s = \&dump;

    sub sstr {
        my ($self) = @_;
        Corvinus::Types::String::String->new($$self->bsstr);
    }

    sub shift_right {
        my ($self, $num, $base) = @_;
        $self->new($$self->copy->brsft($num->get_value, (defined($base) ? $base->get_value : ())));
    }

    sub shift_left {
        my ($self, $num, $base) = @_;
        $self->new($$self->copy->blsft($num->get_value, defined($base) ? $base->get_value : ()));
    }

    sub complex {
        my ($self, $num) = @_;
        Corvinus::Types::Number::Complex->new($self, $num);
    }

    *c = \&complex;

    sub i {
        my ($self) = @_;
        Corvinus::Types::Number::Complex->new(0, $$self);
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '/'}   = \&div;
        *{__PACKAGE__ . '::' . '÷'}  = \&div;
        *{__PACKAGE__ . '::' . '*'}   = \&mul;
        *{__PACKAGE__ . '::' . '+'}   = \&add;
        *{__PACKAGE__ . '::' . '-'}   = \&sub;
        *{__PACKAGE__ . '::' . '%'}   = \&mod;
        *{__PACKAGE__ . '::' . '**'}  = \&pow;
        *{__PACKAGE__ . '::' . '++'}  = \&inc;
        *{__PACKAGE__ . '::' . '--'}  = \&dec;
        *{__PACKAGE__ . '::' . '<'}   = \&lt;
        *{__PACKAGE__ . '::' . '>'}   = \&gt;
        *{__PACKAGE__ . '::' . '&'}   = \&and;
        *{__PACKAGE__ . '::' . '|'}   = \&or;
        *{__PACKAGE__ . '::' . '^'}   = \&xor;
        *{__PACKAGE__ . '::' . '<=>'} = \&cmp;
        *{__PACKAGE__ . '::' . '<='}  = \&le;
        *{__PACKAGE__ . '::' . '≤'} = \&le;
        *{__PACKAGE__ . '::' . '>='}  = \&ge;
        *{__PACKAGE__ . '::' . '≥'} = \&ge;
        *{__PACKAGE__ . '::' . '=='}  = \&eq;
        *{__PACKAGE__ . '::' . '!='}  = \&ne;
        *{__PACKAGE__ . '::' . '≠'} = \&ne;
        *{__PACKAGE__ . '::' . '..'}  = \&array_to;
        *{__PACKAGE__ . '::' . '...'} = \&to;
        *{__PACKAGE__ . '::' . '..^'} = \&to;
        *{__PACKAGE__ . '::' . '^..'} = \&downto;
        *{__PACKAGE__ . '::' . '!'}   = \&factorial;
        *{__PACKAGE__ . '::' . '%%'}  = \&is_div;
        *{__PACKAGE__ . '::' . '>>'}  = \&shift_right;
        *{__PACKAGE__ . '::' . '<<'}  = \&shift_left;
        *{__PACKAGE__ . '::' . '~'}   = \&not;
        *{__PACKAGE__ . '::' . ':'}   = \&complex;
        *{__PACKAGE__ . '::' . '//'}  = \&rdiv;
    }
};

1;
