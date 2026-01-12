#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Strand;

my $source = q[

    (say "GOT: " (+ (numify (readline)) 20))



];

my $kont = Opal::Strand->new->load($source)->run;
isa_ok($kont, 'Opal::Term::Kontinue::Host');

isa_ok($kont->effect, 'Opal::Effect::Halt', '... expected normal exit');

my ($result) = $kont->spill_stack();

say sprintf '%s : <%s>' => $_->stringify, blessed $_ foreach $result isa Opal::Term::List ? $result->uncons : $result;

done_testing;
