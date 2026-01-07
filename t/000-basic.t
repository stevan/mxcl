#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Parser;
use Opal::Expander;

my $parser = Opal::Parser->new(
    buffer => q[

    (1 true (3 "false"))

]);

my @exprs = $parser->parse;

my $expander = Opal::Expander->new( exprs => \@exprs );

my @terms = $expander->expand;

say join "\n" => map { $_->to_string } @exprs;
say join "\n" => map { $_->to_string } @terms;
