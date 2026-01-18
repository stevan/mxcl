#!perl

use v5.42;
use Test::More;

use MXCL::Tokenizer;
use MXCL::Term::Parser;

my $tokenizer = MXCL::Tokenizer->new;

subtest 'simple tokens' => sub {
    my $tokens = $tokenizer->tokenize('foo bar baz');
    is(scalar @$tokens, 3, 'three tokens');
    is($tokens->[0]->source, 'foo', 'first token');
    is($tokens->[1]->source, 'bar', 'second token');
    is($tokens->[2]->source, 'baz', 'third token');
};

subtest 'numbers' => sub {
    my $tokens = $tokenizer->tokenize('42 3.14 -7');
    is(scalar @$tokens, 3, 'three tokens');
    is($tokens->[0]->source, '42', 'integer');
    is($tokens->[1]->source, '3.14', 'float');
    is($tokens->[2]->source, '-7', 'negative');
};

subtest 'strings' => sub {
    my $tokens = $tokenizer->tokenize('"hello" "world"');
    is(scalar @$tokens, 2, 'two tokens');
    is($tokens->[0]->source, '"hello"', 'first string with quotes');
    is($tokens->[1]->source, '"world"', 'second string with quotes');
};

subtest 'parentheses' => sub {
    my $tokens = $tokenizer->tokenize('(foo bar)');
    is(scalar @$tokens, 4, 'four tokens including parens');
    is($tokens->[0]->source, '(', 'open paren');
    is($tokens->[1]->source, 'foo', 'first symbol');
    is($tokens->[2]->source, 'bar', 'second symbol');
    is($tokens->[3]->source, ')', 'close paren');
};

subtest 'brackets and braces' => sub {
    my $tokens = $tokenizer->tokenize('[a b] {c d} @[e f] %{g h}');
    my @sources = map $_->source, @$tokens;
    is_deeply(\@sources, ['[', 'a', 'b', ']', '{', 'c', 'd', '}', '@[', 'e', 'f', ']', '%{', 'g', 'h', '}'], 'all bracket types');
};

subtest 'keywords' => sub {
    my $tokens = $tokenizer->tokenize(':key :value');
    is(scalar @$tokens, 2, 'two tokens');
    is($tokens->[0]->source, ':key', 'first keyword');
    is($tokens->[1]->source, ':value', 'second keyword');
};

subtest 'quote' => sub {
    my $tokens = $tokenizer->tokenize("'foo");
    is(scalar @$tokens, 2, 'two tokens');
    is($tokens->[0]->source, "'", 'quote');
    is($tokens->[1]->source, 'foo', 'quoted symbol');
};

subtest 'nested structure' => sub {
    my $tokens = $tokenizer->tokenize('(+ 1 (* 2 3))');
    my @sources = map $_->source, @$tokens;
    is_deeply(\@sources, ['(', '+', '1', '(', '*', '2', '3', ')', ')'], 'nested parens');
};

subtest 'line tracking' => sub {
    my $tokens = $tokenizer->tokenize("foo\nbar\nbaz");
    is($tokens->[0]->line, 0, 'first token line 0');
    is($tokens->[1]->line, 1, 'second token line 1');
    is($tokens->[2]->line, 2, 'third token line 2');
};

subtest 'whitespace handling' => sub {
    my $tokens = $tokenizer->tokenize("  foo   bar  ");
    is(scalar @$tokens, 2, 'whitespace ignored');
    is($tokens->[0]->source, 'foo', 'first token');
    is($tokens->[1]->source, 'bar', 'second token');
};

done_testing;
