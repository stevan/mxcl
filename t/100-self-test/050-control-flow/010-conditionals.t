#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "if with boolean conditions")
    ($t is (if true 1 2)       1       "... if true returns then-branch")
    ($t is (if false 1 2)      2       "... if false returns else-branch")

    ($t diag "if with truthy/falsy values")
    ($t is (if 1 "yes" "no")       "yes"   "... 1 is truthy")
    ($t is (if 0 "yes" "no")       "no"    "... 0 is falsy")
    ($t is (if "hello" "yes" "no") "yes"   "... non-empty string is truthy")
    ($t is (if "" "yes" "no")      "no"    "... empty string is falsy")
    ($t is (if () "yes" "no")      "no"    "... nil is falsy")
    ($t is (if (list/new 1) "yes" "no") "yes" "... non-empty list is truthy")

    ($t diag "if with computed conditions")
    ($t is (if (> 5 3) "bigger" "smaller") "bigger" "... 5 > 3")
    ($t is (if (< 5 3) "bigger" "smaller") "smaller" "... not 5 < 3")
    ($t is (if (== 2 2) "equal" "different") "equal" "... 2 == 2")

    ($t diag "if with expressions in branches")
    ($t is (if true (+ 1 2) (+ 3 4))   3   "... evaluates then-expr")
    ($t is (if false (+ 1 2) (+ 3 4))  7   "... evaluates else-expr")

    ($t diag "Nested if expressions")
    ($t is (if true (if true 1 2) 3)   1   "... nested if, both true")
    ($t is (if true (if false 1 2) 3)  2   "... nested if, outer true inner false")
    ($t is (if false 1 (if true 2 3))  2   "... nested in else branch")

    ($t diag "let expression tests")
    ($t is (let (x 10) x)              10  "... let binds value")
    ($t is (let (x 5) (+ x 3))         8   "... let value used in body")
    ($t is (let (x (+ 1 2)) x)         3   "... let with computed value")

    ($t diag "let with shadowing")
    (defvar outer 100)
    ($t is (let (outer 1) outer)       1   "... let shadows outer binding")
    ($t is outer                       100 "... outer unchanged after let")

    ($t diag "Nested let expressions")
    ($t is (let (x 1) (let (y 2) (+ x y))) 3 "... nested let")
    ($t is (let (x 1) (let (x 2) x))    2   "... inner let shadows outer")

    ($t diag "do block tests")
    ($t is (do 1 2 3)                  3   "... do returns last value")
    ($t is (do (+ 1 1) (+ 2 2) (+ 3 3)) 6  "... do evaluates all, returns last")

    ($t diag "do with side effects")
    (defvar counter 0)
    (do
        (set! counter (+ counter 1))
        (set! counter (+ counter 1))
        (set! counter (+ counter 1)))
    ($t is counter                     3   "... do executes all expressions")

    ($t diag "quote expression tests")
    ($t ok (word? (quote foo))         "... quote creates a word")
    ($t ok (list? (quote (1 2 3)))     "... quote creates a list")
    ($t is (first (quote (a b c)))     (quote a) "... quoted list elements are words")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
