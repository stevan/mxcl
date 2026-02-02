#!perl

use v5.42;
use Test::More;
use MXCL::Machine;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "pair? predicate tests")
    ($t ok (pair? (pair/new 1 2))      "... pair is pair")
    ($t ok (not (pair? (list/new 1 2))) "... list is not pair")
    ($t ok (not (pair? [1 2]))         "... tuple is not pair")

    ($t diag "list? predicate tests")
    ($t ok (list? (list/new 1 2 3))    "... list is list")
    ($t ok (list? (list/new))          "... empty list is list")
    ($t ok (not (list? ()))            "... nil is not list")
    ($t ok (not (list? [1 2]))         "... tuple is not list")
    ($t ok (not (list? @[1 2]))        "... array is not list")

    ($t diag "nil? predicate tests")
    ($t ok (nil? ())                   "... nil literal is nil")
    ($t ok (nil? (rest (list/new 1)))  "... rest of single-element list is nil")
    ($t ok (not (nil? (list/new)))     "... empty list is not nil")
    ($t ok (not (nil? 0))              "... zero is not nil")
    ($t ok (not (nil? ""))             "... empty string is not nil")

    ($t diag "tuple? predicate tests")
    ($t ok (tuple? [1 2 3])            "... tuple literal is tuple")
    ($t ok (tuple? (tuple/new 1 2 3))  "... tuple/new is tuple")
    ($t ok (tuple? (tuple/new))        "... empty tuple/new is tuple")
    ($t ok (tuple? [])                 "... empty [] literal is tuple")
    ($t ok (not (tuple? (list/new 1 2))) "... list is not tuple")
    ($t ok (not (tuple? @[1 2]))       "... array is not tuple")

    ($t diag "array? predicate tests")
    ($t ok (array? @[1 2 3])           "... array literal is array")
    ($t ok (array? (array/new 1 2 3))  "... array/new is array")
    ($t ok (array? (array/new))        "... empty array/new is array")
    ($t ok (array? @[])                "... empty @[] literal is array")
    ($t ok (not (array? [1 2]))        "... tuple is not array")
    ($t ok (not (array? (list/new 1 2))) "... list is not array")

    ($t diag "hash? predicate tests")
    ($t ok (hash? %{:a 1 :b 2})        "... hash literal is hash")
    ($t ok (hash? (hash/new :a 1))     "... hash/new is hash")
    ($t ok (hash? (hash/new))          "... empty hash/new is hash")
    ($t ok (hash? %{})                 "... empty %{} literal is hash")
    ($t ok (not (hash? [1 2]))         "... tuple is not hash")
    ($t ok (not (hash? (list/new 1 2))) "... list is not hash")

    ($t diag "environment? predicate tests")
    ($t ok (not (environment? 42))     "... number is not environment")

    ($t diag "exception? predicate tests")
    ($t ok (not (exception? 42))       "... number is not exception")
    ($t ok (not (exception? "error"))  "... string is not exception")

    ($t done)
];

my $kont = MXCL::Machine->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
