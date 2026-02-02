#!perl

use v5.42;
use Test::More;
use MXCL::Machine;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "Equality (==) tests")
    ($t ok (== 1 1)            "... 1 == 1")
    ($t ok (== 0 0)            "... 0 == 0")
    ($t ok (== -5 -5)          "... -5 == -5")
    ($t ok (== 3.14 3.14)      "... 3.14 == 3.14")
    ($t ok (not (== 1 2))      "... 1 != 2")
    ($t ok (== 1 1.0)          "... 1 == 1.0 (numeric equality)")
    ($t ok (== true 1)         "... true == 1 (coercion)")
    ($t ok (== false 0)        "... false == 0 (coercion)")

    ($t diag "Equality (==) tests (infix)")
    ($t ok (1 == 1)            "... 1 == 1")
    ($t ok (0 == 0)            "... 0 == 0")
    ($t ok (-5 == -5)          "... -5 == -5")
    ($t ok (3.14 == 3.14)      "... 3.14 == 3.14")
    ($t ok (not (1 == 2))      "... 1 != 2")
    ($t ok (1 == 1.0)          "... 1 == 1.0 (numeric equality)")
    ($t ok (true == 1)         "... true == 1 (coercion)")
    ($t ok (false == 0)        "... false == 0 (coercion)")

    ($t diag "Inequality (!=) tests")
    ($t ok (!= 1 2)            "... 1 != 2")
    ($t ok (!= 0 1)            "... 0 != 1")
    ($t ok (!= -1 1)           "... -1 != 1")
    ($t ok (not (!= 5 5))      "... not (5 != 5)")

    ($t diag "Inequality (!=) tests (infix)")
    ($t ok (1 !=  2)            "... 1 != 2")
    ($t ok (0 !=  1)            "... 0 != 1")
    ($t ok (-1 !=  1)           "... -1 != 1")
    ($t ok (not (5 != 5))      "... not (5 != 5)")

    ($t diag "Less than (<) tests")
    ($t ok (< 1 2)             "... 1 < 2")
    ($t ok (< -5 0)            "... -5 < 0")
    ($t ok (< 0 0.1)           "... 0 < 0.1")
    ($t ok (not (< 2 1))       "... not (2 < 1)")
    ($t ok (not (< 1 1))       "... not (1 < 1)")

    ($t diag "Less than (<) tests (infix)")
    ($t ok (1 < 2)             "... 1 < 2")
    ($t ok (-5 < 0)            "... -5 < 0")
    ($t ok (0 < 0.1)           "... 0 < 0.1")
    ($t ok (not (2 < 1))       "... not (2 < 1)")
    ($t ok (not (1 < 1))       "... not (1 < 1)")

    ($t diag "Less than or equal (<=) tests")
    ($t ok (<= 1 2)            "... 1 <= 2")
    ($t ok (<= 1 1)            "... 1 <= 1")
    ($t ok (<= -1 0)           "... -1 <= 0")
    ($t ok (not (<= 2 1))      "... not (2 <= 1)")

    ($t diag "Less than or equal (<=) tests (infix)")
    ($t ok (1 <= 2)            "... 1 <= 2")
    ($t ok (1 <= 1)            "... 1 <= 1")
    ($t ok (-1 <= 0)           "... -1 <= 0")
    ($t ok (not (2 <= 1))      "... not (2 <= 1)")

    ($t diag "Greater than (>) tests")
    ($t ok (> 2 1)             "... 2 > 1")
    ($t ok (> 0 -5)            "... 0 > -5")
    ($t ok (> 0.1 0)           "... 0.1 > 0")
    ($t ok (not (> 1 2))       "... not (1 > 2)")
    ($t ok (not (> 1 1))       "... not (1 > 1)")

    ($t diag "Greater than (>) tests (infix)")
    ($t ok (2 > 1)             "... 2 > 1")
    ($t ok (0 > -5)            "... 0 > -5")
    ($t ok (0.1 > 0)           "... 0.1 > 0")
    ($t ok (not (1 > 2))       "... not (1 > 2)")
    ($t ok (not (1 > 1))       "... not (1 > 1)")

    ($t diag "Greater than or equal (>=) tests")
    ($t ok (>= 2 1)            "... 2 >= 1")
    ($t ok (>= 1 1)            "... 1 >= 1")
    ($t ok (>= 0 -1)           "... 0 >= -1")
    ($t ok (not (>= 1 2))      "... not (1 >= 2)")

    ($t diag "Greater than or equal (>=) tests (infix)")
    ($t ok (2 >= 1)            "... 2 >= 1")
    ($t ok (1 >= 1)            "... 1 >= 1")
    ($t ok (0 >= -1)           "... 0 >= -1")
    ($t ok (not (1 >= 2))      "... not (1 >= 2)")

    ($t diag "Spaceship operator (<=>) tests")
    ($t is (<=> 1 2)   -1      "... 1 <=> 2 = -1")
    ($t is (<=> 2 1)   1       "... 2 <=> 1 = 1")
    ($t is (<=> 5 5)   0       "... 5 <=> 5 = 0")
    ($t is (<=> -1 0)  -1      "... -1 <=> 0 = -1")
    ($t is (<=> 0 -1)  1       "... 0 <=> -1 = 1")

    ($t diag "Spaceship operator (<=>) tests (infix)")
    ($t is (1 <=> 2)   -1      "... 1 <=> 2 = -1")
    ($t is (2 <=> 1)   1       "... 2 <=> 1 = 1")
    ($t is (5 <=> 5)   0       "... 5 <=> 5 = 0")
    ($t is (-1 <=> 0)  -1      "... -1 <=> 0 = -1")
    ($t is (0 <=> -1)  1       "... 0 <=> -1 = 1")

    ($t done)
];

my $kont = MXCL::Machine->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
