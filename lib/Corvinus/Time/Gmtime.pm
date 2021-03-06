package Corvinus::Time::Gmtime {

    use 5.014;
    use parent qw(
      Corvinus::Object::Object
      );

    use overload
      q{""}   => \&ctime,
      q{bool} => sub { $_[0]->{sec} };

    sub new {
        my (undef, $sec) = @_;

        bless {
               sec  => $sec,
               time => [map { Corvinus::Types::Number::Number->new($_) } gmtime($sec)],
              },
          __PACKAGE__;
    }

    {
        no strict 'refs';

        # The order matters!
        my @names = qw(sec min hour mday mon year wday yday);

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
        Corvinus::Types::String::String->new(scalar gmtime($self->{sec}));
    }

    sub strftime {
        my ($self, $format) = @_;

        state $x = require POSIX;
        Corvinus::Types::String::String->new(POSIX::strftime($format->get_value, @{$self->{time}}));
    }

    *format = \&strftime;
    *strf   = \&strftime;
    *timpf  = \&strftime;

};

1;
