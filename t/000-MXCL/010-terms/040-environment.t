#!perl

use v5.42;
use Test::More;

use MXCL::Term;

subtest 'basic define and lookup' => sub {
    my $env = MXCL::Term::Environment->CREATE;

    my $key = MXCL::Term::Sym->CREATE('x');
    my $val = MXCL::Term::Num->CREATE(42);

    $env->define($key, $val);

    ok($env->has($key), 'has defined key');
    my $found = $env->lookup($key);
    ok($found->equals($val), 'lookup returns defined value');
};

subtest 'lookup missing key' => sub {
    my $env = MXCL::Term::Environment->CREATE;

    my $key = MXCL::Term::Sym->CREATE('missing');
    my $found = $env->lookup($key);
    ok(!defined $found, 'lookup missing returns undef');
};

subtest 'derive creates child scope' => sub {
    my $parent = MXCL::Term::Environment->CREATE;
    my $x = MXCL::Term::Sym->CREATE('x');
    my $y = MXCL::Term::Sym->CREATE('y');

    $parent->define($x, MXCL::Term::Num->CREATE(10));

    my $child = $parent->derive(y => MXCL::Term::Num->CREATE(20));

    # Child can see parent's bindings
    ok($child->lookup($x)->equals(MXCL::Term::Num->CREATE(10)), 'child sees parent binding');

    # Child has its own bindings
    ok($child->lookup($y)->equals(MXCL::Term::Num->CREATE(20)), 'child has own binding');

    # Parent doesn't see child's bindings
    ok(!defined $parent->lookup($y), 'parent does not see child binding');

    # Child has parent
    ok($child->has_parent, 'child has parent');
    ok(!$parent->has_parent, 'parent has no parent (unless base env)');
};

subtest 'shadowing' => sub {
    my $parent = MXCL::Term::Environment->CREATE;
    my $x = MXCL::Term::Sym->CREATE('x');

    $parent->define($x, MXCL::Term::Num->CREATE(10));

    my $child = $parent->derive(x => MXCL::Term::Num->CREATE(99));

    # Child sees shadowed value
    ok($child->lookup($x)->equals(MXCL::Term::Num->CREATE(99)), 'child sees shadowed value');

    # Parent still has original
    ok($parent->lookup($x)->equals(MXCL::Term::Num->CREATE(10)), 'parent still has original');
};

subtest 'update' => sub {
    my $parent = MXCL::Term::Environment->CREATE;
    my $x = MXCL::Term::Sym->CREATE('x');

    $parent->define($x, MXCL::Term::Num->CREATE(10));
    my $child = $parent->derive;

    # Update through child modifies parent's binding
    my $result = $child->update($x, MXCL::Term::Num->CREATE(99));
    ok($result, 'update returns truthy on success');
    ok($parent->lookup($x)->equals(MXCL::Term::Num->CREATE(99)), 'parent value updated');

    # Update missing key fails
    my $missing = MXCL::Term::Sym->CREATE('missing');
    $result = $child->update($missing, MXCL::Term::Num->CREATE(1));
    ok(!$result, 'update returns falsy on missing key');
};

subtest 'is_root' => sub {
    my $root = MXCL::Term::Environment->CREATE;
    ok($root->is_root, 'new env is root');

    my $child = $root->derive;
    ok(!$child->is_root, 'derived env is not root');
};

done_testing;
