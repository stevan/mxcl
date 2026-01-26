#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "not operator tests")
    ($t ok (not false)             "... not false = true")
    ($t ok (not (not true))        "... not not true = true")
    ($t ok (not ())                "... not nil = true")
    ($t ok (not 0)                 "... not 0 = true")
    ($t ok (not "")                "... not '' = true")
    ($t ok (not (not 1))           "... not not 1 = true")
    ($t ok (not (not "hello"))     "... not not 'hello' = true")

    ($t diag "and operator tests")
    ($t ok (and true true)         "... true and true = true")
    ($t ok (not (and true false))  "... true and false = false")
    ($t ok (not (and false true))  "... false and true = false")
    ($t ok (not (and false false)) "... false and false = false")

    ($t diag "and short-circuit evaluation")
    ($t is (and false 42)      false   "... false and 42 returns false (short-circuit)")
    ($t is (and true 42)       42      "... true and 42 returns 42")
    ($t is (and 1 2)           2       "... 1 and 2 returns 2")
    ($t is (and 0 2)           0       "... 0 and 2 returns 0 (short-circuit)")

    ($t diag "or operator tests")
    ($t ok (or true true)          "... true or true = true")
    ($t ok (or true false)         "... true or false = true")
    ($t ok (or false true)         "... false or true = true")
    ($t ok (not (or false false))  "... false or false = false")

    ($t diag "or short-circuit evaluation")
    ($t is (or true 42)        true    "... true or 42 returns true (short-circuit)")
    ($t is (or false 42)       42      "... false or 42 returns 42")
    ($t is (or 1 2)            1       "... 1 or 2 returns 1 (short-circuit)")
    ($t is (or 0 2)            2       "... 0 or 2 returns 2")
    ($t is (or () "default")   "default" "... nil or 'default' returns 'default'")

    ($t diag "Combined logical operations")
    ($t ok (and (or true false) true)  "... (true or false) and true = true")
    ($t ok (or (and false true) true)  "... (false and true) or true = true")
    ($t ok (not (and (not true) true)) "... not ((not true) and true) = true")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
