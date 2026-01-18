#!perl

use v5.42;
use Test::More;

use MXCL::Term;

subtest 'Nil' => sub {
    my $nil = MXCL::Term::Nil->new;
    is($nil->stringify, '()', 'stringify');
    ok(!$nil->boolify, 'boolify false');
    is_deeply([$nil->uncons], [], 'uncons returns empty list');

    my $nil2 = MXCL::Term::Nil->new;
    ok($nil->equals($nil2), 'all nils are equal');

    # CREATE shortcut
    my $created = MXCL::Term::Nil->CREATE;
    ok($created->equals($nil), 'CREATE shortcut');
};

subtest 'List' => sub {
    my $a = MXCL::Term::Num->CREATE(1);
    my $b = MXCL::Term::Num->CREATE(2);
    my $c = MXCL::Term::Num->CREATE(3);

    my $list = MXCL::Term::List->CREATE($a, $b, $c);
    is($list->length, 3, 'length');
    ok($list->first->equals($a), 'first');
    is($list->rest->length, 2, 'rest length');
    ok($list->boolify, 'boolify true');

    my @items = $list->uncons;
    is(scalar @items, 3, 'uncons count');
    ok($items[0]->equals($a), 'uncons first');
    ok($items[2]->equals($c), 'uncons last');

    # Single element list
    my $single = MXCL::Term::List->CREATE($a);
    is($single->length, 1, 'single element length');
    ok($single->rest isa MXCL::Term::Nil, 'rest of single is Nil');

    # Equality
    my $list2 = MXCL::Term::List->CREATE(
        MXCL::Term::Num->CREATE(1),
        MXCL::Term::Num->CREATE(2),
        MXCL::Term::Num->CREATE(3)
    );
    ok($list->equals($list2), 'equals same elements');

    my $list3 = MXCL::Term::List->CREATE($a, $b);
    ok(!$list->equals($list3), 'not equals different length');
};

subtest 'Pair' => sub {
    my $fst = MXCL::Term::Sym->CREATE('key');
    my $snd = MXCL::Term::Num->CREATE(42);

    my $pair = MXCL::Term::Pair->CREATE($fst, $snd);
    ok($pair->fst->equals($fst), 'fst accessor');
    ok($pair->snd->equals($snd), 'snd accessor');
    ok($pair->boolify, 'boolify true');
    like($pair->stringify, qr/key.*42/, 'stringify contains both');
};

subtest 'Tuple' => sub {
    my $a = MXCL::Term::Num->CREATE(1);
    my $b = MXCL::Term::Str->CREATE('two');
    my $c = MXCL::Term::Bool->CREATE(1);

    my $tuple = MXCL::Term::Tuple->CREATE($a, $b, $c);
    is($tuple->size, 3, 'size');
    ok($tuple->at(MXCL::Term::Num->CREATE(0))->equals($a), 'at 0');
    ok($tuple->at(MXCL::Term::Num->CREATE(1))->equals($b), 'at 1');
    ok($tuple->at(MXCL::Term::Num->CREATE(2))->equals($c), 'at 2');
    ok($tuple->boolify, 'boolify true');
    like($tuple->stringify, qr/^\[.*\]$/, 'stringify with brackets');

    # Equality
    my $tuple2 = MXCL::Term::Tuple->CREATE(
        MXCL::Term::Num->CREATE(1),
        MXCL::Term::Str->CREATE('two'),
        MXCL::Term::Bool->CREATE(1)
    );
    ok($tuple->equals($tuple2), 'equals same elements');
};

subtest 'Array' => sub {
    my $arr = MXCL::Term::Array->CREATE(
        MXCL::Term::Num->CREATE(10),
        MXCL::Term::Num->CREATE(20)
    );
    is($arr->length, 2, 'initial length');
    ok($arr->boolify, 'boolify true');

    # get/set
    ok($arr->get(MXCL::Term::Num->CREATE(0))->equals(MXCL::Term::Num->CREATE(10)), 'get 0');
    $arr->set(MXCL::Term::Num->CREATE(0), MXCL::Term::Num->CREATE(99));
    ok($arr->get(MXCL::Term::Num->CREATE(0))->equals(MXCL::Term::Num->CREATE(99)), 'set then get');

    # push/pop
    $arr->push(MXCL::Term::Num->CREATE(30));
    is($arr->length, 3, 'length after push');
    my $popped = $arr->pop;
    ok($popped->equals(MXCL::Term::Num->CREATE(30)), 'pop returns pushed');
    is($arr->length, 2, 'length after pop');

    # shift/unshift
    $arr->unshift(MXCL::Term::Num->CREATE(5));
    is($arr->length, 3, 'length after unshift');
    my $shifted = $arr->shift;
    ok($shifted->equals(MXCL::Term::Num->CREATE(5)), 'shift returns unshifted');

    like($arr->stringify, qr/^@\[.*\]$/, 'stringify with @[]');
};

subtest 'Hash' => sub {
    my $hash = MXCL::Term::Hash->CREATE(
        MXCL::Term::Key->CREATE('a'), MXCL::Term::Num->CREATE(1),
        MXCL::Term::Key->CREATE('b'), MXCL::Term::Num->CREATE(2)
    );
    is($hash->size, 2, 'size');
    ok($hash->boolify, 'boolify true');

    # has/get/set
    ok($hash->has(MXCL::Term::Key->CREATE('a')), 'has existing key');
    ok(!$hash->has(MXCL::Term::Key->CREATE('z')), 'has missing key');
    ok($hash->get(MXCL::Term::Key->CREATE('a'))->equals(MXCL::Term::Num->CREATE(1)), 'get');

    $hash->set(MXCL::Term::Key->CREATE('c'), MXCL::Term::Num->CREATE(3));
    is($hash->size, 3, 'size after set');
    ok($hash->get(MXCL::Term::Key->CREATE('c'))->equals(MXCL::Term::Num->CREATE(3)), 'get after set');

    # delete
    $hash->delete(MXCL::Term::Key->CREATE('c'));
    is($hash->size, 2, 'size after delete');
    ok(!$hash->has(MXCL::Term::Key->CREATE('c')), 'has after delete');

    like($hash->stringify, qr/^%\(.*\)$/, 'stringify with %()');
};

done_testing;
