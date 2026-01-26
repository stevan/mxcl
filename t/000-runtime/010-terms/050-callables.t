#!perl

use v5.42;
use Test::More;

use MXCL::Term;

subtest 'Lambda' => sub {
    my $params = MXCL::Term::List->CREATE(
        MXCL::Term::Sym->CREATE('x'),
        MXCL::Term::Sym->CREATE('y')
    );
    my $body = MXCL::Term::List->CREATE(
        MXCL::Term::Sym->CREATE('+'),
        MXCL::Term::Sym->CREATE('x'),
        MXCL::Term::Sym->CREATE('y')
    );
    my $env = MXCL::Term::Environment->CREATE;

    my $lambda = MXCL::Term::Lambda->CREATE($params, $body, $env);

    ok($lambda->is_applicative, 'Lambda isa Applicative');
    ok($lambda->is_callable, 'Lambda isa Callable');
    ok($lambda->params->equals($params), 'params accessor');
    ok($lambda->body->equals($body), 'body accessor');
    is($lambda->env, $env, 'env accessor');
    ok($lambda->boolify, 'boolify true');
    like($lambda->stringify, qr/lambda/, 'stringify contains lambda');

    # Equality based on params and body
    my $lambda2 = MXCL::Term::Lambda->CREATE($params, $body, $env);
    ok($lambda->equals($lambda2), 'equals same params and body');
};

subtest 'FExpr' => sub {
    my $params = MXCL::Term::List->CREATE(
        MXCL::Term::Sym->CREATE('expr'),
        MXCL::Term::Sym->CREATE('env')
    );
    my $body = MXCL::Term::Sym->CREATE('expr');
    my $env = MXCL::Term::Environment->CREATE;

    my $fexpr = MXCL::Term::FExpr->CREATE($params, $body, $env);

    ok($fexpr->is_operative, 'FExpr isa Operative');
    ok($fexpr->is_callable, 'FExpr isa Callable');
    ok($fexpr->params->equals($params), 'params accessor');
    ok($fexpr->body->equals($body), 'body accessor');
    is($fexpr->env, $env, 'env accessor');
    like($fexpr->stringify, qr/fexpr/, 'stringify contains fexpr');
};

subtest 'Applicative::Native' => sub {
    my $name = MXCL::Term::Sym->CREATE('add');
    my $params = MXCL::Term::List->CREATE(
        MXCL::Term::Key->CREATE('a'),
        MXCL::Term::Key->CREATE('b')
    );
    my $body = sub ($env, $a, $b) {
        MXCL::Term::Num->CREATE($a->numify + $b->numify)
    };

    my $native = MXCL::Term::Applicative::Native->CREATE($name, $params, $body);

    ok($native->is_applicative, 'Native isa Applicative');
    ok($native->is_callable, 'Native isa Callable');
    ok($native->name->equals($name), 'name accessor');
    is($native->body, $body, 'body accessor');
    like($native->stringify, qr/native.*applicative/i, 'stringify');
};

subtest 'Operative::Native' => sub {
    my $name = MXCL::Term::Sym->CREATE('quote');
    my $params = MXCL::Term::List->CREATE(
        MXCL::Term::Key->CREATE('expr')
    );
    my $body = sub ($env, $expr) {
        # Return unevaluated expression
        [ MXCL::Term::Kontinue::Return->new(value => $expr, env => $env) ]
    };

    my $native = MXCL::Term::Operative::Native->CREATE($name, $params, $body);

    ok($native->is_operative, 'Native isa Operative');
    ok($native->is_callable, 'Native isa Callable');
    ok($native->name->equals($name), 'name accessor');
    is($native->body, $body, 'body accessor');
    like($native->stringify, qr/native.*operative/i, 'stringify');
};

subtest 'Callable hierarchy' => sub {
    my $env = MXCL::Term::Environment->CREATE;
    my $params = MXCL::Term::Nil->CREATE;
    my $body = MXCL::Term::Unit->CREATE;

    my $lambda = MXCL::Term::Lambda->CREATE($params, $body, $env);
    my $fexpr = MXCL::Term::FExpr->CREATE($params, $body, $env);

    # Type checks
    ok($lambda->is_applicative, 'Lambda isa Applicative');
    ok(!($lambda->is_operative), 'Lambda not isa Operative');

    ok($fexpr->is_operative, 'FExpr isa Operative');
    ok(!($fexpr->is_applicative), 'FExpr not isa Applicative');

    # Both are Callable
    ok($lambda->is_callable, 'Lambda isa Callable');
    ok($fexpr->is_callable, 'FExpr isa Callable');
};

done_testing;
