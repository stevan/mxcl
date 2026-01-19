#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "String equality (eq) tests")
    (ok (eq "hello" "hello")        "... 'hello' eq 'hello'")
    (ok (eq "" "")                  "... '' eq ''")
    (ok (not (eq "hello" "world"))  "... not ('hello' eq 'world')")
    (ok (not (eq "Hello" "hello"))  "... case sensitive: 'Hello' ne 'hello'")

    (diag "String inequality (ne) tests")
    (ok (ne "hello" "world")        "... 'hello' ne 'world'")
    (ok (ne "a" "b")                "... 'a' ne 'b'")
    (ok (not (ne "test" "test"))    "... not ('test' ne 'test')")

    (diag "String less than (lt) tests")
    (ok (lt "a" "b")                "... 'a' lt 'b'")
    (ok (lt "abc" "abd")            "... 'abc' lt 'abd'")
    (ok (lt "A" "a")                "... 'A' lt 'a' (ASCII order)")
    (ok (not (lt "b" "a"))          "... not ('b' lt 'a')")
    (ok (not (lt "a" "a"))          "... not ('a' lt 'a')")

    (diag "String less than or equal (le) tests")
    (ok (le "a" "b")                "... 'a' le 'b'")
    (ok (le "a" "a")                "... 'a' le 'a'")
    (ok (not (le "b" "a"))          "... not ('b' le 'a')")

    (diag "String greater than (gt) tests")
    (ok (gt "b" "a")                "... 'b' gt 'a'")
    (ok (gt "abd" "abc")            "... 'abd' gt 'abc'")
    (ok (gt "a" "A")                "... 'a' gt 'A' (ASCII order)")
    (ok (not (gt "a" "b"))          "... not ('a' gt 'b')")
    (ok (not (gt "a" "a"))          "... not ('a' gt 'a')")

    (diag "String greater than or equal (ge) tests")
    (ok (ge "b" "a")                "... 'b' ge 'a'")
    (ok (ge "a" "a")                "... 'a' ge 'a'")
    (ok (not (ge "a" "b"))          "... not ('a' ge 'b')")

    (diag "String comparison (cmp) tests")
    (is (cmp "a" "b")   -1          "... 'a' cmp 'b' = -1")
    (is (cmp "b" "a")   1           "... 'b' cmp 'a' = 1")
    (is (cmp "a" "a")   0           "... 'a' cmp 'a' = 0")
    (is (cmp "abc" "abd") -1        "... 'abc' cmp 'abd' = -1")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
