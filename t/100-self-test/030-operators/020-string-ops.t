#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "String concatenation tests")
    (is (~ "hello" " world")    "hello world"   "... concatenate two strings")
    (is (~ "foo" "bar")         "foobar"        "... concatenate without space")
    (is (~ "" "test")           "test"          "... concatenate with empty string")
    (is (~ "test" "")           "test"          "... concatenate to empty string")
    (is (~ "" "")               ""              "... concatenate two empty strings")
    (is (~ "a" (~ "b" "c"))     "abc"           "... nested concatenation")

    (diag "String concatenation tests (infix)")
    (is ("hello" ~  " world")    "hello world"   "... concatenate two strings")
    (is ("foo" ~  "bar")         "foobar"        "... concatenate without space")
    (is (""  ~ "test")           "test"          "... concatenate with empty string")
    (is ("test" ~  "")           "test"          "... concatenate to empty string")
    (is (""  ~ "")               ""              "... concatenate two empty strings")
    (is ("a" ~  (~ "b" "c"))     "abc"           "... nested concatenation")

    (diag "String concatenation with coercion")
    (is (~ "count: " 42)        "count: 42"     "... concatenate string with number")
    (is (~ 1 2)                 "12"            "... concatenate two numbers as strings")
    (is (~ "bool: " true)       "bool: true"    "... concatenate string with bool")

    (diag "String concatenation with coercion (infix)")
    (is ("count: " ~ 42)        "count: 42"     "... concatenate string with number")
    (is ("bool: " ~ true)       "bool: true"    "... concatenate string with bool")

    (diag "Split tests")
    (defvar parts (split "," "a,b,c"))
    (is (first parts)           "a"             "... split first element")
    (is (first (rest parts))    "b"             "... split second element")
    (is (first (rest (rest parts))) "c"         "... split third element")
    (is (list/length parts)     3               "... split produces 3 elements")

    (defvar words (split " " "hello world"))
    (is (first words)           "hello"         "... split by space first word")
    (is (first (rest words))    "world"         "... split by space second word")

    (defvar dotted (split "." "a.b.c"))
    (is (list/length dotted)    3               "... split by dot produces 3 elements")

    (diag "Join tests")
    (is (join "," (list/new "a" "b" "c"))   "a,b,c"     "... join list with comma")
    (is (join " " (list/new "hello" "world")) "hello world" "... join with space")
    (is (join "" (list/new "a" "b" "c"))    "abc"       "... join with empty string")
    (is (join "-" (list/new "one"))         "one"       "... join single element")

    (diag "Split and join roundtrip")
    (is (join "," (split "," "a,b,c"))      "a,b,c"     "... split then join is identity")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
