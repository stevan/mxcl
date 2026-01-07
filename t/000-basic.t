#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];


my $source = q[
    %( :foo 10 :bar '(+ 10 10) )
];


my @tokens = grep defined, split /(\'\(|\%\(|\(|\)|\s+)/ => $source;

say "[$_]" foreach grep !/\s+/, grep $_, @tokens;
