#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use importer 'Data::Dumper' => qw[ Dumper ];
use importer 'Carp'         => qw[ confess ];

use Opal::Parser;
use Opal::Expander;

my $source = q[
    ""
];

my $parser   = Opal::Parser->new;
my @exprs    = $parser->parse($source);
my $expander = Opal::Expander->new( exprs => \@exprs );
my @terms    = $expander->expand;

say 'TOKENS:';
say join "\n" => map { $_->to_string } @exprs;
say 'TERMS:';
say join "\n" => map { sprintf '%s := %s' => blessed $_, $_->to_string } @terms;

