package Corvinus::Perl::Perl {

    use 5.014;

    sub new {
        bless {}, __PACKAGE__;
    }

    sub to_corvinus {
        my ($self, $data) = @_;

        my %refs;

        my $guess_type;
        $guess_type = sub {
            my ($val) = @_;

            my $ref = CORE::ref($val);
            if (not defined $val) {
                return undef;
            }

            if ($ref eq 'ARRAY') {
                my $array = $refs{$val} //= Corvinus::Types::Array::Array->new;
                foreach my $item (@{$val}) {
                    $array->push(
                                 ref($item) eq 'ARRAY' && $item eq $val
                                 ? $array
                                 : $guess_type->($item)
                                );
                }
                return $array;
            }

            if ($ref eq 'HASH') {
                my $hash = $refs{$val} //= Corvinus::Types::Hash::Hash->new;
                foreach my $key (keys %{$val}) {
                    my $value = $val->{$key};
                    $hash->append(
                                    $key, ref($value) eq 'HASH' && $value eq $val
                                  ? $hash
                                  : $guess_type->($value)
                                 );
                }
                return $hash;
            }

            if ($ref eq 'Regexp') {
                return Corvinus::Types::Regex::Regex->new($val);
            }

            if ($ref eq '') {
                state $x = require Scalar::Util;

                if (Scalar::Util::looks_like_number($val)) {
                    return Corvinus::Types::Number::Number->new($val);
                }

                return Corvinus::Types::String::String->new($val);
            }

            # Return an OO object when $val is blessed
            state $x = require Scalar::Util;
            if (defined Scalar::Util::blessed($val)) {
                return Corvinus::Module::OO->__NEW__($val);
            }

            $val;
        };

        $guess_type->($data);
    }

    *to_corvin = \&to_corvinus;

    sub eval {
        my ($self, $perl_code) = @_;
        $self->to_corvinus(eval $perl_code->get_value);
    }
};

1
