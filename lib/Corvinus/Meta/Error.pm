package Corvinus::Meta::Error {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
};

1;
