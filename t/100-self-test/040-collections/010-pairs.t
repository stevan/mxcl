#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "pair/new constructor tests")
    (defvar p (pair/new 1 2))
    (ok (pair? p)               "... pair/new creates a pair")

    (diag "fst accessor tests")
    (is (fst (pair/new 10 20))  10      "... fst returns first element")
    (is (fst (pair/new "a" "b")) "a"    "... fst with strings")
    (is (fst (pair/new true false)) true "... fst with bools")

    (diag "snd accessor tests")
    (is (snd (pair/new 10 20))  20      "... snd returns second element")
    (is (snd (pair/new "a" "b")) "b"    "... snd with strings")
    (is (snd (pair/new true false)) false "... snd with bools")

    (diag "Nested pairs")
    (defvar nested (pair/new (pair/new 1 2) 3))
    (ok (pair? (fst nested))    "... fst of nested is pair")
    (is (fst (fst nested))      1       "... fst fst of nested")
    (is (snd (fst nested))      2       "... snd fst of nested")
    (is (snd nested)            3       "... snd of nested")

    (diag "Pair with different types")
    (defvar mixed (pair/new "key" 42))
    (is (fst mixed)             "key"   "... string as fst")
    (is (snd mixed)             42      "... number as snd")

    (diag "Dot syntax pair literal")
    (defvar dot-pair (1 . 2))
    (ok (pair? dot-pair)        "... dot syntax creates pair")
    (is (fst dot-pair)          1       "... fst of dot pair")
    (is (snd dot-pair)          2       "... snd of dot pair")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
