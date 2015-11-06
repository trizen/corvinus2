package Corvinus::Types::Array::List {

    use parent qw(
      Corvinus::Object::Object
      );

    sub new {
        shift;
        bless \@_, __PACKAGE__;
    }
};

1
