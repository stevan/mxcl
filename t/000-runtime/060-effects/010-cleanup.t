#!/usr/bin/env perl
use v5.42;
use Test::More;

use lib 'lib';

use MXCL::Strand;
use MXCL::Capabilities;
use MXCL::Effect;

# Test that effect cleanup is called properly

# Create a test effect that tracks cleanup
package TestEffect {
    use v5.42;
    use experimental qw(class);

    class TestEffect :isa(MXCL::Effect) {
        field $cleanup_called :reader = false;
        field $name :param :reader;

        method handles ($k, $strand, $pid) {
            # Simple test effect - just returns halt
            return undef;
        }

        method provides { +[] }

        method cleanup() {
            $cleanup_called = true;
        }
    }
}

# Test 1: Effects are accessible
{
    my $effect1 = TestEffect->new(name => 'effect1');
    my $effect2 = TestEffect->new(name => 'effect2');

    my $strand = MXCL::Strand->new(
        capabilities => MXCL::Capabilities->new(
            effects => [$effect1, $effect2]
        )
    );

    my @effects = $strand->capabilities->effects->@*;
    is(scalar @effects, 2, 'effects() returns all effects');
    is($effects[0]->name, 'effect1', 'first effect is correct');
    is($effects[1]->name, 'effect2', 'second effect is correct');
}

# Test 2: Cleanup is called on all effects
{
    my $effect1 = TestEffect->new(name => 'effect1');
    my $effect2 = TestEffect->new(name => 'effect2');

    my $strand = MXCL::Strand->new(
        capabilities => MXCL::Capabilities->new(
            effects => [$effect1, $effect2]
        )
    );

    ok(!$effect1->cleanup_called, 'effect1 cleanup not called initially');
    ok(!$effect2->cleanup_called, 'effect2 cleanup not called initially');

    $strand->capabilities->cleanup;

    ok($effect1->cleanup_called, 'effect1 cleanup was called');
    ok($effect2->cleanup_called, 'effect2 cleanup was called');
}

# Test 3: Cleanup is called on normal run completion
{
    my $effect = TestEffect->new(name => 'test');

    my $strand = MXCL::Strand->new(
        capabilities => MXCL::Capabilities->new(
            effects => [$effect]
        )
    );

    # Load and run a simple program
    $strand->load('(+ 1 2)');
    $strand->run();

    ok($effect->cleanup_called, 'cleanup called after normal run');
}

# Test 4: Cleanup is called even on error
{
    my $effect = TestEffect->new(name => 'test');

    my $strand = MXCL::Strand->new(
        capabilities => MXCL::Capabilities->new(
            effects => [$effect]
        )
    );

    # Load a program that will cause an error
    $strand->load('(throw "test error")');

    eval {
        $strand->run();
    };

    ok($@, 'error was thrown');
    ok($effect->cleanup_called, 'cleanup called even after error');
}

done_testing;
