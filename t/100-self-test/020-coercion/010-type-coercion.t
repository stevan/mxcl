#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "numify coercion tests")
    ($t is (numify 42)       42    "... numify number returns same number")
    ($t is (numify "42")     42    "... numify string converts to number")
    ($t is (numify "3.14")   3.14  "... numify string converts to float")
    ($t is (numify true)     1     "... numify true returns 1")
    ($t is (numify false)    0     "... numify false returns 0")

    ($t diag "stringify coercion tests")
    ($t is (stringify 42)      "42"    "... stringify number returns string")
    ($t is (stringify 3.14)    "3.14"  "... stringify float returns string")
    ($t is (stringify "hello") "hello" "... stringify string returns same string")
    ($t is (stringify true)    "true"  "... stringify true returns 'true'")
    ($t is (stringify false)   "false" "... stringify false returns 'false'")

    ($t diag "boolify coercion tests")
    ($t ok (boolify true)          "... boolify true is true")
    ($t ok (not (boolify false))   "... boolify false is false")
    ($t ok (boolify 1)             "... boolify 1 is true")
    ($t ok (not (boolify 0))       "... boolify 0 is false")
    ($t ok (boolify 42)            "... boolify non-zero is true")
    ($t ok (boolify "hello")       "... boolify non-empty string is true")
    ($t ok (not (boolify ""))      "... boolify empty string is false")
    ($t ok (not (boolify ()))      "... boolify nil is false")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
