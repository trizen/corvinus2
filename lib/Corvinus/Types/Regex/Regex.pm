package Corvinus::Types::Regex::Regex {

    use 5.014;

    use re 'eval';    # XXX: do we really want this?

    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    use overload q{""} => \&get_value;

    sub new {
        my (undef, $regex, $mode) = @_;

        if (ref($mode) eq 'Corvinus::Types::String::String') {
            $mode = $mode->get_value;
        }

        my $global_mode = defined($mode) && $mode =~ tr/g//d;

        if (not defined $mode or $mode eq '') {
            $mode = q{^};
        }

        my $compiled_re = qr{(?$mode:$regex)};

        bless {
               regex  => $compiled_re,
               global => $global_mode,
               pos    => 0,
              },
          __PACKAGE__;
    }

    *call = \&new;

    sub get_value { $_[0]{regex} }

    sub to_regex { $_[0] }
    *to_re = \&to_regex;

    sub match {
        my ($self, $object, $pos) = @_;

        $object //= Corvinus::Types::String::String->new('');

        if ($object->SUPER::isa('ARRAY')) {
            my $match;
            foreach my $item (@{$object}) {
                $match = $self->match($item);
                $match->matched && return $match;
            }
            return $match // $self->match(Corvinus::Types::String::String->new);
        }

        Corvinus::Types::Regex::Match->new(
                                        obj  => $object->get_value,
                                        self => $self,
                                        pos  => defined($pos) ? $pos->get_value : undef,
                                       );
    }

    sub gmatch {
        my ($self, $obj, $pos) = @_;
        local $self->{global} = 1;
        $self->match($obj, $pos);
    }

    sub dump {
        my ($self) = @_;

        my $str = "$self->{regex}";

        my $flags = '';
        if ($str =~ s/\(\?\^u:\(\?(?:\^|(.*?))://) {
            $flags = $1 // '';
            chop $str;
            chop $str;
        }

        Corvinus::Types::String::String->new('/' . $str =~ s{/}{\\/}gr . '/' . $flags . ($self->{global} ? 'g' : ''));
    }

    *to_s = \&dump;

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '=~'} = \&match;
    }

};

1
