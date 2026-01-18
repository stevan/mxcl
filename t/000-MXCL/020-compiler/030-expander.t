#!perl

use v5.42;
use Test::More;

use MXCL::Tokenizer;
use MXCL::Parser;
use MXCL::Expander;
use MXCL::Term;
use MXCL::Term::Parser;

my $tokenizer = MXCL::Tokenizer->new;
my $parser = MXCL::Parser->new;
my $expander = MXCL::Expander->new;

sub expand_string ($source) {
    my $tokens = $tokenizer->tokenize($source);
    my $parsed = $parser->parse($tokens);
    return $expander->expand($parsed);
}

subtest 'numbers' => sub {
    my $exprs = expand_string('42 3.14');
    is(scalar @$exprs, 2, 'two expressions');

    ok($exprs->[0] isa MXCL::Term::Num, 'integer becomes Num');
    is($exprs->[0]->value, 42, 'correct value');

    ok($exprs->[1] isa MXCL::Term::Num, 'float becomes Num');
    is($exprs->[1]->value, 3.14, 'correct float value');
};

subtest 'strings' => sub {
    my $exprs = expand_string('"hello"');
    is(scalar @$exprs, 1, 'one expression');

    ok($exprs->[0] isa MXCL::Term::Str, 'string becomes Str');
    is($exprs->[0]->value, 'hello', 'quotes removed');
};

subtest 'booleans' => sub {
    my $exprs = expand_string('true false');
    is(scalar @$exprs, 2, 'two expressions');

    ok($exprs->[0] isa MXCL::Term::Bool, 'true becomes Bool');
    ok($exprs->[0]->value, 'true is truthy');

    ok($exprs->[1] isa MXCL::Term::Bool, 'false becomes Bool');
    ok(!$exprs->[1]->value, 'false is falsy');
};

subtest 'symbols' => sub {
    my $exprs = expand_string('foo bar-baz');
    is(scalar @$exprs, 2, 'two expressions');

    ok($exprs->[0] isa MXCL::Term::Sym, 'identifier becomes Sym');
    is($exprs->[0]->ident, 'foo', 'correct ident');

    ok($exprs->[1] isa MXCL::Term::Sym, 'hyphenated becomes Sym');
    is($exprs->[1]->ident, 'bar-baz', 'hyphen preserved');
};

subtest 'keywords' => sub {
    my $exprs = expand_string(':name :value');
    is(scalar @$exprs, 2, 'two expressions');

    ok($exprs->[0] isa MXCL::Term::Key, 'keyword becomes Key');
    is($exprs->[0]->ident, 'name', 'colon stripped from ident');

    ok($exprs->[1] isa MXCL::Term::Key, 'second keyword');
    is($exprs->[1]->ident, 'value', 'correct ident');
};

subtest 'empty list becomes Nil' => sub {
    my $exprs = expand_string('()');
    is(scalar @$exprs, 1, 'one expression');

    ok($exprs->[0] isa MXCL::Term::Nil, 'empty list becomes Nil');
};

subtest 'list becomes List' => sub {
    my $exprs = expand_string('(foo 42)');
    is(scalar @$exprs, 1, 'one expression');

    my $list = $exprs->[0];
    ok($list isa MXCL::Term::List, 'list becomes List');
    is($list->length, 2, 'two elements');

    ok($list->first isa MXCL::Term::Sym, 'first is Sym');
    is($list->first->ident, 'foo', 'correct ident');

    my $rest = $list->rest;
    ok($rest->first isa MXCL::Term::Num, 'second is Num');
};

subtest 'pair with dot' => sub {
    my $exprs = expand_string('(a . b)');
    is(scalar @$exprs, 1, 'one expression');

    my $pair = $exprs->[0];
    ok($pair isa MXCL::Term::Pair, 'dot syntax creates Pair');
    ok($pair->fst isa MXCL::Term::Sym, 'fst is Sym');
    is($pair->fst->ident, 'a', 'fst ident');
    ok($pair->snd isa MXCL::Term::Sym, 'snd is Sym');
    is($pair->snd->ident, 'b', 'snd ident');
};

subtest 'quote expands to quote call' => sub {
    my $exprs = expand_string("'foo");
    is(scalar @$exprs, 1, 'one expression');

    my $list = $exprs->[0];
    ok($list isa MXCL::Term::List, 'quote creates List');
    is($list->length, 2, 'quote + symbol');

    ok($list->first isa MXCL::Term::Sym, 'first is quote sym');
    is($list->first->ident, 'quote', 'quote symbol');
};

subtest 'block expands to do call' => sub {
    my $exprs = expand_string('{foo bar}');
    is(scalar @$exprs, 1, 'one expression');

    my $list = $exprs->[0];
    ok($list isa MXCL::Term::List, 'block creates List');
    is($list->first->ident, 'do', 'first is do');
};

subtest 'tuple expands to tuple/new call' => sub {
    my $exprs = expand_string('[1 2 3]');
    is(scalar @$exprs, 1, 'one expression');

    my $list = $exprs->[0];
    ok($list isa MXCL::Term::List, 'tuple creates List');
    is($list->first->ident, 'tuple/new', 'first is tuple/new');
    is($list->length, 4, 'tuple/new + 3 elements');
};

subtest 'array expands to array/new call' => sub {
    my $exprs = expand_string('@[1 2 3]');
    is(scalar @$exprs, 1, 'one expression');

    my $list = $exprs->[0];
    ok($list isa MXCL::Term::List, 'array creates List');
    is($list->first->ident, 'array/new', 'first is array/new');
};

subtest 'hash expands to hash/new call' => sub {
    my $exprs = expand_string('%{:a 1}');
    is(scalar @$exprs, 1, 'one expression');

    my $list = $exprs->[0];
    ok($list isa MXCL::Term::List, 'hash creates List');
    is($list->first->ident, 'hash/new', 'first is hash/new');
};

subtest 'nested structure' => sub {
    my $exprs = expand_string('(+ 1 (* 2 3))');
    is(scalar @$exprs, 1, 'one expression');

    my $outer = $exprs->[0];
    ok($outer isa MXCL::Term::List, 'outer is List');
    is($outer->first->ident, '+', 'outer operator');

    my @items = $outer->uncons;
    my $inner = $items[2];
    ok($inner isa MXCL::Term::List, 'inner is List');
    is($inner->first->ident, '*', 'inner operator');
};

done_testing;
