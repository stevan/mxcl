#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use MXCL::Term;


my $t1 = MXCL::Term::Tuple->CREATE(
    MXCL::Term::Num->CREATE(1),
    MXCL::Term::Num->CREATE(2),
    MXCL::Term::Num->CREATE(3),
);

my $t2 = MXCL::Term::Tuple->CREATE(
    MXCL::Term::Num->CREATE(1),
    MXCL::Term::Num->CREATE(2),
    MXCL::Term::Num->CREATE(3),
);

say $t1;
say $t2;
say $t1->equals($t2) ? "EQUAL" : "NOT EQUAL";
