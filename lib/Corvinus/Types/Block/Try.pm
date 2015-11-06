package Corvinus::Types::Block::Try {

    use 5.014;

    sub new {
        bless {catch => 0}, __PACKAGE__;
    }

    sub try {
        my ($self, $code) = @_;

        my $error = 0;
        local $SIG{__WARN__} = sub { $self->{type} = 'warning'; $self->{msg} = $_[0]; $error = 1 };
        local $SIG{__DIE__}  = sub { $self->{type} = 'error';   $self->{msg} = $_[0]; $error = 1 };

        $self->{val} = eval { $code->run };

        if ($@ || $error) {
            $self->{catch} = 1;
        }

        $self;
    }

    *incearca = \&try;

    sub catch {
        my ($self, $code) = @_;

        $self->{catch}
          ? $code->run(Corvinus::Types::String::String->new($self->{type}),
                       Corvinus::Types::String::String->new($self->{msg} =~ s/^\[.*?\]\h*//r)->chomp)
          : $self->{val};
    }

    *prinde = \&catch;

};

1
