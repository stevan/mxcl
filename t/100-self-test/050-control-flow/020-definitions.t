#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (defvar $t (Tester))

    ($t diag "defvar tests")
    (defvar my-num 42)
    ($t is my-num                      42      "... defvar binds number")

    (defvar my-str "hello")
    ($t is my-str                      "hello" "... defvar binds string")

    (defvar my-list (list/new 1 2 3))
    ($t ok (list? my-list)             "... defvar binds list")

    (defvar computed (+ 10 20))
    ($t is computed                    30      "... defvar evaluates expression")

    ($t diag "defun tests")
    (defun add-one (x) (+ x 1))
    ($t is (add-one 5)                 6       "... defun creates callable function")

    (defun add (x y) (+ x y))
    ($t is (add 3 4)                   7       "... defun with multiple args")

    (defun greet (name) (~ "Hello, " name))
    ($t is (greet "World")             "Hello, World" "... defun with string operations")

    ($t diag "defun with body expressions")
    (defun complex (x)
        (do
            (defvar doubled (* x 2))
            (+ doubled 1)))
    ($t is (complex 5)                 11      "... defun with do block body")

    ($t diag "Recursive defun")
    (defun factorial (n)
        (if (<= n 1)
            1
            (* n (factorial (- n 1)))))
    ($t is (factorial 0)               1       "... factorial 0")
    ($t is (factorial 1)               1       "... factorial 1")
    ($t is (factorial 5)               120     "... factorial 5")

    ($t diag "set! mutation tests")
    (defvar mutable 1)
    (set! mutable 2)
    ($t is mutable                     2       "... set! changes value")

    (set! mutable (+ mutable 10))
    ($t is mutable                     12      "... set! with computed value")

    ($t diag "set! in different scopes")
    (defvar outer-var 100)
    (defun modify-outer ()
        (set! outer-var 200))
    (modify-outer)
    ($t is outer-var                   200     "... set! modifies outer scope")

    ($t diag "lambda tests")
    (defvar identity (lambda (x) x))
    ($t is (identity 42)               42      "... lambda identity function")

    (defvar adder (lambda (a b) (+ a b)))
    ($t is (adder 10 20)               30      "... lambda with multiple args")

    ($t diag "Lambda as values")
    (defvar funcs (list/new
        (lambda (x) (+ x 1))
        (lambda (x) (* x 2))))
    ($t is ((first funcs) 5)           6       "... lambda from list")
    ($t is ((first (rest funcs)) 5)    10      "... second lambda from list")

    ($t diag "Closures")
    (defun make-adder (n)
        (lambda (x) (+ x n)))
    (defvar add-5 (make-adder 5))
    (defvar add-10 (make-adder 10))
    ($t is (add-5 3)                   8       "... closure captures n=5")
    ($t is (add-10 3)                  13      "... closure captures n=10")

    ($t done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
