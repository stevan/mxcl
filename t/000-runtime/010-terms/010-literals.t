#!perl

use v5.42;
use Test::More;

use MXCL::Term;

subtest 'Num' => sub {
    my $num = MXCL::Term::Num->new(value => 42);
    is($num->value, 42, 'value accessor');
    is($num->stringify, '42', 'stringify');
    is($num->numify, 42, 'numify');
    ok($num->boolify, 'boolify true for non-zero');

    my $zero = MXCL::Term::Num->new(value => 0);
    ok(!$zero->boolify, 'boolify false for zero');

    my $num2 = MXCL::Term::Num->new(value => 42);
    ok($num->equals($num2), 'equals same value');

    my $num3 = MXCL::Term::Num->new(value => 99);
    ok(!$num->equals($num3), 'not equals different value');

    # CREATE shortcut
    my $created = MXCL::Term::Num->CREATE(123);
    is($created->value, 123, 'CREATE shortcut');
};

subtest 'Str' => sub {
    my $str = MXCL::Term::Str->new(value => 'hello');
    is($str->value, 'hello', 'value accessor');
    is($str->stringify, 'hello', 'stringify');
    ok($str->boolify, 'boolify true for non-empty');

    my $empty = MXCL::Term::Str->new(value => '');
    ok(!$empty->boolify, 'boolify false for empty string');

    my $str2 = MXCL::Term::Str->new(value => 'hello');
    ok($str->equals($str2), 'equals same value');

    my $str3 = MXCL::Term::Str->new(value => 'world');
    ok(!$str->equals($str3), 'not equals different value');

    # CREATE shortcut
    my $created = MXCL::Term::Str->CREATE('test');
    is($created->value, 'test', 'CREATE shortcut');
};

subtest 'Bool' => sub {
    my $true = MXCL::Term::Bool->new(value => 1);
    ok($true->value, 'value accessor true');
    is($true->stringify, 'true', 'stringify true');
    ok($true->boolify, 'boolify true');
    is($true->numify, 1, 'numify true');

    my $false = MXCL::Term::Bool->new(value => 0);
    ok(!$false->value, 'value accessor false');
    is($false->stringify, 'false', 'stringify false');
    ok(!$false->boolify, 'boolify false');
    is($false->numify, 0, 'numify false');

    ok($true->equals(MXCL::Term::Bool->new(value => 1)), 'equals same value');
    ok(!$true->equals($false), 'not equals different value');

    # CREATE shortcut
    my $created = MXCL::Term::Bool->CREATE(1);
    ok($created->value, 'CREATE shortcut');
};

subtest 'Unit' => sub {
    my $unit = MXCL::Term::Unit->new;
    is($unit->stringify, '(unit)', 'stringify');
    ok(!$unit->boolify, 'boolify false');

    my $unit2 = MXCL::Term::Unit->new;
    ok($unit->equals($unit2), 'all units are equal');

    # CREATE shortcut
    my $created = MXCL::Term::Unit->CREATE;
    ok($created->equals($unit), 'CREATE shortcut');
};

done_testing;
