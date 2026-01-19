#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'Basic defer execution order' => sub {
    my $result = eval_with_output(q[
        (say "1")
        (defer (lambda () (say "3")))
        (say "2")
    ]);
    ok($result->{ok}, 'execution completed');
    is($result->{output}, "1\n2\n3\n", 'defer runs after normal code');
};

subtest 'Multiple defers in FIFO order' => sub {
    my $result = eval_with_output(q[
        (defer (lambda () (say "1")))
        (defer (lambda () (say "2")))
        (defer (lambda () (say "3")))
    ]);
    ok($result->{ok}, 'execution completed');
    is($result->{output}, "1\n2\n3\n", 'defers run in FIFO order');
};

subtest 'Defer in nested blocks' => sub {
    my $result = eval_with_output(q[
        (defer (lambda () (say "4")))
        {
            (defer (lambda () (say "2")))
            (say "1")
        }
        (say "3")
    ]);
    ok($result->{ok}, 'execution completed');
    is($result->{output}, "1\n2\n3\n4\n", 'inner defer runs when block exits');
};

subtest 'Defer with exceptions' => sub {
    my $result = eval_with_output(q[
        (try
            (do
                (defer (lambda () (say "cleanup")))
                (throw "error"))
            (catch (e) (say "caught")))
    ]);
    ok($result->{ok}, 'execution completed');
    is($result->{output}, "cleanup\ncaught\n", 'defer runs before catch');
};

subtest 'Multiple nested defers with exception' => sub {
    my $result = eval_with_output(q[
        (try
            (do
                (defer (lambda () (say "outer-defer")))
                {
                    (defer (lambda () (say "inner-defer")))
                    (throw "boom")
                })
            (catch (e) (say "caught")))
    ]);
    ok($result->{ok}, 'execution completed');
    is($result->{output}, "inner-defer\nouter-defer\ncaught\n", 'all defers run on exception');
};

subtest 'Defer does not affect return value' => sub {
    my $result = eval_mxcl(q[
        (do
            (defer (lambda () 999))
            42)
    ]);
    is($result->value, 42, 'defer does not change return value');
};

done_testing;
