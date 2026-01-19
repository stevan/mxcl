#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "not operator tests")
    (ok (not false)             "... not false = true")
    (ok (not (not true))        "... not not true = true")
    (ok (not ())                "... not nil = true")
    (ok (not 0)                 "... not 0 = true")
    (ok (not "")                "... not '' = true")
    (ok (not (not 1))           "... not not 1 = true")
    (ok (not (not "hello"))     "... not not 'hello' = true")

    (diag "and operator tests")
    (ok (and true true)         "... true and true = true")
    (ok (not (and true false))  "... true and false = false")
    (ok (not (and false true))  "... false and true = false")
    (ok (not (and false false)) "... false and false = false")

    (diag "and short-circuit evaluation")
    (is (and false 42)      false   "... false and 42 returns false (short-circuit)")
    (is (and true 42)       42      "... true and 42 returns 42")
    (is (and 1 2)           2       "... 1 and 2 returns 2")
    (is (and 0 2)           0       "... 0 and 2 returns 0 (short-circuit)")

    (diag "or operator tests")
    (ok (or true true)          "... true or true = true")
    (ok (or true false)         "... true or false = true")
    (ok (or false true)         "... false or true = true")
    (ok (not (or false false))  "... false or false = false")

    (diag "or short-circuit evaluation")
    (is (or true 42)        true    "... true or 42 returns true (short-circuit)")
    (is (or false 42)       42      "... false or 42 returns 42")
    (is (or 1 2)            1       "... 1 or 2 returns 1 (short-circuit)")
    (is (or 0 2)            2       "... 0 or 2 returns 2")
    (is (or () "default")   "default" "... nil or 'default' returns 'default'")

    (diag "Combined logical operations")
    (ok (and (or true false) true)  "... (true or false) and true = true")
    (ok (or (and false true) true)  "... (false and true) or true = true")
    (ok (not (and (not true) true)) "... not ((not true) and true) = true")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
