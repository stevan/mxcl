#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'try/catch - no exception' => sub {
    my $result = eval_mxcl('
        (try
            (+ 1 2)
            (catch (e) 0))
    ');
    is($result->value, 3, 'try returns body value when no exception');
};

subtest 'try/catch - catches exception' => sub {
    my $result = eval_mxcl('
        (try
            (throw "error!")
            (catch (e) 42))
    ');
    is($result->value, 42, 'catch handler runs on throw');
};

subtest 'try/catch - exception in nested call' => sub {
    my $result = eval_mxcl('
        (defun explode () (throw "boom"))
        (try
            (explode)
            (catch (e) 99))
    ');
    is($result->value, 99, 'catch handles nested throw');
};

subtest 'try/catch - handler receives exception' => sub {
    my $result = eval_mxcl('
        (try
            (throw "the-error")
            (catch (e) e))
    ');
    ok($result isa MXCL::Term::Exception, 'handler receives exception');
};

subtest 'nested try/catch - inner catches' => sub {
    my $result = eval_mxcl('
        (try
            (try
                (throw "inner")
                (catch (e) 1))
            (catch (e) 2))
    ');
    is($result->value, 1, 'inner catch handles');
};

subtest 'nested try/catch - outer catches' => sub {
    my $result = eval_mxcl('
        (try
            (do
                (try
                    (throw "inner")
                    (catch (e) (throw "rethrow")))
                42)
            (catch (e) 99))
    ');
    is($result->value, 99, 'outer catches rethrown exception');
};

subtest 'uncaught exception goes to error handler' => sub {
    ok(eval_throws('(throw "uncaught")'), 'uncaught throw is error');
};

subtest 'undefined variable throws' => sub {
    ok(eval_throws('undefined-variable'), 'undefined variable throws');
};

subtest 'exception in condition' => sub {
    my $result = eval_mxcl('
        (try
            (if (throw "in-cond") 1 2)
            (catch (e) 42))
    ');
    is($result->value, 42, 'exception in if condition caught');
};

subtest 'try/catch preserves scope' => sub {
    my $result = eval_mxcl('
        (defvar x 10)
        (try
            (do (defvar y 20) (+ x y))
            (catch (e) 0))
    ');
    is($result->value, 30, 'scope preserved in try');
};

done_testing;
