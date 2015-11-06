#!/usr/bin/perl

use utf8;
use 5.010;
use strict;
use autodie;
use warnings;

use lib qw(.);
use open IO => ':encoding(UTF-8)';

use File::Find qw(find);
use List::Util qw(first);
use File::Basename qw(basename);
use File::Spec::Functions qw(curdir splitdir catfile);

my $dir = shift() // die "usage: $0 lib\n";

my %esc = (
           '>' => 'gt',
           '<' => 'lt',
          );

my %ignored_subs = map { $_ => 1 } qw<
  BEGIN
  ISA
  AUTOLOAD
  DESTROY
  >;

my %ignored_methods = (
                       'Corvinus'                          => [qw(new)],
                       'Corvinus::Types::Block::Return'    => [qw(new)],
                       'Corvinus::Types::Block::Break'     => [qw(new)],
                       'Corvinus::Variable::Variable'      => [qw(new)],
                       'Corvinus::Variable::Ref'           => [qw(new)],
                       'Corvinus::Variable::Local'         => [qw(new)],
                       'Corvinus::Variable::Init'          => [qw(new)],
                       'Corvinus::Variable::InitLocal'     => [qw(new)],
                       'Corvinus::Sys::Sys'                => [qw(new)],
                       'Corvinus::Math::Math'              => [qw(new)],
                       'Corvinus::Time::Localtime'         => [qw(new)],
                       'Corvinus::Time::Gmtime'            => [qw(new)],
                       'Corvinus::Types::Nil::Nil'         => [qw(new)],
                       'Corvinus::Types::Bool::If'         => [qw(new)],
                       'Corvinus::Types::Bool::While'      => [qw(new)],
                       'Corvinus::Types::Bool::Ternary'    => [qw(new)],
                       'Corvinus::Types::Glob::DirHandle'  => [qw(new)],
                       'Corvinus::Types::Glob::FileHandle' => [qw(new)],
                       'Corvinus::Types::Glob::Backtick'   => [qw(new)],
                       'Corvinus::Types::Glob::Stat'       => [qw(new)],
                       'Corvinus::Types::Block::For'       => [qw(new)],
                       'Corvinus::Types::Block::Switch'    => [qw(new)],
                       'Corvinus::Types::Block::Try'       => [qw(new)],
                       'Corvinus::Types::Block::Code'      => [qw(new)],
                       'Corvinus::Types::Block::Given'     => [qw(new)],
                       'Corvinus::Types::Block::Continue'  => [qw(new)],
                       'Corvinus::Types::Regex::Match'     => [qw(new)],
                       'Corvinus::Types::Regex::Regex'     => [qw(new)],
                       'Corvinus::Types::Black::Hole'      => [qw(new)],
                      );

my %ignored_modules = map { $_ => 1 } qw (
  Corvinus::Exec
  Corvinus::Parser
  Corvinus::Optimizer
  Corvinus::Types::Array::HCArray
  Corvinus::Types::Array::List
  Corvinus::Types::Number::NumberFast
  Corvinus::Types::Number::NumberInt
  Corvinus::Types::Number::NumberRat
  Corvinus::Variable::LazyMethod
  Corvinus::Variable::ClassVar
  Corvinus::Deparse::Corvinus
  Corvinus::Deparse::Perl
  );

my $name = basename($dir);
if ($name ne 'lib') {
    die "error: '$dir' is not a lib directory!";
}

chdir $dir;

find {
    no_chdir => 1,
    wanted   => sub {
        /\.pm\z/ && -f && process_file($_);
    },
} => curdir();

sub parse_pod_file {
    my ($file) = @_;

    my %data;
    open my $fh, '<', $file;

    my $meth = 0;
    while (defined(my $line = <$fh>)) {

        if ($meth) {
            my $sec = '';
            $sec .= $line;

            until ($line =~ /^=cut\b/ or eof($fh)) {
                $sec .= ($line = <$fh>);
            }

            if ($sec =~ /^=head2\h+(.*\S)/m) {
                $data{$1} = $sec;
            }
        }
        else {
            $data{__HEADER__} .= $line;
        }

        if ($meth == 0 && $line =~ /^=head1\h+METHODS/) {
            $meth = 1;
        }
    }
    close $fh;

    return \%data;
}

sub process_file {
    my ($file) = @_;

    my (undef, @parts) = splitdir($file);
    require join('/', @parts);

    $parts[-1] =~ s{\.pm\z}{};

    my $module = join('::', @parts);

    exists($ignored_modules{$module})
      && return;

    my $mod_methods = do {
        no strict 'refs';
        \%{$module . '::'};
    };

    my %subs;
    foreach my $sub (keys %{$mod_methods}) {

        next if $sub eq 'get_value';
        next if $sub =~ /^[(_]/;
        next if exists $ignored_subs{$sub};

        my $code;

        if (defined &{$module . '::' . $sub}) {
            $code = \&{$module . '::' . $sub};
        }
        else {
            next;
        }

        if (exists $ignored_methods{$module}) {
            if (first { $_ eq $sub } @{$ignored_methods{$module}}) {
                next;
            }
        }

        push @{$subs{$code}{aliases}}, $sub;
    }

    while (my ($key, $value) = each %subs) {

        my @sorted =
          sort { length($a =~ tr/_//dr) <=> length($b =~ tr/_//dr) or lc($a) cmp lc($b) or $b cmp $a } @{$value->{aliases}};

        $value->{name} = shift @sorted;
        @{$value->{aliases}} = @sorted;

        my $sub       = $value->{name};
        my $orig_name = $sub;
        my $is_method = lc($sub) ne uc($sub);

        $sub =~ s{([<>])}{E<$esc{$1}>}g;

        my $doc = $is_method ? <<"__POD__" : <<"__POD2__";

=head2 $orig_name

$parts[-1].$sub() -> I<Obj>

Return the
__POD__

=head2 $orig_name

I<Obj> B<$sub> I<Obj> -> I<Obj>

Return the
__POD2__

        if (@{$value->{aliases}}) {
            $doc .= "\nAliases: " . join(
                ", ",
                map {
                    my $sub = $_;
                    $sub =~ s{([<>])}{E<$esc{$1}>}g;
                    lc($sub) eq uc($sub) ? "I<$sub()>" : "I<$sub>";
                  } @{$value->{aliases}}
              )
              . "\n";
        }

        $doc .= "\n=cut\n";

        $subs{$key}{doc} //= $doc;
    }

    my @keys = keys %subs;
    if ($#keys == -1) {
        warn "[!] No method found for module: $module\n";
        return;
    }

    my $pod_file = catfile(@parts) . '.pod';

    say "** Writing: $pod_file";

    my $pod_data = {};

    (-e $pod_file) && do {
        $pod_data = parse_pod_file($pod_file);
    };

    while (my ($key, $value) = each %subs) {

        my $alias;
        if (exists $value->{aliases}) {
            $alias = first {
                exists($pod_data->{$_})
            }
            @{$value->{aliases}};
        }

        if ($alias // exists($pod_data->{$value->{name}})) {
            my $doc = $pod_data->{$alias // $value->{name}};
            if (not $doc =~ /^Return the$/m) {
                $subs{$key}{doc} = $doc;
            }
        }
    }

    open my $fh, '>', $pod_file;

    my $header = $pod_data->{__HEADER__};

    if (not defined($header) or $header =~ /^This object is \.\.\.$/m) {
        $header = <<"HEADER";

=encoding utf8

=head1 NAME

$module

=head1 DESCRIPTION

This object is ...

=head1 SYNOPSIS

var obj = $parts[-1].new(...);

HEADER

        my @isa = @{exists($mod_methods->{ISA}) ? $mod_methods->{ISA} : []};

        if (@isa) {
            $header .= <<'HEADER';

=head1 INHERITS

Inherits methods from:

HEADER

            $header .= join("\n", map { "\t* $_" } @isa);
            $header .= "\n\n";
        }

        $header .= <<"HEADER";
=head1 METHODS

HEADER
    }

    # Print the header
    print {$fh} $header;

    # Print the methods
    foreach my $method (
        sort {
                 (lc($a->{name} =~ tr/_//dr) cmp lc($b->{name} =~ tr/_//dr))
              || (lc($a->{name}) cmp lc($b->{name}))
              || ($a->{name} cmp $b->{name})
        } values %subs
      ) {
        print {$fh} $method->{doc};
    }
}
