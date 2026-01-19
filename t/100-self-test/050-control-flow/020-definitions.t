#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "defvar tests")
    (defvar my-num 42)
    (is my-num                      42      "... defvar binds number")

    (defvar my-str "hello")
    (is my-str                      "hello" "... defvar binds string")

    (defvar my-list (list/new 1 2 3))
    (ok (list? my-list)             "... defvar binds list")

    (defvar computed (+ 10 20))
    (is computed                    30      "... defvar evaluates expression")

    (diag "defun tests")
    (defun add-one (x) (+ x 1))
    (is (add-one 5)                 6       "... defun creates callable function")

    (defun add (x y) (+ x y))
    (is (add 3 4)                   7       "... defun with multiple args")

    (defun greet (name) (~ "Hello, " name))
    (is (greet "World")             "Hello, World" "... defun with string operations")

    (diag "defun with body expressions")
    (defun complex (x)
        (do
            (defvar doubled (* x 2))
            (+ doubled 1)))
    (is (complex 5)                 11      "... defun with do block body")

    (diag "Recursive defun")
    (defun factorial (n)
        (if (<= n 1)
            1
            (* n (factorial (- n 1)))))
    (is (factorial 0)               1       "... factorial 0")
    (is (factorial 1)               1       "... factorial 1")
    (is (factorial 5)               120     "... factorial 5")

    (diag "set! mutation tests")
    (defvar mutable 1)
    (set! mutable 2)
    (is mutable                     2       "... set! changes value")

    (set! mutable (+ mutable 10))
    (is mutable                     12      "... set! with computed value")

    (diag "set! in different scopes")
    (defvar outer-var 100)
    (defun modify-outer ()
        (set! outer-var 200))
    (modify-outer)
    (is outer-var                   200     "... set! modifies outer scope")

    (diag "lambda tests")
    (defvar identity (lambda (x) x))
    (is (identity 42)               42      "... lambda identity function")

    (defvar adder (lambda (a b) (+ a b)))
    (is (adder 10 20)               30      "... lambda with multiple args")

    (diag "Lambda as values")
    (defvar funcs (list/new
        (lambda (x) (+ x 1))
        (lambda (x) (* x 2))))
    (is ((first funcs) 5)           6       "... lambda from list")
    (is ((first (rest funcs)) 5)    10      "... second lambda from list")

    (diag "Closures")
    (defun make-adder (n)
        (lambda (x) (+ x n)))
    (defvar add-5 (make-adder 5))
    (defvar add-10 (make-adder 10))
    (is (add-5 3)                   8       "... closure captures n=5")
    (is (add-10 3)                  13      "... closure captures n=10")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
