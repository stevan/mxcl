#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use importer 'Data::Dumper' => qw[ Dumper ];
use importer 'Carp'         => qw[ confess ];

use Opal::Tokenizer;
use Opal::Parser;
use Opal::Expander;

my $source = q/
    (10 20 (30 50)100)
/;

my $tokenizer = Opal::Tokenizer->new( source => $source );
my @tokens    = $tokenizer->tokenize;
my $parser    = Opal::Parser->new( tokens => \@tokens );
my @exprs     = $parser->parse($source);
my $expander  = Opal::Expander->new( exprs => \@exprs );
my @terms     = $expander->expand;

say 'TOKENS:';
say join "\n" => map { $_->to_string } @tokens;
say 'EXPRS:';
say join "\n" => map { $_->to_string } @exprs;
say 'TERMS:';
say join "\n" => map { sprintf '%s := %s' => blessed $_, $_->to_string } @terms;

