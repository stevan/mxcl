#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "callable? predicate tests")
    ($t ok (callable? (lambda (x) x))  "... lambda is callable")
    ($t ok (callable? +)               "... builtin + is callable")
    ($t ok (not (callable? 42))        "... number is not callable")
    ($t ok (not (callable? "hello"))   "... string is not callable")

    ($t diag "applicative? predicate tests")
    ($t ok (applicative? +)            "... + is applicative")
    ($t ok (applicative? -)            "... - is applicative")
    ($t ok (applicative? first)        "... first is applicative")
    ($t ok (not (applicative? 42))     "... number is not applicative")

    ($t diag "lambda? predicate tests")
    ($t ok (lambda? (lambda (x) x))    "... lambda is lambda")
    ($t ok (lambda? (lambda (x y) (+ x y))) "... multi-arg lambda is lambda")
    ($t ok (not (lambda? +))           "... builtin is not lambda")
    ($t ok (not (lambda? 42))          "... number is not lambda")

    ($t diag "operative? predicate tests")
    ($t ok (operative? if)             "... if is operative")
    ($t ok (operative? and)            "... and is operative")
    ($t ok (operative? or)             "... or is operative")
    ($t ok (operative? quote)          "... quote is operative")
    ($t ok (not (operative? +))        "... + is not operative")
    ($t ok (not (operative? (lambda (x) x))) "... lambda is not operative")

    ($t diag "applicative-native? predicate tests")
    ($t ok (applicative-native? +)     "... + is applicative-native")
    ($t ok (applicative-native? first) "... first is applicative-native")
    ($t ok (not (applicative-native? (lambda (x) x))) "... lambda is not applicative-native")
    ($t ok (not (applicative-native? if)) "... if is not applicative-native")

    ($t diag "operative-native? predicate tests")
    ($t ok (operative-native? if)      "... if is operative-native")
    ($t ok (operative-native? and)     "... and is operative-native")
    ($t ok (operative-native? or)      "... or is operative-native")
    ($t ok (not (operative-native? +)) "... + is not operative-native")
    ($t ok (not (operative-native? (lambda (x) x))) "... lambda is not operative-native")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
