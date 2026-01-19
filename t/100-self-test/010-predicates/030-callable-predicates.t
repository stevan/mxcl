#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "callable? predicate tests")
    (ok (callable? (lambda (x) x))  "... lambda is callable")
    (ok (callable? +)               "... builtin + is callable")
    (ok (not (callable? 42))        "... number is not callable")
    (ok (not (callable? "hello"))   "... string is not callable")

    (diag "applicative? predicate tests")
    (ok (applicative? +)            "... + is applicative")
    (ok (applicative? -)            "... - is applicative")
    (ok (applicative? first)        "... first is applicative")
    (ok (not (applicative? 42))     "... number is not applicative")

    (diag "lambda? predicate tests")
    (ok (lambda? (lambda (x) x))    "... lambda is lambda")
    (ok (lambda? (lambda (x y) (+ x y))) "... multi-arg lambda is lambda")
    (ok (not (lambda? +))           "... builtin is not lambda")
    (ok (not (lambda? 42))          "... number is not lambda")

    (diag "operative? predicate tests")
    (ok (operative? if)             "... if is operative")
    (ok (operative? and)            "... and is operative")
    (ok (operative? or)             "... or is operative")
    (ok (operative? quote)          "... quote is operative")
    (ok (not (operative? +))        "... + is not operative")
    (ok (not (operative? (lambda (x) x))) "... lambda is not operative")

    (diag "applicative-native? predicate tests")
    (ok (applicative-native? +)     "... + is applicative-native")
    (ok (applicative-native? first) "... first is applicative-native")
    (ok (not (applicative-native? (lambda (x) x))) "... lambda is not applicative-native")
    (ok (not (applicative-native? if)) "... if is not applicative-native")

    (diag "operative-native? predicate tests")
    (ok (operative-native? if)      "... if is operative-native")
    (ok (operative-native? and)     "... and is operative-native")
    (ok (operative-native? or)      "... or is operative-native")
    (ok (not (operative-native? +)) "... + is not operative-native")
    (ok (not (operative-native? (lambda (x) x))) "... lambda is not operative-native")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
