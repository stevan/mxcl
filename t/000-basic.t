#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];

use Opal::Parser;

my $parser = Opal::Parser->new;

my @exprs = $parser->parse(q[

    (10 (20 30) 40 (50))
    (1 2 3)

]);

say Dumper( [ map $_->DUMP, @exprs ] );

