package Corvinus::Types::Hash::Hash {

    use 5.014;

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload
      q{bool} => sub { scalar(CORE::keys %{$_[0]}) },
      q{""}   => \&dump;

    sub new {
        my ($class, %pairs) = @_;
        bless \%pairs, __PACKAGE__;
    }

    *call = \&new;
    *nou  = \&new;

    sub get_value {
        my ($self) = @_;

        my %hash;
        foreach my $k (CORE::keys %$self) {
            my $v = $self->{$k};
            $hash{$k} = (
                         index(ref($v), 'Corvinus::') == 0
                         ? $v->get_value
                         : $v
                        );
        }

        \%hash;
    }

    sub items {
        my ($self, @keys) = @_;
        Corvinus::Types::Array::Array->new(map { exists($self->{$_}) ? $self->{$_} : undef } @keys);
    }

    sub item {
        my ($self, $key) = @_;
        exists($self->{$key}) ? $self->{$key} : ();
    }

    sub fetch {
        my ($self, $key, $default) = @_;
        exists($self->{$key}) ? $self->{$key} : $default;
    }

    sub dig {
        my ($self, $key, @keys) = @_;

        my $value = $self->fetch($key) // return;

        foreach my $key (@keys) {
            $value = $value->fetch($key) // return;
        }

        $value;
    }

    sub slice {
        my ($self, @keys) = @_;
        $self->new(map { ($_ => exists($self->{$_}) ? $self->{$_} : undef) } @keys);
    }

    sub length {
        my ($self) = @_;
        Corvinus::Types::Number::Number->new(scalar CORE::keys %$self);
    }

    *len     = \&length;
    *lungime = \&length;

    sub eq {
        my ($self, $obj) = @_;

        (%$self eq %{$obj})
          or return Corvinus::Types::Bool::Bool->false;

        while (my ($key, $value) = each %$self) {
            exists($obj->{$key})
              or return Corvinus::Types::Bool::Bool->false;

            $value eq $obj->{$key}
              or return Corvinus::Types::Bool::Bool->false;
        }

        Corvinus::Types::Bool::Bool->true;
    }

    sub ne {
        my ($self, $obj) = @_;
        $self->eq($obj)->not;
    }

    sub same_keys {
        my ($self, $obj) = @_;

        if (ref($self) ne ref($obj)
            or %$self ne %{$obj}) {
            return Corvinus::Types::Bool::Bool->false;
        }

        while (my ($key) = each %$self) {
            exists($obj->{$key})
              or return Corvinus::Types::Bool::Bool->false;
        }

        Corvinus::Types::Bool::Bool->true;
    }

    sub append {
        my ($self, %pairs) = @_;

        foreach my $key (keys %pairs) {
            $self->{$key} = $pairs{$key};
        }

        $self;
    }

    *add    = \&append;
    *adauga = \&append;

    sub delete {
        my ($self, @keys) = @_;
        @keys == 1
          ? delete($self->{$keys[0]})
          : (delete @{$self}{@keys});
    }

    *sterge = \&delete;

    sub map_val {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            $hash{$key} = $code->run(Corvinus::Types::String::String->new($key), $self->{$key});
        }

        $self->new(%hash);
    }

    *map_values  = \&map_val;
    *mapeaza_val = \&map_val;

    sub map {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            my ($k, $v) = $code->run(Corvinus::Types::String::String->new($key), $self->{$key});
            $hash{$k} = $v;
        }

        $self->new(%hash);
    }

    *mapeaza = \&map;

    sub select {
        my ($self, $code) = @_;

        my %hash;
        foreach my $key (CORE::keys %$self) {
            my $value = $self->{$key};
            if ($code->run(Corvinus::Types::String::String->new($key), $value)) {
                $hash{$key} = $value;
            }
        }

        $self->new(%hash);
    }

    *alege      = \&grep;
    *filter     = \&grep;
    *grep       = \&select;
    *selecteaza = \&grep;
    *filtreaza  = \&grep;

    sub count {
        my ($self, $code) = @_;

        my $count = 0;
        foreach my $key (CORE::keys %$self) {
            if ($code->run(Corvinus::Types::String::String->new($key), $self->{$key})) {
                ++$count;
            }
        }

        Corvinus::Types::Number::Number->new($count);
    }

    *count_by    = \&count;
    *numara      = \&count;
    *numara_dupa = \&count;

    sub delete_if {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %$self) {
            if ($code->run(Corvinus::Types::String::String->new($key), $self->{$key})) {
                delete($self->{$key});
            }
        }

        $self;
    }

    *sterge_daca = \&delete_if;

    sub concat {
        my ($self, $obj) = @_;

        my @list;
        while (my ($key, $val) = each %$self) {
            push @list, $key, $val;
        }

        while (my ($key, $val) = each %{$obj}) {
            push @list, $key, $val;
        }

        $self->new(@list);
    }

    *merge  = \&concat;
    *uneste = \&concat;

    sub merge_values {
        my ($self, $obj) = @_;

        while (my ($key, undef) = each %$self) {
            if (exists $obj->{$key}) {
                $self->{$key} = $obj->{$key};
            }
        }

        $self;
    }

    sub keys {
        my ($self) = @_;
        Corvinus::Types::Array::Array->new(map { Corvinus::Types::String::String->new($_) } keys %$self);
    }
    *chei = \&keys;

    sub values {
        my ($self) = @_;
        Corvinus::Types::Array::Array->new(CORE::values %$self);
    }

    *valori = \&values;

    sub each_value {
        my ($self, $code) = @_;

        foreach my $value (CORE::values %$self) {
            if (defined(my $res = $code->_run_code($value))) {
                return $res;
            }
        }

        $code;
    }

    *fiecare_valoare = \&each_value;

    sub each_key {
        my ($self, $code) = @_;

        foreach my $key (CORE::keys %$self) {
            if (defined(my $res = $code->_run_code(Corvinus::Types::String::String->new($key)))) {
                return $res;
            }
        }

        $code;
    }

    *fiecare_cheie = \&each_key;

    sub each {
        my ($self, $obj) = @_;

        if (defined($obj)) {

            foreach my $key (CORE::keys %$self) {
                if (defined(my $res = $obj->_run_code(Corvinus::Types::String::String->new($key), $self->{$key}))) {
                    return $res;
                }
            }

            return $obj;
        }

        my ($key, $value) = each(%$self);

        $key // return;
        Corvinus::Types::Array::Array->new(Corvinus::Types::String::String->new($key), $value);
    }

    *each_pair       = \&each;
    *fiecare         = \&each;
    *fiecare_pereche = \&each;

    sub sort_by {
        my ($self, $code) = @_;

        my @array;
        foreach my $key (CORE::keys %$self) {
            push @array, [$key, $code->run(Corvinus::Types::String::String->new($key), $self->{$key})];
        }

        Corvinus::Types::Array::Array->new(
            map {
                Corvinus::Types::Array::Array->new(Corvinus::Types::String::String->new($_->[0]), $self->{$_->[0]})
              } (sort { $a->[1] cmp $b->[1] } @array)
        );
    }

    *sorteaza_dupa = \&sort_by;

    sub to_a {
        my ($self) = @_;
        Corvinus::Types::Array::Array->new(
            map {
                Corvinus::Types::Array::Pair->new(Corvinus::Types::String::String->new($_), $self->{$_})
              } CORE::keys %$self
        );
    }

    *pairs    = \&to_a;
    *to_array = \&to_a;
    *ca_lista = \&to_a;

    sub exists {
        my ($self, $key) = @_;
        Corvinus::Types::Bool::Bool->new(exists $self->{$key});
    }

    *contine   = \&exists;
    *are_cheie = \&exists;
    *has_key   = \&exists;
    *contains  = \&exists;

    sub flip {
        my ($self) = @_;

        my $new_hash = $self->new();
        @{$new_hash}{map { $_->get_value } CORE::values %$self} =
          (map           { Corvinus::Types::String::String->new($_) } CORE::keys %$self);

        $new_hash;
    }

    *inverseaza = \&flip;

    sub copy {
        my ($self) = @_;

        state $x = require Storable;
        Storable::dclone($self);
    }

    *copiaza = \&copy;

    sub dump {
        my ($self) = @_;

        $Corvinus::SPACES += $Corvinus::SPACES_INCR;

        # Sort the keys case insensitively
        my @keys = sort { (lc($a) cmp lc($b)) || ($a cmp $b) } CORE::keys(%$self);

        my $str = Corvinus::Types::String::String->new(
            "Dict(" . (
                @keys
                ? (
                   (@keys > 1 ? "\n" : '') . join(
                       ",\n",
                       map {
                           my $val = $self->{$_};
                           (@keys > 1 ? (' ' x $Corvinus::SPACES) : '')
                             . "${Corvinus::Types::String::String->new($_)->dump} => "
                             . (eval { $val->can('dump') } ? ${$val->dump} : defined($val) ? $val : 'nil')
                         } @keys
                     )
                     . (@keys > 1 ? ("\n" . (' ' x ($Corvinus::SPACES - $Corvinus::SPACES_INCR))) : '')
                  )
                : ""
              )
              . ")"
        );

        $Corvinus::SPACES -= $Corvinus::SPACES_INCR;
        $str;
    }

    {
        no strict 'refs';

        *{__PACKAGE__ . '::' . '+'}  = \&concat;
        *{__PACKAGE__ . '::' . '=='} = \&eq;
        *{__PACKAGE__ . '::' . '!='} = \&ne;
        *{__PACKAGE__ . '::' . ':'}  = \&new;
    }
};

1
