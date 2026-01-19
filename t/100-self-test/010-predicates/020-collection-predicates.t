#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "pair? predicate tests")
    (ok (pair? (pair/new 1 2))      "... pair is pair")
    (ok (not (pair? (list/new 1 2))) "... list is not pair")
    (ok (not (pair? [1 2]))         "... tuple is not pair")

    (diag "list? predicate tests")
    (ok (list? (list/new 1 2 3))    "... list is list")
    (ok (list? (list/new))          "... empty list is list")
    (ok (not (list? ()))            "... nil is not list")
    (ok (not (list? [1 2]))         "... tuple is not list")
    (ok (not (list? @[1 2]))        "... array is not list")

    (diag "nil? predicate tests")
    (ok (nil? ())                   "... nil literal is nil")
    (ok (nil? (rest (list/new 1)))  "... rest of single-element list is nil")
    (ok (not (nil? (list/new)))     "... empty list is not nil")
    (ok (not (nil? 0))              "... zero is not nil")
    (ok (not (nil? ""))             "... empty string is not nil")

    (diag "tuple? predicate tests")
    (ok (tuple? [1 2 3])            "... tuple literal is tuple")
    (ok (tuple? (tuple/new 1 2 3))  "... tuple/new is tuple")
    (ok (tuple? (tuple/new))        "... empty tuple/new is tuple")
    (ok (tuple? [])                 "... empty [] literal is tuple")
    (ok (not (tuple? (list/new 1 2))) "... list is not tuple")
    (ok (not (tuple? @[1 2]))       "... array is not tuple")

    (diag "array? predicate tests")
    (ok (array? @[1 2 3])           "... array literal is array")
    (ok (array? (array/new 1 2 3))  "... array/new is array")
    (ok (array? (array/new))        "... empty array/new is array")
    (ok (array? @[])                "... empty @[] literal is array")
    (ok (not (array? [1 2]))        "... tuple is not array")
    (ok (not (array? (list/new 1 2))) "... list is not array")

    (diag "hash? predicate tests")
    (ok (hash? %{:a 1 :b 2})        "... hash literal is hash")
    (ok (hash? (hash/new :a 1))     "... hash/new is hash")
    (ok (hash? (hash/new))          "... empty hash/new is hash")
    (ok (hash? %{})                 "... empty %{} literal is hash")
    (ok (not (hash? [1 2]))         "... tuple is not hash")
    (ok (not (hash? (list/new 1 2))) "... list is not hash")

    (diag "environment? predicate tests")
    (ok (not (environment? 42))     "... number is not environment")

    (diag "exception? predicate tests")
    (ok (not (exception? 42))       "... number is not exception")
    (ok (not (exception? "error"))  "... string is not exception")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
