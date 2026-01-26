#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "tuple/new constructor tests")
    (defvar t (tuple/new 1 2 3))
    ($t ok (tuple? t)              "... tuple/new creates a tuple")
    ($t is (tuple/size t)          3       "... tuple has 3 elements")

    ($t diag "Bracket literal syntax")
    (defvar bracket [1 2 3])
    ($t ok (tuple? bracket)        "... [...] creates a tuple")
    ($t is (tuple/size bracket)    3       "... bracket tuple has 3 elements")

    ($t diag "Empty tuple tests")
    (defvar empty (tuple/new))
    ($t ok (tuple? empty)          "... empty tuple/new creates a tuple")
    ($t is (tuple/size empty)      0       "... empty tuple has 0 elements")

    (defvar empty-bracket [])
    ($t ok (tuple? empty-bracket)  "... [] creates empty tuple")
    ($t is (tuple/size empty-bracket) 0    "... empty bracket tuple has 0 elements")

    ($t diag "tuple/size tests")
    ($t is (tuple/size [1 2 3 4 5])    5   "... tuple/size of 5 elements")
    ($t is (tuple/size [])             0   "... tuple/size of empty tuple")
    ($t is (tuple/size ["a"])          1   "... tuple/size of single element")

    ($t diag "tuple/at accessor tests")
    (defvar indexed [10 20 30])
    ($t is (tuple/at indexed 0)    10      "... tuple/at index 0")
    ($t is (tuple/at indexed 1)    20      "... tuple/at index 1")
    ($t is (tuple/at indexed 2)    30      "... tuple/at index 2")

    ($t diag "tuple/at with different types")
    (defvar mixed ["hello" 42 true])
    ($t is (tuple/at mixed 0)      "hello" "... string at index 0")
    ($t is (tuple/at mixed 1)      42      "... number at index 1")
    ($t is (tuple/at mixed 2)      true    "... bool at index 2")

    ($t diag "Nested tuples")
    (defvar nested [[1 2] [3 4]])
    ($t is (tuple/size nested)     2       "... nested tuple has 2 elements")
    ($t ok (tuple? (tuple/at nested 0))    "... first element is tuple")
    ($t is (tuple/at (tuple/at nested 0) 0) 1  "... nested access")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
