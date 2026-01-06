#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Reader;

my $parser = Opal::Reader->new(
    buffer => q[

    (1 2 3)

]);

my $exprs = $parser->parse;

say $exprs->[0]->to_string;
