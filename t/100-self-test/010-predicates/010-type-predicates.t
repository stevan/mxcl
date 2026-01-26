#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "eq? predicate tests")
    ($t ok (eq? 1 1)           "... equal numbers")
    ($t ok (not (eq? 1 2))     "... unequal numbers")
    ($t ok (eq? "foo" "foo")   "... equal strings")
    ($t ok (not (eq? "foo" "bar")) "... unequal strings")
    ($t ok (eq? true true)     "... equal bools")
    ($t ok (not (eq? true false)) "... unequal bools")
    ($t ok (eq? () ())         "... nil equals nil")

    ($t diag "atom? predicate tests")
    ($t ok (atom? 42)          "... number is atom")
    ($t ok (atom? "hello")     "... string is atom")
    ($t ok (atom? true)        "... bool is atom")
    ($t ok (atom? :foo)        "... keyword is atom")
    ($t ok (not (atom? (list/new 1 2))) "... list is not atom")

    ($t diag "literal? predicate tests")
    ($t ok (literal? 42)       "... number is literal")
    ($t ok (literal? "hello")  "... string is literal")
    ($t ok (literal? true)     "... bool is literal")

    ($t diag "bool? predicate tests")
    ($t ok (bool? true)        "... true is bool")
    ($t ok (bool? false)       "... false is bool")
    ($t ok (not (bool? 1))     "... number is not bool")
    ($t ok (not (bool? "true")) "... string is not bool")

    ($t diag "num? predicate tests")
    ($t ok (num? 42)           "... integer is num")
    ($t ok (num? 3.14)         "... float is num")
    ($t ok (num? -10)          "... negative is num")
    ($t ok (not (num? "42"))   "... string is not num")
    ($t ok (not (num? true))   "... bool is not num")

    ($t diag "str? predicate tests")
    ($t ok (str? "hello")      "... string is str")
    ($t ok (str? "")           "... empty string is str")
    ($t ok (not (str? 42))     "... number is not str")
    ($t ok (not (str? true))   "... bool is not str")

    ($t diag "word? predicate tests")
    ($t ok (word? (quote foo)) "... quoted word is word")
    ($t ok (not (word? "foo")) "... string is not word")
    ($t ok (not (word? 42))    "... number is not word")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
