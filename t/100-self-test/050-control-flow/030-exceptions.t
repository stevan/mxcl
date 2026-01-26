#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "Basic try/catch tests")
    ($t is (try 42 (catch (e) e))      42      "... try returns value when no error")
    ($t is (try (+ 1 2) (catch (e) e)) 3       "... try with expression")

    ($t diag "throw and catch tests")
    ($t is (try (throw "error!") (catch (e) "caught"))
        "caught"
        "... catch handles thrown exception")

    (defvar caught-exception (try (throw "the message") (catch (e) e)))
    ($t ok (exception? caught-exception)
        "... catch receives exception object")

    ($t diag "try/catch with computation before throw")
    ($t is (try
            (do
                (defvar x 10)
                (throw "boom")
                x)
            (catch (e) "handled"))
        "handled"
        "... code after throw not executed")

    ($t diag "Nested try/catch")
    ($t is (try
            (try
                (throw "inner")
                (catch (e) "inner-caught"))
            (catch (e) "outer-caught"))
        "inner-caught"
        "... inner catch handles exception")

    ($t is (try
            (try
                (throw "inner")
                (catch (e) (throw "rethrow")))
            (catch (e) "outer-caught"))
        "outer-caught"
        "... rethrown exception caught by outer")

    ($t diag "Exception in catch handler")
    (defvar rethrow-result
        (try
            (try
                (throw "first")
                (catch (e) (throw "second")))
            (catch (e) e)))
    ($t ok (exception? rethrow-result)
        "... exception in catch propagates")

    ($t diag "try/catch with conditional throw")
    (defun maybe-throw (should-throw)
        (if should-throw
            (throw "thrown!")
            "no throw"))

    ($t is (try (maybe-throw false) (catch (e) "caught"))
        "no throw"
        "... no exception when condition false")

    ($t is (try (maybe-throw true) (catch (e) "caught"))
        "caught"
        "... exception when condition true")

    ($t diag "Exception handling patterns")
    ($t is (try
            (throw "original")
            (catch (e) (~ "Error: " (stringify e))))
        "Error: (exception original)"
        "... exception can be stringified")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
