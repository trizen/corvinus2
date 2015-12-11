package Corvinus::Types::Char::Char {

    use parent qw(
      Corvinus::Convert::Convert
      Corvinus::Types::String::String
      );

    sub new {
        my (undef, $char) = @_;
        ref($char) && return $char->to_char;
        $char //= "\0";
        bless \$char, __PACKAGE__;
    }

    sub call {
        my ($self, $char) = @_;
        $self->new(chr ord $char);
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new(q{Caracter(} . $self->to_s->dump->get_value . q{)});
    }
};

1
