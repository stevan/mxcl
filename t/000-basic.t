#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use Opal::Reader;

my $parser = Opal::Reader->new(
    source => q[

    (10 (20 30) 40 (50))
    (1 2 3)

]);

my @exprs = $parser->parse;

say Dumper( [ map $_->DUMP, @exprs ] );

