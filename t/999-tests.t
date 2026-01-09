#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Strand;

my $source = q[

    (+ 10 20)

];

my $kont = Opal::Strand->new->load($source)->run;
isa_ok($kont, 'Opal::Term::Kontinue::Host');

is($kont->effect, 'SYS.exit', '... expected normal exit');

my ($result) = $kont->spill_stack();

say "GOT : ${result}";

done_testing;
