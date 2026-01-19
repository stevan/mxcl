#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "numify coercion tests")
    (is (numify 42)       42    "... numify number returns same number")
    (is (numify "42")     42    "... numify string converts to number")
    (is (numify "3.14")   3.14  "... numify string converts to float")
    (is (numify true)     1     "... numify true returns 1")
    (is (numify false)    0     "... numify false returns 0")

    (diag "stringify coercion tests")
    (is (stringify 42)      "42"    "... stringify number returns string")
    (is (stringify 3.14)    "3.14"  "... stringify float returns string")
    (is (stringify "hello") "hello" "... stringify string returns same string")
    (is (stringify true)    "true"  "... stringify true returns 'true'")
    (is (stringify false)   "false" "... stringify false returns 'false'")

    (diag "boolify coercion tests")
    (ok (boolify true)          "... boolify true is true")
    (ok (not (boolify false))   "... boolify false is false")
    (ok (boolify 1)             "... boolify 1 is true")
    (ok (not (boolify 0))       "... boolify 0 is false")
    (ok (boolify 42)            "... boolify non-zero is true")
    (ok (boolify "hello")       "... boolify non-empty string is true")
    (ok (not (boolify ""))      "... boolify empty string is false")
    (ok (not (boolify ()))      "... boolify nil is false")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
