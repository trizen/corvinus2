package Corvinus::Module::Func {

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

        my ($func) = ($AUTOLOAD =~ /^.*[^:]::(.*)$/);

        my @args = (
            @arg
            ? (
               map {
                   local $Corvinus::Types::Number::Number::GET_PERL_VALUE = 1;
                   index(ref($_), 'Corvinus::') == 0
                     ? $_->get_value
                     : $_
                 } @arg
              )
            : ()
        );

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            ($self->{module} . '::' . $func)->(@args);
        };

        if (@results > 1) {
            return (map { Corvinus::Perl::Perl->to_corvinus($_) } @results);
        }

        Corvinus::Perl::Perl->to_corvinus($results[0]);
    }
}

1;
