#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Parser;
use Opal::Expander;
use Opal::Machine;

my $parser = Opal::Parser->new(
    buffer => q[

    (def thirty 30)

    (def adder (lambda (x y) (+ x y)))

    (list
        30
        thirty
        (+ 10 20)
        (+ 10 (* 4 5))
        (+ (* 2 5) 20)
        (+ (* 2 5) (* 4 (+ 3 2)))
        ((lambda (x y) (+ x y)) 10 20)
        (adder 10 20)
    )

]);

my $env = Opal::Term::Environment->new(entries => {
    'lambda' => Opal::Term::Operative::Native->new(
        name => 'lambda',
        body => sub ($env, $params, $body) {
            return [
                Opal::Term::Kontinue::Return->new(
                    env   => $env,
                    value => Opal::Term::Lambda->new(
                        params => $params,
                        body   => $body,
                        env    => $env
                    )
                )
            ]
        }
    ),
    'def' => Opal::Term::Operative::Native->new(
        name => 'def',
        body => sub ($env, $key, $value) {
            return [
                Opal::Term::Kontinue::Define->new( name => $key, env => $env ),
                Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
            ]
        }
    ),
    'list' => Opal::Term::Applicative::Native->new(
        name => 'list',
        body => sub ($env, @items) {
            return Opal::Term::Nil->new if scalar @items == 0;
            return Opal::Term::List->new( items => \@items );
        }
    ),
    '+' => Opal::Term::Applicative::Native->new(
        name => '+',
        body => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value + $m->value)) }
    ),
    '-' => Opal::Term::Applicative::Native->new(
        name => '-',
        body => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value - $m->value)) }
    ),
    '*' => Opal::Term::Applicative::Native->new(
        name => '*',
        body => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value * $m->value)) }
    ),
    '/' => Opal::Term::Applicative::Native->new(
        name => '/',
        body => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value / $m->value)) }
    ),
});

my @exprs = $parser->parse;

my $expander = Opal::Expander->new( exprs => \@exprs );

my @terms = $expander->expand;

say join "\n" => map { $_->to_string } @exprs;
say join "\n" => map { $_->to_string } @terms;

my $machine = Opal::Machine->new(
    program => \@terms,
    env     => $env
);

my $result = $machine->run;

say "RESULT is ", $result->to_string;

