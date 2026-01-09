
use v5.42;
use experimental qw[ class ];

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Term::Runtime;

class Opal::Environment {
    our $BUILTINS = +{
        'set!' => Opal::Term::Operative::Native->new(
            name => 'set!',
            body => sub ($env, $name, $value) {
                return [
                    Opal::Term::Kontinue::Mutate->new( name => $name, env => $env ),
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
                ]
            }
        ),
        'let' => Opal::Term::Operative::Native->new(
            name => 'let',
            body => sub ($env, $binding, $body) {
                my ($name, $value) = $binding->uncons;
                my $local = $env->derive;
                return [
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $body, env => $local ),
                    Opal::Term::Kontinue::Define->new( name => $name, env => $local ),
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $local ),
                ]
            }
        ),
        'do' => Opal::Term::Operative::Native->new(
            name => 'do',
            body => sub ($env, @exprs) {
                my $local = $env->derive;
                return [
                    reverse map {
                        Opal::Term::Kontinue::Eval::Expr->new(
                            env  => $local,
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
                my $local = $env->derive;
                return [
                    Opal::Term::Kontinue::IfElse->new(
                        env       => $local,
                        condition => $cond,
                        if_true   => $if_true,
                        if_false  => $if_false,
                    ),
                    Opal::Term::Kontinue::Eval::Expr->new(
                        env  => $local,
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
                        exception => Opal::Term::Runtime::Exception->new( msg => $msg ),
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
    };

    sub initialize ($, %bindings) {
        Opal::Term::Runtime::Environment->new( entries => $BUILTINS )->derive( %bindings );
    }
}

