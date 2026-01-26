#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "list/new constructor tests")
    (defvar lst (list/new 1 2 3))
    ($t ok (list? lst)             "... list/new creates a list")
    ($t is (list/length lst)       3       "... list has 3 elements")

    ($t diag "Empty list tests")
    (defvar empty (list/new))
    ($t ok (list? empty)           "... empty list/new creates a list")
    ($t is (list/length empty)     0       "... empty list has 0 elements")

    ($t diag "first accessor tests")
    ($t is (first (list/new 1 2 3))    1       "... first returns first element")
    ($t is (first (list/new "a" "b"))  "a"     "... first with strings")
    ($t is (first (list/new 42))       42      "... first of single element")

    ($t diag "rest accessor tests")
    (defvar r (rest (list/new 1 2 3)))
    ($t ok (list? r)               "... rest returns a list")
    ($t is (list/length r)         2       "... rest has 2 elements")
    ($t is (first r)               2       "... first of rest is 2")

    ($t diag "rest edge cases")
    (defvar single-rest (rest (list/new 1)))
    ($t ok (nil? single-rest)      "... rest of single-element list is nil")

    ($t diag "list/length tests")
    ($t is (list/length (list/new 1 2 3 4 5)) 5   "... list/length of 5 elements")
    ($t is (list/length (list/new))           0   "... list/length of empty list")
    ($t is (list/length (list/new "a"))       1   "... list/length of single element")

    ($t diag "Nested lists")
    (defvar nested (list/new (list/new 1 2) (list/new 3 4)))
    ($t is (list/length nested)    2       "... nested list has 2 elements")
    ($t ok (list? (first nested))  "... first of nested is a list")
    ($t is (first (first nested))  1       "... first first of nested")

    ($t diag "List traversal")
    (defvar nums (list/new 10 20 30))
    ($t is (first nums)                        10  "... first")
    ($t is (first (rest nums))                 20  "... second via rest")
    ($t is (first (rest (rest nums)))          30  "... third via rest rest")
    ($t ok (nil? (rest (rest (rest nums))))    "... rest^3 is nil")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
