#!perl

use v5.42;
use Test::More;
use Test::MXCL;

subtest 'literal evaluation' => sub {
    my $num = eval_mxcl('42');
    ok($num isa MXCL::Term::Num, 'number evaluates to Num');
    is($num->value, 42, 'correct value');

    my $str = eval_mxcl('"hello"');
    ok($str isa MXCL::Term::Str, 'string evaluates to Str');
    is($str->value, 'hello', 'correct value');

    my $true = eval_mxcl('true');
    ok($true isa MXCL::Term::Bool, 'true evaluates to Bool');
    ok($true->value, 'is truthy');

    my $false = eval_mxcl('false');
    ok($false isa MXCL::Term::Bool, 'false evaluates to Bool');
    ok(!$false->value, 'is falsy');
};

subtest 'empty list evaluates to Nil' => sub {
    my $nil = eval_mxcl('()');
    ok($nil isa MXCL::Term::Nil, 'empty list is Nil');
};

subtest 'symbol lookup' => sub {
    my $result = eval_mxcl('(defvar x 42) x');
    ok($result isa MXCL::Term::Num, 'symbol lookup returns Num');
    is($result->value, 42, 'correct value from lookup');
};

subtest 'multiple expressions - returns last' => sub {
    my $result = eval_mxcl('1 2 3');
    ok($result isa MXCL::Term::Num, 'returns Num');
    is($result->value, 3, 'returns last expression');
};

subtest 'nested expressions' => sub {
    my $result = eval_mxcl('(+ 1 (+ 2 3))');
    ok($result isa MXCL::Term::Num, 'nested evaluates');
    is($result->value, 6, 'correct nested result');
};

subtest 'tuple construction' => sub {
    my $result = eval_mxcl('[1 2 3]');
    ok($result isa MXCL::Term::Tuple, 'tuple literal');
    is($result->size, 3, 'correct size');
};

subtest 'array construction' => sub {
    my $result = eval_mxcl('@[1 2 3]');
    ok($result isa MXCL::Term::Array, 'array literal');
    is($result->length, 3, 'correct length');
};

subtest 'hash construction' => sub {
    my $result = eval_mxcl('%{:a 1 :b 2}');
    ok($result isa MXCL::Term::Hash, 'hash literal');
    is($result->size, 2, 'correct size');
};

done_testing;
