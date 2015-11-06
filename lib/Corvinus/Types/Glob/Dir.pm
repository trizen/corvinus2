package Corvinus::Types::Glob::Dir {

    use 5.014;

    use parent qw(
      Corvinus::Convert::Convert
      Corvinus::Types::Glob::File
      );

    sub new {
        my (undef, $dir) = @_;
        if (@_ > 2) {
            state $x = require File::Spec;
            $dir = File::Spec->catdir(map { ref($_) ? $_->to_dir->get_value : $_ } @_[1 .. $#_]);
        }
        elsif (ref($dir)) {
            return $dir->to_dir;
        }
        bless \$dir, __PACKAGE__;
    }

    *call = \&new;
    *nou = \&new;

    sub get_value { ${$_[0]} }
    sub to_dir    { $_[0] }

    sub root {
        my ($self) = @_;

        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->rootdir);
    }

    *radacina = \&root;

    sub home {
        my ($self) = @_;

        my $home =
             $ENV{HOME}
          || $ENV{LOGDIR}
          || (getpwuid($<))[7]
          || `echo -n ~`;

        defined($home) ? __PACKAGE__->new($home) : do {
            state $x = require File::HomeDir;
            __PACKAGE__->new(File::HomeDir->my_home);
        };
    }

    *acasa = \&home;

    sub tmp {
        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->tmpdir);
    }

    *temp = \&tmp;
    *temporar = \&tmp;

    sub cwd {
        state $x = require Cwd;
        __PACKAGE__->new(Cwd::getcwd());
    }

    *curent = \&cwd;

    sub pwd {
        state $x = require File::Spec;
        __PACKAGE__->new(File::Spec->curdir);
    }

    sub split {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Spec;
        Corvinus::Types::Array::Array->new(map { Corvinus::Types::String::String->new($_) } File::Spec->splitdir($self->get_value));
    }

    *imparte = \&split;

    # Returns the parent of the directory
    sub parent {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Basename;
        __PACKAGE__->new(File::Basename::dirname($self->get_value));
    }

    *parinte = \&parent;

    # Remove the directory (works only on empty dirs)
    sub remove {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(rmdir $self->get_value);
    }

    *delete = \&remove;
    *unlink = \&remove;
    *sterge = \&remove;

    # Remove the directory with all its content
    sub remove_tree {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Path;
        Corvinus::Types::Bool::Bool->new(File::Path::remove_tree($self->get_value));
    }

    *sterge_tot = \&remove_tree;

    # Create directory without parents
    sub create {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(mkdir($self->get_value));
    }

    *make  = \&create;
    *mkdir = \&create;
    *creeaza = \&create;

    # Create the directory (with parents, if needed)
    sub create_tree {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        state $x = require File::Path;
        my $path = $self->get_value;
        -d $path
          ? Corvinus::Types::Bool::Bool->true
          : Corvinus::Types::Bool::Bool->new(File::Path::make_path($path));
    }

    *make_tree = \&create_tree;
    *mktree    = \&create_tree;
    *make_path = \&create_tree;
    *mkpath    = \&create_tree;
    *creeaza_tot = \&create_tree;

    sub open {
        my ($self, $fh_ref, $err_ref) = @_;

        my $success = opendir(my $dir_h, $self->get_value);
        my $error   = $!;
        my $dir_obj = Corvinus::Types::Glob::DirHandle->new(dir_h => $dir_h, dir => $self);

        if (defined $fh_ref) {
            ${$fh_ref} = $dir_obj;

            return $success
              ? Corvinus::Types::Bool::Bool->true
              : do {
                defined($err_ref) && do { ${$err_ref} = Corvinus::Types::String::String->new($error) };
                Corvinus::Types::Bool::Bool->false;
              };
        }

        $success ? $dir_obj : ();
    }

    *open_r = \&open;
    *deschide = \&open;

    sub open_w  { ... }
    sub open_rw { ... }

    sub chdir {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(chdir($self->get_value));
    }

    *schimba = \&chdir;

    sub chroot {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        Corvinus::Types::Bool::Bool->new(chroot($self->get_value));
    }

    sub concat {
        my ($self, $file) = @_;

        if (@_ == 3) {
            ($self, $file) = ($file, $_[2]);
        }

        state $x = require File::Spec;
        $file->new(File::Spec->catdir($self->get_value, $file->get_value));
    }

    *catfile = \&concat;
    *uneste = \&concat;

    sub is_empty {
        my ($self) = @_;
        @_ == 2 && ($self = $_[1]);
        CORE::opendir(my $dir_h, $self->get_value) || return;
        while (defined(my $file = CORE::readdir $dir_h)) {
            next if $file eq '.' or $file eq '..';
            return Corvinus::Types::Bool::Bool->false;
        }
        Corvinus::Types::Bool::Bool->true;
    }

    *e_gol = \&is_empty;

    sub dump {
        my ($self) = @_;
        Corvinus::Types::String::String->new('Dir(' . ${Corvinus::Types::String::String->new($self->get_value)->dump} . ')');
    }

    {
        no strict 'refs';
        *{__PACKAGE__ . '::' . '+'} = \&concat;
    }

};

1
