#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "tuple/new constructor tests")
    (defvar t (tuple/new 1 2 3))
    (ok (tuple? t)              "... tuple/new creates a tuple")
    (is (tuple/size t)          3       "... tuple has 3 elements")

    (diag "Bracket literal syntax")
    (defvar bracket [1 2 3])
    (ok (tuple? bracket)        "... [...] creates a tuple")
    (is (tuple/size bracket)    3       "... bracket tuple has 3 elements")

    (diag "Empty tuple tests")
    (defvar empty (tuple/new))
    (ok (tuple? empty)          "... empty tuple/new creates a tuple")
    (is (tuple/size empty)      0       "... empty tuple has 0 elements")

    (defvar empty-bracket [])
    (ok (tuple? empty-bracket)  "... [] creates empty tuple")
    (is (tuple/size empty-bracket) 0    "... empty bracket tuple has 0 elements")

    (diag "tuple/size tests")
    (is (tuple/size [1 2 3 4 5])    5   "... tuple/size of 5 elements")
    (is (tuple/size [])             0   "... tuple/size of empty tuple")
    (is (tuple/size ["a"])          1   "... tuple/size of single element")

    (diag "tuple/at accessor tests")
    (defvar indexed [10 20 30])
    (is (tuple/at indexed 0)    10      "... tuple/at index 0")
    (is (tuple/at indexed 1)    20      "... tuple/at index 1")
    (is (tuple/at indexed 2)    30      "... tuple/at index 2")

    (diag "tuple/at with different types")
    (defvar mixed ["hello" 42 true])
    (is (tuple/at mixed 0)      "hello" "... string at index 0")
    (is (tuple/at mixed 1)      42      "... number at index 1")
    (is (tuple/at mixed 2)      true    "... bool at index 2")

    (diag "Nested tuples")
    (defvar nested [[1 2] [3 4]])
    (is (tuple/size nested)     2       "... nested tuple has 2 elements")
    (ok (tuple? (tuple/at nested 0))    "... first element is tuple")
    (is (tuple/at (tuple/at nested 0) 0) 1  "... nested access")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
