package Corvinus::Deparse::Perl {

    use utf8;
    use 5.014;

    use List::Util qw(all);
    use Scalar::Util qw(refaddr);

    my %addr;
    my %type;
    my %const;
    my %top_add;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
            before      => '',
            header      => '',
            top_program => "\n",
            between     => ";\n",
            after       => ";\n",
            namespaces  => [],

            assignment_ops => {
                               '=' => '=',
                              },

            lazy_ops => {
                '?'  => '?',
                '||' => '||',
                '&&' => '&&',
                ':=' => '//=',

                # '='     => '=',
                '||='   => '||=',
                '&&='   => '&&=',
                '\\\\'  => '//',
                '\\\\=' => '//=',
                        },

            special_constructs => {
                                   'Corvinus::Types::Block::If'    => 1,
                                   'Corvinus::Types::Block::While' => 1,
                                   'Corvinus::Types::Block::For'   => 1,
                                  },

            translations => {
                'Corvinus::Types::Block::While' => {
                                                    cat_timp => 'while',
                                                   },

                'Corvinus::Types::Block::If' => {
                                                 daca     => 'if',
                                                 sau_daca => 'elsif',
                                                 altfel   => 'else',
                                                },

                'Corvinus::Types::Block::For' => {
                                                  pentru => 'for',
                                                 },

                'Corvinus::Perl::Builtin' => {
                                              sari_la => 'goto',
                                             },

                'Corvinus::Object::Unary' => {
                                              '>'     => 'say',
                                              '>>'    => 'print',
                                              'spune' => 'say',
                                              'scrie' => 'print',
                                             },
                            },

            reassign_ops => {map (("$_=" => $_), qw(+ - % * // / & | ^ ** && || << >> ÷))},

            inc_dec_ops => {
                            '++' => 'inc',
                            '--' => 'dec',
                           },
            %args,
                   );

        $opts{header} .= <<"HEADER";

use utf8;
use $];

HEADER

        %addr    = ();
        %type    = ();
        %top_add = ();
        %const   = ();

        bless \%opts, __PACKAGE__;
    }

    sub make_constant {
        my ($self, $ref, $new_method, $name, @args) = @_;

        if (not $self->{_has_constant}) {
            $self->{_has_constant} = 1;
            $self->{before} .= "use constant {\n";
        }

        '(main::' . (
            (
             $const{$ref, $#args, @args} //= [
                 $name . @args,
                 do {
                     local $" = ", ";
                     $self->{before} .= "\t$name" . @args . " => " . $ref . "->$new_method(@args),\n";
                   }
             ]
            )->[0]
              . ')'
        );
    }

    sub top_add {
        my ($self, $line) = @_;
        if (not exists $top_add{$line}) {
            undef $top_add{$line};
            $self->{top_program} .= $line;
        }
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;

        my $ref = ref($obj);
        $self->_dump_string(
                              $ref eq 'Corvinus::Variable::ClassInit'     ? $self->_dump_class_name($obj)
                            : $ref eq 'Corvinus::Variable::Ref'           ? 'REF'
                            : $ref eq 'Corvinus::Types::Block::BlockInit' ? 'Corvinus::Types::Block::Block'
                            :                                               $ref
                           );
    }

    sub _dump_string {
        my ($self, $str) = @_;

        state $x = eval { require Data::Dump };
        $x || return ('"' . quotemeta($str) . '"');

        my $d = Data::Dump::quote($str);

        # Make sure that code-points between 128 and 256
        # will be stored internally as UTF-8 strings.
        if ($str =~ /[\200-\400]/) {
            return "do { require Encode; Encode::decode_utf8(Encode::encode_utf8($d)) }";
        }

        $d;
    }

    sub _dump_var {
        my ($self, $var, $refaddr) = @_;

        $var->{name} // return 'undef';

        # $var->{in_use} || exists($var->{value}) || exists($var->{ref_type}) || return 'undef';

        (
           exists($var->{array}) ? '@'
         : exists($var->{hash})  ? '%'
         :                         '$'
        )
          . $var->{name}
          . ($refaddr // refaddr($var));
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        '(' . join(', ', map { $self->_dump_var($_) } @vars) . ')';
    }

    sub _dump_init_vars {
        my ($self, $init_obj) = @_;

        my @vars = @{$init_obj->{vars}};
        @vars || return '';

        my @dumped_values = map { exists($_->{value}) ? $self->deparse_expr({self => $_->{value}}) : ('undef') } @vars;

        # Ignore "undef" values
        if (all { $_ eq 'undef' } @dumped_values) {
            @dumped_values = ();
        }

        my @code;
        push @code,
            '('
          . join(', ', map { $self->_dump_var($_) } @vars) . ')'
          . (exists($init_obj->{args}) ? '=' . $self->deparse_args($init_obj->{args}) : '');

        foreach my $var (@vars) {

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my @' . $name . ';'];

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    push @code,
                      (   (' ' x $Corvinus::SPACES) . '@'
                        . $name . '=('
                        . $self->deparse_expr({self => $var->{value}})
                        . ") if not \@$name;\n");
                }

                push @code, (' ' x $Corvinus::SPACES) . "\$$name = Corvinus::Types::Array::Array->new(\@$name);\n";
                $var->{in_use} ||= 1;
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);
                push @{$self->{block_declarations}}, [$self->{current_block} // -1, 'my %' . $name . ';'];

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    push @code,
                      (   (' ' x $Corvinus::SPACES) . '%'
                        . $name . '=('
                        . $self->deparse_expr({self => $var->{value}})
                        . ") if not keys \%$name;\n");
                }

                push @code, (' ' x $Corvinus::SPACES) . "\$$name = Corvinus::Types::Hash::Hash->new(\%$name);\n";
                $var->{in_use} ||= 1;
                delete $var->{hash};
            }
            elsif (exists $var->{value}) {
                my $value = $self->deparse_expr({self => $var->{value}});
                if ($value ne '') {
                    push @code, (' ' x $Corvinus::SPACES) . "\$$var->{name}" . refaddr($var) . " //= " . $value . ";\n";
                }
            }
        }

        push @{$self->{block_declarations}},
          [$self->{current_block} // -1, 'my(' . join(', ', map { $self->_dump_var($_) } @vars) . ')' . ';'];

        # Return the lvalue variables on assignments
        if (@code > 1 or exists($init_obj->{args})) {
            push @code, '(' . join(', ', map { $self->_dump_var($_) } @vars) . ')';
            return 'CORE::sub : lvalue {' . join(';', @code) . '}->()';
        }

        # Return one var as a list
        '(' . join(',', @code) . ')';
    }

    sub _dump_class_attributes {
        my ($self, @attrs) = @_;

        my @code;
        foreach my $attr (@attrs) {

            my @vars = @{$attr->{vars}};
            @vars || next;

            my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } @vars;

            push @code,
              (   'my('
                . join(', ', @dumped_vars) . ')'
                . (exists($attr->{args}) ? '=' . $self->deparse_args($attr->{args}) : ''));
            foreach my $var (@vars) {
                if (exists $var->{value}) {
                    my $value = $self->deparse_expr({self => $var->{value}});
                    if ($value ne '') {
                        push @code, "\$$var->{name}" . refaddr($var) . " //= " . $value . ";";
                    }
                }
            }

        }

        @code ? ((' ' x $Corvinus::SPACES) . join(";\n" . (' ' x $Corvinus::SPACES), @code) . ";\n") : '';
    }

    sub _dump_sub_init_vars {
        my ($self, @vars) = @_;

        @vars || return '';

        my @dumped_vars = map { ref($_) ? $self->_dump_var($_) : $_ } @vars;

        # Return when all variables are "undef"
        if (all { $_ eq 'undef' } @dumped_vars) {
            return '';
        }

        my $code = (' ' x $Corvinus::SPACES) . "my (" . join(', ', @dumped_vars) . ') = @_;' . "\n";

        foreach my $var (@vars) {

            ref($var) || next;
            if (exists $var->{array}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the array is empty
                if (exists $var->{value}) {
                    $code .= ('@' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not \@$name;\n");
                }

                $code .= (' ' x $Corvinus::SPACES) . "my \$$name = Corvinus::Types::Array::Array->new(\@$name);\n";
                delete $var->{array};
            }
            elsif (exists $var->{hash}) {
                my $name = $var->{name} . refaddr($var);

                # Overwrite with the default values, when the hash has no keys
                if (exists $var->{value}) {
                    $code .= ('%' . $name . '=(' . $self->deparse_expr({self => $var->{value}}) . ") if not keys \%$name;\n");
                }

                $code .= (' ' x $Corvinus::SPACES) . "my \$$name = Corvinus::Types::Hash::Hash->new(\%$name);\n";
                delete $var->{hash};
            }
            else {

                if (exists $var->{value}) {
                    my $value = $self->deparse_expr({self => $var->{value}});
                    if ($value ne '') {
                        $code .= (' ' x $Corvinus::SPACES) . "\$$var->{name}" . refaddr($var) . " //= " . $value . ";\n";
                    }
                }
            }
        }

        $code;
    }

    sub _dump_array {
        my ($self, $ref, $array) = @_;
        $ref . '->new(' . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . ')';
    }

    sub _dump_indices {
        my ($self, $array) = @_;
        '[' . join(', ', map { ref($_) ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_})) : $_ } @{$array}) . ']';
    }

    sub _dump_unpacked_indices {
        my ($self, $array) = @_;
        '[' . join(
            ', ',
            map {
                '@{'
                  . (
                     ref($_)
                     ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                     : die "[ERROR] Value '$_' can't be unpacked in Array index!"
                    )
                  . '}'
              } @{$array}
          )
          . ']';
    }

    sub _dump_lookups {
        my ($self, $array) = @_;
        '{' . join(', ', map { ref($_) ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_})) : $_ } @{$array}) . '}';
    }

    sub _dump_unpacked_lookups {
        my ($self, $array) = @_;
        '{' . join(
            ', ',
            map {
                '@{'
                  . (
                     ref($_)
                     ? ($self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}))
                     : die "[ERROR] Value '$_' can't be unpacked in Hash lookup!"
                    )
                  . '}'
              } @{$array}
          )
          . '}';
    }

    sub _dump_var_attr {
        my ($self, @vars) = @_;

        'vars => [' . join(
            ', ',
            map {
                    "{ name => "
                  . $self->_dump_string($_->{name})
                  . (exists($_->{slurpy})    ? (", slurpy => " . $_->{slurpy})                       : '')
                  . (exists($_->{ref_type})  ? (", type => " . $self->_dump_reftype($_->{ref_type})) : '')
                  . (exists($_->{has_value}) ? (', has_value => 1')                                  : '')
                  . (
                     exists($_->{where_block})
                     ? (', where_block => sub{'
                        . $self->_dump_sub_init_vars($_->{where_block}{init_vars}{vars}[0])
                        . $self->deparse_generic('', ';', '', $_->{where_block}{code}) . '}')
                     : ''
                    )
                  . (
                     exists($_->{where_expr}) ? (', where_expr => do{' . $self->deparse_expr({self => $_->{where_expr}}) . '}')
                     : ''
                    )
                  . '}'
              } @vars
          )
          . ']' . ', '
          . 'table => {'
          . join(', ', map { $self->_dump_string($vars[$_]{name}) . ' => ' . $_ } 0 .. $#vars) . '}';
    }

    sub _dump_class_name {
        my ($self, $class) = @_;
        join('::', '_', $class->{class}, $class->{name});
    }

    sub deparse_generic {
        my ($self, $before, $sep, $after, @args) = @_;
        $before . join(
            $sep,
            map {
                    ref($_) eq 'HASH' ? $self->deparse_script($_)
                  : ref($_) ? $self->deparse_expr({self => $_})
                  : $self->_dump_string($_)
              } @args
          )
          . $after;
    }

    sub deparse_args {
        my ($self, @args) = @_;
        $self->deparse_generic('(', ', ', ')', @args);
    }

    sub deparse_block_expr {
        my ($self, @args) = @_;
        $self->deparse_generic('do{', ';', '}', @args);
    }

    sub deparse_bare_block {
        my ($self, @args) = @_;

        $Corvinus::SPACES += $Corvinus::SPACES_INCR;
        my $code = $self->deparse_generic("{\n" . " " x ($Corvinus::SPACES),
                                          ";\n" . (" " x ($Corvinus::SPACES)),
                                          "\n" .  (" " x ($Corvinus::SPACES - $Corvinus::SPACES_INCR)) . "}", @args);
        $Corvinus::SPACES -= $Corvinus::SPACES_INCR;

        $code;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code    = '';
        my $obj     = $expr->{self};
        my $refaddr = refaddr($obj);

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
        }
        elsif ($ref eq 'Corvinus::Variable::Variable') {
            if ($obj->{type} eq 'var') {

                my $name = $obj->{name} . $refaddr;

                if ($obj->{name} eq 'ENV') {
                    $self->top_add("require Encode;\n");
                    $self->top_add(  qq{my \$$name = Corvinus::Types::Hash::Hash->new}
                                   . qq{(map{Corvinus::Types::String::String->new(Encode::decode_utf8(\$_))} \%ENV);\n});
                }
                elsif ($obj->{name} eq 'ARGV') {
                    $self->top_add("require Encode;\n");
                    $self->top_add(  qq{my \$$name = Corvinus::Types::Array::Array->new}
                                   . qq{(map {Corvinus::Types::String::String->new(Encode::decode_utf8(\$_))} \@ARGV);\n});
                }

                $code = $self->_dump_var($obj, $refaddr);
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {

                if ($addr{$refaddr}++) {
                    $code = "\$$obj->{name}$refaddr";
                }
                else {
                    my $block = $obj->{value};

                    # Anonymous function
                    if ($obj->{name} eq '') {
                        $obj->{name} = "__ANON__";
                    }

                    my $name = $obj->{name};

                    # Check for alphanumeric name
                    if (not $obj->{name} =~ /^[_\pL][_\pL\pN]*\z/) {
                        $obj->{name} = '__NONANN__';    # use this name for non-alphanumeric names
                    }

                    # The name of the function
                    $code .= "\$$obj->{name}$refaddr = ";

                    # Deparse the block of the method/function
                    {
                        local $self->{function} = refaddr($block);
                        local $self->{parent_name} = [$obj->{type}, "$obj->{class}::$name"];
                        push @{$self->{function_declarations}}, [$self->{function}, "my \$$obj->{name}$refaddr;"];
                        $code .= $self->deparse_expr({self => $block});
                    }

                    # Check to see if the method/function has kids (can do multiple dispatch)
                    if (exists $obj->{value}{kids}) {
                        chop $code;

                        my @kids = map {
                            local $_->{type} = 'func';
                            "do{" . $self->deparse_expr({self => $_}) . "}";
                        } @{$obj->{value}{kids}};

                        $code .= ', kids => [' . join(', ', @kids) . '])';
                    }

                    # Check the return value (when "-> Type" is specified)
                    if (exists $obj->{returns}) {
                        my $types = '[' . join(',', map { $self->_dump_reftype($_) } @{$obj->{returns}}) . ']';
                        $code = "do {$code; \$$obj->{name}$refaddr\->{returns} = $types; \$$obj->{name}$refaddr}";
                    }

                    # Memoize the method/function (when "is cached" trait is specified)
                    if ($obj->{cached}) {
                        $self->top_add("require Memoize;\n");
                        $code =
                            "do {$code;\n"
                          . (' ' x $Corvinus::SPACES)
                          . "\$$obj->{name}$refaddr\->{code} = Memoize::memoize(\$$obj->{name}${refaddr}->{code}); \$$obj->{name}$refaddr}";
                    }

                    if ($obj->{type} eq 'method') {

                        # Special "AUTOLOAD" method
                        if ($obj->{name} eq 'AUTOLOAD') {
                            $code .= ";\n"
                              . (' ' x $Corvinus::SPACES)
                              . "our \$AUTOLOAD;\n"
                              . (' ' x $Corvinus::SPACES)
                              . "sub $obj->{name} { my \$self = shift;\n"
                              . (' ' x $Corvinus::SPACES)
                              . "my (\$class, \$method) = (\$AUTOLOAD =~ /^(.*[^:])::(.*)\$/);\n"
                              . (' ' x $Corvinus::SPACES)
                              . "\$$obj->{name}$refaddr->call(\$self, Corvinus::Types::String::String->new(\$class), Corvinus::Types::String::String->new(\$method), \@_) }";
                        }

                        # Other methods
                        else {
                            $code .= ";\n"
                              . (' ' x $Corvinus::SPACES)
                              . "state \$_$refaddr = do { no strict 'refs'; *{"
                              . $self->_dump_string("$self->{package_name}::$name")
                              . "} = sub { \$$obj->{name}$refaddr->call(\@_) } }";
                        }
                    }
                }
            }
        }
        elsif ($ref eq 'Corvinus::Object::Unary') {
            ## OK
        }
        elsif ($ref eq 'Corvinus::Variable::Local') {
            $code = 'local ' . $self->deparse_script($obj->{expr});
        }
        elsif ($ref eq 'Corvinus::Variable::Global') {
            $code = '$' . $obj->{class} . '::' . $obj->{name},;
        }
        elsif ($ref eq 'Corvinus::Variable::Define') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . 'main::' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $self->top_add('use constant ' . $name . ' => ' . 'do {' . $self->deparse_script($obj->{expr}) . " };\n");
            }
            $code = $value;
        }
        elsif ($ref eq 'Corvinus::Variable::Const') {
            my $name  = $obj->{name} . $refaddr;
            my $value = '(' . $name . ')';
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;

                # Use dynamical constants inside functions
                if (exists $self->{function} or exists $self->{class}) {
                    $self->top_add("use experimental 'lexical_subs';\n");
                    $code = "state sub $name() { state \$_$refaddr"
                      . (defined($obj->{expr}) ? (" = " . $self->deparse_script($obj->{expr})) : '') . " }";
                }

                # Otherwise, use static constants
                else {
                    $code = "sub $name() { state \$_$refaddr"
                      . (defined($obj->{expr}) ? " = " . ($self->deparse_script($obj->{expr})) : '') . "}";
                }
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Static') {
            my $name  = $obj->{name} . $refaddr;
            my $value = "\$$name";
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "(state \$$name" . (defined($obj->{expr}) ? (" = " . $self->deparse_script($obj->{expr})) : '') . ")";
            }
            else {
                $code = $value;
            }
        }
        elsif ($ref eq 'Corvinus::Variable::ConstInit') {
            $code = join(";\n" . (" " x $Corvinus::SPACES), map { $self->deparse_expr({self => $_}) } @{$obj->{vars}});
        }
        elsif ($ref eq 'Corvinus::Variable::Init') {
            $code = $self->_dump_init_vars($obj);
        }
        elsif ($ref eq 'Corvinus::Variable::ClassInit') {
            if ($addr{$refaddr}++) {
                $code = q{'} . $self->_dump_class_name($obj) . q{'};
            }
            else {
                my $block = $obj->{block};

                $code = "do {package ";

                my $package_name;
                if (ref $obj->{name}) {

                    if (ref $obj->{name} eq 'HASH') {
                        die "[ERROR] Invalid class name: '$obj->{name}' inside namespace '$obj->{class}'";
                    }

                    $code .= ($package_name = ref($obj->{name}));
                }
                else {

                    if ($obj->{name} eq '') {
                        $obj->{name} = '__ANON__' . $refaddr;
                    }

                    $code .= ($package_name = $self->_dump_class_name($obj));
                }

                local $self->{class}            = refaddr($block);
                local $self->{class_name}       = $package_name;
                local $self->{parent_name}      = ['class', $package_name];
                local $self->{package_name}     = $package_name;
                local $self->{inherit}          = $obj->{inherit} if exists $obj->{inherit};
                local $self->{class_vars}       = $obj->{vars} if exists $obj->{vars};
                local $self->{class_attributes} = $obj->{attributes} if exists $obj->{attributes};
                local $self->{ref_class}        = 1 if ref($obj->{name});
                $code .= $self->deparse_expr({self => $block});
                $code .= '; ' . $self->_dump_string($package_name) . '}';
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::BlockInit') {
            if ($addr{$refaddr}++) {
                $code = q{Corvinus::Types::Block::Block->new(code => __SUB__, type => 'block'};

                if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                    $code .= ', ' . $self->_dump_var_attr(@{$obj->{init_vars}{vars}});
                }

                $code .= ')';
            }
            else {
                if (%{$obj}) {

                    $Corvinus::SPACES += $Corvinus::SPACES_INCR;

                    my $is_function = exists($self->{function}) && $self->{function} == $refaddr;
                    my $is_class    = exists($self->{class})    && $self->{class} == $refaddr;

                    local $self->{current_block} = $refaddr;

                    if ($is_class) {
                        $code = " {\n";

                        if ($is_class) {
                            local $" = " ";
                            $code .= " " x $Corvinus::SPACES;
                            $code .= "use base qw("
                              . (
                                 exists($self->{inherit})
                                 ? (join(' ', map { ref($_) ? $self->_dump_class_name($_) : $_ } @{$self->{inherit}}) . ' ')
                                 : ''
                                )
                              . ($self->{package_name} eq 'Corvinus::Object::Object' ? '' : "Corvinus::Object::Object")
                              . ");\n";
                        }

                        if ($is_class and not $self->{ref_class}) {

                            $code .=
                              (" " x $Corvinus::SPACES)
                              . "\$new$refaddr = Corvinus::Types::Block::Block->new(code => sub {" . "\n";
                            push @{$self->{function_declarations}}, [$refaddr, "my \$new$refaddr;"];

                            $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                            $code .= $self->_dump_sub_init_vars(@{$self->{class_vars}})
                              . $self->_dump_class_attributes(@{$self->{class_attributes}});

                            $code .= (' ' x $Corvinus::SPACES) . 'my $self = bless {';
                            foreach my $var (@{$self->{class_vars}}, map { @{$_->{vars}} } @{$self->{class_attributes}}) {
                                $code .= qq{"\Q$var->{name}\E"=>} . $self->_dump_var($var) . ',';
                            }

                            $code .=
                                '}, __PACKAGE__;' . "\n"
                              . (' ' x $Corvinus::SPACES)
                              . '$self->init() if $self->can("init");' . "\n"
                              . (' ' x $Corvinus::SPACES)
                              . '$self;' . "\n";

                            $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                            $code .=
                                (" " x $Corvinus::SPACES . "}") . ', '
                              . $self->_dump_var_attr(@{$self->{class_vars}})
                              . ", type => "
                              . $self->_dump_string('class')
                              . ", name => "
                              . $self->_dump_string($self->{parent_name}[1]) . ");\n"
                              . (' ' x $Corvinus::SPACES)
                              . "state \$_$refaddr = do { no strict 'refs'; *{"
                              . $self->_dump_string("$self->{package_name}\::new")
                              . "} = *{"
                              . $self->_dump_string("$self->{package_name}\::call")
                              . "} = sub { CORE::shift(\@_); \$new$refaddr->call(\@_) } };\n";

                            foreach my $var (@{$self->{class_vars}}, map { @{$_->{vars}} } @{$self->{class_attributes}}) {
                                $code .=
                                  (' ' x $Corvinus::SPACES) . qq{sub $var->{name} : lvalue { \$_[0]->{"\Q$var->{name}\E"} }\n};
                            }
                        }
                    }
                    else {
                        $code = 'Corvinus::Types::Block::Block->new(';
                    }

                    if (not $is_class) {

                        $code .= "\n" . (" " x ($Corvinus::SPACES - $Corvinus::SPACES_INCR)) . "code => sub {\n";

                        if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                            $code .= $self->_dump_sub_init_vars(@{$obj->{init_vars}{vars}});
                        }

                        if ($is_function) {
                            $code .= (' ' x $Corvinus::SPACES) . 'my @return;' . "\n";
                        }
                    }

                    my @statements = $self->deparse_script($obj->{code});

                    # Localize function declarations
                    if ($is_function) {
                        while (    exists($self->{function_declarations})
                               and @{$self->{function_declarations}}
                               and $self->{function_declarations}[-1][0] != $refaddr) {
                            $code .= (' ' x $Corvinus::SPACES) . pop(@{$self->{function_declarations}})->[1] . "\n";
                        }
                    }

                    # Localize variable declarations
                    while (    exists($self->{block_declarations})
                           and @{$self->{block_declarations}}
                           and $self->{block_declarations}[-1][0] == $refaddr) {
                        $code .= (' ' x $Corvinus::SPACES) . pop(@{$self->{block_declarations}})->[1] . "\n";
                    }

                    # Make the last statement to be the return value
                    if ($is_function && @statements) {

                        if ($statements[-1] =~ /^\@return = /) {

                            # Make a minor improvement by removing the 'goto'
                            $statements[-1] =~ s/;\h*goto END$refaddr\z//;
                            $statements[-1] =~ s/^\@return = /return/;
                        }
                        else {
                            $statements[-1] = 'return do { ' . $statements[-1] . ' }';
                        }
                    }

                    $code .=
                        (" " x $Corvinus::SPACES)
                      . join(";\n" . (" " x $Corvinus::SPACES), @statements)
                      . ($is_function ? (";\n" . (" " x $Corvinus::SPACES) . "END$refaddr: \@return;\n") : '') . "\n"
                      . (" " x ($Corvinus::SPACES -= $Corvinus::SPACES_INCR)) . '}';

                    if (not $is_class) {
                        if ($is_function) {
                            $code .= ','
                              . join(',',
                                     'type => ' . $self->_dump_string($self->{parent_name}[0]),
                                     'name => ' . $self->_dump_string($self->{parent_name}[1]));
                        }
                        else {
                            $code .= ', '
                              . join(', ',
                                     'type => ' . $self->_dump_string('block'),
                                     'name => ' . $self->_dump_string('__BLOCK__'),);
                        }

                        if (exists $self->{class_name}) {
                            $code .= ',' . 'class => ' . $self->_dump_string($self->{class_name});
                        }

                        if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                            $code .= ', ' . $self->_dump_var_attr(@{$obj->{init_vars}{vars}});
                        }
                        $code .= ')';
                    }
                }
                else {
                    $code = q{'Corvinus::Types::Block::Block'};
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::ClassAttr') {
            ## ok
        }
        elsif ($ref eq 'Corvinus::Variable::Struct') {
            my $name = $self->_dump_class_name($obj);
            if ($addr{$refaddr}++) {
                $code = $name;
            }
            else {
                $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                $code =
                    "package $name {\n"
                  . (' ' x $Corvinus::SPACES)
                  . "\$new$refaddr = Corvinus::Types::Block::Block->new(code => sub {" . "\n"
                  . (' ' x $Corvinus::SPACES)
                  . $self->_dump_sub_init_vars(@{$obj->{vars}})
                  . (' ' x ($Corvinus::SPACES * 2))
                  . "bless {"
                  . join(", ", map { $self->_dump_string($_->{name}) . " => " . $self->_dump_var($_) } @{$obj->{vars}})
                  . "}, __PACKAGE__" . "\n"
                  . (' ' x $Corvinus::SPACES) . "}" . ', '
                  . 'name => '
                  . $self->_dump_string($name) . ', '
                  . 'type => '
                  . $self->_dump_string('struct') . ', '
                  . $self->_dump_var_attr(@{$obj->{vars}}) . ");\n" . ";\n"
                  . (' ' x $Corvinus::SPACES)
                  . "state \$_$refaddr = do { no strict 'refs'; *{"
                  . $self->_dump_string("$name\::new")
                  . "} = *{"
                  . $self->_dump_string("$name\::call")
                  . "} = sub { CORE::shift(\@_); \$new$refaddr->call(\@_) } };\n"
                  . (' ' x $Corvinus::SPACES)
                  . join("\n" . (' ' x $Corvinus::SPACES),
                         map { "sub $_->{name} : lvalue { \$_[0]->{$_->{name}} }" } @{$obj->{vars}})
                  . "\n"
                  . (' ' x ($Corvinus::SPACES - $Corvinus::SPACES_INCR)) . "}";

                push @{$self->{function_declarations}}, [$refaddr, "my \$new$refaddr;"];

                $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
            }
        }
        elsif ($ref eq 'Corvinus::Types::Number::Number') {
            my $value = $obj->get_value;

            if (ref($value)) {
                if (ref($value) eq 'Math::BigRat') {
                    $value = (q{Math::BigRat->new('} . join('/', $value->parts) . q{')});
                }
                else {
                    $value = (q{'} . $value->bstr . q{'});
                }
            }

            $code = $self->make_constant($ref, 'new', "Number$refaddr", $value);
        }
        elsif ($ref eq 'Corvinus::Types::String::String') {
            $code = $self->make_constant($ref, 'new', "String$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Corvinus::Types::Array::Array' or $ref eq 'Corvinus::Types::Array::HCArray') {
            $code = $self->_dump_array('Corvinus::Types::Array::Array', $obj);
        }
        elsif ($ref eq 'Corvinus::Types::Bool::Bool') {
            $code = $self->make_constant($ref, 'new', ${$obj} ? ("true$refaddr", 1) : ("false$refaddr", 0));
        }
        elsif ($ref eq 'Corvinus::Types::Regex::Regex') {
            $code =
              $self->make_constant($ref, 'new', "Regex$refaddr",
                                   $self->_dump_string("$obj->{regex}"),
                                   $obj->{global} ? '"g"' : ());
        }
        elsif ($ref eq 'Corvinus::Types::Block::If' or $ref eq 'Corvinus::Types::Block::While') {
            ## ok
        }
        elsif ($ref eq 'Corvinus::Types::Bool::Ternary') {
            $code = '('
              . $self->deparse_script($obj->{cond}) . '?'
              . $self->deparse_block_expr($obj->{true}) . ':'
              . $self->deparse_block_expr($obj->{false}) . ')';
        }
        elsif ($ref eq 'Corvinus::Variable::NamedParam') {
            $code = $ref . '->new(' . $self->_dump_string($obj->[0]) . ',' . $self->deparse_args(@{$obj->[1]}) . ')';
        }
        elsif ($ref eq 'Corvinus::Types::Nil::Nil') {
            $code = 'undef';
        }
        elsif ($ref eq 'Corvinus::Types::Hash::Hash') {
            if (keys(%{$obj})) {
                $code = $ref . '->new(' . join(
                    ',',
                    map {
                        $self->_dump_string($_) . ' => '
                          . (defined($obj->{$_}) ? $self->deparse_expr({self => $obj->{$_}}) : 'undef')
                      } keys(%{$obj})
                  )
                  . ')';
            }
            else {
                $code = $self->make_constant($ref, 'new', "Hash$refaddr");
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::Do') {
            $code = 'do {' . join(';', $self->deparse_script($obj->{block}{code})) . '}';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Loop') {
            $code = 'while(1) {' . join(';', $self->deparse_script($obj->{block}{code})) . '}';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Given') {
            $self->top_add(qq{use experimental 'smartmatch';\n});
            my $dvar = $self->_dump_var($obj->{block}{init_vars}->{vars}[0]);
            $code =
                'do{given (my '
              . $dvar . '='
              . $self->deparse_args($obj->{expr}) . ')'
              . $self->deparse_bare_block($obj->{block}{code}) . '}';
        }
        elsif ($ref eq 'Corvinus::Types::Block::When') {
            $code = 'when($_ ~~ ' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Case') {
            $code = 'when(!!' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Default') {
            $code = 'default' . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Gather') {
            $code =
                "do {my \@_$refaddr;"
              . $self->deparse_bare_block($obj->{block}->{code})
              . "; Corvinus::Types::Array::Array->new(\@_$refaddr)}";
        }
        elsif ($ref eq 'Corvinus::Types::Block::Take') {
            my $raddr = refaddr($obj->{gather});
            $code = "do { push \@_$raddr," . $self->deparse_args($obj->{expr}) . "; \$_$raddr\[-1] }";
        }
        elsif ($ref eq 'Corvinus::Types::Block::Try') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Corvinus::Variable::Ref') {
            ## ok
        }
        elsif ($ref eq 'Corvinus::Types::Block::For') {
            ## ok
        }
        elsif ($ref eq 'Corvinus::Types::Block::Break') {
            $code = 'last';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Next') {
            $code = 'next';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Continue') {
            $code = 'continue';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Return') {
            if (not exists $expr->{call}) {

                if (exists $self->{function}) {
                    $code = "goto END$self->{function}";
                }
                else {
                    $code = 'return Corvinus::Types::Block::Return->new';
                }
            }
        }
        elsif ($ref eq 'Corvinus::Math::Math') {
            $code = $self->make_constant($ref, 'new', "Math$refaddr");
        }
        elsif ($ref eq 'Corvinus::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = $self->make_constant($ref, 'new', "STDIN$refaddr", 'fh => \*STDIN');
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = $self->make_constant($ref, 'new', "STDOUT$refaddr", 'fh => \*STDOUT');
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = $self->make_constant($ref, 'new', "STDERR$refaddr", 'fh => \*STDERR');
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = $self->make_constant($ref, 'new', "ARGF$refaddr", 'fh => \*ARGV');
            }
            else {
                my $data = $self->_dump_string(
                                               do { seek($obj->{fh}, 0, 0); local $/; readline($obj->{fh}) }
                                              );
                $code =
                  $self->make_constant($ref, 'new', "DATA$refaddr", qq{fh => do {open my \$fh, '<:utf8', \\$data; \$fh}});
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Magic') {
            $code = $obj->{name};
        }
        elsif ($ref eq 'Corvinus::Types::Glob::Socket') {
            $code = $self->make_constant($ref, 'new', "Socket$refaddr");
        }
        elsif ($ref eq 'Corvinus::Eval::Eval') {
            $Corvinus::EVALS{$refaddr} = $obj;
            $code = qq~
            eval do {
            local \$Corvinus::DEPARSER->{before} = '';
            local \$Corvinus::DEPARSER->{top_program} = '';
            local \$Corvinus::DEPARSER->{_has_constant} = 0;
            local \$Corvinus::DEPARSER->{function_declarations} = [];
            local \$Corvinus::DEPARSER->{block_declarations} = [];
            \$Corvinus::DEPARSER->deparse(
            do {
                local \$Corvinus::PARSER->{line} = 0;
                local \$Corvinus::PARSER->{file_name} = 'eval($refaddr)';
                local \$Corvinus::PARSER->{vars} = \$Corvinus::EVALS{$refaddr}{vars};
                local \$Corvinus::PARSER->{ref_vars_refs} = \$Corvinus::EVALS{$refaddr}{ref_vars_refs};
                \$Corvinus::PARSER->parse_script(code => \\(~ . $self->deparse_script($obj->{expr}) . qq~->get_value));
            })}~;
        }
        elsif ($ref eq 'Corvinus::Time::Time') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Corvinus::Sys::Sig') {
            $code = $self->make_constant($ref, 'new', "Sig$refaddr");
        }
        elsif ($ref eq 'Corvinus::Types::Number::Complex') {
            $code = $self->make_constant($ref, 'new', "Complex$refaddr", "'" . ${$obj}->Re . "'", "'" . ${$obj}->Im . "'");
        }
        elsif ($ref eq 'Corvinus::Types::Array::Pair') {
            if (all { not defined($_) } @{$obj}) {
                $code = $self->make_constant($ref, 'new', "Pair$refaddr");
            }
            else {
                $code =
                    $ref
                  . '->new('
                  . join(', ', map { defined($_) ? $self->deparse_expr({self => $_}) : 'undef' } @{$obj}) . ')';
            }
        }
        elsif ($ref eq 'Corvinus::Types::Null::Null') {
            $code = $self->make_constant($ref, 'new', "Null$refaddr");
        }
        elsif ($ref eq 'Corvinus::Module::OO') {
            $code = $self->make_constant($ref, '__NEW__', "MOD_OO$refaddr", $self->_dump_string($obj->{module}));
        }
        elsif ($ref eq 'Corvinus::Module::Func') {
            $code = $self->make_constant($ref, '__NEW__', "MOD_F$refaddr", $self->_dump_string($obj->{module}));
        }
        elsif ($ref eq 'Corvinus::Types::Range::RangeNumber' or $ref eq 'Corvinus::Types::Range::RangeString') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::Backtick') {
            $code = $self->make_constant($ref, 'new', "Backtick$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Corvinus::Types::Glob::File') {
            $code = $self->make_constant($ref, 'new', "File$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Corvinus::Types::Glob::Dir') {
            $code = $self->make_constant($ref, 'new', "Dir$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Corvinus::Sys::Sys') {
            $code = $self->make_constant($ref, 'new', "Sys$refaddr");
        }
        elsif ($ref eq 'Corvinus::Meta::Assert') {
            my @args = $self->deparse_script($obj->{arg});

            if ($obj->{act} eq 'assert') {

                # Check arity
                @args == 1
                  or die "[EROARE] Număr incorect de argumente pentru $obj->{act}\() în"
                  . " $obj->{file} la linia $obj->{line} (necesită un argument)\n";

                # Generate code
                $code =
                    qq~do{my \$a$refaddr = do{$args[0]}; \$a$refaddr~
                  . qq~ or CORE::die "afirmația $obj->{act}(\$a$refaddr) este falsă ~
                  . qq~în \Q$obj->{file}\E la linia $obj->{line}\\n"}~;
            }
            elsif ($obj->{act} eq 'assert_eq' or $obj->{act} eq 'assert_ne') {

                # Check arity
                @args == 2
                  or die "[EROARE] Număr incorect de argumente pentru $obj->{act}\() în"
                  . " $obj->{file} la linia $obj->{line} (necesită două argumente)\n";

                # Generate code
                $code = "do{"
                  . "my \$a$refaddr = do{$args[0]};"
                  . "my \$b$refaddr = do{$args[1]};"
                  . ($obj->{act} eq 'assert_ne' ? qq{CORE::not(\$a$refaddr eq \$b$refaddr)} : qq{\$a$refaddr eq \$b$refaddr})
                  . qq~ or CORE::die "afirmația $obj->{act}(\$a$refaddr, \$b$refaddr) este falsă în \Q$obj->{file}\E la linia $obj->{line}\\n"}~;
            }
        }
        elsif ($ref eq 'Corvinus::Meta::Error') {
            my @args = $self->deparse_args($obj->{arg});
            $code = qq~do{CORE::die(@args, " în \Q$obj->{file}\E linia $obj->{line}\\n")}~;
        }
        elsif ($ref eq 'Corvinus::Meta::Warning') {
            my @args = $self->deparse_args($obj->{arg});
            $code = qq~Corvinus::Types::Bool::Bool->new(CORE::warn(@args, " în \Q$obj->{file}\E linia $obj->{line}\\n"))~;
        }
        elsif ($ref eq 'Corvinus::Object::Object') {
            $code = $self->make_constant($ref, 'new', "Object$refaddr");
        }
        elsif ($ref eq 'Corvinus::Variable::LazyMethod') {
            $code = $ref . '->new';
        }
        elsif ($ref eq 'Corvinus::Types::Block::ForArray') {
            $code =
                'for my '
              . $self->deparse_expr({self => $obj->{var}}) . '(@{'
              . $self->deparse_expr({self => $obj->{array}}) . '})'
              . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Corvinus::Types::Byte::Bytes') {
            $code = $self->_dump_array($ref, $obj);
        }
        elsif ($ref eq 'Corvinus::Types::Byte::Byte') {
            $code = $self->make_constant($ref, 'new', "Byte$refaddr", $obj->get_value);
        }
        elsif ($ref eq 'Corvinus::Types::Char::Chars') {
            $code = $self->_dump_array($ref, $obj);
        }
        elsif ($ref eq 'Corvinus::Types::Char::Char') {
            $code = $self->make_constant($ref, 'new', "Char$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Corvinus::Types::Grapheme::Graphemes') {
            $code = $self->_dump_array($ref, $obj);
        }
        elsif ($ref eq 'Corvinus::Types::Grapheme::Grapheme') {
            $code = $self->make_constant($ref, 'new', "Grapheme$refaddr", $self->_dump_string(${$obj}));
        }
        elsif ($ref eq 'Corvinus::Types::Array::MultiArray') {
            $code = $self->make_constant($ref, 'new', "MultiArr$refaddr");
        }
        elsif ($ref eq 'Corvinus::Types::Glob::Pipe') {
            $code = $self->make_constant($ref, 'new', "Pipe$refaddr", map { $self->_dump_string($_) } @{$obj});
        }
        elsif ($ref eq 'Corvinus::Parser') {
            $code = $self->make_constant($ref, 'new', "Parser$refaddr");
        }
        elsif ($ref eq 'Corvinus') {
            $code = $self->make_constant($ref, 'new', "Corvinus$refaddr");
        }
        elsif ($ref eq 'Corvinus::Perl::Perl') {
            $code = $self->make_constant($ref, 'new', "Perl$refaddr");
        }
        elsif ($ref eq 'Corvinus::Meta::Unimplemented') {
            $code =
                qq{CORE::die "Cod neimplementat în " . }
              . $self->_dump_string($obj->{file})
              . qq{. " la linia $obj->{line}\\n"};
        }

        # Array and hash indices
        if (exists $expr->{ind}) {
            my $limit = $#{$expr->{ind}};
            foreach my $i (0 .. $limit) {

                my $ind = $expr->{ind}[$i];
                if (exists $ind->{array}) {

                    my $pos = $ind->{array};

                    if (substr($code, -1) eq '@') {
                        $code .= $self->_dump_unpacked_indices($pos);
                    }
                    else {
                        $code = '@{' . $code . '}' . $self->_dump_indices($pos);
                    }
                }
                else {

                    my $key = $ind->{hash};

                    if (substr($code, -1) eq '@') {
                        $code .= $self->_dump_unpacked_lookups($key);
                    }
                    else {
                        $code = '@{' . $code . '}' . $self->_dump_lookups($key);
                    }
                }

                if ($i < $limit) {
                    if ($expr->{ind}[$i + 1]{array}) {
                        $code = '(' . $code . ' //= Corvinus::Types::Array::Array->new' . ')';
                    }
                    else {
                        $code = '(' . $code . ' //= Corvinus::Types::Hash::Hash->new' . ')';
                    }
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {

            my $end = $#{$expr->{call}};
            foreach my $i (0 .. $end) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if ($code ne '') {
                    if (not exists $self->{special_constructs}{$ref}) {
                        $code = '(' . $code . ')';
                    }
                }

                if ($ref eq 'Corvinus::Types::Block::Return') {

                    if (exists $self->{function}) {
                        $code .= 'do {';
                        if (@{$call->{arg}}) {
                            $code .= '@return = ' . $self->deparse_args(@{$call->{arg}}) . ';';
                        }
                        $code .= 'goto ' . "END$self->{function}}";
                    }
                    else {
                        $code .= 'return Corvinus::Types::Block::Return->new' . $self->deparse_args(@{$call->{arg}});
                    }

                    next;
                }

                # !!!Experimental!!!
                #~ if ($ref eq 'Corvinus::Types::Block::Break') {
                #~ $code .= 'return Corvinus::Types::Block::Break->new' . $self->deparse_args(@{$call->{arg}});
                #~ next;
                #~ }
                #~ elsif ($ref eq 'Corvinus::Types::Block::Next') {
                #~ $code .= 'return Corvinus::Types::Block::Next->new' . $self->deparse_args(@{$call->{arg}});
                #~ next;
                #~ }

                if (defined $method) {

                    if (exists $self->{translations}{$ref} and exists $self->{translations}{$ref}{$method}) {
                        $method = $self->{translations}{$ref}{$method};
                    }

                    if ($ref eq 'Corvinus::Variable::Ref') {    # variable refs

                        # Variable refencing
                        if ($method eq '\\' or $method eq '&') {
                            $code = '\\' . $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        # Variable dereferencing
                        elsif ($method eq '*') {
                            $code = '${' . $self->deparse_args(@{$call->{arg}}) . '}';
                            next;
                        }

                        # Prefix ++ and -- operators on variables
                        elsif (exists $self->{inc_dec_ops}{$method}) {
                            my $var = $self->deparse_args(@{$call->{arg}});
                            $code = "do{my\$ref=\\$var;\$\$ref=\$\$ref\->$self->{inc_dec_ops}{$method}}";
                            next;
                        }
                    }

                    # Postfix ++ and -- operators on variables
                    if (exists($self->{inc_dec_ops}{$method})) {
                        $code =
                          "do{my\$ref=\\$code;my\$value=\$\$ref;\$\$ref=\$value\->$self->{inc_dec_ops}{$method}; \$value}";
                        next;
                    }

                    if (exists($self->{lazy_ops}{$method})) {
                        $code .= $self->{lazy_ops}{$method} . $self->deparse_block_expr(@{$call->{arg}});
                        next;
                    }

                    # Variable assignment (=)
                    if (exists($self->{assignment_ops}{$method})) {
                        $code = "($code$self->{assignment_ops}{$method}" . $self->deparse_args(@{$call->{arg}}) . ")[-1]";
                        next;
                    }

                    # Reassignment operators, such as: +=, -=, *=, /=, etc...
                    if (exists $self->{reassign_ops}{$method}) {

                        $code =
                          "CORE::sub : lvalue {my \$ref=\\$code; \$\$ref=\$\$ref\->\${\\'$self->{reassign_ops}{$method}'}"
                          . $self->deparse_args(@{$call->{arg}}) . "}->()";

                        next;
                    }

                    # != and == methods
                    if ($method eq '==' or $method eq '!=') {
                        $code =
                            'Corvinus::Types::Bool::Bool->new('
                          . ($method eq '!=' ? 'CORE::not ' : '') . 'do{'
                          . $code
                          . '} eq do{'
                          . $self->deparse_args(@{$call->{arg}}) . '})';
                        next;
                    }

                    # <=> method
                    if ($method eq '<=>') {
                        $code =
                            'Corvinus::Types::Number::Number->new(do{'
                          . $code
                          . '} cmp do{'
                          . $self->deparse_args(@{$call->{arg}}) . '})';
                        next;
                    }

                    # !~ and ~~ methods
                    if ($method eq '~~' or $method eq '!~') {
                        $self->top_add(qq{use experimental 'smartmatch';\n});
                        $code =
                            'Corvinus::Types::Bool::Bool->new('
                          . ($method eq '!~' ? 'CORE::not ' : '') . 'do{'
                          . $code
                          . '} ~~ do{'
                          . $self->deparse_args(@{$call->{arg}}) . '})';
                        next;
                    }

                    # ! prefix-unary
                    if ($ref eq 'Corvinus::Object::Unary') {
                        if ($method eq '!') {
                            $code = 'Corvinus::Types::Bool::Bool->new(!do{' . $self->deparse_args(@{$call->{arg}}) . '})';
                            next;
                        }

                        if ($method eq '-') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->neg';
                            next;
                        }

                        if ($method eq '+') {
                            $code = $self->deparse_args(@{$call->{arg}});
                            next;
                        }

                        if ($method eq '~') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->not';
                            next;
                        }

                        if ($method eq '√') {
                            $code = $self->deparse_args(@{$call->{arg}}) . '->sqrt';
                            next;
                        }

                        if ($method eq 'say') {
                            $code = 'Corvinus::Types::Bool::Bool->new(CORE::say ' . $self->deparse_args(@{$call->{arg}}) . ')';
                            next;
                        }

                        if ($method eq 'print') {
                            $code =
                              'Corvinus::Types::Bool::Bool->new(CORE::print ' . $self->deparse_args(@{$call->{arg}}) . ')';
                            next;
                        }
                    }

                    if (ref($method)) {
                        $code .=
                          '->${\\do{' . $self->deparse_expr(ref($method) eq 'HASH' ? $method : {self => $method}) . '}}';
                    }
                    elsif ($method =~ /^[\pL_]/) {

                        # Exclamation mark (!) at the end of a method
                        if (substr($method, -1) eq '!') {

                            $code =
                                "CORE::sub : lvalue {my \$ref=\\$code; \$\$ref=\$\$ref\->"
                              . substr($method, 0, -1)
                              . (exists($call->{arg}) ? $self->deparse_args(@{$call->{arg}}) : '') . "}->()";

                            next;
                        }

                        # Special case for methods without '->'
                        else {
                            $code .= '->' if $code ne '';
                            $code .= $method;
                        }
                    }
                    else {

                        # Postfix dereference method
                        if ($method eq '@' or $method eq '@*') {
                            $self->top_add(qq{use experimental 'postderef';\n});
                            $code .= '->' . $method;
                        }

                        # Operator-like method call
                        else {
                            $code .= '->${\\' . q{'} . $method . q{'} . '}';
                        }
                    }
                }

                if (exists $call->{keyword}) {

                    my $key = $call->{keyword};
                    if (exists $self->{translations}{$ref} and exists $self->{translations}{$ref}{$key}) {
                        $key = $self->{translations}{$ref}{$key};
                    }

                    $code .= $key;
                }

                if (exists $call->{arg}) {
                    if ($ref eq 'Corvinus::Types::Block::For') {
                        $code .= $self->deparse_generic('(', ';', ')', @{$call->{arg}});
                    }
                    else {
                        $code .= $self->deparse_args(@{$call->{arg}});
                    }
                }

                if (exists $call->{block}) {

                    # TODO: move above the deparsing of `Block::If`
                    if ($ref eq 'Corvinus::Types::Block::If' and $i == $end) {
                        $code =
                          "do {\n" . (' ' x $Corvinus::SPACES) . $code . $self->deparse_bare_block(@{$call->{block}}) . '}';
                    }
                    else {
                        $code .= $self->deparse_bare_block(@{$call->{block}});
                    }
                    next;
                }
            }
        }

        $code;
    }

    sub deparse_script {
        my ($self, $struct) = @_;

        my @results;

        foreach my $class (grep exists $struct->{$_}, @{$self->{namespaces}}, 'main') {

            my $max = $#{$struct->{$class}};
            foreach my $i (0 .. $max) {
                my $expr = $struct->{$class}[$i];

                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});

                if (
                    $i > 0
                    and (
                         ref($expr) eq 'Corvinus::Variable::Label'
                         or (    ref($struct->{$class}[$i - 1]) eq 'HASH'
                             and ref($struct->{$class}[$i - 1]{self}) eq 'Corvinus::Variable::Label')
                        )
                  ) {
                    $results[-1] =
                        (ref($expr) eq 'Corvinus::Variable::Label' ? $expr->{name} : $struct->{$class}[$i - 1]{self}->{name})
                      . ':'
                      . $results[-1];
                }
                elsif (
                       $i == $max
                       and (ref($expr) eq 'Corvinus::Variable::Label'
                            or (ref($expr) eq 'HASH' and ref($expr->{self}) eq 'Corvinus::Variable::Label'))
                  ) {
                    $results[-1] = (ref($expr) eq 'Corvinus::Variable::Label' ? $expr->{name} : $expr->{self}{name}) . ':';
                }
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);

        (
             $self->{before}
           . ($self->{_has_constant} ? "};\n" : '')
           . (
              exists($self->{function_declarations})
                && @{$self->{function_declarations}}
              ? ("\n" . join("\n", map { $_->[1] } @{$self->{function_declarations}}) . "\n")
              : ''
             )
           . (
              exists($self->{block_declarations})
                && @{$self->{block_declarations}} ? ("\n" . join("\n", map { $_->[1] } @{$self->{block_declarations}}) . "\n")
              : ''
             )
           . $self->{top_program} . "\n"
           . join($self->{between}, @statements)
           . $self->{after}
        ) =~ s/^\s*/$self->{header}/r;
    }
}

1;
