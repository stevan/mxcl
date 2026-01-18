#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'list/new' => sub {
    my $result = eval_mxcl('(list/new 1 2 3)');
    ok($result isa MXCL::Term::List, 'creates List');
    is($result->length, 3, 'correct length');
};

subtest 'first' => sub {
    is(eval_mxcl('(first (list/new 1 2 3))')->value, 1, 'first of list');
};

subtest 'rest' => sub {
    my $result = eval_mxcl('(rest (list/new 1 2 3))');
    ok($result isa MXCL::Term::List, 'rest is List');
    is($result->length, 2, 'rest has 2 elements');
    is($result->first->value, 2, 'rest starts at second');
};

subtest 'rest of single' => sub {
    my $result = eval_mxcl('(rest (list/new 1))');
    ok($result isa MXCL::Term::Nil, 'rest of single is Nil');
};

subtest 'pair/new' => sub {
    my $result = eval_mxcl('(pair/new 1 2)');
    ok($result isa MXCL::Term::Pair, 'creates Pair');
};

subtest 'fst and snd' => sub {
    is(eval_mxcl('(fst (pair/new 10 20))')->value, 10, 'fst of pair');
    is(eval_mxcl('(snd (pair/new 10 20))')->value, 20, 'snd of pair');
};

subtest 'tuple/new' => sub {
    my $result = eval_mxcl('[1 2 3]');
    ok($result isa MXCL::Term::Tuple, 'bracket syntax creates Tuple');
    is($result->size, 3, 'correct size');
};

subtest 'array/new' => sub {
    my $result = eval_mxcl('@[1 2 3]');
    ok($result isa MXCL::Term::Array, '@[] creates Array');
    is($result->length, 3, 'correct length');
};

subtest 'hash/new' => sub {
    my $result = eval_mxcl('%{:a 1 :b 2}');
    ok($result isa MXCL::Term::Hash, '%{} creates Hash');
    is($result->size, 2, 'correct size');
};

subtest 'predicates' => sub {
    ok(eval_mxcl('(list? (list/new 1 2))')->value, 'list? true for list');
    ok(!eval_mxcl('(list? 42)')->value, 'list? false for non-list');

    ok(eval_mxcl('(nil? ())')->value, 'nil? true for nil');
    ok(!eval_mxcl('(nil? (list/new 1))')->value, 'nil? false for non-nil');

    ok(eval_mxcl('(pair? (pair/new 1 2))')->value, 'pair? true for pair');
    ok(eval_mxcl('(tuple? [1 2])')->value, 'tuple? true for tuple');
    ok(eval_mxcl('(array? @[1 2])')->value, 'array? true for array');
    ok(eval_mxcl('(hash? %{:a 1})')->value, 'hash? true for hash');
};

subtest 'eq? for collections' => sub {
    ok(eval_mxcl('(eq? (list/new 1 2) (list/new 1 2))')->value, 'equal lists');
    ok(!eval_mxcl('(eq? (list/new 1 2) (list/new 1 3))')->value, 'unequal lists');
    ok(eval_mxcl('(eq? () ())')->value, 'nil equals nil');
};

done_testing;
