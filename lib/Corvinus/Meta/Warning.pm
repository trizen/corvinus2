package Corvinus::Meta::Warning {

    sub new {
        my (undef, %opt) = @_;
        bless \%opt, __PACKAGE__;
    }
};

1;
