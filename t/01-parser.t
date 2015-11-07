#!perl

use 5.010;
use strict;
use autodie;
use warnings FATAL => 'all';
use Test::More;

no warnings 'once';

use File::Find qw(find);
use List::Util qw(first);
use File::Spec::Functions qw(catfile catdir);

use lib 'lib';
require Corvinus;

my $scripts_dir = 'scripts';

my @scripts;
find {
    no_chdir => 1,
    wanted   => sub {
        if (/\.corvin\z/) {
            push @scripts, $_;
        }
    },
} => $scripts_dir;

plan tests => (scalar(@scripts) * 2);

foreach my $corvin_script (@scripts) {

    my $content = do {
        open my $fh, '<:utf8', $corvin_script;
        local $/;
        <$fh>;
    };

    %Corvinus::INCLUDED   = ();
    @Corvinus::NAMESPACES = ();

    my $parser = Corvinus::Parser->new(script_name => $corvin_script);
    my $struct = $parser->parse_script(code => \$content);

    is(ref($struct), 'HASH');

    my $deparser = Corvinus::Deparse::Perl->new(namespaces => \@Corvinus::NAMESPACES);
    my $code = $deparser->deparse($struct);

    ok($code ne '');
}
