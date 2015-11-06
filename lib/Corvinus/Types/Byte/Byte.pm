package Corvinus::Types::Byte::Byte {

    use 5.014;
    use parent qw(
      Corvinus::Types::Number::Number
      );

    sub new {
        my (undef, $byte) = @_;
        bless \Math::BigInt->new($byte), __PACKAGE__;
    }

    *call = \&new;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Byte(' . $self->get_value . ')');
    }
};

1
