#!perl

use v5.42;
use Test::More;

use MXCL::Term;
use MXCL::Term::Kontinue;

my $env = MXCL::Term::Environment->CREATE;

subtest 'Kontinue base class - stack operations' => sub {
    my $k = MXCL::Term::Kontinue::Return->new(
        env   => $env,
        value => MXCL::Term::Num->CREATE(42)
    );

    # Stack is initially empty
    my $popped = $k->stack->pop;
    ok(!defined $popped, 'stack_pop from empty returns undef');

    # Push and pop
    $k->stack->push(MXCL::Term::Num->CREATE(1));
    $k->stack->push(MXCL::Term::Num->CREATE(2));

    $popped = $k->stack->pop;
    ok($popped->equals(MXCL::Term::Num->CREATE(2)), 'pop returns last pushed');

    $popped = $k->stack->pop;
    ok($popped->equals(MXCL::Term::Num->CREATE(1)), 'pop returns first pushed');

    # Spill stack
    $k->stack->push(MXCL::Term::Num->CREATE(10));
    $k->stack->push(MXCL::Term::Num->CREATE(20));
    my @spilled = $k->stack->splice(0);
    is(scalar @spilled, 2, 'spill returns all');
    ok($spilled[0]->equals(MXCL::Term::Num->CREATE(10)), 'first spilled');
    ok($spilled[1]->equals(MXCL::Term::Num->CREATE(20)), 'second spilled');

    # Stack is now empty
    @spilled = $k->stack->splice(0);
    is(scalar @spilled, 0, 'stack empty after spill');
};

subtest 'Kontinue::Return' => sub {
    my $value = MXCL::Term::Str->CREATE('hello');
    my $k = MXCL::Term::Kontinue::Return->new(
        env   => $env,
        value => $value
    );

    is($k->type, 'Return', 'type is Return');
    ok($k->value->equals($value), 'value accessor');
    is($k->env, $env, 'env accessor');
    like($k->stringify, qr/Return/, 'stringify contains type');
};

subtest 'Kontinue::Eval::Expr' => sub {
    my $expr = MXCL::Term::Sym->CREATE('foo');
    my $k = MXCL::Term::Kontinue::Eval::Expr->new(
        env  => $env,
        expr => $expr
    );

    is($k->type, 'Eval::Expr', 'type');
    ok($k->expr->equals($expr), 'expr accessor');
    like($k->stringify, qr/Eval::Expr/, 'stringify');
};

subtest 'Kontinue::Eval::Cons' => sub {
    my $cons = MXCL::Term::List->CREATE(
        MXCL::Term::Sym->CREATE('+'),
        MXCL::Term::Num->CREATE(1),
        MXCL::Term::Num->CREATE(2)
    );
    my $k = MXCL::Term::Kontinue::Eval::Cons->new(
        env  => $env,
        cons => $cons
    );

    is($k->type, 'Eval::Cons', 'type');
    ok($k->cons->equals($cons), 'cons accessor');
};

subtest 'Kontinue::Apply::Expr' => sub {
    my $args = MXCL::Term::List->CREATE(
        MXCL::Term::Num->CREATE(1),
        MXCL::Term::Num->CREATE(2)
    );
    my $k = MXCL::Term::Kontinue::Apply::Expr->new(
        env  => $env,
        args => $args
    );

    is($k->type, 'Apply::Expr', 'type');
    ok($k->args->equals($args), 'args accessor');
};

subtest 'Kontinue::Define' => sub {
    my $name = MXCL::Term::Sym->CREATE('x');
    my $k = MXCL::Term::Kontinue::Define->new(
        env  => $env,
        name => $name
    );

    is($k->type, 'Define', 'type');
    ok($k->name->equals($name), 'name accessor');
};

subtest 'Kontinue::Mutate' => sub {
    my $name = MXCL::Term::Sym->CREATE('x');
    my $k = MXCL::Term::Kontinue::Mutate->new(
        env  => $env,
        name => $name
    );

    is($k->type, 'Mutate', 'type');
    ok($k->name->equals($name), 'name accessor');
};

subtest 'Kontinue::IfElse' => sub {
    my $cond = MXCL::Term::Sym->CREATE('test');
    my $if_true = MXCL::Term::Num->CREATE(1);
    my $if_false = MXCL::Term::Num->CREATE(0);

    my $k = MXCL::Term::Kontinue::IfElse->new(
        env       => $env,
        condition => $cond,
        if_true   => $if_true,
        if_false  => $if_false
    );

    is($k->type, 'IfElse', 'type');
    ok($k->condition->equals($cond), 'condition accessor');
    ok($k->if_true->equals($if_true), 'if_true accessor');
    ok($k->if_false->equals($if_false), 'if_false accessor');
};

subtest 'Kontinue::Throw' => sub {
    my $ex = MXCL::Term::Exception->CREATE(
        MXCL::Term::Str->CREATE('error')
    );
    my $k = MXCL::Term::Kontinue::Throw->new(
        env       => $env,
        exception => $ex
    );

    is($k->type, 'Throw', 'type');
    ok($k->exception isa MXCL::Term::Exception, 'exception accessor');
};

subtest 'Kontinue::Catch' => sub {
    my $handler = MXCL::Term::Lambda->CREATE(
        MXCL::Term::List->CREATE(MXCL::Term::Sym->CREATE('e')),
        MXCL::Term::Sym->CREATE('e'),
        $env
    );
    my $k = MXCL::Term::Kontinue::Catch->new(
        env     => $env,
        handler => $handler
    );

    is($k->type, 'Catch', 'type');
    ok($k->handler isa MXCL::Term::Lambda, 'handler accessor');
};

subtest 'Kontinue::Host' => sub {
    # We need an effect - use a simple mock
    package MockEffect {
        use v5.42;
        sub new { bless {}, shift }
    }

    my $effect = MockEffect->new;
    my $k = MXCL::Term::Kontinue::Host->new(
        env    => $env,
        effect => $effect,
        config => { operation => 'test' }
    );

    is($k->type, 'Host', 'type');
    is($k->effect, $effect, 'effect accessor');
    is_deeply($k->config, { operation => 'test' }, 'config accessor');
};

done_testing;
