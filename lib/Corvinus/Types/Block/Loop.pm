package Corvinus::Types::Block::Loop {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

}

1;
