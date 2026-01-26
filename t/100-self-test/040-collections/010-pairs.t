#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "pair/new constructor tests")
    (defvar p (pair/new 1 2))
    ($t ok (pair? p)               "... pair/new creates a pair")

    ($t diag "fst accessor tests")
    ($t is (fst (pair/new 10 20))  10      "... fst returns first element")
    ($t is (fst (pair/new "a" "b")) "a"    "... fst with strings")
    ($t is (fst (pair/new true false)) true "... fst with bools")

    ($t diag "snd accessor tests")
    ($t is (snd (pair/new 10 20))  20      "... snd returns second element")
    ($t is (snd (pair/new "a" "b")) "b"    "... snd with strings")
    ($t is (snd (pair/new true false)) false "... snd with bools")

    ($t diag "Nested pairs")
    (defvar nested (pair/new (pair/new 1 2) 3))
    ($t ok (pair? (fst nested))    "... fst of nested is pair")
    ($t is (fst (fst nested))      1       "... fst fst of nested")
    ($t is (snd (fst nested))      2       "... snd fst of nested")
    ($t is (snd nested)            3       "... snd of nested")

    ($t diag "Pair with different types")
    (defvar mixed (pair/new "key" 42))
    ($t is (fst mixed)             "key"   "... string as fst")
    ($t is (snd mixed)             42      "... number as snd")

    ($t diag "Dot syntax pair literal")
    (defvar dot-pair (1 . 2))
    ($t ok (pair? dot-pair)        "... dot syntax creates pair")
    ($t is (fst dot-pair)          1       "... fst of dot pair")
    ($t is (snd dot-pair)          2       "... snd of dot pair")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
