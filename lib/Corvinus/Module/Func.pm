package Corvinus::Module::Func {

    use 5.014;
    our $AUTOLOAD;

    sub __NEW__ {
        my (undef, $module) = @_;
        bless {module => $module}, __PACKAGE__;
    }

    sub DESTROY {
        return;
    }

    sub __LOCATE__ {
        my ($self, $name) = @_;

        no strict 'refs';
        my $mod_space = \%{$self->{module} . '::'};

        if (exists $mod_space->{$name}) {
            return $self->{module} . '::' . $name;
        }

        return;
    }

    sub _var {
        my ($self, $name) = @_;

        if (defined(my $type = $self->__LOCATE__($name))) {
            no strict 'refs';
            return ${$type};
        }

        warn qq{[WARN] Variable '$name' is not exported by module: "$self->{module}"!\n};
        return;
    }

    sub _arr {
        my ($self, $name) = @_;

        if (defined(my $type = $self->__LOCATE__($name))) {
            no strict 'refs';
            return Corvinus::Types::Array::Array->new(@{$type});
        }

        warn qq{[WARN] Array '$name' is not exported by module: "$self->{module}"!\n};
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
                   index(ref($_), 'Corvinus::') == 0 ? $_->get_value
                     : ref($_) eq 'REF' ? ${$_}
                     : $_
                 } @arg
              )
            : ()
        );

        my @results = do {
            local *UNIVERSAL::AUTOLOAD;
            (\&{$self->{module} . '::' . $func})->(@args);
        };

        if (@results > 1) {
            return (map { Corvinus::Perl::Perl->to_corvinus($_) } @results);
        }

        Corvinus::Perl::Perl->to_corvinus($results[0]);
    }
}

1;
