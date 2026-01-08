#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use importer 'Data::Dumper' => qw[ Dumper ];
use importer 'Carp'         => qw[ confess ];

use Opal::Parser;

my $source = q[
    (10 (20 30) 40)
];

my $parser = Opal::Parser->new;

my @tokens = $parser->parse($source);

say $_->to_string foreach @tokens;
