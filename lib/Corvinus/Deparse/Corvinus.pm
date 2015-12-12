package Corvinus::Deparse::Corvinus {

    use 5.014;
    our @ISA = qw(Corvinus);
    use Scalar::Util qw(refaddr reftype);

    my %addr;

    sub new {
        my (undef, %args) = @_;

        my %opts = (
                    before       => '',
                    between      => ";\n",
                    after        => ";\n",
                    class        => 'main',
                    extra_parens => 0,
                    namespaces   => [],
                    %args,
                   );
        %addr = ();    # reset the addr map
        bless \%opts, __PACKAGE__;
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

    sub deparse_bare_block {
        my ($self, @args) = @_;

        $Corvinus::SPACES += $Corvinus::SPACES_INCR;
        my $code = $self->deparse_generic("{\n" . " " x ($Corvinus::SPACES),
                                          ";\n" . (" " x ($Corvinus::SPACES)),
                                          "\n" .  (" " x ($Corvinus::SPACES - $Corvinus::SPACES_INCR)) . "}", @args);

        $Corvinus::SPACES -= $Corvinus::SPACES_INCR;

        $code;
    }

    sub _dump_init_vars {
        my ($self, $init_obj, $type) = @_;
        my $code = $type . '(' . $self->_dump_vars(@{$init_obj->{vars}}) . ')';

        if (exists $init_obj->{args}) {
            $code .= '=' . $self->deparse_args($init_obj->{args});
        }

        $code;
    }

    sub _dump_reftype {
        my ($self, $obj) = @_;

        my $ref = ref($obj);

            $ref eq 'Corvinus::Variable::ClassInit'     ? $obj->{name}
          : $ref eq 'Corvinus::Types::Block::BlockInit' ? 'Bloc'
          :                                               substr($ref, rindex($ref, '::') + 2);
    }

    sub _dump_vars {
        my ($self, @vars) = @_;
        join(
            ', ',
            map {
                    (exists($_->{array}) ? '*' : exists($_->{hash}) ? ':' : '')
                  . (exists($_->{class}) && $_->{class} ne $self->{class} ? $_->{class} . '::' : '')
                  . (exists($_->{ref_type}) ? ($self->_dump_reftype($_->{ref_type}) . ' ') : '')
                  . $_->{name}
                  . (exists($_->{where_block}) ? $self->deparse_expr({self => $_->{where_block}}) : '')
                  . (exists($_->{where_expr}) ? ('(' . $self->deparse_expr({self => $_->{where_expr}}) . ')') : '')
                  . (exists($_->{value}) ? ('=(' . $self->deparse_expr({self => $_->{value}}) . ')') : '')
              } @vars
            );
    }

    sub _dump_string {
        my ($self, $str) = @_;

        return 'Text' if $str eq '';
        state $x = eval { require Data::Dump };
        $x || return ('"' . quotemeta($str) . '"');

        Data::Dump::quote($str);
    }

    sub _dump_number {
        my ($self, $num) = @_;

        state $table = {
                        'inf'  => q{Numar.inf},
                        '-inf' => q{Numar.inf('-')},
                        'nan'  => q{Numar.nan},
                        '0'    => q{Numar},
                       };

        exists($table->{lc($num)}) ? $table->{lc($num)} : $num;
    }

    sub _dump_array {
        my ($self, $array) = @_;
        '[' . join(', ', map { $self->deparse_expr(ref($_) eq 'HASH' ? $_ : {self => $_}) } @{$array}) . ']';
    }

    sub _dump_class_name {
        my ($self, $class) = @_;
        ref($class) ? $self->_dump_reftype($class) : $class;
    }

    sub deparse_expr {
        my ($self, $expr) = @_;

        my $code = '';
        my $obj  = $expr->{self};

        # Self obj
        my $ref = ref($obj);
        if ($ref eq 'HASH') {
            $code = join(', ', exists($obj->{self}) ? $self->deparse_expr($obj) : $self->deparse_script($obj));
            if ($self->{extra_parens}) {
                $code = "($code)";
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Variable') {
            if ($obj->{type} eq 'var' or $obj->{type} eq 'static' or $obj->{type} eq 'const') {
                $code =
                  $obj->{name} =~ /^[0-9]+\z/
                  ? ('$' . $obj->{name})
                  : (($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name});
            }
            elsif ($obj->{type} eq 'func' or $obj->{type} eq 'method') {
                if ($addr{refaddr($obj)}++) {
                    $code =
                      $obj->{name} eq ''
                      ? '__FUNC__'
                      : (($obj->{class} ne $self->{class} ? $obj->{class} . '::' : '') . $obj->{name});
                }
                else {
                    my $block     = $obj->{value};
                    my $in_module = $obj->{class} ne $self->{class};

                    if ($in_module) {
                        $code = "modul $obj->{class} {\n";
                        $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                        $code .= ' ' x $Corvinus::SPACES;
                    }

                    $code .= $obj->{type} . ' ' . $obj->{name};
                    local $self->{class} = $obj->{class};
                    my $var_obj = delete $block->{init_vars};

                    $code .= '('
                      . $self->_dump_vars(@{$var_obj->{vars}}[($obj->{type} eq 'method' ? 1 : 0) .. $#{$var_obj->{vars}}])
                      . ') ';

                    if (exists $obj->{cached}) {
                        $code .= 'e memorata ';
                    }

                    if (exists $obj->{returns}) {
                        $code .= '-> (' . join(',', map { $self->deparse_expr({self => $_}) } @{$obj->{returns}}) . ') ';
                    }

                    $code .= $self->deparse_expr({self => $block});
                    $block->{init_vars} = $var_obj;

                    if ($in_module) {
                        $code .= "\n}";
                        $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                    }
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::ClassAttr') {
            $code = $self->_dump_init_vars($obj, 'are');
        }
        elsif ($ref eq 'Corvinus::Variable::Struct') {
            if ($addr{refaddr($obj)}++) {
                $code = $obj->{name};
            }
            else {
                $code = "struct $obj->{name} {" . $self->_dump_vars(@{$obj->{vars}}) . '}';
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Local') {
            $code = 'local ' . '(' . $self->deparse_script($obj->{expr}) . ')';
        }
        elsif ($ref eq 'Corvinus::Variable::Global') {
            $code = 'global ' . $obj->{class} . '::' . $obj->{name},;
        }
        elsif ($ref eq 'Corvinus::Variable::Init') {
            $code = $self->_dump_init_vars($obj, 'var');
        }
        elsif ($ref eq 'Corvinus::Variable::ConstInit') {
            $code = join(";\n" . (" " x $Corvinus::SPACES), map { $self->deparse_expr({self => $_}) } @{$obj->{vars}});
        }
        elsif ($ref eq 'Corvinus::Types::Range::RangeNumber' or $ref eq 'Corvinus::Types::Range::RangeString') {
            $code = $self->_dump_reftype($obj);
        }
        elsif ($ref eq 'Corvinus::Variable::Define') {
            my $name = $obj->{name};
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "define $name = (" . $self->deparse_script($obj->{expr}) . ')';
            }
            else {
                $code = $name;
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Const') {
            my $name = $obj->{name};
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "const $name = (" . $self->deparse_script($obj->{expr}) . ')';
            }
            else {
                $code = $name;
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Static') {
            my $name = $obj->{name};
            if (not exists $obj->{inited}) {
                $obj->{inited} = 1;
                $code = "static $name = (" . $self->deparse_script($obj->{expr}) . ')';
            }
            else {
                $code = $name;
            }
        }
        elsif ($ref eq 'Corvinus::Variable::ClassInit') {
            if ($addr{refaddr($obj)}++) {
                $code =
                  $self->_dump_class_name(
                                     $obj->{name} eq ''
                                     ? '__CLASS__'
                                     : ($obj->{class} ne $self->{class} ? ($obj->{class} . '::' . $obj->{name}) : $obj->{name})
                  );
            }
            else {
                my $block     = $obj->{block};
                my $in_module = $obj->{class} ne $self->{class};

                if ($in_module) {
                    $code = "modul $obj->{class} {\n";
                    $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                    $code .= ' ' x $Corvinus::SPACES;
                }

                local $self->{class} = $obj->{class};
                $code .= "class " . $self->_dump_class_name($obj->{name});
                $code .= '(' . $self->_dump_vars(@{$obj->{vars}}) . ')';
                if (exists $obj->{inherit}) {
                    $code .= ' << ' . join(', ', map { $_->{name} } @{$obj->{inherit}}) . ' ';
                }
                $code .= $self->deparse_expr({self => $block});

                if ($in_module) {
                    $code .= "\n}";
                    $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                }
            }
        }
        elsif ($ref eq 'Corvinus::Types::Block::BlockInit') {
            if ($addr{refaddr($obj)}++) {
                $code = keys(%{$obj}) ? '__BLOC__' : 'Bloc';
            }
            else {
                if (keys(%{$obj})) {
                    $code = '{';
                    if (exists($obj->{init_vars}) and @{$obj->{init_vars}{vars}}) {
                        my @vars = @{$obj->{init_vars}{vars}};
                        if (@vars) {
                            $code .= '| ' . $self->_dump_vars(@vars) . ' |';
                        }
                    }

                    $Corvinus::SPACES += $Corvinus::SPACES_INCR;
                    my @statements = $self->deparse_script($obj->{code});

                    if (@statements) {
                        $statements[-1] = '(' . $statements[-1] . ')';
                    }

                    if (@statements == 1 and length($statements[0]) <= 80) {
                        $code .= "$statements[0]}";
                    }
                    else {
                        $code .=
                          @statements
                          ? ("\n"
                             . (" " x $Corvinus::SPACES)
                             . join(";\n" . (" " x $Corvinus::SPACES), @statements) . "\n"
                             . (" " x ($Corvinus::SPACES - $Corvinus::SPACES_INCR)) . '}')
                          : '}';
                    }

                    $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
                }
                else {
                    $code = 'Bloc';
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Ref') {
            if (not exists $expr->{call}) {
                $code = 'Ref';
            }
        }
        elsif ($ref eq 'Corvinus::Sys::Sys') {
            $code = exists($obj->{file_name}) ? '' : 'Sistem';
        }
        elsif ($ref eq 'Corvinus::Meta::Assert') {
            $code = $obj->{act} . $self->deparse_args($obj->{arg});
        }
        elsif ($ref eq 'Corvinus::Meta::Error') {
            $code = 'eroare' . $self->deparse_args($obj->{arg});
        }
        elsif ($ref eq 'Corvinus::Meta::Warning') {
            $code = 'avert' . $self->deparse_args($obj->{arg});
        }
        elsif ($ref eq 'Corvinus::Meta::Unimplemented') {
            $code = '...';
        }
        elsif ($ref eq 'Corvinus::Eval::Eval') {
            $code = 'eval' . $self->deparse_args($obj->{expr});
        }
        elsif ($ref eq 'Corvinus::Parser') {
            $code = 'Parser';
        }
        elsif ($ref eq 'Corvinus') {
            $code = 'Corvinus';
        }
        elsif ($ref eq 'Corvinus::Variable::NamedParam') {
            $code = $obj->[0] . ':' . $self->deparse_args(@{$obj->[1]});
        }
        elsif ($ref eq 'Corvinus::Variable::Label') {
            $code = '@:' . $obj->{name};
        }
        elsif ($ref eq 'Corvinus::Variable::LazyMethod') {
            $code = 'LazyMethod';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Break') {
            $code = 'stop';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Given') {
            $code = 'dat ' . $self->deparse_args($obj->{expr}) . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::When') {
            $code = 'cand(' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Case') {
            $code = 'caz(' . $self->deparse_args($obj->{expr}) . ')' . $self->deparse_bare_block($obj->{block}{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Default') {
            $code = 'altfel' . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Next') {
            $code = 'sari';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Continue') {
            $code = 'continua';
        }
        elsif ($ref eq 'Corvinus::Types::Block::Return') {
            if (not exists $expr->{call}) {
                $code = 'return';
            }
        }
        elsif ($ref eq 'Corvinus::Types::Bool::Ternary') {
            $code = '('
              . $self->deparse_script($obj->{cond}) . ' ? '
              . $self->deparse_args($obj->{true}) . ' : '
              . $self->deparse_args($obj->{false}) . ')';
        }
        elsif ($ref eq 'Corvinus::Module::OO') {
            $code = '%s' . $self->_dump_string($obj->{module});
        }
        elsif ($ref eq 'Corvinus::Module::Func') {
            $code = '%S' . $self->_dump_string($obj->{module});
        }
        elsif ($ref eq 'Corvinus::Types::Array::List') {
            $code = join(', ', map { $self->deparse_expr({self => $_}) } @{$obj});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Gather') {
            $code = 'aduna ' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Take') {
            $code = 'ia' . $self->deparse_args($obj->{expr});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Do') {
            $code = 'do ' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Corvinus::Types::Block::Loop') {
            $code = 'bucla ' . $self->deparse_expr({self => $obj->{block}});
        }
        elsif ($ref eq 'Corvinus::Types::Block::ForArray') {
            $code =
                'pentru '
              . $self->deparse_expr({self => $obj->{var}}) . ' in ('
              . $self->deparse_expr({self => $obj->{array}}) . ') '
              . $self->deparse_bare_block($obj->{block}->{code});
        }
        elsif ($ref eq 'Corvinus::Math::Math') {
            $code = 'Mate';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::DirHandle') {
            $code = 'DirHandle';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::FileHandle') {
            if ($obj->{fh} eq \*STDIN) {
                $code = 'STDIN';
            }
            elsif ($obj->{fh} eq \*STDOUT) {
                $code = 'STDOUT';
            }
            elsif ($obj->{fh} eq \*STDERR) {
                $code = 'STDERR';
            }
            elsif ($obj->{fh} eq \*ARGV) {
                $code = 'ARGF';
            }
            else {
                $code = 'DATA';
                if (not exists $addr{$obj->{fh}}) {
                    my $orig_pos = tell($obj->{fh});
                    seek($obj->{fh}, 0, 0);
                    $self->{after} .= "\n__DATA__\n" . do {
                        local $/;
                        require Encode;
                        Encode::decode_utf8(readline($obj->{fh}));
                    };
                    seek($obj->{fh}, $orig_pos, 0);
                    $addr{$obj->{fh}} = 1;
                }
            }
        }
        elsif ($ref eq 'Corvinus::Variable::Magic') {
            $code = $obj->{name};
        }
        elsif ($ref eq 'Corvinus::Types::Hash::Hash') {
            $code = keys(%{$obj}) ? $obj->dump->get_value : 'Hash';
        }
        elsif ($ref eq 'Corvinus::Types::Glob::Socket') {
            $code = 'Socket';
        }
        elsif ($ref eq 'Corvinus::Perl::Perl') {
            $code = 'Perl';
        }
        elsif ($ref eq 'Corvinus::Time::Time') {
            $code = 'Timp';
        }
        elsif ($ref eq 'Corvinus::Sys::Sig') {
            $code = 'Semnal';
        }
        elsif ($ref eq 'Corvinus::Types::Number::Number') {
            my $value = $obj->get_value;

            if (ref($value)) {
                if (ref($value) eq 'Math::BigRat') {
                    $code = '(' . join('//', map { $self->_dump_number($_) } $value->parts()) . ')';
                }
                else {
                    $code = $self->_dump_number($value->bstr);
                }
            }
            else {
                $code = $self->_dump_number($value);
            }
        }
        elsif ($ref eq 'Corvinus::Types::Array::Array' or $ref eq 'Corvinus::Types::Array::HCArray') {
            if (not @{$obj}) {
                $code = 'Lista';
            }
            else {
                $code = $self->_dump_array($obj);
            }
        }
        elsif ($ref eq 'Corvinus::Types::Nil::Nil') {
            $code = 'nul';
        }
        elsif ($ref eq 'Corvinus::Object::Object') {
            $code = 'Object';
        }
        elsif ($ref =~ /^Corvinus::/ and $obj->can('dump')) {
            $code = $obj->dump->get_value;

            if ($ref eq 'Corvinus::Types::Glob::Backtick') {
                if (${$obj} eq '') {
                    $code = 'Comanda';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Number::Complex') {
                if (${$obj} == 0) {
                    $code = 'Complex';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Regex::Regex') {
                if ($code eq '//') {
                    $code = 'Regex';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Glob::File') {
                if (${$obj} eq '') {
                    $code = 'Fisier';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Array::Pair') {
                if (    not defined($obj->[0])
                    and not defined($obj->[1])) {
                    $code = 'Pereche';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Byte::Bytes') {
                if (not @{$obj}) {
                    $code = 'Octeti';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Byte::Byte') {
                if (${$obj} == 0) {
                    $code = 'Octet';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Char::Chars') {
                if (not @{$obj}) {
                    $code = 'Caractere';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Grapheme::Grapheme') {
                if (${$obj} eq "\0") {
                    $code = 'Grafem';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Grapheme::Graphemes') {
                if (not @{$obj}) {
                    $code = 'Grafeme';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Glob::Dir') {
                if (${$obj} eq '') {
                    $code = 'Dosar';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Char::Char') {
                if (${$obj} eq "\0") {
                    $code = 'Caracter';
                }
            }
            elsif ($ref eq 'Corvinus::Types::String::String') {
                if (${$obj} eq '') {
                    $code = 'Text';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Array::MultiArray') {
                if (not @{$obj}) {
                    $code = 'MultiLista';
                }
            }
            elsif ($ref eq 'Corvinus::Types::Glob::Pipe') {
                if (not @{$obj}) {
                    $code = 'Proces';
                }
            }
        }

        # Array and hash indices
        if (exists $expr->{ind}) {
            foreach my $ind (@{$expr->{ind}}) {
                if (exists $ind->{array}) {
                    $code .= $self->_dump_array($ind->{array});
                }
                else {
                    $code .= '{'
                      . join(',',
                             map { ref($_) eq 'HASH' ? ($self->deparse_expr($_)) : $self->deparse_generic('', '', '', $_) }
                               @{$ind->{hash}})
                      . '}';
                }
            }
        }

        # Method call on the self obj (+optional arguments)
        if (exists $expr->{call}) {
            foreach my $i (0 .. $#{$expr->{call}}) {

                my $call   = $expr->{call}[$i];
                my $method = $call->{method};

                if (defined $method and $method eq 'call' and exists $call->{arg}) {
                    undef $method;
                }

                if (defined $method) {

                    if (ref($method) ne '') {
                        $code .= '.'
                          . (
                             '('
                               . $self->deparse_expr(
                                                     ref($method) eq 'HASH'
                                                     ? $method
                                                     : {self => $method}
                                                    )
                               . ')'
                            );

                    }
                    elsif ($method =~ /^[\pL_]/) {

                        if ($ref eq 'Corvinus::Types::Block::BlockInit' and ($method eq 'loop' or $method eq 'bucla')) {
                            $code = "bucla $code";
                        }
                        else {

                            if ($code ne '') {
                                $code .= '->';
                            }

                            $code .= $method;
                        }
                    }
                    else {

                        if ($method eq '@') {
                            $code .= ".$method";
                        }
                        elsif ($method eq '@*') {
                            $code = "\@($code)";
                        }
                        else {
                            if ($ref eq 'Corvinus::Variable::Ref' or $ref eq 'Corvinus::Object::Unary') {
                                $code .= $method;
                            }
                            else {
                                $code = "($code) $method ";
                            }
                        }
                    }
                }

                if (exists $call->{keyword}) {
                    if ($code ne '') {
                        $code .= ' ';
                    }
                    $code .= $call->{keyword};
                }

                if (exists $call->{arg}) {
                    if ($ref eq 'Corvinus::Types::Block::For') {
                        $code .= '(' . join(';', map { $self->deparse_args($_) } @{$call->{arg}}) . ')';
                    }
                    else {
                        $code .= $self->deparse_args(@{$call->{arg}});
                    }
                }

                if (exists $call->{block}) {
                    $code .= $self->deparse_bare_block(@{$call->{block}});
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
            my $in_module = $class ne $self->{class};
            local $self->{class} = $class;
            foreach my $i (0 .. $#{$struct->{$class}}) {
                my $expr = $struct->{$class}[$i];
                push @results, ref($expr) eq 'HASH' ? $self->deparse_expr($expr) : $self->deparse_expr({self => $expr});
            }
            if ($in_module) {
                my $spaces = " " x $Corvinus::SPACES_INCR;
                s/^/$spaces/gm for @results;
                $results[0] = "modul $class {\n" . $results[0];
                $results[-1] .= "\n}";
            }
        }

        wantarray ? @results : $results[-1];
    }

    sub deparse {
        my ($self, $struct) = @_;
        my @statements = $self->deparse_script($struct);
        $self->{before} . join($self->{between}, @statements) . $self->{after};
    }
};

1
