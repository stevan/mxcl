#!perl

use v5.42;
use Test::More;

use MXCL::Term;

subtest 'Sym' => sub {
    my $sym = MXCL::Term::Sym->new(ident => 'foo');
    is($sym->ident, 'foo', 'ident accessor');
    is($sym->stringify, 'foo', 'stringify');
    ok($sym->boolify, 'boolify true');

    my $sym2 = MXCL::Term::Sym->new(ident => 'foo');
    ok($sym->equals($sym2), 'equals same ident');

    my $sym3 = MXCL::Term::Sym->new(ident => 'bar');
    ok(!$sym->equals($sym3), 'not equals different ident');

    # CREATE shortcut
    my $created = MXCL::Term::Sym->CREATE('baz');
    is($created->ident, 'baz', 'CREATE shortcut');
};

subtest 'Key' => sub {
    my $key = MXCL::Term::Key->new(ident => 'name');
    is($key->ident, 'name', 'ident accessor');
    is($key->stringify, ':name', 'stringify with colon prefix');
    ok($key->boolify, 'boolify true');

    my $key2 = MXCL::Term::Key->new(ident => 'name');
    ok($key->equals($key2), 'equals same ident');

    my $key3 = MXCL::Term::Key->new(ident => 'other');
    ok(!$key->equals($key3), 'not equals different ident');

    # CREATE shortcut
    my $created = MXCL::Term::Key->CREATE('value');
    is($created->ident, 'value', 'CREATE shortcut');
};

subtest 'Sym vs Key' => sub {
    my $sym = MXCL::Term::Sym->new(ident => 'foo');
    my $key = MXCL::Term::Key->new(ident => 'foo');

    # Both are Words but different types
    ok($sym isa MXCL::Term::Word, 'Sym isa Word');
    ok($key isa MXCL::Term::Word, 'Key isa Word');
    ok($sym->equals($key), 'Sym not equals Key with same ident');
};

done_testing;
