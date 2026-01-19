#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "Basic try/catch tests")
    (is (try 42 (catch (e) e))      42      "... try returns value when no error")
    (is (try (+ 1 2) (catch (e) e)) 3       "... try with expression")

    (diag "throw and catch tests")
    (is (try (throw "error!") (catch (e) "caught"))
        "caught"
        "... catch handles thrown exception")

    (defvar caught-exception (try (throw "the message") (catch (e) e)))
    (ok (exception? caught-exception)
        "... catch receives exception object")

    (diag "try/catch with computation before throw")
    (is (try
            (do
                (defvar x 10)
                (throw "boom")
                x)
            (catch (e) "handled"))
        "handled"
        "... code after throw not executed")

    (diag "Nested try/catch")
    (is (try
            (try
                (throw "inner")
                (catch (e) "inner-caught"))
            (catch (e) "outer-caught"))
        "inner-caught"
        "... inner catch handles exception")

    (is (try
            (try
                (throw "inner")
                (catch (e) (throw "rethrow")))
            (catch (e) "outer-caught"))
        "outer-caught"
        "... rethrown exception caught by outer")

    (diag "Exception in catch handler")
    (defvar rethrow-result
        (try
            (try
                (throw "first")
                (catch (e) (throw "second")))
            (catch (e) e)))
    (ok (exception? rethrow-result)
        "... exception in catch propagates")

    (diag "try/catch with conditional throw")
    (defun maybe-throw (should-throw)
        (if should-throw
            (throw "thrown!")
            "no throw"))

    (is (try (maybe-throw false) (catch (e) "caught"))
        "no throw"
        "... no exception when condition false")

    (is (try (maybe-throw true) (catch (e) "caught"))
        "caught"
        "... exception when condition true")

    (diag "Exception handling patterns")
    (is (try
            (throw "original")
            (catch (e) (~ "Error: " (stringify e))))
        "Error: (exception original)"
        "... exception can be stringified")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
