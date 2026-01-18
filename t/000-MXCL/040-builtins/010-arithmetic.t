#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'addition' => sub {
    is(eval_mxcl('(+ 1 2)')->value, 3, 'simple addition');
    is(eval_mxcl('(+ 10 20)')->value, 30, 'larger numbers');
    is(eval_mxcl('(+ 1.5 2.5)')->value, 4, 'float addition');
    is(eval_mxcl('(+ -5 10)')->value, 5, 'negative number');
};

subtest 'subtraction' => sub {
    is(eval_mxcl('(- 5 3)')->value, 2, 'simple subtraction');
    is(eval_mxcl('(- 3 5)')->value, -2, 'negative result');
    is(eval_mxcl('(- 10.5 0.5)')->value, 10, 'float subtraction');
};

subtest 'multiplication' => sub {
    is(eval_mxcl('(* 3 4)')->value, 12, 'simple multiplication');
    is(eval_mxcl('(* 2.5 4)')->value, 10, 'float multiplication');
    is(eval_mxcl('(* -3 4)')->value, -12, 'negative multiplication');
};

subtest 'division' => sub {
    is(eval_mxcl('(/ 10 2)')->value, 5, 'simple division');
    is(eval_mxcl('(/ 7 2)')->value, 3.5, 'non-integer division');
    is(eval_mxcl('(/ 1 4)')->value, 0.25, 'fraction');
};

subtest 'modulo' => sub {
    is(eval_mxcl('(% 10 3)')->value, 1, 'simple modulo');
    is(eval_mxcl('(% 15 5)')->value, 0, 'even modulo');
    is(eval_mxcl('(% 7 4)')->value, 3, 'remainder');
};

subtest 'nested arithmetic' => sub {
    is(eval_mxcl('(+ 1 (* 2 3))')->value, 7, '1 + (2 * 3)');
    is(eval_mxcl('(* (+ 1 2) (+ 3 4))')->value, 21, '(1+2) * (3+4)');
    is(eval_mxcl('(- (* 10 10) (+ 50 50))')->value, 0, '100 - 100');
};

done_testing;
