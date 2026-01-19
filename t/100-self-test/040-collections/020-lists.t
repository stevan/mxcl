#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "list/new constructor tests")
    (defvar lst (list/new 1 2 3))
    (ok (list? lst)             "... list/new creates a list")
    (is (list/length lst)       3       "... list has 3 elements")

    (diag "Empty list tests")
    (defvar empty (list/new))
    (ok (list? empty)           "... empty list/new creates a list")
    (is (list/length empty)     0       "... empty list has 0 elements")

    (diag "first accessor tests")
    (is (first (list/new 1 2 3))    1       "... first returns first element")
    (is (first (list/new "a" "b"))  "a"     "... first with strings")
    (is (first (list/new 42))       42      "... first of single element")

    (diag "rest accessor tests")
    (defvar r (rest (list/new 1 2 3)))
    (ok (list? r)               "... rest returns a list")
    (is (list/length r)         2       "... rest has 2 elements")
    (is (first r)               2       "... first of rest is 2")

    (diag "rest edge cases")
    (defvar single-rest (rest (list/new 1)))
    (ok (nil? single-rest)      "... rest of single-element list is nil")

    (diag "list/length tests")
    (is (list/length (list/new 1 2 3 4 5)) 5   "... list/length of 5 elements")
    (is (list/length (list/new))           0   "... list/length of empty list")
    (is (list/length (list/new "a"))       1   "... list/length of single element")

    (diag "Nested lists")
    (defvar nested (list/new (list/new 1 2) (list/new 3 4)))
    (is (list/length nested)    2       "... nested list has 2 elements")
    (ok (list? (first nested))  "... first of nested is a list")
    (is (first (first nested))  1       "... first first of nested")

    (diag "List traversal")
    (defvar nums (list/new 10 20 30))
    (is (first nums)                        10  "... first")
    (is (first (rest nums))                 20  "... second via rest")
    (is (first (rest (rest nums)))          30  "... third via rest rest")
    (ok (nil? (rest (rest (rest nums))))    "... rest^3 is nil")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
