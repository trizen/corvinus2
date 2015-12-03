package Corvinus::Types::Block::Code {

    use utf8;
    use 5.014;
    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

    sub run {
        my ($self, @args) = @_;
        $self->{code}->(@args);
    }

    *executa = \&run;

    sub _multiple_dispatch {
        my ($self, @args) = @_;

      OUTER: foreach my $method ($self, (exists($self->{kids}) ? @{$self->{kids}} : ())) {
            my $table = $self->{table};

            my %seen;
            my @left_args;
            my @vars = @{$method->{vars}};

            foreach my $arg (@args) {
                if (ref($arg) eq 'Corvinus::Variable::NamedParam') {
                    if (exists $table->{$arg->[0]}) {
                        my $info = $vars[$table->{$arg->[0]}];
                        if (exists $info->{slurpy}) {
                            $seen{$arg->[0]} = $arg->[1];
                        }
                        else {
                            $seen{$arg->[0]} = $arg->[1][-1];
                        }
                    }
                    else {
                        next OUTER;
                    }
                }
                else {
                    push @left_args, $arg;
                }
            }

            foreach my $var (@vars) {
                exists($seen{$var->{name}}) && next;
                @left_args || last;
                if (exists($var->{slurpy})) {
                    $seen{$var->{name}} = [splice(@left_args)];
                    last;
                }
                else {
                    $seen{$var->{name}} = shift(@left_args);
                }
            }

            @left_args && next;

            my @pos_args;
            foreach my $var (@vars) {
                if (exists $var->{type}) {

                    if (exists $seen{$var->{name}}) {
                        my $value = $seen{$var->{name}};
                        if (ref($value) eq $var->{type}
                            or eval { $value->SUPER::isa($var->{type}) }) {

                            if (exists $var->{where_block}) {
                                $var->{where_block}($value) or next OUTER;
                            }
                            elsif (exists $var->{where_expr}) {
                                $value eq $var->{where_expr} or next OUTER;
                            }

                            push @pos_args, $value;
                        }
                        else {
                            next OUTER;
                        }
                    }
                    elsif (exists $var->{has_value}) {
                        push @pos_args, undef;
                    }
                    else {
                        next OUTER;
                    }
                }
                elsif (exists $seen{$var->{name}}) {
                    if (exists $var->{where_block}) {
                        $var->{where_block}($seen{$var->{name}}) or next OUTER;
                    }
                    elsif (exists $var->{where_expr}) {
                        $var->{where_expr} eq $seen{$var->{name}} or next OUTER;
                    }

                    push @pos_args, exists($var->{slurpy}) ? @{$seen{$var->{name}}} : $seen{$var->{name}};
                }
                elsif (exists $var->{slurpy}) {
                    ## ok
                }
                elsif (exists $var->{has_value}) {
                    push @pos_args, undef;
                }
                else {
                    next OUTER;
                }
            }

            return ($method, $method->{code}(@pos_args));
        }

        my $name = Corvinus::normalize_type($self->{name} // '__ANON__');
        my $type = $self->{type};

        if ($type eq 'method') {
            $type = 'metoda';
        }
        elsif ($type eq 'func') {
            $type = 'functia';
        }
        elsif ($type eq 'block') {
            $type = 'bloc';
        }
        elsif ($type eq 'struct') {
            $type = 'structura';
        }

        die "[EROARE] $type `$name` nu este definită pentru `$name("
          . join(', ', map { ref($_) ? Corvinus::normalize_type(ref($_)) : 'nil' } @args)
          . ")`, apelată ca `"
          . $name . '('
          . join(
            ', ',
            map {
                    ref($_) && eval { $_->can('dump') } ? $_->dump
                  : ref($_) ? Corvinus::normalize_type(ref($_))
                  : 'nil'
              } @args
          )
          . ')`'
          . "\n\nVariantele posibile sunt:"
          . "\n    $name("
          . join(
            ")\n    $name(",
            map {
                join(
                    ', ',
                    map {
                            (exists($_->{slurpy}) ? '*' : '')
                          . $_->{name}
                          . (exists($_->{type}) ? (": " . Corvinus::normalize_type($_->{type})) : '')
                      } @{$_->{vars}}
                    )
              } ($self, (exists($self->{kids}) ? @{$self->{kids}} : ()))
          )
          . ")\n";
    }

    sub call {
        my ($block, @args) = @_;

        my ($self, @objs) = $block->_multiple_dispatch(@args);

        # Unpack 'return'ed values from bare-blocks
        if (@objs == 1 and ref($objs[0]) eq 'Corvinus::Types::Block::Return') {
            @objs = @{$objs[0]{obj}};
        }

        # Check the return types
        if (exists $self->{returns}) {

            if ($#{$self->{returns}} != $#objs) {
                die qq{[EROARE] Număr invalid the obiecte returnate din $self->{type} }
                  . (defined($self->{class}) ? Corvinus::normalize_type($self->{class}) . '.' : '')
                  . qq{$self->{name}\(): got }
                  . @objs
                  . ", dar așteptam "
                  . @{$self->{returns}};
            }

            foreach my $i (0 .. $#{$self->{returns}}) {
                if (not(ref($objs[$i]) eq ($self->{returns}[$i]) or eval { $objs[$i]->SUPER::isa($self->{returns}[$i]) })) {
                    die qq{[EROARE] Tip de obiect invalid returnat din $self->{type} }
                      . (defined($self->{class}) ? Corvinus::normalize_type($self->{class}) . '.' : '')
                      . qq{$self->{name}\(): avem `}
                      . Corvinus::normalize_type(ref($objs[$i]))
                      . qq{`, dar așteptam `}
                      . Corvinus::normalize_type($self->{returns}[$i]) . "`";
                }
            }
        }

        wantarray ? @objs : $objs[-1];
    }

    {
        my $ref = \&UNIVERSAL::AUTOLOAD;

        sub get_value {
            my ($self) = @_;
            sub {
                my @args = @_;
                local *UNIVERSAL::AUTOLOAD = $ref;
                if (defined($a) || defined($b)) { push @args, $a, $b }
                elsif (defined($_)) { unshift @args, $_ }
                $self->call(@args);
            };
        }
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeat;
    }

    sub capture {
        my ($self) = @_;

        open my $str_h, '>:utf8', \my $str;
        if (defined(my $old_h = select($str_h))) {
            $self->run;
            close $str_h;
            select $old_h;
        }

        Corvinus::Types::String::String->new($str)->decode_utf8;
    }

    *cap = \&capture;

    sub repeat {
        my ($self, $num) = @_;

        $num = defined($num) ? $num->get_value : 1;

        return $self if $num < 1;

        if ($num < (-1 >> 1)) {

            $num = $num->numify if ref($num);

            foreach my $i (1 .. $num) {
                if (defined(my $res = $self->_run_code(Corvinus::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        else {

            $num = Math::BigFloat->new($num) if not ref($num);

            for (my $i = Math::BigFloat->new(1) ; $i->bcmp($num) <= 0 ; $i->binc) {
                if (defined(my $res = $self->_run_code(Corvinus::Types::Number::Number->new($i->copy)))) {
                    return $res;
                }
            }
        }

        $self;
    }

    sub _run_code {
        my ($self, @args) = @_;
        my $result = $self->run(@args);
        ref($result) eq 'Corvinus::Types::Block::Return' ? $result : ();
    }

    sub exec {
        my ($self) = @_;

        for (1) {
            $self->run;
            return $self;
        }

        Corvinus::Types::Black::Hole->new;
    }

    *do = \&exec;

    sub while {
        my ($self, $condition) = @_;
        Corvinus::Types::Block::While->new->while($condition, $self);
    }

    *cat_timp = \&while;

    sub loop {
        my ($self) = @_;

        while (1) {
            if (defined(my $res = $self->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    *bucla = \&loop;

    sub if {
        my ($self, $bool) = @_;

        if ($bool) {
            return $self->run;
        }

        $bool;
    }

    *daca = \&if;

    sub fork {
        my ($self) = @_;

        state $x = require Storable;
        open(my $fh, '+>', undef);    # an anonymous temporary file
        my $fork = Corvinus::Types::Block::Fork->new(fh => $fh);

        my $pid = fork() // die "[EROARE]: nu pot face fork()";
        if ($pid == 0) {
            srand();
            my $obj = $self->run;
            ref($obj) && Storable::store_fd($obj, $fh);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    *bifurca = \&fork;
    *paralel = \&fork;

    sub pfork {
        my ($self) = @_;

        my $fork = Corvinus::Types::Block::Fork->new();

        my $pid = CORE::fork() // die "[EROARE]: nu pot face fork()";
        if ($pid == 0) {
            srand();
            $self->run;
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub thread {
        my ($self) = @_;
        state $x = do {
            require threads;
            *threads::get  = \&threads::join;
            *threads::wait = \&threads::join;
            1;
        };
        threads->create(sub { $self->run });
    }

    *thr = \&thread;

    sub for {
        my ($self, @args) = @_;
        Corvinus::Types::Block::For->new->for(@args, $self);
    }

    sub dump {
        $_[0];
    }
}

1;
