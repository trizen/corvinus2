package Corvinus::Variable::NamedParam {

    #use overload q{""} => \&dump;

    sub new {
        my (undef, $name, @args) = @_;
        bless [$name, \@args], __PACKAGE__;
    }

    sub dump {
        my ($self) = @_;
        my ($name, $args) = @{$self};
        my @args = map {
            ref($_) && eval { $_->can('dump') }
              ? $_->dump
              : $_
        } @{$args};
        Corvinus::Types::String::String->new("$name: " . (@args == 1 ? $args[0] : ('(' . join(', ', @args) . ')')));
    }
}

1;
