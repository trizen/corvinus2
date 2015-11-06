package Corvinus::Module::OO {

    use 5.014;
    our $AUTOLOAD;

    sub __NEW__ {
        my (undef, $module) = @_;
        bless {module => $module}, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub AUTOLOAD {
        my ($self, @arg) = @_;
        my ($method) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        if ($method eq '') {
            return Corvinus::Module::Func->__NEW__($self->{module});
        }

        my @args = (
            @arg
            ? (
               map {
                   local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
                   ref($_) eq __PACKAGE__ ? $_->{module}
                     : index(ref($_), 'Corvinus::') == 0 ? $_->get_value
                     : ref($_) eq 'REF' ? ${$_}
                     : $_
                 } @arg
              )
            : ()
        );

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            $self->{module}->$method(@args);
        };

        if (@results > 1) {
            return (map { Corvinus::Perl::Perl->to_corvinus($_) } @results);
        }

        Corvinus::Perl::Perl->to_corvinus($results[0]);
    }
}

1;
