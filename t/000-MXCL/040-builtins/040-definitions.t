#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'defvar' => sub {
    my $result = eval_mxcl('(defvar x 42) x');
    is($result->value, 42, 'defvar defines variable');
};

subtest 'defvar returns value' => sub {
    my $result = eval_mxcl('(defvar x 42)');
    is($result->value, 42, 'defvar returns defined value');
};

subtest 'defvar with expression' => sub {
    my $result = eval_mxcl('(defvar x (+ 1 2)) x');
    is($result->value, 3, 'defvar evaluates expression');
};

subtest 'defun' => sub {
    my $result = eval_mxcl('
        (defun double (x) (* x 2))
        (double 21)
    ');
    is($result->value, 42, 'defun defines function');
};

subtest 'defun returns lambda' => sub {
    my $result = eval_mxcl('(defun f (x) x)');
    ok($result isa MXCL::Term::Lambda, 'defun returns Lambda');
};

subtest 'set!' => sub {
    my $result = eval_mxcl('
        (defvar x 10)
        (set! x 20)
        x
    ');
    is($result->value, 20, 'set! mutates variable');
};

subtest 'set! returns value' => sub {
    my $result = eval_mxcl('
        (defvar x 10)
        (set! x 42)
    ');
    is($result->value, 42, 'set! returns new value');
};

subtest 'let' => sub {
    my $result = eval_mxcl('(let (x 42) x)');
    is($result->value, 42, 'let binds variable');
};

subtest 'let scoping' => sub {
    my $result = eval_mxcl('
        (defvar x 10)
        (let (x 20) x)
    ');
    is($result->value, 20, 'let shadows outer');

    my $outer = eval_mxcl('
        (defvar x 10)
        (let (y 20) x)
    ');
    is($outer->value, 10, 'let sees outer scope');
};

subtest 'let does not leak' => sub {
    my $result = eval_mxcl('
        (defvar result 0)
        (let (x 42) (set! result x))
        result
    ');
    is($result->value, 42, 'can set outer from let');

    # x should not be visible after let
    ok(eval_throws('
        (let (x 42) x)
        x
    '), 'x not visible after let');
};

subtest 'nested let' => sub {
    my $result = eval_mxcl('
        (let (x 1)
            (let (y 2)
                (+ x y)))
    ');
    is($result->value, 3, 'nested let');
};

subtest 'do block' => sub {
    my $result = eval_mxcl('{1 2 3}');
    is($result->value, 3, 'do returns last');
};

subtest 'do with definitions' => sub {
    my $result = eval_mxcl('{
        (defvar x 10)
        (defvar y 20)
        (+ x y)
    }');
    is($result->value, 30, 'do with defvar');
};

done_testing;
