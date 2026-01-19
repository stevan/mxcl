#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "if with boolean conditions")
    (is (if true 1 2)       1       "... if true returns then-branch")
    (is (if false 1 2)      2       "... if false returns else-branch")

    (diag "if with truthy/falsy values")
    (is (if 1 "yes" "no")       "yes"   "... 1 is truthy")
    (is (if 0 "yes" "no")       "no"    "... 0 is falsy")
    (is (if "hello" "yes" "no") "yes"   "... non-empty string is truthy")
    (is (if "" "yes" "no")      "no"    "... empty string is falsy")
    (is (if () "yes" "no")      "no"    "... nil is falsy")
    (is (if (list/new 1) "yes" "no") "yes" "... non-empty list is truthy")

    (diag "if with computed conditions")
    (is (if (> 5 3) "bigger" "smaller") "bigger" "... 5 > 3")
    (is (if (< 5 3) "bigger" "smaller") "smaller" "... not 5 < 3")
    (is (if (== 2 2) "equal" "different") "equal" "... 2 == 2")

    (diag "if with expressions in branches")
    (is (if true (+ 1 2) (+ 3 4))   3   "... evaluates then-expr")
    (is (if false (+ 1 2) (+ 3 4))  7   "... evaluates else-expr")

    (diag "Nested if expressions")
    (is (if true (if true 1 2) 3)   1   "... nested if, both true")
    (is (if true (if false 1 2) 3)  2   "... nested if, outer true inner false")
    (is (if false 1 (if true 2 3))  2   "... nested in else branch")

    (diag "let expression tests")
    (is (let (x 10) x)              10  "... let binds value")
    (is (let (x 5) (+ x 3))         8   "... let value used in body")
    (is (let (x (+ 1 2)) x)         3   "... let with computed value")

    (diag "let with shadowing")
    (defvar outer 100)
    (is (let (outer 1) outer)       1   "... let shadows outer binding")
    (is outer                       100 "... outer unchanged after let")

    (diag "Nested let expressions")
    (is (let (x 1) (let (y 2) (+ x y))) 3 "... nested let")
    (is (let (x 1) (let (x 2) x))    2   "... inner let shadows outer")

    (diag "do block tests")
    (is (do 1 2 3)                  3   "... do returns last value")
    (is (do (+ 1 1) (+ 2 2) (+ 3 3)) 6  "... do evaluates all, returns last")

    (diag "do with side effects")
    (defvar counter 0)
    (do
        (set! counter (+ counter 1))
        (set! counter (+ counter 1))
        (set! counter (+ counter 1)))
    (is counter                     3   "... do executes all expressions")

    (diag "quote expression tests")
    (ok (word? (quote foo))         "... quote creates a word")
    (ok (list? (quote (1 2 3)))     "... quote creates a list")
    (is (first (quote (a b c)))     (quote a) "... quoted list elements are words")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
