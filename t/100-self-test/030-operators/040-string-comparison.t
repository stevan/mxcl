#!perl

use v5.42;
use Test::More;
use MXCL::Machine;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "String equality (eq) tests")
    ($t ok (eq "hello" "hello")        "... 'hello' eq 'hello'")
    ($t ok (eq "" "")                  "... '' eq ''")
    ($t ok (not (eq "hello" "world"))  "... not ('hello' eq 'world')")
    ($t ok (not (eq "Hello" "hello"))  "... case sensitive: 'Hello' ne 'hello'")

    ($t diag "String inequality (ne) tests")
    ($t ok (ne "hello" "world")        "... 'hello' ne 'world'")
    ($t ok (ne "a" "b")                "... 'a' ne 'b'")
    ($t ok (not (ne "test" "test"))    "... not ('test' ne 'test')")

    ($t diag "String less than (lt) tests")
    ($t ok (lt "a" "b")                "... 'a' lt 'b'")
    ($t ok (lt "abc" "abd")            "... 'abc' lt 'abd'")
    ($t ok (lt "A" "a")                "... 'A' lt 'a' (ASCII order)")
    ($t ok (not (lt "b" "a"))          "... not ('b' lt 'a')")
    ($t ok (not (lt "a" "a"))          "... not ('a' lt 'a')")

    ($t diag "String less than or equal (le) tests")
    ($t ok (le "a" "b")                "... 'a' le 'b'")
    ($t ok (le "a" "a")                "... 'a' le 'a'")
    ($t ok (not (le "b" "a"))          "... not ('b' le 'a')")

    ($t diag "String greater than (gt) tests")
    ($t ok (gt "b" "a")                "... 'b' gt 'a'")
    ($t ok (gt "abd" "abc")            "... 'abd' gt 'abc'")
    ($t ok (gt "a" "A")                "... 'a' gt 'A' (ASCII order)")
    ($t ok (not (gt "a" "b"))          "... not ('a' gt 'b')")
    ($t ok (not (gt "a" "a"))          "... not ('a' gt 'a')")

    ($t diag "String greater than or equal (ge) tests")
    ($t ok (ge "b" "a")                "... 'b' ge 'a'")
    ($t ok (ge "a" "a")                "... 'a' ge 'a'")
    ($t ok (not (ge "a" "b"))          "... not ('a' ge 'b')")

    ($t diag "String comparison (cmp) tests")
    ($t is (cmp "a" "b")   -1          "... 'a' cmp 'b' = -1")
    ($t is (cmp "b" "a")   1           "... 'b' cmp 'a' = 1")
    ($t is (cmp "a" "a")   0           "... 'a' cmp 'a' = 0")
    ($t is (cmp "abc" "abd") -1        "... 'abc' cmp 'abd' = -1")

    ($t done)
];

my $kont = MXCL::Machine->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
