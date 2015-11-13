package Corvinus::Types::Block::Do {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }

}

1;
