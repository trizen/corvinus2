package Corvinus::Types::Grapheme::Graphemes {

    use parent qw(
      Corvinus::Types::Array::Array
      );

    use overload q{""} => \&dump;

    sub new {
        my (undef, @graphemes) = @_;
        bless \@graphemes, __PACKAGE__;
    }

    sub call {
        my ($self, @strings) = @_;
        $self->new(map { Corvinus::Types::Grapheme::Grapheme->new($_) } map { /\X/g } @strings);
    }

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Grafeme(' . join(', ', map { $_->dump->get_value } @{$self}) . ')');
    }
};

1
