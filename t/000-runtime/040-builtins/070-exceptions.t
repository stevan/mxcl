#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'throw' => sub {
    ok(eval_throws('(throw "error")'), 'throw causes error');
};

subtest 'try without exception' => sub {
    my $result = eval_mxcl('(try 42 (catch (e) 0))');
    is($result->value, 42, 'try returns body value');
};

subtest 'try catches throw' => sub {
    my $result = eval_mxcl('(try (throw "x") (catch (e) 99))');
    is($result->value, 99, 'catch handler runs');
};

subtest 'catch receives exception' => sub {
    my $result = eval_mxcl('(try (throw "test") (catch (e) e))');
    ok($result isa MXCL::Term::Exception, 'exception passed to handler');
};

subtest 'exception? predicate' => sub {
    my $result = eval_mxcl('
        (try
            (throw "x")
            (catch (e) (exception? e)))
    ');
    ok($result->value, 'exception? true for exception');

    ok(!eval_mxcl('(exception? 42)')->value, 'exception? false for non-exception');
};

subtest 'nested try - inner catches' => sub {
    my $result = eval_mxcl('
        (try
            (+ 1 (try (throw "inner") (catch (e) 10)))
            (catch (e) 99))
    ');
    is($result->value, 11, 'inner catch handles, outer continues');
};

subtest 'rethrow' => sub {
    my $result = eval_mxcl('
        (try
            (try
                (throw "original")
                (catch (e) (throw "rethrown")))
            (catch (e) 42))
    ');
    is($result->value, 42, 'rethrown exception caught by outer');
};

subtest 'exception in catch handler' => sub {
    my $result = eval_mxcl('
        (try
            (try
                (throw "first")
                (catch (e) (throw "second")))
            (catch (e) 100))
    ');
    is($result->value, 100, 'exception in handler caught by outer');
};

done_testing;
