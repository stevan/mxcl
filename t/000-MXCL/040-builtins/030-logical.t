#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'not' => sub {
    ok(!eval_mxcl('(not true)')->value, 'not true = false');
    ok(eval_mxcl('(not false)')->value, 'not false = true');
    ok(!eval_mxcl('(not 1)')->value, 'not 1 = false');
    ok(eval_mxcl('(not 0)')->value, 'not 0 = true');
    ok(eval_mxcl('(not "")')->value, 'not "" = true');
    ok(!eval_mxcl('(not "x")')->value, 'not "x" = false');
};

subtest 'and - both true' => sub {
    ok(eval_mxcl('(and true true)')->value, 'true and true');
};

subtest 'and - short circuit' => sub {
    # and returns first falsy or last truthy
    my $result = eval_mxcl('(and false (throw "never"))');
    ok(!$result->value, 'and short-circuits on false');
};

subtest 'and - returns last truthy' => sub {
    my $result = eval_mxcl('(and 1 2)');
    is($result->value, 2, 'and returns last truthy value');
};

subtest 'and - returns first falsy' => sub {
    my $result = eval_mxcl('(and 1 false)');
    ok(!$result->value, 'and returns false');

    my $result2 = eval_mxcl('(and 0 1)');
    is($result2->value, 0, 'and returns 0 (falsy)');
};

subtest 'or - both false' => sub {
    ok(!eval_mxcl('(or false false)')->value, 'false or false');
};

subtest 'or - short circuit' => sub {
    # or returns first truthy or last falsy
    my $result = eval_mxcl('(or true (throw "never"))');
    ok($result->value, 'or short-circuits on true');
};

subtest 'or - returns first truthy' => sub {
    my $result = eval_mxcl('(or 1 2)');
    is($result->value, 1, 'or returns first truthy');

    my $result2 = eval_mxcl('(or false 42)');
    is($result2->value, 42, 'or returns second when first falsy');
};

subtest 'or - returns last falsy' => sub {
    my $result = eval_mxcl('(or false 0)');
    is($result->value, 0, 'or returns last falsy value');
};

subtest 'combined logical' => sub {
    ok(eval_mxcl('(and (or false true) (not false))')->value, 'combined');
    ok(!eval_mxcl('(or (and true false) (and false true))')->value, 'complex');
};

done_testing;
