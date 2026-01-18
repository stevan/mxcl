#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'if - true condition' => sub {
    is(eval_mxcl('(if true 1 2)')->value, 1, 'if true returns then');
};

subtest 'if - false condition' => sub {
    is(eval_mxcl('(if false 1 2)')->value, 2, 'if false returns else');
};

subtest 'if - truthy values' => sub {
    is(eval_mxcl('(if 1 "yes" "no")')->value, 'yes', 'non-zero is truthy');
    is(eval_mxcl('(if "x" "yes" "no")')->value, 'yes', 'non-empty string is truthy');
};

subtest 'if - falsy values' => sub {
    is(eval_mxcl('(if 0 "yes" "no")')->value, 'no', 'zero is falsy');
    is(eval_mxcl('(if "" "yes" "no")')->value, 'no', 'empty string is falsy');
    is(eval_mxcl('(if () "yes" "no")')->value, 'no', 'nil is falsy');
};

subtest 'if - evaluates only one branch' => sub {
    # If both branches were evaluated, this would throw
    my $result = eval_mxcl('(if true 42 (throw "should not run"))');
    is($result->value, 42, 'else branch not evaluated when true');

    $result = eval_mxcl('(if false (throw "should not run") 42)');
    is($result->value, 42, 'then branch not evaluated when false');
};

subtest 'if - condition is evaluated' => sub {
    my $result = eval_mxcl('
        (defvar x 5)
        (if (> x 3) "big" "small")
    ');
    is($result->value, 'big', 'condition expression evaluated');
};

subtest 'if - nested' => sub {
    my $result = eval_mxcl('
        (defvar x 5)
        (if (> x 10)
            "large"
            (if (> x 3)
                "medium"
                "small"))
    ');
    is($result->value, 'medium', 'nested if');
};

subtest 'if - scoping' => sub {
    my $result = eval_mxcl('
        (defvar x 10)
        (if true
            (do (defvar y 20) (+ x y))
            0)
    ');
    is($result->value, 30, 'if branch has access to outer scope');
};

done_testing;
