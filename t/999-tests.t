#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use MXCL::Strand;

my $source = q[


];

my $kont = MXCL::Strand->new->load($source)->run;
isa_ok($kont, 'MXCL::Term::Kontinue::Host');
isa_ok($kont->effect, 'MXCL::Effect::Halt', '... expected normal exit');
my ($result) = $kont->spill_stack();
say sprintf '%s : <%s>' => $_->stringify, blessed $_ foreach $result isa MXCL::Term::List ? $result->uncons : $result;
done_testing;
