#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'native applicative' => sub {
    my $result = eval_mxcl('(+ 1 2)');
    ok($result isa MXCL::Term::Num, 'native applicative returns value');
    is($result->value, 3, 'correct result');
};

subtest 'native operative - lambda' => sub {
    my $result = eval_mxcl('(lambda (x) x)');
    ok($result isa MXCL::Term::Lambda, 'lambda operative returns Lambda');
};

subtest 'lambda application' => sub {
    my $result = eval_mxcl('((lambda (x) x) 42)');
    ok($result isa MXCL::Term::Num, 'lambda application returns value');
    is($result->value, 42, 'identity lambda');
};

subtest 'lambda with multiple params' => sub {
    my $result = eval_mxcl('((lambda (x y) (+ x y)) 10 20)');
    is($result->value, 30, 'multi-param lambda');
};

subtest 'lambda closure' => sub {
    my $result = eval_mxcl('
        (defvar make-adder (lambda (n) (lambda (x) (+ x n))))
        (defvar add10 (make-adder 10))
        (add10 5)
    ');
    is($result->value, 15, 'closure captures environment');
};

subtest 'defun creates named function' => sub {
    my $result = eval_mxcl('
        (defun double (x) (* x 2))
        (double 21)
    ');
    is($result->value, 42, 'defun function works');
};

subtest 'recursive function' => sub {
    my $result = eval_mxcl('
        (defun factorial (n)
            (if (<= n 1)
                1
                (* n (factorial (- n 1)))))
        (factorial 5)
    ');
    is($result->value, 120, 'recursive function');
};

subtest 'nested function calls' => sub {
    my $result = eval_mxcl('
        (defun add (a b) (+ a b))
        (defun mul (a b) (* a b))
        (add (mul 2 3) (mul 4 5))
    ');
    is($result->value, 26, 'nested calls (6 + 20)');
};

subtest 'operative - quote' => sub {
    my $result = eval_mxcl("'foo");
    ok($result isa MXCL::Term::Sym, 'quoted symbol not evaluated');
    is($result->ident, 'foo', 'correct symbol');
};

subtest 'operative - if' => sub {
    my $t = eval_mxcl('(if true 1 2)');
    is($t->value, 1, 'if true returns then');

    my $f = eval_mxcl('(if false 1 2)');
    is($f->value, 2, 'if false returns else');
};

subtest 'higher-order function' => sub {
    my $result = eval_mxcl('
        (defun apply-twice (f x) (f (f x)))
        (defun inc (n) (+ n 1))
        (apply-twice inc 0)
    ');
    is($result->value, 2, 'higher-order function');
};

done_testing;
