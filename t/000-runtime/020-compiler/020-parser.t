#!perl

use v5.42;
use Test::More;

use MXCL::Tokenizer;
use MXCL::Parser;
use MXCL::Term::Parser;

my $tokenizer = MXCL::Tokenizer->new;
my $parser = MXCL::Parser->new;

sub parse_string ($source) {
    my $tokens = $tokenizer->tokenize($source);
    return $parser->parse($tokens);
}

subtest 'single symbol' => sub {
    my $exprs = parse_string('foo');
    is(scalar @$exprs, 1, 'one expression');
    ok($exprs->[0] isa MXCL::Term::Parser::Token, 'is Token');
    is($exprs->[0]->source, 'foo', 'correct source');
};

subtest 'multiple symbols' => sub {
    my $exprs = parse_string('foo bar baz');
    is(scalar @$exprs, 3, 'three expressions');
    is($exprs->[0]->source, 'foo', 'first');
    is($exprs->[1]->source, 'bar', 'second');
    is($exprs->[2]->source, 'baz', 'third');
};

subtest 'simple list' => sub {
    my $exprs = parse_string('(foo bar)');
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    ok($compound isa MXCL::Term::Parser::Compound, 'is Compound');
    is($compound->open->source, '(', 'open paren');
    is($compound->close->source, ')', 'close paren');

    my @elements = @{$compound->elements};
    is(scalar @elements, 2, 'two elements');
    is($elements[0]->source, 'foo', 'first element');
    is($elements[1]->source, 'bar', 'second element');
};

subtest 'nested lists' => sub {
    my $exprs = parse_string('(+ 1 (* 2 3))');
    is(scalar @$exprs, 1, 'one expression');

    my $outer = $exprs->[0];
    ok($outer isa MXCL::Term::Parser::Compound, 'outer is Compound');

    my @elements = @{$outer->elements};
    is(scalar @elements, 3, 'three elements in outer');
    is($elements[0]->source, '+', 'operator');
    is($elements[1]->source, '1', 'first arg');

    my $inner = $elements[2];
    ok($inner isa MXCL::Term::Parser::Compound, 'inner is Compound');
    my @inner_elements = @{$inner->elements};
    is(scalar @inner_elements, 3, 'three elements in inner');
    is($inner_elements[0]->source, '*', 'inner operator');
};

subtest 'empty list' => sub {
    my $exprs = parse_string('()');
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    ok($compound isa MXCL::Term::Parser::Compound, 'is Compound');
    is(scalar @{$compound->elements}, 0, 'no elements');
};

subtest 'brackets - tuple' => sub {
    my $exprs = parse_string('[1 2 3]');
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    is($compound->open->source, '[', 'open bracket');
    is($compound->close->source, ']', 'close bracket');
    is(scalar @{$compound->elements}, 3, 'three elements');
};

subtest 'brackets - array' => sub {
    my $exprs = parse_string('@[1 2 3]');
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    is($compound->open->source, '@[', 'open @[');
    is($compound->close->source, ']', 'close bracket');
};

subtest 'braces - block' => sub {
    my $exprs = parse_string('{foo bar}');
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    is($compound->open->source, '{', 'open brace');
    is($compound->close->source, '}', 'close brace');
};

subtest 'braces - hash' => sub {
    my $exprs = parse_string('%{:a 1 :b 2}');
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    is($compound->open->source, '%{', 'open %{');
    is($compound->close->source, '}', 'close brace');
};

subtest 'quote' => sub {
    my $exprs = parse_string("'foo");
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    ok($compound isa MXCL::Term::Parser::Compound, 'quote creates Compound');
    is($compound->open->source, "'", 'open is quote');
    is(scalar @{$compound->elements}, 1, 'one quoted element');
    is($compound->elements->[0]->source, 'foo', 'quoted symbol');
};

subtest 'quote list' => sub {
    my $exprs = parse_string("'(a b c)");
    is(scalar @$exprs, 1, 'one expression');

    my $compound = $exprs->[0];
    is($compound->open->source, "'", 'outer is quote');

    my $inner = $compound->elements->[0];
    ok($inner isa MXCL::Term::Parser::Compound, 'inner is list');
    is(scalar @{$inner->elements}, 3, 'three quoted elements');
};

done_testing;
