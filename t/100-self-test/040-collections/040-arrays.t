#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "array/new constructor tests")
    (defvar arr (array/new 1 2 3))
    (ok (array? arr)            "... array/new creates an array")
    (is (array/length arr)      3       "... array has 3 elements")

    (diag "@[] literal syntax")
    (defvar literal @[1 2 3])
    (ok (array? literal)        "... @[...] creates an array")
    (is (array/length literal)  3       "... literal array has 3 elements")

    (diag "Empty array tests")
    (defvar empty (array/new))
    (ok (array? empty)          "... empty array/new creates an array")
    (is (array/length empty)    0       "... empty array has 0 elements")

    (defvar empty-literal @[])
    (ok (array? empty-literal)  "... @[] creates empty array")
    (is (array/length empty-literal) 0  "... empty literal array has 0 elements")

    (diag "array/get tests")
    (defvar indexed @[10 20 30])
    (is (array/get indexed 0)   10      "... array/get index 0")
    (is (array/get indexed 1)   20      "... array/get index 1")
    (is (array/get indexed 2)   30      "... array/get index 2")

    (diag "array/set! mutation tests")
    (defvar mutable @[1 2 3])
    (array/set! mutable 1 99)
    (is (array/get mutable 1)   99      "... array/set! modifies element")
    (is (array/get mutable 0)   1       "... other elements unchanged")
    (is (array/get mutable 2)   3       "... other elements unchanged")

    (diag "array/push tests")
    (defvar pushable @[1 2])
    (array/push pushable 3)
    (is (array/length pushable) 3       "... push increases length")
    (is (array/get pushable 2)  3       "... pushed element at end")

    (diag "array/pop tests")
    (defvar poppable @[1 2 3])
    (defvar popped (array/pop poppable))
    (is popped                  3       "... pop returns last element")
    (is (array/length poppable) 2       "... pop decreases length")

    (diag "array/unshift tests")
    (defvar unshiftable @[2 3])
    (array/unshift unshiftable 1)
    (is (array/length unshiftable) 3    "... unshift increases length")
    (is (array/get unshiftable 0)  1    "... unshifted element at start")
    (is (array/get unshiftable 1)  2    "... other elements shifted")

    (diag "array/shift tests")
    (defvar shiftable @[1 2 3])
    (defvar shifted (array/shift shiftable))
    (is shifted                 1       "... shift returns first element")
    (is (array/length shiftable) 2      "... shift decreases length")
    (is (array/get shiftable 0) 2       "... elements shifted down")

    (diag "array/splice tests")
    (defvar spliceable @[1 2 3 4 5])
    (defvar spliced (array/splice spliceable 1 2))
    (ok (array? spliced)        "... splice returns array")
    (is (array/length spliced)  2       "... spliced array has removed elements")
    (is (array/get spliced 0)   2       "... spliced first element")
    (is (array/get spliced 1)   3       "... spliced second element")
    (is (array/length spliceable) 3     "... original array modified")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
