#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Term;
use Opal::Tokenizer;
use Opal::Parser;
use Opal::Expander;
use Opal::Machine;

my $source = q/

    (10 20 (30 50)100)

/;

