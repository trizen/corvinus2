package Corvinus::Parser {

    use utf8;
    use 5.014;

    our $DEBUG = 0;

    sub new {
        my (undef, %opts) = @_;

        my %options = (
            line          => 1,
            inc           => [],
            class         => 'main',           # a.k.a. namespace
            vars          => {'main' => []},
            ref_vars_refs => {'main' => []},
            EOT           => [],

            postfix_ops => {                   # postfix operators
                             '--'  => 1,
                             '++'  => 1,
                             '...' => 1,
                             '!'   => 1,
                           },

            hyper_ops => {

                # type => [takes args, method name]
                map    => [1, 'map_operator'],
                pam    => [1, 'pam_operator'],
                unroll => [1, 'unroll_operator'],
                reduce => [0, 'reduce_operator'],
            },

            binpost_ops => {    # infix + postfix operators
                             '...' => 1,
                           },

            special_constructs => {
                                   'Corvinus::Types::Block::While' => 1,
                                   'Corvinus::Types::Block::If'    => 1,
                                   'Corvinus::Types::Block::For'   => 1,
                                   'Corvinus::Types::Block::Given' => 1,
                                   'Corvinus::Types::Block::When'  => 1,
                                  },

            static_obj_re => qr{\G
                (?>
                       (?:nul|nil)\b                             (?{ state $x = Corvinus::Types::Nil::Nil->new })
                     | (?:adev(?:arat)?+|true)\b                 (?{ state $x = Corvinus::Types::Bool::Bool->true })
                     | (?:false?+|Bool)\b                        (?{ state $x = Corvinus::Types::Bool::Bool->false })
                     | (?:sari|next)\b                           (?{ state $x = Corvinus::Types::Block::Next->new })
                     | (?:stop|break)\b                          (?{ state $x = Corvinus::Types::Block::Break->new })
                     | continu[ae]\b                             (?{ state $x = Corvinus::Types::Block::Continue->new })
                     | BlackHole\b                               (?{ state $x = Corvinus::Types::Black::Hole->new })
                     | Block?+\b                                 (?{ state $x = Corvinus::Types::Block::CodeInit->new })
                     | (?:Comanda|Backtick)\b                    (?{ state $x = Corvinus::Types::Glob::Backtick->new })
                     | ARGF\b                                    (?{ state $x = Corvinus::Types::Glob::FileHandle->new(fh => \*ARGV) })
                     | (?:STDIN|FileHandle)\b                    (?{ state $x = Corvinus::Types::Glob::FileHandle->stdin })
                     | STDOUT\b                                  (?{ state $x = Corvinus::Types::Glob::FileHandle->stdout })
                     | STDERR\b                                  (?{ state $x = Corvinus::Types::Glob::FileHandle->stderr })
                     | DirHandle\b                               (?{ state $x = Corvinus::Types::Glob::Dir->cwd->open })
                     | (?:Dosar|Dir)\b                           (?{ state $x = Corvinus::Types::Glob::Dir->new })
                     | (?:File|Fisier)\b                         (?{ state $x = Corvinus::Types::Glob::File->new })
                     | (?:Lista|Arr(?:ay)?+)\b                   (?{ state $x = Corvinus::Types::Array::Array->new })
                     | (?:Multi(?:Lista|Arr(?:ay)?+))\b          (?{ state $x = Corvinus::Types::Array::MultiArray->new })
                     | (?:Pereche|Pair)\b                        (?{ state $x = Corvinus::Types::Array::Pair->new })
                     | (?:Hash|Dict(?:ionar)?+)\b                (?{ state $x = Corvinus::Types::Hash::Hash->new })
                     | (?:Text|String)\b                         (?{ state $x = Corvinus::Types::String::String->new })
                     | Num(?:ar|ber)?+\b                         (?{ state $x = Corvinus::Types::Number::Number->new })
                     | (?:RangeNum(?:ber)?+|SirNum(?:ar)?+)\b    (?{ state $x = Corvinus::Types::Range::RangeNumber->new })
                     | (?:RangeStr(?:ing)?+|SirText)\b           (?{ state $x = Corvinus::Types::Range::RangeString->new })
                     | Mat[eh]\b                                 (?{ state $x = Corvinus::Math::Math->new })
                     | Socket\b                                  (?{ state $x = Corvinus::Types::Glob::Socket->new })
                     | (?:Proces|Pipe)\b                         (?{ state $x = Corvinus::Types::Glob::Pipe->new })
                     | (?:Octet|Byte)\b                          (?{ state $x = Corvinus::Types::Byte::Byte->new })
                     | Ref\b                                     (?{ state $x = Corvinus::Variable::Ref->new })
                     | (?:Metoda|LazyMethod)\b                   (?{ state $x = Corvinus::Variable::LazyMethod->new })
                     | (?:Octeti|Bytes)\b                        (?{ state $x = Corvinus::Types::Byte::Bytes->new })
                     | (?:Timp|Time)\b                           (?{ state $x = Corvinus::Time::Time->new })
                     | Complex\b                                 (?{ state $x = Corvinus::Types::Number::Complex->new })
                     | (?:Semnal|Sig|SIG)\b                      (?{ state $x = Corvinus::Sys::SIG->new })
                     | (?:Caractere|Chars)\b                     (?{ state $x = Corvinus::Types::Char::Chars->new })
                     | (?:Caracter|Char)\b                       (?{ state $x = Corvinus::Types::Char::Char->new })
                     | (?:Grafeme|Graphemes)\b                   (?{ state $x = Corvinus::Types::Grapheme::Graphemes->new })
                     | (?:Grafem|Grapheme)\b                     (?{ state $x = Corvinus::Types::Grapheme::Grapheme->new })
                     | (?:Sistem|Sys)\b                          (?{ state $x = Corvinus::Sys::Sys->new })
                     | Regexp?\b                                 (?{ state $x = Corvinus::Types::Regex::Regex->new('') })
                     | Corvinus\b                                (?{ state $x = Corvinus->new })
                     | Ob[ij]ect\b                               (?{ state $x = Corvinus::Object::Object->new })
                     | Perl\b                                    (?{ state $x = Corvinus::Perl::Perl->new })
                     | \$\.                                      (?{ state $x = Corvinus::Variable::Magic->new('$.') })
                     | \$\?                                      (?{ state $x = Corvinus::Variable::Magic->new('$?') })
                     | \$\$                                      (?{ state $x = Corvinus::Variable::Magic->new('$$') })
                     | \$\^T\b                                   (?{ state $x = Corvinus::Variable::Magic->new('$^T') })
                     | \$\|                                      (?{ state $x = Corvinus::Variable::Magic->new('$|') })
                     | \$!                                       (?{ state $x = Corvinus::Variable::Magic->new('$!') })
                     | \$"                                       (?{ state $x = Corvinus::Variable::Magic->new('$"') })
                     | \$\\                                      (?{ state $x = Corvinus::Variable::Magic->new('$\\') })
                     | \$@                                       (?{ state $x = Corvinus::Variable::Magic->new('$@') })
                     | \$%                                       (?{ state $x = Corvinus::Variable::Magic->new('$%') })
                     | \$~                                       (?{ state $x = Corvinus::Variable::Magic->new('$~') })
                     | \$/                                       (?{ state $x = Corvinus::Variable::Magic->new('$/') })
                     | \$&                                       (?{ state $x = Corvinus::Variable::Magic->new('$&') })
                     | \$'                                       (?{ state $x = Corvinus::Variable::Magic->new('$\'') })
                     | \$`                                       (?{ state $x = Corvinus::Variable::Magic->new('$`') })
                     | \$:                                       (?{ state $x = Corvinus::Variable::Magic->new('$:') })
                     | \$\]                                      (?{ state $x = Corvinus::Variable::Magic->new('$]') })
                     | \$\[                                      (?{ state $x = Corvinus::Variable::Magic->new('$[') })
                     | \$;                                       (?{ state $x = Corvinus::Variable::Magic->new('$;') })
                     | \$,                                       (?{ state $x = Corvinus::Variable::Magic->new('$,') })
                     | \$\^O\b                                   (?{ state $x = Corvinus::Variable::Magic->new('$^O') })
                     | \$\^PERL\b                                (?{ state $x = Corvinus::Variable::Magic->new('$^X') })
                     | (?:\$0|\$\^CORVIN)\b                      (?{ state $x = Corvinus::Variable::Magic->new('$0') })
                     | \$\)                                      (?{ state $x = Corvinus::Variable::Magic->new('$)') })
                     | \$\(                                      (?{ state $x = Corvinus::Variable::Magic->new('$(') })
                     | \$<                                       (?{ state $x = Corvinus::Variable::Magic->new('$<') })
                     | \$>                                       (?{ state $x = Corvinus::Variable::Magic->new('$>') })
                     | ∞                                         (?{ state $x = Corvinus::Types::Number::Number->new->inf })
                ) (?!::)
            }x,
            prefix_obj_re => qr{\G
              (?:
                  (?:daca|if)\b                                  (?{ Corvinus::Types::Block::If->new })
                | (?:executa|do)\b                               (?{ Corvinus::Types::Block::Do->new })
                | (?:cat_timp|while)\b                           (?{ Corvinus::Types::Block::While->new })
                | (?:incearca|try)\b                             (?{ Corvinus::Types::Block::Try->new })
                | (?:pentru|for)\b                               (?{ Corvinus::Types::Block::For->new })
                | return(?:eaza)?+\b                             (?{ Corvinus::Types::Block::Return->new })
                | (?:dat|given)\b                                (?{ Corvinus::Types::Block::Given->new })
                | (?:cand|when)\b                                (?{ Corvinus::Types::Block::When->new })
                | (?:definit|citeste|defined|read)\b             (?{ state $x = Corvinus::Sys::Sys->new })
                | (?:sari_la|eroare|avert|goto|die|warn)\b       (?{ state $x = Corvinus::Perl::Builtin->new })
                | (?:[*\\&]|\+\+|--)                             (?{ state $x = Corvinus::Variable::Ref->new })
                | (?:>>?|[√+~!-]|(?:spune|scrie|print|say)\b)    (?{ state $x = Corvinus::Object::Unary->new })
                | :                                              (?{ state $x = Corvinus::Types::Hash::Hash->new })
              )
            }x,
            quote_operators_re => qr{\G
             (?:
                # String
                 (?: ['‘‚’] | %q\b. )                                      (?{ [qw(0 new Corvinus::Types::String::String)] })
                |(?: ["“„”] | %(?:Q\b. | (?!\w). ))                        (?{ [qw(1 new Corvinus::Types::String::String)] })

                # File
                | %f\b.                                                    (?{ [qw(0 new Corvinus::Types::Glob::File)] })
                | %F\b.                                                    (?{ [qw(1 new Corvinus::Types::Glob::File)] })

                # Dir
                | %d\b.                                                    (?{ [qw(0 new Corvinus::Types::Glob::Dir)] })
                | %D\b.                                                    (?{ [qw(1 new Corvinus::Types::Glob::Dir)] })

                # Pipe
                | %p\b.                                                    (?{ [qw(0 new Corvinus::Types::Glob::Pipe)] })
                | %P\b.                                                    (?{ [qw(1 new Corvinus::Types::Glob::Pipe)] })

                # Backtick
                | %x\b.                                                    (?{ [qw(0 new Corvinus::Types::Glob::Backtick)] })
                | (?: %X\b. | ` )                                          (?{ [qw(1 new Corvinus::Types::Glob::Backtick)] })

                # Bytes
                | %b\b.                                                    (?{ [qw(0 to_bytes Corvinus::Types::Byte::Bytes)] })
                | %B\b.                                                    (?{ [qw(1 to_bytes Corvinus::Types::Byte::Bytes)] })

                # Chars
                | %c\b.                                                    (?{ [qw(0 to_chars Corvinus::Types::Char::Chars)] })
                | %C\b.                                                    (?{ [qw(1 to_chars Corvinus::Types::Char::Chars)] })

                # Graphemes
                | %g\b.                                                    (?{ [qw(0 to_graphemes Corvinus::Types::Grapheme::Graphemes)] })
                | %G\b.                                                    (?{ [qw(1 to_graphemes Corvinus::Types::Grapheme::Graphemes)] })

                # Symbols
                | %s\b.                                                    (?{ [qw(0 __NEW__ Corvinus::Module::OO)] })
                | %S\b.                                                    (?{ [qw(0 __NEW__ Corvinus::Module::Func)] })
             )
            }xs,
            built_in_classes => {
                map { $_ => 1 }
                  qw(
                  Fisier File
                  FileHandle
                  Dosar Dir
                  DirHandle
                  Lista Array Arr
                  Pereche Pair
                  MultiLista MultiArray MultiArr
                  Dict Dictionar Hash
                  Text String
                  Num Numar Number
                  SirText
                  SirNum SirNumar
                  Complex
                  Mate Math
                  Proces Pipe
                  Ref
                  Socket
                  Octet Byte
                  Octeti Bytes
                  Caracter Char
                  Caractere Chars
                  Grafem Grafeme
                  Bool
                  Sistem Sys
                  Semnal Sig
                  Regex Regexp
                  Timp
                  Perl
                  Corvinus
                  Obiect Object
                  Parser
                  Bloc Block
                  BlackHole
                  Comanda Backtick
                  Metoda

                  adev adevarat true
                  fals false
                  nul nil
                  )
            },
            keywords => {
                map { $_ => 1 }
                  qw(
                  sari
                  stop
                  return returneaza
                  pentru bucla
                  daca cat_timp
                  dat cand
                  incearca
                  continua
                  import
                  include
                  eval
                  citeste
                  eroare
                  avert

                  assert
                  assert_eq
                  assert_ne

                  local
                  global
                  var
                  const
                  func
                  enum
                  class
                  static
                  define
                  struct
                  modul

                  DATA
                  ARGV
                  ARGF
                  ENV

                  STDIN
                  STDOUT
                  STDERR

                  __FILE__
                  __LINE__
                  __END__
                  __DATA__
                  __TIME__
                  __DATE__
                  __NAMESPACE__

                  )
            },
            match_flags_re  => qr{[msixpogcaludn]+},
            var_name_re     => qr/[_\pL][_\pL\pN]*(?>::[_\pL][_\pL\pN]*)*/,
            method_name_re  => qr/[_\pL][_\pL\pN]*!?/,
            var_init_sep_re => qr/\G\h*(?:=>|[=:])\h*/,
            operators_re    => do {
                local $" = q{|};

                # The order matters! (in a way)
                my @operators = map { quotemeta } qw(

                  ||= ||
                  &&= &&

                  ^.. ..^

                  %%
                  ~~ !~
                  <=>
                  <<= >>=
                  << >>
                  |= |
                  &= &
                  == =~
                  := =
                  <= >= < >
                  ++ --
                  += +
                  -= -
                  /= / ÷= ÷
                  **= **
                  %= %
                  ^= ^
                  *= *
                  ...
                  != ..
                  \\\\= \\\\
                  ! \\
                  : « » ~
                  );

                qr{
                    (?(DEFINE)
                        (?<ops>
                              @operators
                            | \p{Block: Mathematical_Operators}
                            | \p{Block: Supplemental_Mathematical_Operators}
                        )
                    )

                      »(?<unroll>[_\pL][_\pL\pN]*|(?&ops))«          # unroll operator (e.g.: »add« or »+«)
                    | >>(?<unroll>[_\pL][_\pL\pN]*|(?&ops))<<        # unroll operator (e.g.: >>add<< or >>+<<)

                    | »(?<map>[_\pL][_\pL\pN]*|(?&ops))»             # mapping operator (e.g.: »add» or »+»)
                    | >>(?<map>[_\pL][_\pL\pN]*|(?&ops))>>           # mapping operator (e.g.: >>add>> or >>+>>)

                    | «(?<pam>[_\pL][_\pL\pN]*|(?&ops))«             # reverse mapping operator (e.g.: «add« or «+«)
                    | <<(?<pam>[_\pL][_\pL\pN]*|(?&ops))<<           # reverse mapping operator (e.g.: <<add<< or <<+<<)

                    | <<(?<reduce>[_\pL][_\pL\pN]*|(?&ops))>>        # reduce operator (e.g.: <<add>> or <<+>>)
                    | «(?<reduce>[_\pL][_\pL\pN]*|(?&ops))»          # reduce operator (e.g.: «add» or «+»)

                    | \h*\^(?<op>[_\pL][_\pL\pN]*[!:?]?)\^\h*        # method-like operator (e.g.: ^add^)
                    | (?<op>(?&ops))                                 # primitive operator   (e.g.: +, -, *, /)
                }x;
            },

            # Reference: http://en.wikipedia.org/wiki/International_variation_in_quotation_marks
            delim_pairs => {
                qw~
                  ( )       [ ]       { }       < >
                  « »       » «       ‹ ›       › ‹
                  „ ”       “ ”       ‘ ’       ‚ ’
                  〈 〉     ﴾ ﴿       〈 〉     《 》
                  「 」     『 』     【 】     〔 〕
                  〖 〗     〘 〙     〚 〛     ⸨ ⸩
                  ⌈ ⌉       ⌊ ⌋       〈 〉     ❨ ❩
                  ❪ ❫       ❬ ❭       ❮ ❯       ❰ ❱
                  ❲ ❳       ❴ ❵       ⟅ ⟆       ⟦ ⟧
                  ⟨ ⟩       ⟪ ⟫       ⟬ ⟭       ⟮ ⟯
                  ⦃ ⦄       ⦅ ⦆       ⦇ ⦈       ⦉ ⦊
                  ⦋ ⦌       ⦍ ⦎       ⦏ ⦐       ⦑ ⦒
                  ⦗ ⦘       ⧘ ⧙       ⧚ ⧛       ⧼ ⧽
                  ~
            },
            %opts,
                      );

        $options{ref_vars} = $options{vars};
        $options{file_name}   //= '-';
        $options{script_name} //= '-';

        bless \%options, __PACKAGE__;
    }

    sub fatal_error {
        my ($self, %opt) = @_;

        my $start      = rindex($opt{code}, "\n", $opt{pos}) + 1;
        my $point      = $opt{pos} - $start;
        my $error_line = (split(/\R/, substr($opt{code}, $start, 80)))[0];

        my @lines = (
                     "am identificat o erorare în programul dvs.",
                     "ceva este greșit în programul dvs.",
                     "ceva este scris greșit; vă rugăm să verificăți programul cu atenție",
                     "nu mai pot continua; mă opresc aici",
                    );

        state $x = require File::Basename;
        my $basename = File::Basename::basename($0);

        my $error = sprintf("%s: %s\n\nFisier: %s\nLinia : %s\nEroare: %s\n\n" . ("~" x 80) . "\n%s\n",
                            $basename,
                            $lines[rand @lines],
                            $self->{file_name} // '-',
                            $self->{line}, join(', ', grep { defined } $opt{error}, $opt{expected}), $error_line,);

        my $pointer = ' ' x ($point) . '^' . "\n";
        die $error, $pointer, '~' x 80, "\n";
    }

    sub find_var {
        my ($self, $var_name, $class) = @_;

        foreach my $var (@{$self->{vars}{$class}}) {
            next if ref $var eq 'ARRAY';
            if ($var->{name} eq $var_name) {
                return (wantarray ? ($var, 1) : $var);
            }
        }

        foreach my $var (@{$self->{ref_vars_refs}{$class}}) {
            next if ref $var eq 'ARRAY';
            if ($var->{name} eq $var_name) {
                return (wantarray ? ($var, 0) : $var);
            }
        }

        return;
    }

    sub check_declarations {
        my ($self, $hash_ref) = @_;

        foreach my $class (grep { $_ eq 'main' } keys %{$hash_ref}) {

            my $array_ref = $hash_ref->{$class};

            foreach my $variable (@{$array_ref}) {
                if (ref $variable eq 'ARRAY') {
                    $self->check_declarations({$class => $variable});
                }
                elsif ($self->{interactive}) {

                    # Minor exception for interactive mode
                    if (ref $variable->{obj} eq 'HASH') {
                        ++$variable->{obj}{in_use};
                    }

                }
                elsif (   $variable->{count} == 0
                       && $variable->{type} ne 'class'
                       && $variable->{type} ne 'func'
                       && $variable->{type} ne 'method'
                       && $variable->{type} ne 'global'
                       && $variable->{name} ne 'self'
                       && $variable->{name} ne ''
                       && chr(ord $variable->{name}) ne '_') {

                    warn '[WARN] '
                      . "$variable->{type} '$variable->{name}' has been declared, but not used again, at "
                      . "$self->{file_name}, line $variable->{line}\n";
                }
                elsif ($DEBUG) {
                    warn "[WARN] Variable '$variable->{name}' is used $variable->{count} times!\n";
                }
            }
        }
    }

    sub get_name_and_class {
        my ($self, $var_name) = @_;

        my $rindex = rindex($var_name, '::');
        $rindex != -1
          ? (substr($var_name, $rindex + 2), substr($var_name, 0, $rindex))
          : ($var_name, $self->{class});
    }

    sub get_quoted_words {
        my ($self, %opt) = @_;

        my $string = $self->get_quoted_string(code => $opt{code}, no_count_line => 1);
        $self->parse_whitespace(code => \$string);

        my @words;
        while ($string =~ /\G((?>[^\s\\]+|\\.)++)/gcs) {
            push @words, $1 =~ s{\\#}{#}gr;
            $self->parse_whitespace(code => \$string);
        }

        return \@words;
    }

    sub get_quoted_string {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        /\G(?=\s)/ && $self->parse_whitespace(code => $opt{code});

        my $delim;
        if (/\G(?=(.))/) {
            $delim = $1;
            if ($delim eq '\\' && /\G\\(.*?)\\/gsc) {
                return $1;
            }
        }
        else {
            $self->fatal_error(
                               error => qq{nu pot găsi punctul unde începe delimitarea},
                               code  => $_,
                               pos   => pos($_),
                              );
        }

        my $beg_delim = quotemeta $delim;
        my $pair_delim = exists($self->{delim_pairs}{$delim}) ? $self->{delim_pairs}{$delim} : ();

        my $string = '';
        if (defined $pair_delim) {
            my $end_delim = quotemeta $pair_delim;
            my $re_delim  = $beg_delim . $end_delim;
            if (m{\G(?<main>$beg_delim((?>[^$re_delim\\]+|\\.|(?&main))*+)$end_delim)}sgc) {
                $string = $2 =~ s/\\([$re_delim])/$1/gr;
            }
        }
        elsif (m{\G$beg_delim([^\\$beg_delim]*+(?>\\.[^\\$beg_delim]*)*)}sgc) {
            $string = $1 =~ s/\\([$beg_delim])/$1/gr;
        }

        (defined($pair_delim) ? /\G(?<=\Q$pair_delim\E)/ : /\G$beg_delim/gc)
          || $self->fatal_error(
                                error => sprintf(qq{nu pot găsi delimitatorul final: <%s>}, $pair_delim // $delim),
                                code  => $_,
                                pos   => pos($_)
                               );

        $self->{line} += $string =~ s/\R\K//g if not $opt{no_count_line};
        return $string;
    }

    ## get_method_name() returns the following values:
    # 1st: method/operator (or undef)
    # 2nd: does operator require and argument (0 or 1)
    # 3rd: type of operator (e.g.: »+« is "uop", [+] is "rop")
    sub get_method_name {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        # Parse whitespace
        $self->parse_whitespace(code => $opt{code});

        # Alpha-numeric method name
        if (/\G($self->{method_name_re})/goc) {
            return ($1, 0, '');
        }

        # Operator-like method name
        if (m{\G$self->{operators_re}}goc) {
            my ($key) = keys(%+);
            return (
                    $+,
                    (
                     exists($self->{hyper_ops}{$key})
                     ? $self->{hyper_ops}{$key}[0]
                     : not(exists $self->{postfix_ops}{$+})
                    ),
                    $key
                   );
        }

        # Method name as expression
        my ($obj) = $self->parse_expr(code => $opt{code});
        return ({self => $obj // return}, 0, '');
    }

    sub parse_delim {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        my @delims = ('|', keys(%{$self->{delim_pairs}}));
        if (exists $opt{ignore_delim}) {
            @delims = grep { not exists $opt{ignore_delim}{$_} } @delims;
        }

        my $regex = do {
            local $" = "";
            qr/\G([@delims])\h*/;
        };

        my $end_delim;
        if (/$regex/gc) {
            $end_delim = $self->{delim_pairs}{$1} // $1;
            $self->parse_whitespace(code => $opt{code});
        }

        return $end_delim;
    }

    sub get_init_vars {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        my $end_delim = $self->parse_delim(%opt);

        my @vars;
        my %classes;

        while (/\G(?<type>$self->{var_name_re}\h+$self->{var_name_re})/goc || /\G([*:]?$self->{var_name_re})/goc) {
            push @vars, $1;

            if ($opt{with_vals} && defined($end_delim)) {

                # Add the variables into the symbol table
                my ($name, $class_name) = $self->get_name_and_class($vars[-1]);

                undef $classes{$class_name};
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => '',
                    name  => $name,
                    count => 0,
                    type  => $opt{type},
                    line  => $self->{line},
                  };

                if (/$self->{var_init_sep_re}/goc) {
                    my $code = substr($_, pos);
                    $self->parse_obj(code => \$code);
                    $vars[-1] .= '=' . substr($_, pos($_), pos($code));
                    pos($_) += pos($code);
                }
            }

            defined($end_delim) && (/\G\h*,\h*/gc || last);
            $self->parse_whitespace(code => $opt{code});
        }

        # Remove the newly added variables
        foreach my $class_name (keys %classes) {
            for (my $i = 0 ; $i <= $#{$self->{vars}{$class_name}} ; $i++) {
                if (ref($self->{vars}{$class_name}[$i]) eq 'HASH' and not ref($self->{vars}{$class_name}[$i]{obj})) {
                    splice(@{$self->{vars}{$class_name}}, $i--, 1);
                }
            }
        }

        $self->parse_whitespace(code => $opt{code});

        defined($end_delim)
          && (
              /\G\h*\Q$end_delim\E/gc
              || $self->fatal_error(
                                    code  => $_,
                                    pos   => pos,
                                    error => "nu pot găsi delimitatorul final: '$end_delim'",
                                   )
             );

        return \@vars;
    }

    sub parse_init_vars {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        my $end_delim = $self->parse_delim(%opt);

        my @var_objs;
        while (/\G(?<type>$self->{var_name_re})\h+($self->{var_name_re})/goc || /\G([*:]?)($self->{var_name_re})/goc) {
            my ($attr, $name) = ($1, $2);

            my $ref_type;
            if (defined($+{type})) {
                my $type = $+{type};

                my $obj = do {
                    local $self->{_want_name} = 1;
                    $self->parse_expr(code => \$type);
                };

                if (not defined($obj) or ref($obj) eq 'HASH') {
                    $self->fatal_error(
                                       code     => $_,
                                       pos      => pos,
                                       error    => "invalid type <<$type>> for variable '$name'",
                                       expected => "expected a type, such as: Str, Num, File, etc...",
                                      );
                }

                $ref_type = $obj;
            }

            my $class_name;
            ($name, $class_name) = $self->get_name_and_class($name);

            if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                $self->fatal_error(
                    code => $_,
                    pos  => $-[2],
                    error =>
"'$name' nu poate fi folosit în acest context pentru că este un cuvânt cheie sau o variabilă predefinită!",
                );
            }

            my $value;
            if (defined($end_delim) && /$self->{var_init_sep_re}/goc) {
                my $obj = $self->parse_obj(code => $opt{code});
                $value = (
                          ref($obj) eq 'HASH'
                          ? $obj
                          : {$self->{class} => [{self => $obj}]}
                         );
            }

            my $obj = Corvinus::Variable::Variable->new(
                                                        name => $name,
                                                        type => $opt{type},
                                                        (defined($ref_type) ? (ref_type => $ref_type) : ()),
                                                        class => $class_name,
                                                        defined($value) ? (value => $value, has_value => 1) : (),
                                                        $attr eq '*' ? (array => 1) : $attr eq ':' ? (hash => 1) : (),
                                                        $opt{in_use} ? (in_use => 1) : (),
                                                       );

            if (!$opt{private}) {
                unshift @{$self->{vars}{$class_name}},
                  {
                    obj   => $obj,
                    name  => $name,
                    count => 0,
                    type  => $opt{type},
                    line  => $self->{line},
                  };
            }

            push @var_objs, $obj;
            defined($end_delim) && (/\G\h*,\h*/gc || last);
            $self->parse_whitespace(code => $opt{code});
        }

        $self->parse_whitespace(code => $opt{code});

        defined($end_delim)
          && (
              /\G\h*\Q$end_delim\E/gc
              || $self->fatal_error(
                                    code  => $_,
                                    pos   => pos,
                                    error => "nu pot găsi delimitatorul final: '$end_delim'",
                                   )
             );

        return \@var_objs;
    }

    sub parse_whitespace {
        my ($self, %opt) = @_;

        my $beg_line    = $self->{line};
        my $found_space = -1;
        local *_ = $opt{code};
        {
            ++$found_space;

            # Whitespace
            if (/\G(?=\s)/) {

                # Horizontal space
                if (/\G\h+/gc) {
                    redo;
                }

                # Generic line
                if (/\G\R/gc) {
                    ++$self->{line};

                    # Here-document
                    while ($#{$self->{EOT}} != -1) {
                        my ($name, $type, $obj) = @{shift @{$self->{EOT}}};

                        my ($indent, $spaces);
                        if (chr ord $name eq '-') {
                            $name = substr($name, 1);
                            $indent = 1;
                        }

                        my $acc = '';
                        until (/\G$name(?:\R|\z)/gc) {

                            if (/\G(.*)/gc) {
                                $acc .= "$1\n";
                            }

                            # Indentation is true
                            if ($indent && /\G\R(\h+)$name(?:\R|\z)/gc) {
                                ++$self->{line};
                                $spaces = length($1);
                                last;
                            }

                            /\G\R/gc
                              ? ++$self->{line}
                              : die sprintf(qq{%s:%s: nu pot gasi textul terminator "%s" niciunde în fișier.\n},
                                            $self->{file_name}, $beg_line, $name);
                        }

                        if ($indent) {
                            $acc =~ s/^\h{1,$spaces}//gm;
                        }

                        ++$self->{line};
                        push @{$obj->{$self->{class}}},
                          {
                              self => $type == 0
                            ? Corvinus::Types::String::String->new($acc)
                            : Corvinus::Types::String::String->new($acc)->apply_escapes($self)
                          };
                    }

                    /\G\h+/gc;
                    redo;
                }

                # Vertical space
                if (/\G\v+/gc) {    # should not reach here
                    redo;
                }
            }

            # Embedded comments (http://perlcabal.org/syn/S02.html#Embedded_Comments)
            if (/\G#`(?=[[:punct:]])/gc) {
                $self->get_quoted_string(code => $opt{code});
                redo;
            }

            # One-line comment
            if (/\G#.*/gc) {
                redo;
            }

            # Multi-line C comment
            if (m{\G/\*}gc) {
                while (1) {
                    m{\G.*?\*/}gc && last;
                    /\G.+/gc || (/\G\R/gc ? $self->{line}++ : last);
                }
                redo;
            }

            if ($found_space > 0) {
                return 1;
            }

            return;
        }
    }

    sub parse_expr {
        my ($self, %opt) = @_;

        local *_ = $opt{code};
        {
            $self->parse_whitespace(code => $opt{code});

            # End of an expression, or end of the script
            if (/\G;/gc || /\G\z/) {
                return;
            }

            if (/$self->{quote_operators_re}/goc) {
                my ($double_quoted, $method, $package) = @{$^R};

                pos($_) -= 1;
                my ($string, $pos) = $self->get_quoted_string(code => $opt{code});

                # Special case for array-like objects (bytes and chars)
                my @array_like;
                if ($method ne 'new' and $method ne '__NEW__') {
                    @array_like = ($package, $method);
                    $package    = 'Corvinus::Types::String::String';
                    $method     = 'new';
                }

                my $obj = (
                    $double_quoted
                    ? do {
                        state $str = Corvinus::Types::String::String->new;    # load the string module
                        Corvinus::Types::String::String::apply_escapes($package->$method($string), $self);
                      }
                    : $package->$method($string =~ s{\\\\}{\\}gr)
                );

                # Special case for backticks (add method 'exec')
                if ($package eq 'Corvinus::Types::Glob::Backtick') {
                    my $struct =
                        $double_quoted && ref($obj) eq 'HASH'
                      ? $obj
                      : {
                         $self->{class} => [
                                            {
                                             self => $obj,
                                             call => [],
                                            }
                                           ]
                        };

                    push @{$struct->{$self->{class}}[-1]{call}}, {method => 'exec'};
                    $obj = $struct;
                }
                elsif (@array_like) {
                    if ($double_quoted and ref($obj) eq 'HASH') {
                        push @{$obj->{$self->{class}}[-1]{call}}, {method => $array_like[1]};
                    }
                    else {
                        $obj = $array_like[0]->call($obj);
                    }
                }

                return $obj;
            }

            # Object as expression
            if (/\G(?=\()/) {
                my $obj = $self->parse_arguments(code => $opt{code});
                return $obj;
            }

            # Block as object
            if (/\G(?=\{)/) {
                my $obj = $self->parse_block(code => $opt{code});
                return $obj;
            }

            # Array as object
            if (/\G(?=\[)/) {

                my $array = Corvinus::Types::Array::HCArray->new();
                my $obj = $self->parse_array(code => $opt{code});

                if (ref $obj->{$self->{class}} eq 'ARRAY') {
                    push @{$array}, (@{$obj->{$self->{class}}});
                }

                return $array;
            }

            # Bareword followed by a fat comma or preceded by a colon
            if (   /\G:([_\pL\pN]+)/gc
                || /\G([_\pL][_\pL\pN]*)(?=\h*=>)/gc) {

                # || /\G([_\pL][_\pL\pN]*)(?=\h*=>|:(?![=:]))/gc) {
                return Corvinus::Types::String::String->new($1);
            }

            if (/\G([_\pL][_\pL\pN]*):(?![=:])/gc) {
                my $name = $1;
                my $obj = (
                           /\G\s*(?=\()/gc
                           ? $self->parse_arguments(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );
                return Corvinus::Variable::NamedParam->new($name, $obj);
            }

            # Declaration of variable types
            if (/\Gvar\b\h*/gc) {
                my $type = 'var';
                my $vars = $self->parse_init_vars(code => $opt{code}, type => $type);

                $vars // $self->fatal_error(
                                            code  => $_,
                                            pos   => pos,
                                            error => "expected a variable name after the keyword '$type'!",
                                           );

                my $init_obj = Corvinus::Variable::Init->new(vars => $vars);

                if (/\G\h*=\h*/gc) {
                    my $args = (
                                /\G\s*(?=\()/gc
                                ? $self->parse_arguments(code => $opt{code})
                                : $self->parse_obj(code => $opt{code})
                      ) // $self->fatal_error(
                                              code  => $_,
                                              pos   => pos,
                                              error => "expected an expression after variable declaration",
                                             );

                    $init_obj->{args} = $args;
                }

                return $init_obj;
            }

            # Declaration of constants and static variables
            if (/\G(define|const|static)\b\h*/gc) {
                my $type = $1;
                my $vars = $self->parse_init_vars(code => $opt{code}, type => $type, private => 1);

                foreach my $var (@{$vars}) {
                    my $name = $var->{name};
                    if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                        $self->fatal_error(
                            code => $_,
                            pos  => (pos($_) - length($name)),
                            error =>
"'$name' nu poate fi folosit în acest context pentru că este un cuvânt cheie sau o variabilă predefinită!",
                        );
                    }
                }

                if (@{$vars} == 1 and /\G\h*=\h*/gc) {

                    my $v          = $vars->[0];
                    my $name       = $v->{name};
                    my $class_name = $v->{class};

                    my $obj = $self->parse_obj(code => $opt{code});
                    $obj // $self->fatal_error(
                                     code  => $_,
                                     pos   => pos,
                                     error => qq{este necesară o expresie care să poată fi evaluată pentru numele "$name"},
                    );

                    my $var =
                      $type eq 'define'
                      ? Corvinus::Variable::Define->new(init => 1, name => $name, class => $class_name, expr => $obj)
                      : $type eq 'static'
                      ? Corvinus::Variable::Static->new(init => 1, name => $name, class => $class_name, expr => $obj)
                      : $type eq 'const'
                      ? Corvinus::Variable::Const->new(init => 1, name => $name, class => $class_name, expr => $obj)
                      : die "[PARSER ERROR] Invalid variable type: $type";

                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $var,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                    return $var;
                }

                my @var_objs;
                foreach my $v (@{$vars}) {

                    my $obj        = $v->{value};
                    my $name       = $v->{name};
                    my $class_name = $v->{class};

                    my $var =
                        $type eq 'define' ? Corvinus::Variable::Define->new(name => $name, class => $class_name, expr => $obj)
                      : $type eq 'static' ? Corvinus::Variable::Static->new(name => $name, class => $class_name, expr => $obj)
                      : $type eq 'const' ? Corvinus::Variable::Const->new(name => $name, class => $class_name, expr => $obj)
                      :                    die "[PARSER ERROR] Invalid variable type: $type";

                    push @var_objs, $var;

                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $var,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };

                }

                return Corvinus::Variable::ConstInit->new(vars => \@var_objs);
            }

            # Struct declaration
            if (/\Gstruct\b\h*/gc) {

                my ($name, $class_name);
                if (/\G($self->{var_name_re})\h*/goc) {
                    ($name, $class_name) = $self->get_name_and_class($1);
                }

                if (defined($name) and (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name}))) {
                    $self->fatal_error(
                        code => $_,
                        pos  => (pos($_) - length($name)),
                        error =>
"'$name' nu poate fi folosit în acest context pentru că este un cuvânt cheie sau o variabilă predefinită!",
                    );
                }

                my $vars =
                  $self->parse_init_vars(
                                         code      => $opt{code},
                                         with_vals => 1,
                                         private   => 1,
                                         type      => 'var',
                                        );

                my $struct = Corvinus::Variable::Struct->new(
                                                             name  => $name,
                                                             class => $class_name,
                                                             vars  => $vars,
                                                            );

                if (defined $name) {
                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $struct,
                        name  => $name,
                        count => 0,
                        type  => 'struct',
                        line  => $self->{line},
                      };
                }

                return $struct;
            }

            # Declaration of enums
            if (/\Genum\b\h*/gc) {
                my $vars =
                  $self->parse_init_vars(
                                         code      => $opt{code},
                                         with_vals => 1,
                                         private   => 1,
                                         type      => 'var',
                                        );

                @{$vars}
                  || $self->fatal_error(
                    code => $_,
                    pos  => pos,
                    error =>
q{este necesară specificarea a unuia sau mai multor identificatori după cuvântul cheie „enumera”, urmând sintaxa: „enumera(a, b, c, ...)”},
                  );

                my $value = Corvinus::Types::Number::Number->new(-1);

                foreach my $var (@{$vars}) {
                    my $name = $var->{name};

                    if (ref $var->{value} eq 'HASH') {
                        $var->{value} = $var->{value}{$self->{class}}[-1]{self};
                    }

                    $value =
                        $var->{has_value}
                      ? $var->{value}
                      : $value->inc;

                    if (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name})) {
                        $self->fatal_error(
                            code => $_,
                            pos  => (pos($_) - length($name)),
                            error =>
"'$name' nu poate fi folosit în acest context pentru că este un cuvânt cheie sau o variabilă predefinită!",
                        );
                    }

                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $value,
                        name  => $name,
                        count => 0,
                        type  => 'enum',
                        line  => $self->{line},
                      };
                }

                return $value;
            }

            if (/\G\@(?!:)/gc) {
                my $pos = pos($_);
                my $obj = (
                           /\G(?=\()/
                           ? $self->parse_arguments(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );

                if (not defined $obj) {
                    $self->fatal_error(
                                       code  => $_,
                                       pos   => $pos,
                                       error => "expected an expression after unary operator: '\@'",
                                      );
                }

                return {$self->{class} => [{self => $obj, call => [{method => '@*'}]}]};
            }

            # Local variables
            if (/\Glocal\b\h*/gc) {
                my $expr = $self->parse_obj(code => $opt{code});
                return Corvinus::Variable::Local->new(expr => $expr);
            }

            # Declaration of local variables, classes, methods and functions
            if (
                   /\G(func|clas[sa]|global)\b\h*/gc
                || /\G(->)\h*/gc
                || (exists($self->{current_class})
                    && /\G(method|metoda)\b\h*/gc)
              ) {

                my $beg_pos = $-[0];
                my $type =
                    $1 eq '->'
                  ? exists($self->{current_class}) && !(exists($self->{current_method}))
                      ? 'method'
                      : 'func'
                  : $1;

                state $trans = {
                                clasa  => 'class',
                                metoda => 'method',
                               };

                if (exists $trans->{$type}) {
                    $type = $trans->{$type};
                }

                my $name       = '';
                my $class_name = $self->{class};
                my $built_in_obj;
                if ($type eq 'class' and /\G(?![{(])/) {

                    my $try_expr;
                    if (/\G($self->{var_name_re})\h*/gco) {
                        ($name, $class_name) = $self->get_name_and_class($1);
                    }
                    else {
                        $try_expr = 1;
                    }

                    if (
                        $try_expr or exists($self->{built_in_classes}{$name}) or do {
                            my $obj = $self->find_var($name, $class_name);
                            defined($obj) and $obj->{type} eq 'class';
                        }
                      ) {

                        local $self->{_want_name} = 1;
                        my ($obj) = $self->parse_expr(code => $try_expr ? $opt{code} : \$name);

                        if (ref($obj) eq 'HASH') {
                            $self->fatal_error(
                                               error => "can't use an expression inside class declaration",
                                               code  => $_,
                                               pos   => pos($_),
                                              );
                        }

                        $built_in_obj = $obj;

                        if (defined $built_in_obj) {
                            $name = '';
                        }
                    }
                }

                if ($type ne 'class') {
                    $name = (
                               /\G($self->{var_name_re})\h*/goc ? $1
                             : $type eq 'method' && /\G($self->{operators_re})\h*/goc ? $+
                             :                                                          ''
                            );
                    ($name, $class_name) = $self->get_name_and_class($name);
                }

                local $self->{class} = $class_name;

                if (    $type ne 'method'
                    and $type ne 'class'
                    and (exists($self->{keywords}{$name}) or exists($self->{built_in_classes}{$name}))) {
                    $self->fatal_error(
                        code => $_,
                        pos  => $-[0],
                        error =>
"'$name' nu poate fi folosit în acest context pentru că este un cuvânt cheie sau o variabilă predefinită!",
                    );
                }

                my $obj =
                    $type eq 'func'   ? Corvinus::Variable::Variable->new(name => $name, type => $type, class => $class_name)
                  : $type eq 'method' ? Corvinus::Variable::Variable->new(name => $name, type => $type, class => $class_name)
                  : $type eq 'class'
                  ? Corvinus::Variable::ClassInit->new(name => ($built_in_obj // $name), class => $class_name)
                  : $type eq 'global' ? Corvinus::Variable::Global->new(name => $name, class => $class_name)
                  : $self->fatal_error(
                                       error    => "invalid type",
                                       expected => "expected a magic thing to happen",
                                       code     => $_,
                                       pos      => pos($_),
                                      );

                my $private = 0;
                if (($type eq 'method' or $type eq 'func') and $name ne '') {
                    my $var = $self->find_var($name, $class_name);

                    # Redeclaration of a function or a method in the same scope
                    if (defined $var) {

                        if ($var->{obj}{type} ne $type) {
                            $self->fatal_error(
                                code => $_,
                                pos  => $-[0],
                                error =>
"redeclarare invalidă ca funcție sau metodă a identificatorului '$var->{obj}{name}' (declarat inițial la linia $var->{line})",
                            );
                        }

                        push @{$var->{obj}{value}{kids}}, $obj;
                        $private = 1;
                    }
                }

                if (not $private) {
                    unshift @{$self->{vars}{$class_name}},
                      {
                        obj   => $obj,
                        name  => $name,
                        count => 0,
                        type  => $type,
                        line  => $self->{line},
                      };
                }

                if ($type eq 'global') {
                    return $obj;
                }

                if ($type eq 'class') {
                    my $var_names =
                      $self->parse_init_vars(
                                             code         => $opt{code},
                                             with_vals    => 1,
                                             private      => 1,
                                             in_use       => 1,
                                             type         => 'var',
                                             ignore_delim => {
                                                              '{' => 1,
                                                              '<' => 1,
                                                             },
                                            );

                    $obj->set_params($var_names);

                    # Class inheritance (class Name(...) << Name1, Name2)
                    if (/\G\h*<<?\h*/gc) {
                        while (/\G($self->{var_name_re})\h*/gco) {
                            my ($name) = $1;
                            if (defined(my $class = $self->find_var($name, $class_name))) {
                                if ($class->{type} eq 'class') {
                                    push @{$obj->{inherit}}, $class->{obj};
                                }
                                else {
                                    $self->fatal_error(
                                                       error    => "this is not a class",
                                                       expected => "expected a class name",
                                                       code     => $_,
                                                       pos      => pos($_) - length($name) - 1,
                                                      );
                                }
                            }
                            elsif (exists $self->{built_in_classes}{$name}) {
                                if ($name ne 'Corvinus') {
                                    my $ref = $self->parse_expr(code => \$name);
                                    push @{$obj->{inherit}}, ref($ref);
                                }
                            }
                            else {
                                $self->fatal_error(
                                                   error    => "can't find '$name' class",
                                                   expected => "expected an existent class name",
                                                   code     => $_,
                                                   pos      => pos($_) - length($name) - 1,
                                                  );
                            }

                            /\G,\h*/gc;
                        }
                    }

                    /\G\h*(?=\{)/gc
                      || $self->fatal_error(
                                            error    => "invalid class declaration",
                                            expected => "expected: class $name(...){...}",
                                            code     => $_,
                                            pos      => pos($_)
                                           );

                    if (ref($built_in_obj) eq 'Corvinus::Variable::ClassInit') {
                        $obj->{name} = $built_in_obj->{name};
                    }

                    local $self->{class_name} = (defined($built_in_obj) ? ref($built_in_obj) : $obj->{name});
                    local $self->{current_class} = $built_in_obj // $obj;
                    my $block = $self->parse_block(code => $opt{code});

                    $obj->set_block($block);
                }

                if ($type eq 'func' or $type eq 'method') {

                    my $var_names =
                      $self->get_init_vars(
                                           code         => $opt{code},
                                           with_vals    => 1,
                                           ignore_delim => {
                                                            '{' => 1,
                                                            '-' => 1,
                                                           }
                                          );

                    # Functions and method traits (example: "is cached")
                    if (/\G\h*(?:is|e)\h+(?=\w)/gc) {

                        state $trans = {
                                        memorat  => 'cached',
                                        memorata => 'cached',
                                       };

                        while (/\G(\w+)/gc) {
                            my $trait = $1;

                            if (exists $trans->{$trait}) {
                                $trait = $trans->{$trait};
                            }

                            if ($trait eq 'cached') {
                                $obj->{cached} = 1;
                            }

                            #elsif ($type eq 'method' and $trait eq 'exported') {
                            #    $obj->{exported} = 1;
                            #}
                            else {
                                $self->fatal_error(
                                                   error => "Unknown $type trait: $trait",
                                                   code  => $_,
                                                   pos   => pos($_),
                                                  );
                            }

                            /\G\h*,\h*/gc || last;
                        }
                    }

                    # Function return type (func name(...) -> Type {...})
                    if (/\G\h*->\h*/gc) {

                        my $ret_name;
                        my $try_expr;
                        my $pos = pos($_);
                        if (/\G($self->{var_name_re})\h*/gco) {
                            $ret_name = $1;
                        }
                        else {
                            $try_expr = 1;
                        }

                        if (
                            $try_expr or (
                                defined($ret_name) and (
                                    exists($self->{built_in_classes}{$ret_name}) or do {
                                        my $obj = $self->find_var($ret_name, $class_name);
                                        defined($obj) and $obj->{type} eq 'class';
                                    }
                                )
                            )
                          ) {
                            local $self->{_want_name} = 1;
                            my ($return_obj) = $self->parse_expr(code => $try_expr ? $opt{code} : \$ret_name);

                            if (ref($return_obj) eq 'HASH') {
                                $self->fatal_error(
                                                   error    => "invalid return-type for $type $self->{class_name}<<$name>>",
                                                   expected => "expected a valid type, such as: Str, Num, Arr, etc...",
                                                   code     => $_,
                                                   pos      => $pos,
                                                  );
                            }

                            $obj->{returns} = $return_obj;
                        }
                        else {
                            $self->fatal_error(
                                               error    => "tip invalid de returnare specificat pentru funcția '$name'",
                                               expected => "exemplu de tipuri valide: Text, Numar, Lista, etc...",
                                               code     => $_,
                                               pos      => $pos,
                                              );
                        }
                    }

                    /\G\h*\{\h*/gc
                      || $self->fatal_error(
                                            error    => "declarare invalidă pentru '$type'",
                                            expected => "sintaxa este: „$type $name(...){...}”",
                                            code     => $_,
                                            pos      => pos($_)
                                           );

                    local $self->{$type eq 'func' ? 'current_function' : 'current_method'} = $obj;
                    my $args = '|' . join(',', $type eq 'method' ? 'self' : (), @{$var_names}) . ' |';

                    my $code = '{' . $args . substr($_, pos);
                    my $block = $self->parse_block(code => \$code);
                    pos($_) += pos($code) - length($args) - 1;

                    $obj->{value} = $block;

                    #if (not $private) {
                    #    $self->{current_class}->add_method($name, $block) if $type eq 'method';
                    #}
                }

                return $obj;
            }

            # "default {...}" construct
            if (/\G(?:default|altfel)\h*(?=\{)/gc) {
                my $block = $self->parse_block(code => $opt{code});
                return Corvinus::Types::Block::Default->new(block => $block);
            }

            ## Experimental gather/take
            if (/\G(?:gather|colect(?:eaza)?+)\h*(?=\{)/gc) {
                my $obj = Corvinus::Types::Block::Gather->new();

                local $self->{current_gather} = $obj;

                my $block = $self->parse_block(code => $opt{code});
                $obj->{block} = $block;

                return $obj;
            }

            if (exists($self->{current_gather}) and /\G(?:take|ia)\b\h*/gc) {

                my $obj = (
                           /\G(?=\()/
                           ? $self->parse_arguments(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );

                return Corvinus::Types::Block::Take->new(expr => $obj, gather => $self->{current_gather});
            }

            # Binary, hexdecimal and octal numbers
            if (/\G0(b[10_]*|x[0-9A-Fa-f_]*|[0-9_]+\b)/gc) {
                my $number = "0" . ($1 =~ tr/_//dr);
                return
                  Corvinus::Types::Number::Number->new(
                                                       $number =~ /^0[0-9]/
                                                       ? Math::BigInt->from_oct($number)
                                                       : Math::BigInt->new($number)
                                                      );
            }

            # Integer or float number
            if (/\G([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)/gc) {
                return Corvinus::Types::Number::Number->new($1 =~ tr/_//dr);
            }

            # Implicit method call on special variable: _
            if (/\G\./) {

                if (defined(my $var = $self->find_var('_', $self->{class}))) {
                    $var->{count}++;
                    ref($var->{obj}) eq 'Corvinus::Variable::Variable' && do {
                        $var->{obj}{in_use} = 1;
                    };
                    return $var->{obj};
                }

                $self->fatal_error(
                                   code  => $_,
                                   pos   => pos($_),
                                   error => "variabila „_” nu poate fi găsită în scopul curent",
                                  );
            }

            # Quoted words or numbers (%w/a b c/)
            if (/\G%([wWin])\b/gc || /\G(?=(«|<(?!<)))/) {
                my ($type) = $1;
                my $strings = $self->get_quoted_words(code => $opt{code});

                if ($type eq 'w' or $type eq '<') {
                    return Corvinus::Types::Array::HCArray->new(
                                               map { Corvinus::Types::String::String->new(s{\\(?=[\\#\s])}{}gr) } @{$strings});
                }
                elsif ($type eq 'i') {
                    return Corvinus::Types::Array::HCArray->new(
                        map {
                            Corvinus::Types::Number::Number->new(Math::BigInt->new(s{\\(?=[\\#\s])}{}gr))
                          } @{$strings}
                    );
                }
                elsif ($type eq 'n') {
                    return Corvinus::Types::Array::HCArray->new(
                                               map { Corvinus::Types::Number::Number->new(s{\\(?=[\\#\s])}{}gr) } @{$strings});
                }

                my ($inline_expression, @objs);
                foreach my $item (@{$strings}) {
                    my $str = Corvinus::Types::String::String->new($item)->apply_escapes($self);
                    if (!$inline_expression and ref $str eq 'HASH') {
                        $inline_expression = 1;
                    }
                    push @objs, $str;
                }

                return (
                        $inline_expression
                        ? Corvinus::Types::Array::HCArray->new(map { {self => $_} } @objs)
                        : Corvinus::Types::Array::HCArray->new(@objs)
                       );
            }

            if (/$self->{prefix_obj_re}/goc) {
                pos($_) = $-[0];
                return ($^R, 1);
            }

            # Eval keyword
            if (/\Geval\b\h*/gc) {
                my $obj = (
                           /\G(?=\()/
                           ? $self->parse_arguments(code => $opt{code})
                           : $self->parse_obj(code => $opt{code})
                          );

                return
                  Corvinus::Eval::Eval->new(
                                            expr          => $obj,
                                            vars          => {$self->{class} => [@{$self->{vars}{$self->{class}}}]},
                                            ref_vars_refs => {$self->{class} => [@{$self->{ref_vars_refs}{$self->{class}}}]},
                                           );
            }

            #if (/\G(?:die|warn|assert(?:_(?:eq|ne))?)\b/gc) {
            if (/\Gassert(?:_(?:eq|ne))?\b/gc) {
                pos($_) = $-[0];
                return (Corvinus::Sys::Sys->new(line => $self->{line}, file_name => $self->{file_name}), 1);
            }

            if (/\GParser\b/gc) {
                return $self;
            }

            # Regular expression
            if (m{\G(?=/)} || /\G%r\b/gc) {
                my $string = $self->get_quoted_string(code => $opt{code});
                return Corvinus::Types::Regex::Regex->new($string, /\G($self->{match_flags_re})/goc ? $1 : undef);
            }

            # Static object (like String or nil)
            if (/$self->{static_obj_re}/goc) {
                return $^R;
            }

            if (/\G__MAIN__\b/gc) {
                return Corvinus::Types::String::String->new($self->{script_name});
            }

            if (/\G__FILE__\b/gc) {
                return Corvinus::Types::String::String->new($self->{file_name});
            }

            if (/\G__DATE__\b/gc) {
                my (undef, undef, undef, $day, $mon, $year) = localtime;
                return Corvinus::Types::String::String->new(
                                                           join('-', $year + 1900, map { sprintf "%02d", $_ } $mon + 1, $day));
            }

            if (/\G__TIME__\b/gc) {
                my ($sec, $min, $hour) = localtime;
                return Corvinus::Types::String::String->new(join(':', map { sprintf "%02d", $_ } $hour, $min, $sec));
            }

            if (/\G__LINE__\b/gc) {
                return Corvinus::Types::Number::Number->new($self->{line});
            }

            if (/\G__(?:END|DATA)__\b\h*+\R?/gc) {
                if (exists $self->{'__DATA__'}) {
                    $self->{'__DATA__'} = substr($_, pos);
                }
                pos($_) = length($_);
                return;
            }

            if (/\GDATA\b/gc) {
                return (
                    $self->{static_objects}{'__DATA__'} //= do {
                        open my $str_fh, '<:raw', \$self->{'__DATA__'};
                        Corvinus::Types::Glob::FileHandle->new(fh   => $str_fh,
                                                               self => Corvinus::Types::Glob::File->new($self->{file_name}));
                      }
                );
            }

            # Beginning of a here-document (<<"EOT", <<'EOT', <<EOT)
            if (/\G<<(?=\S)/gc) {
                my ($name, $type) = (undef, 1);

                if (/\G(?=(['"„]))/) {
                    $type = 0 if $1 eq q{'};
                    my $str = $self->get_quoted_string(code => $opt{code});
                    $name = $str;
                }
                elsif (/\G(-?[_\pL\pN]+)/gc) {
                    $name = $1;
                }
                else {
                    $self->fatal_error(
                                       error    => "invalid 'here-doc' declaration",
                                       expected => "expected an alpha-numeric token after '<<'",
                                       code     => $_,
                                       pos      => pos($_)
                                      );
                }

                my $obj = {$self->{class} => []};
                push @{$self->{EOT}}, [$name, $type, $obj];

                return $obj;
            }

            if (exists($self->{current_block}) && /\G__BLOCK__\b/gc) {
                return $self->{current_block};
            }

            if (/\G__NAMESPACE__\b/gc) {
                return Corvinus::Types::String::String->new($self->{class});
            }

            if (exists($self->{current_function})) {
                /\G__FUNC(?:TIE)?+__\b/gc && return $self->{current_function};
                /\G__(?:FUNC_NAME|NUME_FUNC(?:TIE)?+)__\b/gc
                  && return Corvinus::Types::String::String->new($self->{current_function}{name});
            }

            if (exists($self->{current_class})) {
                /\G__CLAS[SA]__\b/gc && return $self->{current_class};
                /\G__(?:CLASS_NAME|NUME_CLASA)__\b/gc && return Corvinus::Types::String::String->new($self->{class_name});
            }

            if (exists($self->{current_method})) {
                /\G__(?:METHOD|METODA)__\b/gc && return $self->{current_method};
                /\G__(?:METHOD_NAME|NUME_METODA)__\b/gc
                  && return Corvinus::Types::String::String->new($self->{current_method}{name});
            }

            # Variable call
            if (/\G($self->{var_name_re})/goc) {
                my ($name, $class) = $self->get_name_and_class($1);

                if (defined(my $var = $self->find_var($name, $class))) {
                    $var->{count}++;
                    ref($var->{obj}) eq 'Corvinus::Variable::Variable' && do {
                        $var->{obj}{in_use} = 1;
                    };
                    return $var->{obj};
                }

                if ($name eq 'ARGV' or $name eq 'ENV') {

                    my $type = 'var';
                    my $variable =
                      Corvinus::Variable::Variable->new(name => $name, type => $type, class => $class, in_use => 1);

                    unshift @{$self->{vars}{$class}},
                      {
                        obj   => $variable,
                        name  => $name,
                        count => 1,
                        type  => $type,
                        line  => $self->{line},
                      };

                    return $variable;
                }

                # Class instance variables
                state $x = require List::Util;
                if (ref($self->{current_class}) eq 'Corvinus::Variable::ClassInit'
                    and defined(my $var = List::Util::first(sub { $_->{name} eq $name }, @{$self->{current_class}{vars}},))) {
                    if (exists $self->{current_method}) {
                        if (defined(my $var = $self->find_var('self', $class))) {
                            $var->{count}++;
                            $var->{obj}{in_use} = 1;
                            return
                              scalar {
                                      $self->{class} => [
                                                         {
                                                          self   => $var->{obj},
                                                          lookup => [[$name]],
                                                         }
                                                        ]
                                     };
                        }
                    }
                    else {
                        return $var;
                    }
                }

                if (/\G(?=\h*:?=(?![=~>]))/) {

                    my $var = Corvinus::Variable::Global->new(name => $name, class => $class);

                    if (not $self->{interactive}) {
                        warn "[WARN] Implicit declaration of global variable '$name', at line $self->{line}\n";
                    }

                    unshift @{$self->{vars}{$class}},
                      {
                        obj   => $var,
                        name  => $name,
                        count => 0,
                        type  => 'global',
                        line  => $self->{line},
                      };

                    return $var;
                }

                # Type constant
                my $obj;
                if (
                        not $self->{_want_name}
                    and $class ne $self->{class}
                    and defined(
                        eval {
                            local $self->{_want_name} = 1;
                            my $code = $class;
                            ($obj) = $self->parse_expr(code => \$code);
                            $obj;
                        }
                    )
                  ) {
                    return
                      Corvinus::Variable::Static->new(
                                                      name => '__CONST__',
                                                      expr => {
                                                               $self->{class} => [
                                                                     {
                                                                      self => $obj,
                                                                      call => [
                                                                          {
                                                                           method => 'get_constant',
                                                                           arg => [Corvinus::Types::String::String->new($name)]
                                                                          }
                                                                      ]
                                                                     }
                                                               ]
                                                              }
                                                     );
                }

                # Method call in functional style
                if (not $self->{_want_name} and ($class eq $self->{class} or $class eq 'CORE')) {

                    my $pos = pos($_);
                    /\G\h*/gc;    # remove any horizontal whitespace
                    my $arg = (
                                 /\G(?=\()/ ? $self->parse_arguments(code => $opt{code})
                               : /\G(?=\{)/ ? $self->parse_block(code => $opt{code})
                               :              $self->parse_obj(code => $opt{code})
                              );

                    if (ref($arg) and ref($arg) ne 'HASH') {
                        return
                          scalar {
                                  $self->{class} => [
                                                     {
                                                      self => $arg,
                                                      call => [{method => $name}]
                                                     }
                                                    ]
                                 };
                    }
                    elsif (ref($arg) eq 'HASH') {
                        if (not exists($arg->{$self->{class}})) {
                            $self->fatal_error(
                                               code  => $_,
                                               pos   => ($pos - length($name)),
                                               error => "metoda „$name” nu poate fi aplicată pe un obiect nedefinit",
                                              );
                        }

                        return scalar {
                            $self->{class} => [
                                {
                                 self => {
                                          $self->{class} => [{%{shift(@{$arg->{$self->{class}}})}}]
                                         },
                                 call => [
                                     {
                                      method => $name,
                                      (
                                       @{$arg->{$self->{class}}}
                                       ? (
                                          arg => [
                                              map {
                                                  { $self->{class} => [{%{$_}}] }
                                                } @{$arg->{$self->{class}}}
                                          ]
                                         )
                                       : ()
                                      ),
                                     }
                                 ],
                                }
                            ]
                        };
                    }
                }

                # Undeclared variable
                $self->fatal_error(
                                   code  => $_,
                                   pos   => (pos($_) - length($name) - 1),
                                   error => "variabila „$name” nu este declarată în scopul curent",
                                  );
            }

            # Regex variables ($1, $2, ...)
            if (/\G\$([0-9]+)\b/gc) {
                $self->fatal_error(
                                   code  => $_,
                                   pos   => (pos($_) - length($1)),
                                   error => "attempt to use the deprecated regex variables",
                                  );

                #return $self->{regexp_vars}{$1} //= Corvinus::Variable::Variable->new(name => $1, type => 'var');
            }

            /\G\$/gc && redo;

            #warn "$self->{script_name}:$self->{line}: unexpected char: " . substr($_, pos($_), 1) . "\n";
            #return undef, pos($_) + 1;

            return;
        }
    }

    sub parse_arguments {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        if (/\G\(/gc) {
            my $p = pos($_);
            local $self->{parentheses} = 1;
            my $obj = $self->parse_script(code => $opt{code});

            $self->{parentheses}
              && $self->fatal_error(
                                    code  => $_,
                                    pos   => $p - 1,
                                    error => "paranteze rotunde nebalansate",
                                   );

            return $obj;
        }
    }

    sub parse_array {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        if (/\G\[/gc) {
            my $p = pos($_);
            local $self->{right_brackets} = 1;
            my $obj = $self->parse_script(code => $opt{code});

            $self->{right_brackets}
              && $self->fatal_error(
                                    code  => $_,
                                    pos   => $p - 1,
                                    error => "paranteze drepte nebalansate",
                                   );

            return $obj;
        }
    }

    sub parse_lookup {
        my ($self, %opt) = @_;

        local *_ = $opt{code};

        if (/\G\{/gc) {
            my $p = pos($_);
            local $self->{curly_brackets} = 1;
            my $obj = $self->parse_script(code => $opt{code});

            $self->{curly_brackets}
              && $self->fatal_error(
                                    code  => $_,
                                    pos   => $p - 1,
                                    error => "unbalanced curly brackets",
                                   );

            return $obj;
        }
    }

    sub parse_block {
        my ($self, %opt) = @_;

        local *_ = $opt{code};
        if (/\G\{/gc) {

            my $p = pos($_);
            local $self->{curly_brackets} = 1;

            my $ref = $self->{vars}{$self->{class}} //= [];
            my $count = scalar(@{$self->{vars}{$self->{class}}});

            unshift @{$self->{ref_vars_refs}{$self->{class}}}, @{$ref};
            unshift @{$self->{vars}{$self->{class}}}, [];

            $self->{vars}{$self->{class}} = $self->{vars}{$self->{class}}[0];

            my $block = Corvinus::Types::Block::CodeInit->new({});
            local $self->{current_block} = $block;

            # Parse whitespace (if any)
            $self->parse_whitespace(code => $opt{code});

            my $var_objs = [];
            if (/\G(?=\|)/) {
                $var_objs =
                  $self->parse_init_vars(code => $opt{code},
                                         type => 'var');
            }

            {    # special '_' variable
                my $var_obj = Corvinus::Variable::Variable->new(name => '_', type => 'var', class => $self->{class});
                push @{$var_objs}, $var_obj;

                my (undef, $code) = $self->find_var('_', $self->{class});
                if (not defined($code) or $code == 0) {
                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $var_obj,
                        name  => '_',
                        count => 0,
                        type  => 'var',
                        line  => $self->{line},
                      };
                }
            }

            my $obj = $self->parse_script(code => $opt{code});

            $self->{curly_brackets}
              && $self->fatal_error(
                                    code  => $_,
                                    pos   => $p - 1,
                                    error => "acolade nebalansate",
                                   );

            $block->{vars} = [map { $_->{obj} }
                                grep { ref($_) eq 'HASH' and ref($_->{obj}) eq 'Corvinus::Variable::Variable' }
                                @{$self->{vars}{$self->{class}}}
                             ];

            $block->{init_vars} = Corvinus::Variable::Init->new(vars => $var_objs);

            $block->{code} = $obj;
            splice @{$self->{ref_vars_refs}{$self->{class}}}, 0, $count;
            $self->{vars}{$self->{class}} = $ref;

            return $block;
        }
    }

    sub append_method {
        my ($self, %opt) = @_;

        # Hyper-operator
        if (exists $self->{hyper_ops}{$opt{op_type}}) {
            push @{$opt{array}},
              {
                method => $self->{hyper_ops}{$opt{op_type}}[1],
                arg    => [$opt{method}],
              };
        }

        # Basic operator/method
        else {
            push @{$opt{array}}, {method => $opt{method}};
        }

        # Append the argument (if any)
        if (exists($opt{arg}) and (%{$opt{arg}} || ($opt{method} =~ /^$self->{operators_re}\z/))) {
            push @{$opt{array}[-1]{arg}}, $opt{arg};
        }
    }

    sub parse_methods {
        my ($self, %opt) = @_;

        my @methods;
        local *_ = $opt{code};

        {
            if ((/\G(?![-=]>)/ && /\G(?=$self->{operators_re})/o) || /\G(\.|\s*(?!\.\.)\.)/gc) {
                my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                if (defined($method)) {

                    my $has_arg;
                    if (/\G\h*(?=[({])/gc || $req_arg || exists($self->{binpost_ops}{$method})) {

                        my $code = substr($_, pos);
                        my $arg = (
                                     /\G(?=\()/ ? $self->parse_arguments(code => \$code)
                                   : ($req_arg || exists($self->{binpost_ops}{$method})) ? $self->parse_obj(code => \$code)
                                   : /\G(?=\{)/ ? $self->parse_block(code => \$code)
                                   :              die "[PARSING ERROR] Something is wrong in the if condition"
                                  );

                        if (defined $arg) {
                            pos($_) += pos($code);
                            $has_arg = 1;
                            $self->append_method(
                                                 array   => \@methods,
                                                 method  => $method,
                                                 arg     => $arg,
                                                 op_type => $op_type,
                                                );
                        }
                        elsif (exists($self->{binpost_ops}{$method})) {
                            ## it's a postfix operator
                        }
                        else {
                            $self->fatal_error(
                                code  => $_,
                                pos   => pos($_) - 1,
                                error => "operatorul „$method” necesită specificarea a încă unui obiect în dreapta sa",
                            );
                        }
                    }

                    $has_arg || do {
                        $self->append_method(
                                             array   => \@methods,
                                             method  => $method,
                                             op_type => $op_type,
                                            );
                    };
                    redo;
                }
            }
        }

        return \@methods;
    }

    sub parse_suffixes {
        my ($self, %opt) = @_;

        my $struct = $opt{struct};
        local *_ = $opt{code};

        my $parsed = 0;

        {
            if (/\G(?=\{)/) {
                $struct->{$self->{class}}[-1]{self} = {
                        $self->{class} => [
                            {
                             self => $struct->{$self->{class}}[-1]{self},
                             exists($struct->{$self->{class}}[-1]{call}) ? (call => delete $struct->{$self->{class}}[-1]{call})
                             : (),
                             exists($struct->{$self->{class}}[-1]{ind}) ? (ind => delete $struct->{$self->{class}}[-1]{ind})
                             : (),
                             exists($struct->{$self->{class}}[-1]{lookup})
                             ? (lookup => delete $struct->{$self->{class}}[-1]{lookup})
                             : (),
                            }
                        ]
                };

                while (/\G(?=\{)/) {
                    my $lookup = $self->parse_lookup(code => $opt{code});
                    push @{$struct->{$self->{class}}[-1]{lookup}}, $lookup->{$self->{class}};
                }

                $parsed ||= 1;
                redo;
            }

            if (/\G(?=\[)/) {
                $struct->{$self->{class}}[-1]{self} = {
                        $self->{class} => [
                            {
                             self => $struct->{$self->{class}}[-1]{self},
                             exists($struct->{$self->{class}}[-1]{call}) ? (call => delete $struct->{$self->{class}}[-1]{call})
                             : (),
                             exists($struct->{$self->{class}}[-1]{ind}) ? (ind => delete $struct->{$self->{class}}[-1]{ind})
                             : (),
                             exists($struct->{$self->{class}}[-1]{lookup})
                             ? (lookup => delete $struct->{$self->{class}}[-1]{lookup})
                             : (),
                            }
                        ]
                };

                while (/\G(?=\[)/) {
                    my ($ind) = $self->parse_expr(code => $opt{code});
                    push @{$struct->{$self->{class}}[-1]{ind}}, $ind;
                }

                $parsed ||= 1;
                redo;
            }

            if (/\G\h*(?=\()/gc) {
                my $arg = $self->parse_arguments(code => $opt{code});

                push @{$struct->{$self->{class}}[-1]{call}},
                  {
                    method => 'call',
                    (%{$arg} ? (arg => [$arg]) : ())
                  };

                redo;
            }
        }

        $parsed;
    }

    sub parse_obj {
        my ($self, %opt) = @_;

        my %struct;
        local *_ = $opt{code};

        my ($obj, $obj_key) = $self->parse_expr(code => $opt{code});

        if (defined $obj) {
            push @{$struct{$self->{class}}}, {self => $obj};

            if ($obj_key) {
                my ($method) = $self->get_method_name(code => $opt{code});
                if (defined $method) {

                    my $arg = (
                               /\G\h*(?=\()/gc
                               ? $self->parse_arguments(code => $opt{code})
                               : $self->parse_obj(code => $opt{code})
                              );

                    if (defined $arg) {
                        my @arg = ($arg);

                        if (    ref($struct{$self->{class}}[-1]{self}) eq 'Corvinus::Types::Block::For'
                            and ref($arg) eq 'HASH') {
                            if ($#{$arg->{$self->{class}}} == 2) {
                                @arg = (
                                    map {
                                        { $self->{class} => [$_] }
                                      } @{$arg->{$self->{class}}}
                                );
                            }
                            elsif ($#{$arg->{$self->{class}}} != 0) {
                                $self->fatal_error(
                                                   code  => $_,
                                                   pos   => pos($_) - 1,
                                                   error => "invalid for-loop: too many arguments",
                                                  );
                            }
                        }

                        push @{$struct{$self->{class}}[-1]{call}}, {method => $method, arg => \@arg};
                    }
                    elsif (ref($obj) ne 'Corvinus::Types::Block::Return') {
                        $self->fatal_error(
                                           code  => $_,
                                           error => "expected an argument. Did you mean '$method()' instead?",
                                           pos   => pos($_) - 1,
                                          );
                    }
                }
                else {
                    die "[PARSER ERROR] The same object needs to be parsed again as a method for itself!";
                }
            }

            {
                if (/\G\h*(?=\.\h*(?:$self->{method_name_re}|[(\$]))/ogc) {
                    my $methods = $self->parse_methods(code => $opt{code});
                    push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                }

                if (/\G\h*\.?(\@)\h*(?=[\[\{])/gc) {
                    push @{$struct{$self->{class}}[-1]{call}}, {method => $1};
                    redo;
                }

                if (/\G\h*(?=\()/gc) {
                    my $arg = $self->parse_arguments(code => $opt{code});

                    push @{$struct{$self->{class}}[-1]{call}},
                      {
                        method => 'call',
                        (%{$arg} ? (arg => [$arg]) : ())
                      };

                    redo;
                }

                if (    exists($struct{$self->{class}}[-1]{call})
                    and exists $self->{special_constructs}{ref($obj)}
                    and /\G\h*(?=\{)/gc) {

                    my $arg = $self->parse_block(code => $opt{code});

                    if (ref($obj) eq 'Corvinus::Types::Block::For') {
                        if ($#{$struct{$self->{class}}[-1]{call}[-1]{arg}} == 0) {
                            $struct{$self->{class}}[-1]{self} = shift @{delete $struct{$self->{class}}[-1]{call}[-1]{arg}};
                            push @{$struct{$self->{class}}[-1]{call}[-1]{arg}}, $arg;
                        }
                        else {
                            push @{$struct{$self->{class}}[-1]{call}[-1]{block}}, $arg->{code};
                        }
                    }
                    else {

                        push @{$struct{$self->{class}}[-1]{call}[-1]{block}}, $arg->{code};

                        if (ref($obj) eq 'Corvinus::Types::Block::If') {
                          ELSIF: {
                                if (/\G(?=\s*(?:sau_daca|elsif)\h*\()/) {
                                    $self->parse_whitespace(code => $opt{code});
                                    while (/\G\h*(?:sau_daca|elsif)\h*(?=\()/gc) {
                                        my $arg = $self->parse_arguments(code => $opt{code});
                                        $self->parse_whitespace(code => $opt{code});
                                        my $block = $self->parse_block(code => $opt{code});
                                        push @{$struct{$self->{class}}[-1]{call}},
                                          {keyword => 'elsif', arg => [$arg], block => [$block->{code}]};
                                        redo ELSIF;
                                    }
                                }
                            }

                            if (/\G(?=\s*(?:altfel|else)\h*\{)/) {
                                $self->parse_whitespace(code => $opt{code});
                                /\G(?:altfel|else)\h*/gc;
                                my $block = $self->parse_block(code => $opt{code});
                                push @{$struct{$self->{class}}[-1]{call}}, {keyword => 'else', block => [$block->{code}]};
                            }
                        }
                    }
                }

                # Do-while construct
                if (ref($obj) eq 'Corvinus::Types::Block::Do' and /\G\h*(?:cat_timp|while)\b/gc) {
                    my $arg = $self->parse_obj(code => $opt{code});
                    push @{$struct{$self->{class}}[-1]{call}}, {keyword => 'while', arg => [$arg]};
                }

                # Try-catch construct
                if (ref($obj) eq 'Corvinus::Types::Block::Try') {
                    $self->parse_whitespace();
                    if (/\G\h*(?:catch|salveaza)\b/gc) {
                        my $arg = $self->parse_obj(code => $opt{code});
                        push @{$struct{$self->{class}}[-1]{call}}, {method => 'catch', arg => [$arg]};
                    }
                }

                # Parse array and hash fetchers ([...] and {...})
                $self->parse_suffixes(code => $opt{code}, struct => \%struct) && redo;

                if (/\G(?!\h*[=-]>)/ && /\G(?=$self->{operators_re})/o) {
                    my ($method, $req_arg, $op_type) = $self->get_method_name(code => $opt{code});

                    my $has_arg;
                    if ($req_arg or exists $self->{binpost_ops}{$method}) {
                        my $lonely_obj = /\G\h*(?=\()/gc;

                        my $code = substr($_, pos);
                        my $arg = (
                                     $lonely_obj
                                   ? $self->parse_arguments(code => \$code)
                                   : $self->parse_obj(code => \$code)
                                  );

                        if (defined $arg) {
                            pos($_) += pos($code);
                            if (ref $arg ne 'HASH') {
                                $arg = {$self->{class} => [{self => $arg}]};
                            }

                            if (not $lonely_obj) {
                                my $methods = $self->parse_methods(code => $opt{code});
                                if (@{$methods}) {
                                    push @{$arg->{$self->{class}}[-1]{call}}, @{$methods};
                                }
                            }

                            $has_arg = 1;
                            $self->append_method(
                                                 array   => \@{$struct{$self->{class}}[-1]{call}},
                                                 method  => $method,
                                                 arg     => $arg,
                                                 op_type => $op_type,
                                                );
                        }
                        elsif (exists $self->{binpost_ops}{$method}) {
                            ## it's a postfix operator
                        }
                        else {
                            $self->fatal_error(
                                code  => $_,
                                pos   => pos($_) - 1,
                                error => "operatorul „$method” necesită specificarea a încă unui obiect în dreapta sa",
                            );
                        }
                    }

                    $has_arg || do {
                        $self->append_method(
                                             array   => \@{$struct{$self->{class}}[-1]{call}},
                                             method  => $method,
                                             op_type => $op_type,
                                            );
                    };
                    redo;
                }
            }
        }
        else {
            return;
        }

        return \%struct;
    }

    sub parse_script {
        my ($self, %opt) = @_;

        my %struct;
        local *_ = $opt{code};
      MAIN: {
            $self->parse_whitespace(code => $opt{code});

            # Module declaration
            if (/\Gmodule?+\b\h*/gc) {
                my $name =
                  /\G($self->{var_name_re})\h*/goc
                  ? $1
                  : $self->fatal_error(
                                       error    => "declarare invalidă de modul",
                                       expected => "sintaxa este: „modul Nume {...}”",
                                       code     => $_,
                                       pos      => pos($_)
                                      );

                /\G\h*\{\h*/gc
                  || $self->fatal_error(
                                        error    => "declarare invalidă de modul",
                                        expected => "sintaxa este: „modul $name {...}”",
                                        code     => $_,
                                        pos      => pos($_)
                                       );

                my $parser = __PACKAGE__->new(file_name   => $self->{file_name},
                                              script_name => $self->{script_name},);
                local $parser->{line}  = $self->{line};
                local $parser->{class} = $name;
                local $parser->{ref_vars}{$name} = $self->{ref_vars}{$name} if exists($self->{ref_vars}{$name});

                if ($name ne 'main' and not grep $_ eq $name, @Corvinus::NAMESPACES) {
                    unshift @Corvinus::NAMESPACES, $name;
                }

                my $code = '{' . substr($_, pos);
                my ($struct, $pos) = $parser->parse_block(code => \$code);
                pos($_) += pos($code) - 1;
                $self->{line} = $parser->{line};

                foreach my $class (keys %{$struct->{code}}) {
                    push @{$struct{$class}}, @{$struct->{code}{$class}};
                    if (exists $self->{ref_vars}{$class}) {
                        unshift @{$self->{ref_vars}{$class}}, @{$parser->{ref_vars}{$class}[0]};
                    }
                    else {
                        push @{$self->{ref_vars}{$class}},
                          @{
                              $#{$parser->{ref_vars}{$class}} == 0 && ref($parser->{ref_vars}{$class}[0]) eq 'ARRAY'
                            ? $parser->{ref_vars}{$class}[0]
                            : $parser->{ref_vars}{$class}
                           };
                    }
                }

                redo;
            }

            if (/\Gimport\b\h*/gc) {

                my $var_names =
                  $self->get_init_vars(code      => $opt{code},
                                       with_vals => 0);

                @{$var_names}
                  || $self->fatal_error(
                                 code  => $_,
                                 pos   => (pos($_)),
                                 error => "este necesară specificarea a unuia sau mai multor identificatori pentru importare",
                  );

                foreach my $var_name (@{$var_names}) {
                    my ($name, $class) = $self->get_name_and_class($var_name);

                    if ($class eq $self->{class}) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => pos($_),
                                           error => "nu se poate importa '${class}::${name}' în același modul",
                                          );
                    }

                    my $var = $self->find_var($name, $class);

                    if (not defined $var) {
                        $self->fatal_error(
                                           code  => $_,
                                           pos   => pos($_),
                                           error => "variable '${class}::${name}' hasn't been declared",
                                          );
                    }

                    $var->{count}++;

                    unshift @{$self->{vars}{$self->{class}}},
                      {
                        obj   => $var->{obj},
                        name  => $name,
                        count => 0,
                        type  => $var->{type},
                        line  => $self->{line},
                      };
                }

                redo;
            }

            if (/\G\@:([\pL_][\pL\pN_]*)/gc) {
                push @{$struct{$self->{class}}}, {self => Corvinus::Variable::Label->new(name => $1)};
                redo;
            }

            if (/\Ginclude\b\h*/gc) {
                my $expr = eval {
                    local $self->{_want_name} = 1;
                    my $code = substr($_, pos);
                    my ($obj) = $self->parse_expr(code => \$code);
                    pos($_) += pos($code);
                    $obj;
                };

                my @abs_filenames;
                if ($@) {    # an error occured

                    # Try to get variable-like values (e.g.: include Some::Module::Name)
                    my $var_names = $self->get_init_vars(code      => $opt{code},
                                                         with_vals => 0,);

                    @{$var_names}
                      || $self->fatal_error(
                           code => $_,
                           pos  => pos($_),
                           error =>
                             "modulul pentru includere nu este specificat în mod corect, sintaxa este: „Nume::De::Modul„",
                      );

                    foreach my $var_name (@{$var_names}) {

                        next if exists $Corvinus::INCLUDED{$var_name};

                        state $x = require File::Spec;
                        my @path = split(/::/, $var_name);
                        my $mod_path = File::Spec->catfile(@path[0 .. $#path - 1], $path[-1] . '.cv');

                        $Corvinus::INCLUDED{$var_name} = $mod_path;

                        if (@{$self->{inc}} == 0) {
                            state $y = require File::Basename;
                            push @{$self->{inc}}, split(':', $ENV{CORVINUS_INC}) if exists($ENV{CORVINUS_INC});
                            push @{$self->{inc}},
                              File::Spec->catdir(File::Basename::dirname(File::Spec->rel2abs($0)),
                                                 File::Spec->updir, 'share', 'corvinus');
                            push @{$self->{inc}}, File::Basename::dirname(File::Spec->rel2abs($self->{script_name}));
                            push @{$self->{inc}}, File::Spec->curdir;
                        }

                        my ($full_path, $found_module);
                        foreach my $inc_dir (@{$self->{inc}}) {
                            if (    -e ($full_path = File::Spec->catfile($inc_dir, $mod_path))
                                and -f _
                                and -r _ ) {
                                $found_module = 1;
                                last;
                            }
                        }

                        $found_module // $self->fatal_error(
                                                            code  => $_,
                                                            pos   => pos($_),
                                                            error => "nu poate fi găsit modulul '${mod_path}' în dosarele ['"
                                                              . join("', '", @{$self->{inc}}) . "']",
                                                           );

                        push @abs_filenames, [$full_path, $var_name];
                    }
                }
                else {

                    my @files = (
                        ref($expr) eq 'HASH'
                        ? do {
                            map   { $_->{self} }
                              map { @{$_->{self}->{$self->{class}}} }
                              map { @{$expr->{$_}} }
                              keys %{$expr};
                          }
                        : $expr
                    );

                    push @abs_filenames, map {
                        my $value = $_;
                        do {
                            $value = $value->get_value;
                        } while (index(ref($value), 'Corvinus::') == 0);

                        ref($value) ne ''
                          ? $self->fatal_error(
                                               code  => $_,
                                               pos   => pos($_),
                                               error => 'tip invalid pentru includere „'
                                                 . ref($value)
                                                 . '” (este necesar un obiect de tip text)',
                                              )
                          : [$value];
                    } @files;
                }

                foreach my $pair (@abs_filenames) {

                    my ($full_path, $name) = @{$pair};

                    open(my $fh, '<:utf8', $full_path)
                      || $self->fatal_error(
                                            code  => $_,
                                            pos   => pos($_),
                                            error => "fișierul '$full_path' nu poate fi deschis pentru citire: $!"
                                           );

                    my $content = do { local $/; <$fh> };
                    close $fh;

                    my $parser = __PACKAGE__->new(file_name   => $full_path,
                                                  script_name => $self->{script_name},);

                    local $parser->{class} = $name if defined $name;
                    if (defined $name and $name ne 'main' and not grep $_ eq $name, @Corvinus::NAMESPACES) {
                        unshift @Corvinus::NAMESPACES, $name;
                    }
                    my $struct = $parser->parse_script(code => \$content);

                    foreach my $class (keys %{$struct}) {
                        if (defined $name) {
                            $struct{$class} = $struct->{$class};
                            $self->{ref_vars}{$class} = $parser->{ref_vars}{$class};
                        }
                        else {
                            push @{$struct{$class}}, @{$struct->{$class}};
                            unshift @{$self->{ref_vars}{$class}}, @{$parser->{ref_vars}{$class}};
                        }
                    }
                }

                redo;
            }

            if (/\G(?:[;,]+|=>)/gc) {
                redo;
            }

            # Ternary operator
            if (%struct && /\G\?/gc) {
                $self->parse_whitespace(code => $opt{code});

                my $true = (
                            /\G(?=\()/
                            ? $self->parse_arguments(code => $opt{code})
                            : $self->parse_obj(code => $opt{code})
                           );

                $self->parse_whitespace(code => $opt{code});

                /\G:/gc
                  || $self->fatal_error(
                                        code     => $_,
                                        pos      => pos($_) - 1,
                                        error    => "invalid usage of the ternary operator",
                                        expected => "expected ':'",
                                       );

                $self->parse_whitespace(code => $opt{code});

                my $false = (
                             /\G(?=\()/
                             ? $self->parse_arguments(code => $opt{code})
                             : $self->parse_obj(code => $opt{code})
                            );

                my $tern = Corvinus::Types::Bool::Ternary->new(
                                                           cond => scalar {$self->{class} => [pop @{$struct{$self->{class}}}]},
                                                           true => $true,
                                                           false => $false
                );

                push @{$struct{$self->{class}}}, {self => $tern};
                redo MAIN;
            }

            my $obj = $self->parse_obj(code => $opt{code});

            if (defined $obj) {
                push @{$struct{$self->{class}}}, {self => $obj};

                {

                    my $pos_before = pos($_);
                    $self->parse_whitespace(code => $opt{code});
                    my $pos_after = pos($_);

                    my $has_newline = substr($_, $pos_before, $pos_after - $pos_before) =~ /\R/;

                    if (/\G(?:[;,]+|=>)/gc) {
                        redo MAIN;
                    }

                    state $bin_ops = {
                        map { $_ => 1 }
                          qw(
                          &&=
                          ||=
                          \\=
                          :=

                          &&
                          ||
                          \\

                          += -= *= /=
                          |= &= ^= %=
                          =~
                          ==
                          ~~
                          !~
                          !=
                          )
                    };

                    my $is_operator = /\G(?!->)/ && /\G(?=($self->{operators_re}))/o;
                    my $op = $1;

                    if (
                           ($is_operator && defined($op) && exists $bin_ops->{$op})
                        || (!$has_newline && $is_operator)
                        || /\G(?:->|\.)\h*/gc

                        #|| /\G(?=$self->{method_name_re})/o
                      ) {

                        # Implicit end of statement -- redo
                        $self->parse_whitespace(code => $opt{code});

                        my $methods;
                        if ($is_operator) {
                            $methods = $self->parse_methods(code => $opt{code});
                        }
                        else {
                            my $code = '.' . substr($_, pos);
                            $methods = $self->parse_methods(code => \$code);
                            pos($_) += pos($code) - 1;
                        }

                        if (@{$methods}) {
                            push @{$struct{$self->{class}}[-1]{call}}, @{$methods};
                        }
                        else {
                            $self->fatal_error(
                                               error => 'metodă nespecificată',
                                               code  => $_,
                                               pos   => pos($_) - 1,
                                              );
                        }

                        $self->parse_suffixes(code => $opt{code}, struct => \%struct);
                        redo;
                    }
                    elsif (!$has_newline and /\G(daca|if|cat_timp|while|si|and|sau|or)\b\h*/gc) {
                        my $keyword = $1;

                        state $trans = {
                                        daca     => 'if',
                                        cat_timp => 'while',
                                        si       => 'and',
                                        sau      => 'or',
                                       };

                        if (exists $trans->{$keyword}) {
                            $keyword = $trans->{$keyword};
                        }

                        my $obj =
                          (/\G(?=\()/ ? $self->parse_arguments(code => $opt{code}) : $self->parse_obj(code => $opt{code}));
                        push @{$struct{$self->{class}}[-1]{call}}, {keyword => $keyword, arg => [$obj]};
                        redo;
                    }
                    else {
                        redo MAIN;
                    }
                }
            }

            if (/\G(?:[;,]+|=>)/gc) {
                redo;
            }

            # We are at the end of the script.
            # We make some checks, and return the \%struct hash ref.
            if (/\G\z/) {
                $self->check_declarations($self->{ref_vars});
                return \%struct;
            }

            if (/\G\]/gc) {

                if (--$self->{right_brackets} < 0) {
                    $self->fatal_error(
                                       error => 'paranteză dreaptă nebalansată',
                                       code  => $_,
                                       pos   => pos($_) - 1,
                                      );
                }

                return \%struct;
            }

            if (/\G\}/gc) {

                if (--$self->{curly_brackets} < 0) {
                    $self->fatal_error(
                                       error => 'acoladă nebalansată',
                                       code  => $_,
                                       pos   => pos($_) - 1,
                                      );
                }

                return \%struct;
            }

            # The end of an argument expression
            if (/\G\)/gc) {

                if (--$self->{parentheses} < 0) {
                    $self->fatal_error(
                                       error => 'paranteză rotundă nebalansată',
                                       code  => $_,
                                       pos   => pos($_) - 1,
                                      );
                }

                return \%struct;
            }

            $self->fatal_error(
                code => $_,
                pos  => (pos($_)),
                error =>
"au fost găsite două obiecte consecutive în locul în care se aștepta o metodă sau un terminator de expresie („;”)",
            );

            pos($_) += 1;
            redo;
        }
    }
};

1
