#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "eq? predicate tests")
    (ok (eq? 1 1)           "... equal numbers")
    (ok (not (eq? 1 2))     "... unequal numbers")
    (ok (eq? "foo" "foo")   "... equal strings")
    (ok (not (eq? "foo" "bar")) "... unequal strings")
    (ok (eq? true true)     "... equal bools")
    (ok (not (eq? true false)) "... unequal bools")
    (ok (eq? () ())         "... nil equals nil")

    (diag "atom? predicate tests")
    (ok (atom? 42)          "... number is atom")
    (ok (atom? "hello")     "... string is atom")
    (ok (atom? true)        "... bool is atom")
    (ok (atom? :foo)        "... keyword is atom")
    (ok (not (atom? (list/new 1 2))) "... list is not atom")

    (diag "literal? predicate tests")
    (ok (literal? 42)       "... number is literal")
    (ok (literal? "hello")  "... string is literal")
    (ok (literal? true)     "... bool is literal")

    (diag "bool? predicate tests")
    (ok (bool? true)        "... true is bool")
    (ok (bool? false)       "... false is bool")
    (ok (not (bool? 1))     "... number is not bool")
    (ok (not (bool? "true")) "... string is not bool")

    (diag "num? predicate tests")
    (ok (num? 42)           "... integer is num")
    (ok (num? 3.14)         "... float is num")
    (ok (num? -10)          "... negative is num")
    (ok (not (num? "42"))   "... string is not num")
    (ok (not (num? true))   "... bool is not num")

    (diag "str? predicate tests")
    (ok (str? "hello")      "... string is str")
    (ok (str? "")           "... empty string is str")
    (ok (not (str? 42))     "... number is not str")
    (ok (not (str? true))   "... bool is not str")

    (diag "word? predicate tests")
    (ok (word? (quote foo)) "... quoted word is word")
    (ok (not (word? "foo")) "... string is not word")
    (ok (not (word? 42))    "... number is not word")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
