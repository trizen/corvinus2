package Corvinus::Types::Char::Chars {

    use parent qw(
      Corvinus::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @chars) = @_;
        bless \@chars, __PACKAGE__;
    }

    sub call {
        my ($self, @strings) = @_;
        $self->new(map { Corvinus::Types::Char::Char->new($_) } split(//, join('', @strings)));
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Caractere(' . join(', ', map { $_->dump->get_value } @{$self}) . ')');
    }
};

1
