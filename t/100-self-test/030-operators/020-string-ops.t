#!perl

use v5.42;
use Test::More;
use MXCL::Machine;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "String concatenation tests")
    ($t is (~ "hello" " world")    "hello world"   "... concatenate two strings")
    ($t is (~ "foo" "bar")         "foobar"        "... concatenate without space")
    ($t is (~ "" "test")           "test"          "... concatenate with empty string")
    ($t is (~ "test" "")           "test"          "... concatenate to empty string")
    ($t is (~ "" "")               ""              "... concatenate two empty strings")
    ($t is (~ "a" (~ "b" "c"))     "abc"           "... nested concatenation")

    ($t diag "String concatenation tests (infix)")
    ($t is ("hello" ~  " world")    "hello world"   "... concatenate two strings")
    ($t is ("foo" ~  "bar")         "foobar"        "... concatenate without space")
    ($t is (""  ~ "test")           "test"          "... concatenate with empty string")
    ($t is ("test" ~  "")           "test"          "... concatenate to empty string")
    ($t is (""  ~ "")               ""              "... concatenate two empty strings")
    ($t is ("a" ~  (~ "b" "c"))     "abc"           "... nested concatenation")

    ($t diag "String concatenation with coercion")
    ($t is (~ "count: " 42)        "count: 42"     "... concatenate string with number")
    ($t is (~ 1 2)                 "12"            "... concatenate two numbers as strings")
    ($t is (~ "bool: " true)       "bool: true"    "... concatenate string with bool")

    ($t diag "String concatenation with coercion (infix)")
    ($t is ("count: " ~ 42)        "count: 42"     "... concatenate string with number")
    ($t is ("bool: " ~ true)       "bool: true"    "... concatenate string with bool")

    ($t diag "Split tests")
    (defvar parts (split "," "a,b,c"))
    ($t is (first parts)           "a"             "... split first element")
    ($t is (first (rest parts))    "b"             "... split second element")
    ($t is (first (rest (rest parts))) "c"         "... split third element")
    ($t is (list/length parts)     3               "... split produces 3 elements")

    (defvar words (split " " "hello world"))
    ($t is (first words)           "hello"         "... split by space first word")
    ($t is (first (rest words))    "world"         "... split by space second word")

    (defvar dotted (split "." "a.b.c"))
    ($t is (list/length dotted)    3               "... split by dot produces 3 elements")

    ($t diag "Join tests")
    ($t is (join "," (list/new "a" "b" "c"))   "a,b,c"     "... join list with comma")
    ($t is (join " " (list/new "hello" "world")) "hello world" "... join with space")
    ($t is (join "" (list/new "a" "b" "c"))    "abc"       "... join with empty string")
    ($t is (join "-" (list/new "one"))         "one"       "... join single element")

    ($t diag "Split and join roundtrip")
    ($t is (join "," (split "," "a,b,c"))      "a,b,c"     "... split then join is identity")

    ($t done)
];

my $kont = MXCL::Machine->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
