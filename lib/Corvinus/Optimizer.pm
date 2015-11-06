package Corvinus::Optimizer {

    use 5.014;
    require Scalar::Util;

    use constant {
                  STRING  => 'Corvinus::Types::String::String',
                  NUMBER  => 'Corvinus::Types::Number::Number',
                  REGEX   => 'Corvinus::Types::Regex::Regex',
                  BOOL    => 'Corvinus::Types::Bool::Bool',
                  ARRAY   => 'Corvinus::Types::Array::Array',
                  MATH    => 'Corvinus::Math::Math',
                  FILE    => 'Corvinus::Types::Glob::File',
                  SOCKET  => 'Corvinus::Types::Glob::Socket',
                  COMPLEX => 'Corvinus::Types::Number::Complex',
                 };

    {
        my %cache;

        sub methods {
            my ($package, @names) = @_;
            my $module = $cache{$package} //= (($package =~ s{::}{/}gr) . '.pm');
            exists($INC{$module}) || require($module);
            map { \&{$package . '::' . $_} } @names;
        }
    }

    sub table {
        scalar {map { $_ => 1 } @_};
    }

    my %rules = (
        (STRING) => [

            # String.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(STRING, qw(
                   concat
                   gt lt le ge cmp

                   xor and or
                   eq ne

                   index
                   unpack

                   levenshtein
                   contains
                   overlaps
                   begins_with
                   ends_with
                   count

                   sprintf
                   sprintlnf

                   encode
                   decode
                   )
               )
            ),

            # String.method()
            (
             map {
                 { $_, [] }
               } methods(STRING, qw(
                   lc uc tc wc tclc lcfirst

                   pop
                   chomp
                   length

                   ord
                   oct
                   hex
                   bin
                   num
                   not

                   repeat
                   reverse
                   clear
                   is_empty

                   trim
                   trim_beg
                   trim_end

                   encode_utf8
                   decode_utf8

                   sprintf
                   sprintlnf

                   dump to_s
                   apply_escapes
                   unescape
                   quotemeta
                   looks_like_number
                   )
               )
            ),

            # String.method(Number)
            (
             map {
                 { $_, [table(NUMBER)] }
               } methods(STRING, qw(
                   eq ne

                   times
                   repeat
                   char_at

                   sprintf
                   sprintlnf

                   shift_left
                   shift_right
                   )
               )
            ),

            # String.method(String | Number | Regex)
            #(map {{$_, [table(STRING, NUMBER, REGEX)]}} methods(STRING, qw(split))),

            # String.method(String, String)
            (
             map {
                 { $_, [table(STRING), table(STRING)] }
               } methods(STRING, qw(
                   tr
                   )
               )
            ),

            # String.method(String, String, String)
            (
             map {
                 { $_, [table(STRING), table(STRING), table(STRING)] }
               } methods(STRING, qw(
                   tr
                   )
               )
            ),

            # String.method(String, Number)
            (
             map {
                 { $_, [table(STRING), table(NUMBER)] }
               } methods(STRING, qw(
                   index
                   contains
                   sprintf
                   sprintlnf
                   )
               )
            ),

        ],

        (NUMBER) => [

            # Number.method(Number)
            (
             map {
                 { $_, [table(NUMBER)] }
               } methods(NUMBER, qw(
                   + - / * % **

                   lt gt le ge cmp acmp
                   eq ne
                   and or xor

                   divmod

                   complex
                   root log
                   max min
                   round roundf
                   digit
                   nok
                   is_div

                   shift_right
                   shift_left
                   next_power_of
                   )
               )
            ),

            # Number.method()
            (
             map {
                 { $_, [] }
               } methods(NUMBER, qw(
                   inc dec not

                   factorial
                   sqrt
                   abs

                   hex oct bin
                   exp int
                   cos sin
                   log ln log10 log2

                   infinity
                   negate
                   sign
                   nan
                   chr

                   is_zero
                   is_nan
                   is_positive
                   is_negative
                   is_even
                   is_odd
                   is_inf
                   is_int

                   ceil
                   floor
                   length

                   as_bin
                   as_oct
                   as_hex

                   complex i

                   sstr
                   dump
                   commify
                   next_power_of_two
                   )
               )
            ),

            # Number.method(Number, Number)
            (
             map {
                 { $_, [table(NUMBER), table(NUMBER)] }
               } methods(NUMBER, qw(
                   shift_right
                   shift_left
                   )
               )
            ),
        ],

        (BOOL) => [
            (
             map {
                 { $_, [] }
               } methods(BOOL, qw(
                   not
                   is_true
                   true
                   false
                   to_bool
                   dump
                   )
               )
            ),
        ],

        (ARRAY) => [
            (
             map {
                 { $_, [] }
               } methods(ARRAY, qw(
                   first
                   last

                   len end
                   is_empty

                   min max
                   minmax

                   sum
                   prod

                   to_s
                   to_list
                   dump
                   )
               )
            ),

            (
             map {
                 { $_, [table(NUMBER)] }
               } methods(ARRAY, qw(
                   exists
                   defined
                   )
               )
            ),

            (
             map {
                 { $_, [table(STRING)] }
               } methods(ARRAY, qw(
                   pack
                   join
                   )
               )
            ),

            (
             map {
                 { $_, [table('')] }
               } methods(ARRAY, qw(reduce_operator))
            ),
        ],

        (MATH) => [

            # Math.method(Number)
            (
             map {
                 { $_, [table(NUMBER)] }
               } methods(MATH, qw(
                   sqrt
                   root
                   pow
                   exp

                   e
                   pi

                   atan
                   atan2
                   cos
                   sin
                   asin

                   log
                   log2
                   log10
                   npow2

                   abs
                   ceil
                   floor
                   )
               )
            ),

            # Math.method(Number, Number)
            (
             map {
                 { $_, [table(NUMBER), table(NUMBER)] }
               } methods(MATH, qw(
                   exp
                   atan
                   atan2
                   cos
                   sin
                   asin

                   log
                   npow
                   )
               )
            ),

            # Math.method()
            (
             map {
                 { $_, [] }
               } methods(MATH, qw(
                   e
                   pi
                   inf
                   )
               )
            ),

            # Math.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(MATH, qw(get_constant))
            ),
        ],

        (FILE) => [

            # File.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(FILE, qw(get_constant))
            ),
        ],

        (SOCKET) => [

            # Socket.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(SOCKET, qw(get_constant))
            ),
        ],

        (COMPLEX) => [

            # Complex.method(Complex)
            (
             map {
                 { $_, [table(COMPLEX)] }
               } methods(COMPLEX, qw(
                   cmp
                   roundf
                   )
               )
            ),

            # Complex.method()
            (
             map {
                 { $_, [] }
               } methods(COMPLEX, qw(
                   inc
                   dec

                   int
                   negate
                   not
                   sign

                   real
                   imaginary

                   is_zero
                   is_nan
                   is_positive
                   is_negative
                   is_even
                   is_odd
                   is_inf
                   is_int

                   ceil
                   floor

                   sstr
                   dump
                   factorial
                   )
               )
            ),

            # Complex.method(String)
            (
             map {
                 { $_, [table(STRING)] }
               } methods(COMPLEX, qw(get_constant))
            ),
        ],
    );

    my %addr;

    sub new {
        my (undef, %opts) = @_;
        %addr = ();
        bless \%opts, __PACKAGE__;
    }

    sub optimize_expr {
        my ($self, $expr) = @_;

        my $obj = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $obj = $self->optimize($obj);
        }
        elsif ($ref eq "Corvinus::Variable::Variable") {
            if ($obj->{type} eq 'var') {
                ## ok
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{Scalar::Util::refaddr($obj)}++) {
                    ## ok
                }
                else {
                    $obj->{value} = $self->optimize_expr({self => $obj->{value}});
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::ClassInit') {
            if ($addr{Scalar::Util::refaddr($obj)}++) {
                ## ok
            }
            else {
                $obj->{block} = $self->optimize_expr({self => $obj->{block}});
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Init') {
            if ($addr{Scalar::Util::refaddr($obj)}++) {
                ## ok
            }
            else {
                if (exists $obj->{args}) {
                    my %code = $self->optimize($obj->{args});
                    $obj->{args} = \%code;
                }
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::CodeInit') {
            if ($addr{Scalar::Util::refaddr($obj)}++) {
                ## ok
            }
            else {
                my %code = $self->optimize($obj->{code});
                $obj->{code} = \%code;
            }
        }
        elsif ($ref eq 'Corvinus::Types::Array::HCArray') {
            foreach my $i (0 .. $#{$obj}) {
                if (ref($obj->[$i]) eq 'HASH') {
                    $obj->[$i] = $self->optimize_expr($obj->[$i]);
                }
            }
        }

        if (not exists($expr->{ind}) and not exists($expr->{lookup}) and not exists($expr->{call})) {
            return (ref($obj) eq 'HASH' ? {self => $obj} : $obj);
        }

        $obj = {
                self => $obj,
                (exists($expr->{ind})    ? (ind    => []) : ()),
                (exists($expr->{lookup}) ? (lookup => []) : ()),
                (exists($expr->{call})   ? (call   => []) : ()),
               };

        # Array indices
        if (exists $expr->{ind}) {
            foreach my $i (0 .. $#{$expr->{ind}}) {
                $obj->{ind}[$i] = [map { $self->optimize_expr($_) } @{$expr->{ind}[$i]}];
            }
        }

        # Hash lookup
        if (exists $expr->{lookup}) {
            foreach my $i (0 .. $#{$expr->{lookup}}) {
                $obj->{lookup}[$i] = [map { ref($_) eq 'HASH' ? $self->optimize_expr($_) : $_ } @{$expr->{lookup}[$i]}];
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {

            my $count   = 0;
            my $ref_obj = ref($obj->{self});

            foreach my $i (0 .. $#{$expr->{call}}) {
                my $call = $expr->{call}[$i];

                # Method call
                my $method = $call->{method};

                if (defined $method) {
                    if (ref($method) eq 'HASH') {
                        $method = $self->optimize_expr($method) // {self => {}};
                    }

                    $obj->{call}[$i] = {method => $method};
                }
                elsif (exists $call->{keyword}) {
                    $obj->{call}[$i] = {keyword => $call->{keyword}};
                }

                # Method arguments
                if (exists $call->{arg}) {
                    foreach my $j (0 .. $#{$call->{arg}}) {
                        my $arg = $call->{arg}[$j];
                        push @{$obj->{call}[$i]{arg}}, ref $arg eq 'HASH'
                          && $ref_obj ne 'Corvinus::Types::Block::For' ? do { my %arg = $self->optimize($arg); \%arg } : $arg;
                    }
                }

                # Block
                if (exists $call->{block}) {
                    foreach my $j (0 .. $#{$call->{block}}) {
                        my $arg = $call->{block}[$j];
                        push @{$obj->{call}[$i]{block}},
                          ref $arg eq 'HASH' ? do { my %arg = $self->optimize($arg); \%arg } : $arg;
                    }
                }

                #
                ## Constant folding support
                #
                my $optimized = 0;
                if (    defined($ref_obj)
                    and exists($rules{$ref_obj})
                    and not exists($expr->{ind})
                    and not exists($expr->{lookup})
                    and ref($method) eq '') {

                    my $code = $ref_obj->SUPER::can($method);

                    if (defined $code) {
                        my $obj_call = $obj->{call}[$i];

                        foreach my $rule (@{$rules{$ref_obj}}) {

                            if (exists($rule->{$code})
                                and (exists($obj_call->{arg}) ? ($#{$obj_call->{arg}} == 0) : 1)) {

                                my @args = (
                                      exists($obj_call->{arg})
                                    ? ref($obj_call->{arg}[0]) eq 'HASH'
                                          ? do {
                                              @{(values(%{$obj_call->{arg}[0]}))[0]};
                                          }
                                          : $obj_call->{arg}[0]
                                    : ()
                                );

                                if ($#args == $#{$rule->{$code}}) {

                                    my $ok = 1;
                                    foreach my $j (0 .. $#args) {
                                        if (not exists($rule->{$code}[$j]{ref($args[$j])})) {
                                            $ok = 0;
                                            last;
                                        }
                                    }

                                    if ($ok) {
                                        $obj->{self} = $obj->{self}->$code(@args);
                                        $ref_obj     = ref($obj->{self});
                                        $optimized   = 1;
                                    }

                                    last;
                                }
                            }
                        }
                    }
                }

                if ($optimized) {
                    ++$count;
                }
                else {
                    undef $ref_obj;
                }
            }

            if ($count > 0) {
                if ($count == @{$obj->{call}}) {
                    if (not exists $expr->{ind} and not exists $expr->{lookup}) {
                        return $obj->{self};
                    }
                    else {
                        delete $obj->{call};
                    }
                }
                else {
                    splice(@{$obj->{call}}, 0, $count);
                }
            }
        }

        return $obj;
    }

    sub optimize {
        my ($self, $struct) = @_;

        my %opt_struct;
        my @classes = keys %{$struct};

        foreach my $class (@classes) {
            foreach my $i (0 .. $#{$struct->{$class}}) {
                push @{$opt_struct{$class}}, scalar $self->optimize_expr($struct->{$class}[$i]);
            }
        }

        wantarray ? %opt_struct : $#{$opt_struct{$classes[-1]}} > 0 ? \%opt_struct : $opt_struct{$classes[-1]}[-1];
    }
};

1;
