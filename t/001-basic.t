#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Parser;
use Opal::Expander;
use Opal::Machine;

my $source = q[

    (def thirty 30)

    (defun adder (x y) (+ x y))

    (list
        30
        thirty
        (+ 10 20)
        (+ 10 (* 4 5))
        (+ (* 2 5) 20)
        (+ (* 2 5) (* 4 (+ 3 2)))
        ((lambda (x y) (+ x y)) 10 20)
        (adder 10 20)
        (first (list 30 20 10))
        (first (rest (list 40 30 20 10)))
        (try (+ 10 20) (catch (e) e))
        (+ 10 (or false 20))
        (+ 10 (and true 20))
        (if true 30 false)
        (if (+ 0 0) false (+ 10 20))
        (if "test" (+ 10 20) false)
        (if "" false (+ 10 20))
        (if () false (+ 10 20))
    )

];

#$source = q[
#
#    (+ 10 (or 10 20))
#
#];


my $env = Opal::Term::Environment->new(entries => {
    'do' => Opal::Term::Operative::Native->new(
        name => 'do',
        body => sub ($env, @exprs) {
            return [
                reverse map {
                    Opal::Term::Kontinue::Eval::Expr->new(
                        env  => $env,
                        expr => $_
                    )
                } @exprs
            ]
        }
    ),
    'and' => Opal::Term::Operative::Native->new(
        name => 'and',
        body => sub ($env, $lhs, $rhs) {
            return [
                Opal::Term::Kontinue::IfElse->new(
                    env       => $env,
                    condition => $lhs,
                    if_true   => $rhs,
                    if_false  => $lhs,
                ),
                Opal::Term::Kontinue::Eval::Expr->new(
                    env  => $env,
                    expr => $lhs
                )
            ]
        }
    ),
    'or' => Opal::Term::Operative::Native->new(
        name => 'or',
        body => sub ($env, $lhs, $rhs) {
            return [
                Opal::Term::Kontinue::IfElse->new(
                    env       => $env,
                    condition => $lhs,
                    if_true   => $lhs,
                    if_false  => $rhs,
                ),
                Opal::Term::Kontinue::Eval::Expr->new(
                    env  => $env,
                    expr => $lhs
                )
            ]
        }
    ),
    'if' => Opal::Term::Operative::Native->new(
        name => 'if',
        body => sub ($env, $cond, $if_true, $if_false) {
            return [
                Opal::Term::Kontinue::IfElse->new(
                    env       => $env,
                    condition => $cond,
                    if_true   => $if_true,
                    if_false  => $if_false,
                ),
                Opal::Term::Kontinue::Eval::Expr->new(
                    env  => $env,
                    expr => $cond
                )
            ]
        }
    ),
    'throw' => Opal::Term::Operative::Native->new(
        name => 'throw',
        body => sub ($env, $msg) {
            return [
                Opal::Term::Kontinue::Throw->new(
                    env       => $env,
                    exception => Opal::Term::Exception->new( msg => $msg ),
                )
            ]
        }
    ),
    'try' => Opal::Term::Operative::Native->new(
        name => 'try',
        body => sub ($env, $expr, $handler) {
            my ($params, $body) = $handler->rest->uncons;
            return [
                Opal::Term::Kontinue::Catch->new(
                    env     => $env,
                    handler => Opal::Term::Lambda->new(
                        params => $params,
                        body   => $body,
                        env    => $env
                    ),
                ),
                Opal::Term::Kontinue::Eval::Expr->new(
                    env  => $env,
                    expr => $expr
                )
            ]
        }
    ),
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
        body => sub ($env, $name, $value) {
            return [
                Opal::Term::Kontinue::Define->new( name => $name, env => $env ),
                Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
            ]
        }
    ),
    'defun' => Opal::Term::Operative::Native->new(
        name => 'defun',
        body => sub ($env, $name, $params, $body) {
            return [
                Opal::Term::Kontinue::Define->new( name => $name, env => $env ),
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
    'list' => Opal::Term::Applicative::Native->new(
        name => 'list',
        body => sub ($env, @items) {
            return Opal::Term::Nil->new if scalar @items == 0;
            return Opal::Term::List->new( items => \@items );
        }
    ),
    'first' => Opal::Term::Applicative::Native->new(
        name => 'first',
        body => sub ($env, $list) { $list->first }
    ),
    'rest' => Opal::Term::Applicative::Native->new(
        name => 'rest',
        body => sub ($env, $list) { $list->rest }
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

my $parser   = Opal::Parser->new;
my @exprs    = $parser->parse($source);
my $expander = Opal::Expander->new( exprs => \@exprs );
my @terms    = $expander->expand;

say join "\n" => map { $_->to_string } @exprs;
say join "\n" => map { $_->to_string } @terms;

my $machine = Opal::Machine->new(
    program => \@terms,
    env     => $env
);

my $result = $machine->run;

say "RESULT is ", $result->to_string;

