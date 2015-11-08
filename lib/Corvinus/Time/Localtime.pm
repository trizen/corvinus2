package Corvinus::Time::Localtime {

    use 5.014;
    use parent qw(
      Corvinus::Time::Gmtime
      );

    use overload
      q{""}   => \&ctime,
      q{bool} => sub { $_[0]->{sec} };

    sub new {
        my (undef, $sec) = @_;

        bless {
               sec  => $sec,
               time => [map { Corvinus::Types::Number::Number->new($_) } localtime($sec)],
              },
          __PACKAGE__;
    }

    {
        no strict 'refs';

        # The order matters!
        my @names = qw(sec min hour mday mon year wday yday isdst);

        foreach my $i (0 .. $#names) {
            *{__PACKAGE__ . '::' . $names[$i]} = sub {
                $_[0]{time}[$i];
            };
        }

        *day         = \&mday;
        *zi          = \&mday;
        *month       = \&mon;
        *luna        = \&mon;
        *minute      = \&min;
        *minut       = \&min;
        *second      = \&sec;
        *secunda     = \&sec;
        *month_day   = \&mday;
        *ziua_lunii  = \&mday;
        *week_day    = \&wday;
        *ziua_sapt   = \&wday;
        *year_day    = \&yday;
        *ziua_anului = \&yday;
    }

    sub ctime {
        my ($self) = @_;
        Corvinus::Types::String::String->new(scalar localtime($self->{sec}));
    }
};

1;
