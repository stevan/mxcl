#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "array/new constructor tests")
    (defvar arr (array/new 1 2 3))
    ($t ok (array? arr)            "... array/new creates an array")
    ($t is (array/length arr)      3       "... array has 3 elements")

    ($t diag "@[] literal syntax")
    (defvar literal @[1 2 3])
    ($t ok (array? literal)        "... @[...] creates an array")
    ($t is (array/length literal)  3       "... literal array has 3 elements")

    ($t diag "Empty array tests")
    (defvar empty (array/new))
    ($t ok (array? empty)          "... empty array/new creates an array")
    ($t is (array/length empty)    0       "... empty array has 0 elements")

    (defvar empty-literal @[])
    ($t ok (array? empty-literal)  "... @[] creates empty array")
    ($t is (array/length empty-literal) 0  "... empty literal array has 0 elements")

    ($t diag "array/get tests")
    (defvar indexed @[10 20 30])
    ($t is (array/get indexed 0)   10      "... array/get index 0")
    ($t is (array/get indexed 1)   20      "... array/get index 1")
    ($t is (array/get indexed 2)   30      "... array/get index 2")

    ($t diag "array/set! mutation tests")
    (defvar mutable @[1 2 3])
    (array/set! mutable 1 99)
    ($t is (array/get mutable 1)   99      "... array/set! modifies element")
    ($t is (array/get mutable 0)   1       "... other elements unchanged")
    ($t is (array/get mutable 2)   3       "... other elements unchanged")

    ($t diag "array/push tests")
    (defvar pushable @[1 2])
    (array/push pushable 3)
    ($t is (array/length pushable) 3       "... push increases length")
    ($t is (array/get pushable 2)  3       "... pushed element at end")

    ($t diag "array/pop tests")
    (defvar poppable @[1 2 3])
    (defvar popped (array/pop poppable))
    ($t is popped                  3       "... pop returns last element")
    ($t is (array/length poppable) 2       "... pop decreases length")

    ($t diag "array/unshift tests")
    (defvar unshiftable @[2 3])
    (array/unshift unshiftable 1)
    ($t is (array/length unshiftable) 3    "... unshift increases length")
    ($t is (array/get unshiftable 0)  1    "... unshifted element at start")
    ($t is (array/get unshiftable 1)  2    "... other elements shifted")

    ($t diag "array/shift tests")
    (defvar shiftable @[1 2 3])
    (defvar shifted (array/shift shiftable))
    ($t is shifted                 1       "... shift returns first element")
    ($t is (array/length shiftable) 2      "... shift decreases length")
    ($t is (array/get shiftable 0) 2       "... elements shifted down")

    ($t diag "array/splice tests")
    (defvar spliceable @[1 2 3 4 5])
    (defvar spliced (array/splice spliceable 1 2))
    ($t ok (array? spliced)        "... splice returns array")
    ($t is (array/length spliced)  2       "... spliced array has removed elements")
    ($t is (array/get spliced 0)   2       "... spliced first element")
    ($t is (array/get spliced 1)   3       "... spliced second element")
    ($t is (array/length spliceable) 3     "... original array modified")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
