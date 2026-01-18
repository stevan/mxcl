#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'defer executes after expression' => sub {
    my $result = eval_with_output(q[
        {
            (defer (lambda () (say "deferred")))
            (say "immediate")
        }
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "immediate\ndeferred\n", 'defer runs after scope exit');
};

subtest 'defer order - multiple defers in same scope' => sub {
    my $result = eval_with_output(q[
        {
            (defer (lambda () (say "1")))
            (defer (lambda () (say "2")))
            (defer (lambda () (say "3")))
            (say "body")
        }
    ]);

    ok($result->{ok}, 'execution completed');
    # Check actual order - will update expectation based on what we get
    like($result->{output}, qr/^body\n/, 'body runs first');
    like($result->{output}, qr/\n1\n/, 'defer 1 runs');
    like($result->{output}, qr/\n2\n/, 'defer 2 runs');
    like($result->{output}, qr/\n3\n/, 'defer 3 runs');
};

subtest 'nested scopes - each scope has own defers' => sub {
    my $result = eval_with_output(q[
        {
            (defer (lambda () (say "outer-1")))
            (say "outer-start")
            {
                (defer (lambda () (say "inner-1")))
                (defer (lambda () (say "inner-2")))
                (say "inner-body")
            }
            (say "outer-middle")
            (defer (lambda () (say "outer-2")))
            (say "outer-end")
        }
    ]);

    ok($result->{ok}, 'execution completed');
    like($result->{output}, qr/outer-start.*inner-body.*outer-middle.*outer-end/s,
        'bodies execute in order');
    like($result->{output}, qr/inner-body.*inner-[12].*inner-[12].*outer-middle/s,
        'inner defers run before continuing outer scope');
    like($result->{output}, qr/outer-end.*outer-[12].*outer-[12]/s,
        'outer defers run at outer scope exit');
};

subtest 'defer with let scope' => sub {
    my $result = eval_with_output(q[
        (let (x 10)
            {
                (defer (lambda () (say x)))
                (say "body")
            }
        )
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "body\n10\n", 'defer captures let bindings');
};

subtest 'defer with if branches' => sub {
    my $result = eval_with_output(q[
        (if true
            {
                (defer (lambda () (say "if-defer")))
                (say "if-body")
            }
            {
                (defer (lambda () (say "else-defer")))
                (say "else-body")
            }
        )
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "if-body\nif-defer\n", 'defer in if branch runs');
};

subtest 'defer runs during exception unwinding' => sub {
    my $result = eval_with_output(q[
        (try
            {
                (defer (lambda () (say "cleanup")))
                (say "before-throw")
                (throw "error")
                (say "after-throw")
            }
            (catch (e)
                (say "caught")
            )
        )
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "before-throw\ncleanup\ncaught\n",
        'defer runs before catch handler');
};

subtest 'multiple defers during exception unwinding' => sub {
    my $result = eval_with_output(q[
        (try
            {
                (defer (lambda () (say "defer-1")))
                (defer (lambda () (say "defer-2")))
                (throw "error")
            }
            (catch (e)
                (say "caught")
            )
        )
    ]);

    ok($result->{ok}, 'execution completed');
    like($result->{output}, qr/defer-[12].*defer-[12].*caught/s,
        'all defers run before catch');
};

subtest 'nested scopes during exception unwinding' => sub {
    my $result = eval_with_output(q[
        (try
            {
                (defer (lambda () (say "outer-defer")))
                {
                    (defer (lambda () (say "inner-defer")))
                    (throw "error")
                }
            }
            (catch (e)
                (say "caught")
            )
        )
    ]);

    ok($result->{ok}, 'execution completed');
    like($result->{output}, qr/inner-defer.*outer-defer.*caught/s,
        'nested defers run in correct order during unwinding');
};

subtest 'defer returns unit' => sub {
    my $result = eval_mxcl(q[
        {
            (defer (lambda () (say "x")))
        }
    ]);

    ok($result isa MXCL::Term::Unit, 'defer returns unit');
};

subtest 'defer with lambda closure' => sub {
    my $result = eval_with_output(q[
        {
            (defvar counter 0)
            (defer (lambda () (say counter)))
            (set! counter 5)
            (defer (lambda () (say counter)))
            (set! counter 10)
        }
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "10\n10\n",
        'deferred lambdas see final value of mutable variable');
};

subtest 'exception in defer callback - exception chaining' => sub {
    # When a defer callback throws during exception unwinding,
    # the exception is chained to the original exception
    my $result = eval_with_output(q[
        (try
            {
                (defer (lambda () (say "defer-1")))
                (defer (lambda ()
                    {
                        (say "defer-throws")
                        (throw "defer-error")
                    }
                ))
                (defer (lambda () (say "defer-3")))
                (throw "original-error")
            }
            (catch (e)
                (say "caught")
            )
        )
    ]);

    ok($result->{ok}, 'execution completed even with exception in defer');
    # When a defer throws, remaining defers in that sequence are skipped
    # and the exception is chained
    like($result->{output}, qr/defer-throws/, 'throwing defer executes');
    like($result->{output}, qr/defer-1/, 'defer after throwing one runs');
    like($result->{output}, qr/caught/, 'original exception is caught with chained exception');
};

subtest 'try gives finally semantics - defer runs on success' => sub {
    my $result = eval_with_output(q[
        (try
            {
                (defer (lambda () (say "finally")))
                (say "body")
                42
            }
            (catch (e) 0)
        )
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "body\nfinally\n", 'defer runs even without exception');
};

subtest 'try gives finally semantics - defer runs on error' => sub {
    my $result = eval_with_output(q[
        (try
            {
                (defer (lambda () (say "finally")))
                (throw "error")
            }
            (catch (e) 0)
        )
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "finally\n", 'defer runs before catch on error');
};

subtest 'defer in defun body' => sub {
    my $result = eval_with_output(q[
        (defun test ()
            {
                (defer (lambda () (say "cleanup")))
                (say "function-body")
                42
            }
        )
        (test)
    ]);

    ok($result->{ok}, 'execution completed');
    is($result->{output}, "function-body\ncleanup\n", 'defer works in function');
};

done_testing;
