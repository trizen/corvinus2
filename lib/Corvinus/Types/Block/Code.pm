package Corvinus::Types::Block::Code {

    use 5.014;
    use parent qw(
      Corvinus::Object::Object
      Corvinus::Convert::Convert
      );

    sub new {
        my (undef, $sub) = @_;
        bless {code => $sub}, __PACKAGE__;
    }

    sub run {
        my ($self, @args) = @_;
        my @objs = $self->{code}->(@args);
        wantarray ? @objs : $objs[-1];
    }

    *executa = \&run;

    sub call {
        my ($self, @args) = @_;
        my @objs = $self->{code}->(@args);

        @objs == 1 && ref($objs[0]) eq 'Corvinus::Types::Block::Return'
          ? (
             wantarray
             ? @{$objs[0]{obj}}
             : $objs[0]{obj}[-1]
            )
          : (
             wantarray
             ? @objs
             : $objs[-1]
            );
    }

    {
        my $ref = \&UNIVERSAL::AUTOLOAD;

        sub get_value {
            my ($self) = @_;
            sub {
                my @args = @_;
                local *UNIVERSAL::AUTOLOAD = $ref;
                if (defined($a) || defined($b)) { push @args, $a, $b }
                elsif (defined($_)) { unshift @args, $_ }
                $self->call(@args);
            };
        }
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '*'} = \&repeat;
    }

    sub capture {
        my ($self) = @_;

        open my $str_h, '>:utf8', \my $str;
        if (defined(my $old_h = select($str_h))) {
            $self->run;
            close $str_h;
            select $old_h;
        }

        Corvinus::Types::String::String->new($str)->decode_utf8;
    }

    *cap = \&capture;

    sub repeat {
        my ($self, $num) = @_;

        $num = defined($num) ? $num->get_value : 1;

        return $self if $num < 1;

        if ($num < (-1 >> 1)) {

            $num = $num->numify if ref($num);

            foreach my $i (1 .. $num) {
                if (defined(my $res = $self->_run_code(Corvinus::Types::Number::Number->new($i)))) {
                    return $res;
                }
            }
        }
        else {

            $num = Math::BigFloat->new($num) if not ref($num);

            for (my $i = Math::BigFloat->new(1) ; $i->bcmp($num) <= 0 ; $i->binc) {
                if (defined(my $res = $self->_run_code(Corvinus::Types::Number::Number->new($i->copy)))) {
                    return $res;
                }
            }
        }

        $self;
    }

    sub _run_code {
        my ($self, @args) = @_;
        my $result = $self->run(@args);
        ref($result) eq 'Corvinus::Types::Block::Return' ? $result : ();
    }

    sub exec {
        my ($self) = @_;

        for (1) {
            $self->run;
            return $self;
        }

        Corvinus::Types::Black::Hole->new;
    }

    *do = \&exec;

    sub while {
        my ($self, $condition) = @_;
        Corvinus::Types::Block::While->new->while($condition, $self);
    }

    *cat_timp = \&while;

    sub loop {
        my ($self) = @_;

        while (1) {
            if (defined(my $res = $self->_run_code)) {
                return $res;
            }
        }

        $self;
    }

    *bucla = \&loop;

    sub if {
        my ($self, $bool) = @_;

        if ($bool) {
            return $self->run;
        }

        $bool;
    }

    *daca = \&if;

    sub fork {
        my ($self) = @_;

        state $x = require Storable;
        open(my $fh, '+>', undef);    # an anonymous temporary file
        my $fork = Corvinus::Types::Block::Fork->new(fh => $fh);

        my $pid = fork() // die "[FATAL ERROR]: cannot fork";
        if ($pid == 0) {
            srand();
            my $obj = $self->run;
            ref($obj) && Storable::store_fd($obj, $fh);
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    *bifurca = \&fork;

    sub pfork {
        my ($self) = @_;

        my $fork = Corvinus::Types::Block::Fork->new();

        my $pid = CORE::fork() // die "[FATAL ERROR]: cannot fork";
        if ($pid == 0) {
            srand();
            $self->run;
            exit 0;
        }

        $fork->{pid} = $pid;
        $fork;
    }

    sub thread {
        my ($self) = @_;
        state $x = do {
            require threads;
            *threads::get  = \&threads::join;
            *threads::wait = \&threads::join;
            1;
        };
        threads->create(sub { $self->run });
    }

    *thr = \&thread;

    sub for {
        my ($self, @args) = @_;
        Corvinus::Types::Block::For->new->for(@args, $self);
    }

    sub dump {
        $_[0];
    }
}

1;
