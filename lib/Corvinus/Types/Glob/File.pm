package Corvinus::Types::Glob::File {

    use 5.014;

    use parent qw(
      Corvinus::Convert::Convert
      Corvinus::Types::String::String
      );

    sub new {
        my (undef, $file) = @_;
        if (@_ > 2) {
            state $x = require File::Spec;
            $file = File::Spec->catfile(map { ref($_) ? $_->to_file->get_value : $_ } @_[1 .. $#_]);
        }
        elsif (ref($file) && ref($file) ne 'SCALAR') {
            return $file->to_file;
        }
        bless \$file, __PACKAGE__;
    }

    *call = \&new;
    *nou  = \&new;

    sub get_value { ${$_[0]} }
    sub to_file   { $_[0] }

    sub get_constant {
        my ($self, $str) = @_;

        my $name = $str->get_value;
        state $CACHE = {};

        if (exists $CACHE->{$name}) {
            return $CACHE->{$name};
        }

        state $x = require Fcntl;
        my $call = \&{'Fcntl' . '::' . $name};

        if (defined(&$call)) {
            return $CACHE->{$name} = Corvinus::Types::Number::Number->new($call->());
        }

        warn qq{[WARN] Inexistent File constant "$name"!\n};
        return;
    }

    sub touch {
        my ($self, @args) = @_;
        $self->open('>>', @args);
    }

    *make    = \&touch;
    *mkfile  = \&touch;
    *create  = \&touch;
    *creeaza = \&touch;

    sub size {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Number::Number->new(-s $self->get_value);
    }

    *marime = \&size;

    sub compare {
        my ($self, $file) = @_;
        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }
        state $x = require File::Compare;
        Corvinus::Types::Number::Number->new(File::Compare::compare($self->get_value, $file->get_value));
    }

    *compara = \&compare;

    sub exists {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-e $self->get_value);
    }

    *exista = \&exists;

    sub is_empty {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-z $self->get_value);
    }

    *e_gol = \&is_empty;

    sub is_directory {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-d $self->get_value);
    }

    *e_dosar = \&is_directory;
    *is_dir  = \&is_directory;

    sub is_link {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new(-l $self->get_value);
    }

    *e_link = \&e_link;

    sub readlink {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::String::String->new(CORE::readlink($self->get_value));
    }

    *read_link    = \&readlink;
    *citeste_link = \&readlink;

    sub is_socket {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-S $self->get_value);
    }

    *e_socket = \&is_socket;

    sub is_block {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-b $self->get_value);
    }

    *e_block = \&is_block;

    sub is_char_device {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-c $self->get_value);
    }

    *e_dispozitiv_caracter = \&is_char_device;

    sub is_readable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-r $self->get_value);
    }

    *poate_fi_citit = \&is_readable;

    sub is_writeable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-w $self->get_value);
    }

    *poate_fi_scris = \&is_writeable;

    sub has_setuid_bit {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-u $self->get_value);
    }

    sub has_setgid_bit {
        my ($self) = @_;
        Corvinus::Types::Bool::Bool->new(-g $self->get_value);
    }

    sub has_sticky_bit {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-k $self->get_value);
    }

    sub modification_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-M $self->get_value);
    }

    sub access_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-A $self->get_value);
    }

    sub change_time_days_diff {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-C $self->get_value);
    }

    sub is_executable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-x $self->get_value);
    }

    *e_executabil = \&is_executable;

    sub is_owned {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-o $self->get_value);
    }

    *e_detinut = \&is_owned;

    sub is_real_readable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-R $self->get_value);
    }

    *poate_fi_super_citit = \&is_real_readable;

    sub is_real_writeable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-W $self->get_value);
    }

    *poate_fi_super_scris = \&is_real_writeable;

    sub is_real_executable {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-X $self->get_value);
    }

    *e_super_executabil = \&is_real_executable;

    sub is_real_owned {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-O $self->get_value);
    }

    *e_super_detinut = \&is_real_owned;

    sub is_binary {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-B $self->get_value);
    }

    *e_binar = \&is_binary;

    sub is_text {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-T $self->get_value);
    }

    *e_text = \&is_text;

    sub is_file {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(-f $self->get_value);
    }

    *e_fisier = \&is_file;

    sub name {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::String::String->new($self->get_value);
    }

    *nume = \&name;

    sub basename {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        state $x = require File::Basename;
        Corvinus::Types::String::String->new(File::Basename::basename($self->get_value));
    }

    *base         = \&basename;
    *base_name    = \&basename;
    *nume_de_baza = \&basename;

    sub dirname {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        state $x = require File::Basename;
        Corvinus::Types::Glob::Dir->new(File::Basename::dirname($self->get_value));
    }

    *dir      = \&dirname;
    *dir_name = \&dirname;
    *dosar    = \&dirname;

    sub is_absolute {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Spec;
        Corvinus::Types::Bool::Bool->new(File::Spec->file_name_is_absolute($self->get_value));
    }

    *is_abs = \&is_absolute;

    sub abs_name {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);

        state $x = require File::Spec;
        $self->new(File::Spec->rel2abs($self->get_value));
    }

    *abs           = \&abs_name;
    *absname       = \&abs_name;
    *rel2abs       = \&abs_name;
    *cale_absoluta = \&abs_name;
    *nume_absolut  = \&abs_name;

    sub rel_name {
        my ($self, $base) = @_;
        state $x = require File::Spec;
        $self->new(File::Spec->rel2abs($self->get_value, defined($base) ? $base->get_value : ()));
    }

    *rel           = \&rel_name;
    *relname       = \&rel_name;
    *abs2rel       = \&rel_name;
    *cale_relativa = \&rel_name;
    *nume_relativ  = \&rel_name;

    sub rename {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        Corvinus::Types::Bool::Bool->new(CORE::rename($self->get_value, $file->get_value));
    }

    *redenumeste = \&rename;

    sub move {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        state $x = require File::Copy;
        Corvinus::Types::Bool::Bool->new(File::Copy::move($self->get_value, $file->get_value));
    }

    *mv   = \&move;
    *muta = \&move;

    sub copy {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        state $x = require File::Copy;
        Corvinus::Types::Bool::Bool->new(File::Copy::copy($self->get_value, $file->get_value));
    }

    *cp      = \&copy;
    *copiaza = \&copy;

    sub edit {
        my ($self, $code) = @_;

        if (@_ == 3) {
            ($self, $code) = ($code, $_[2]);
        }

        my @lines;
        open(my $fh, '+<:utf8', $self->get_value) || return Corvinus::Types::Bool::Bool->false;
        while (defined(my $line = <$fh>)) {
            push @lines, $code->run(Corvinus::Types::String::String->new($line));
        }

        truncate($fh, 0) || do {
            warn "[WARN] Can't truncate file `$self->get_value': $!";
            return;
        };

        seek($fh, 0, 0) || do {
            warn "[WARN] Can't seek the begining of file `$self->get_value': $!";
            return;
        };

        Corvinus::Types::Bool::Bool->new(
            do {
                local $, = q{};
                local $\ = q{};
                print $fh @lines;
                close $fh;
              }
        );
    }

    *editeaza = \&edit;

    sub open {
        my ($self, $mode, $fh_ref, $err_ref) = @_;

        if (ref $mode) {
            $mode = $mode->get_value;
        }

        my $success = CORE::open(my $fh, $mode, $self->get_value);
        my $error   = $!;
        my $fh_obj  = Corvinus::Types::Glob::FileHandle->new(fh => $fh, self => $self);

        if (defined $fh_ref) {
            ${$fh_ref} = $fh_obj;

            return $success
              ? Corvinus::Types::Bool::Bool->true
              : do {
                defined($err_ref) && do { ${$err_ref} = Corvinus::Types::String::String->new($error) };
                Corvinus::Types::Bool::Bool->false;
              };
        }

        $success ? $fh_obj : ();
    }

    *deschide = \&open;

    sub open_r {
        my ($self, @rest) = @_;
        $self->open('<:utf8', @rest);
    }

    *open_read       = \&open_r;
    *deschide_citire = \&open_r;
    *deschide_c      = \&open_r;

    sub open_w {
        my ($self, @rest) = @_;
        $self->open('>:utf8', @rest);
    }

    *open_write       = \&open_w;
    *deschide_scriere = \&open_w;
    *deschide_s       = \&open_w;

    sub open_a {
        my ($self, @rest) = @_;
        $self->open('>>:utf8', @rest);
    }

    *open_append       = \&open_a;
    *deschide_adaugare = \&open_a;
    *deschide_a        = \&open_a;

    sub open_rw {
        my ($self, @rest) = @_;
        $self->open('+<:utf8', @rest);
    }

    *open_read_write = \&open_rw;
    *deschide_cs     = \&open_rw;

    sub opendir {
        my ($self, @rest) = @_;
        Corvinus::Types::Glob::Dir->new($self->get_value)->open(@rest);
    }

    *deschide_dosar    = \&opendir;
    *deschide_ca_dosar = \&opendir;

    sub sysopen {
        my ($self, $var_ref, $mode, $perm) = @_;

        my $success = sysopen(my $fh, $self->get_value, $mode->get_value, defined($perm) ? $perm->get_value : 0666);

        if ($success) {
            ${$var_ref} = Corvinus::Types::Glob::FileHandle->new(fh => $fh, self => $self);
        }

        Corvinus::Types::Bool::Bool->new($success);
    }

    sub stat {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Glob::Stat->stat($self->get_value, $self);
    }

    sub lstat {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Glob::Stat->lstat($self->get_value, $self);
    }

    sub chown {
        my ($self, $uid, $gid) = @_;

        if (@_ == 4) {
            ($self, $uid, $gid) = ($uid, $gid, $_[3]);
        }

        Corvinus::Types::Bool::Bool->new(CORE::chown($uid->get_value, $gid->get_value, $self->get_value));
    }

    sub chmod {
        my ($self, $permission) = @_;

        if (@_ == 3) {
            ($self, $permission) = ($permission, $_[2]);
        }

        Corvinus::Types::Bool::Bool->new(CORE::chmod($permission->get_value, $self->get_value));
    }

    sub utime {
        my ($self, $atime, $mtime) = @_;

        if (@_ == 4) {
            ($self, $atime, $mtime) = ($atime, $mtime, $_[3]);
        }

        Corvinus::Types::Bool::Bool->new(CORE::utime($atime->get_value, $mtime->get_value, $self->get_value));
    }

    sub truncate {
        my ($self, $length) = @_;

        if (@_ == 3) {
            ($self, $length) = ($length, $_[2]);
        }

        my $len = defined($length) ? $length->get_value : 0;
        Corvinus::Types::Bool::Bool->new(CORE::truncate($self->get_value, $len));
    }

    sub unlink {
        my ($self, @args) = @_;
        @args
          ? Corvinus::Types::Number::Number->new(CORE::unlink(map { $_->get_value } @args))
          : Corvinus::Types::Bool::Bool->new(CORE::unlink($self->get_value));
    }

    *delete = \&unlink;
    *remove = \&unlink;
    *sterge = \&unlink;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new(
                                            'Fisier(' . ${Corvinus::Types::String::String->new($self->get_value)->dump} . ')');
    }

    # Path split
    *split = \&Corvinus::Types::Glob::Dir::split;

};

1
