
use v5.42;
use experimental qw[ class switch try ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Effect;

class MXCL::Term::Runtime::Exception :isa(MXCL::Term::Exception) {}

class MXCL::Machine {
    field $program  :param :reader;
    field $env      :param :reader;
    field $on_exit  :param :reader;
    field $on_error :param :reader;

    field $queue :reader;
    field $ticks :reader;

    ADJUST {
        $ticks = 0;
        $queue = [
            $on_exit,
            MXCL::Term::Kontinue::Context::Enter
                ->new( env => $env )
                ->wrap(@$program),
        ];
    }

    method return_values (@values) {
        $queue->[-1]->stack->push( @values )
    }

    method evaluate_term ($expr, $env) {
        given ($expr->type) {
            when ('Sym') {
                my $value = $env->lookup( $expr );

                if ( not defined $value ) {
                    return MXCL::Term::Kontinue::Throw->new(
                        env       => $env,
                        exception => MXCL::Term::Runtime::Exception->new(
                            msg => MXCL::Term::Str->new(
                                value => "Could not find ".($expr->ident)." in Environment"
                            )
                        )
                    );
                }

                return MXCL::Term::Kontinue::Return->new( value => $value, env => $env )
            }
            when ('List') {
                return MXCL::Term::Kontinue::Eval::Cons->new( cons => $expr, env => $env )
            }
            default {
                return MXCL::Term::Kontinue::Return->new( value => $expr, env => $env )
            }
        }
    }

    method resume (@kont) {
        push @$queue => @kont;
        return $self->run_until_host;
    }

    method run_until_host {
        while (@$queue) {
            $ticks++;
            my $k = pop @$queue;
            #warn sprintf "-- TICKS[%03d] %s\n" => $ticks, ('-' x 85);
            #warn "KONT :=> $k\n";
            #warn join "\n  " => "QUEUE:", (reverse @$queue), "\n";
            try {
                given ($k->type) {
                    when ('Host') {
                        return $k
                    }
                    when ('Return') {
                        $self->return_values( $k->value )
                    }
                    when ('Mutate') {
                        my $value = $k->stack->pop();
                        my $name  = $k->name;

                        if (!$k->env->update( $k->name, $value )) {
                            push @$queue => MXCL::Term::Kontinue::Throw->new(
                                env       => $env,
                                exception => MXCL::Term::Runtime::Exception->new(
                                    msg => MXCL::Term::Str->new(
                                        value => "Could not find ".($k->name->ident)." in Environment"
                                    )
                                )
                            );
                        }

                        $self->return_values( $value );
                    }
                    when ('Define') {
                        my $value = $k->stack->pop();
                        $k->env->define( $k->name, $value );
                        $self->return_values( $value );
                    }
                    when ('Context::Enter') {
                        # pass values on ...
                        $self->return_values( $k->stack->splice(0) );
                        # and define a local `defer` to capture
                        $k->env->define(
                            MXCL::Term::Sym->CREATE('defer'),
                            MXCL::Builtins::lift_applicative('defer', [qw[ action ]], sub ($env, $action) {
                                $k->leave->defer($action);
                                return MXCL::Term::Unit->new;
                            })
                        );
                    }
                    when ('Context::Leave') {
                        if ($k->has_deferred) {
                            #say "HEY THERE!!!!!";
                            #say "GOT ", $k->env->deferred->elements->@*;
                            push @$queue => (
                                MXCL::Term::Kontinue::Return->new(
                                    value => $k->stack->shift,
                                    env   => $k->env,
                                )->with_stack(
                                    $k->stack->splice(0)
                                ),
                                reverse map {
                                    MXCL::Term::Kontinue::Apply::Applicative->new(
                                        env  => $k->env,
                                        call => $_,
                                    )
                                } $k->deferred->splice(0)
                            );
                        }
                        else {
                            # just pass values on ...
                            $self->return_values( $k->stack->splice(0) );
                        }
                    }
                    when ('IfElse') {
                        my $condition = $k->stack->pop();
                        if ($condition->boolify) {
                            push @$queue =>
                                # AND short/circuit
                                refaddr $k->condition == refaddr $k->if_true
                                    ? MXCL::Term::Kontinue::Return->new( value => $condition, env => $k->env )
                                    : $self->evaluate_term( $k->if_true, $k->env );
                        } else {
                            push @$queue =>
                                # OR short/circuit
                                refaddr $k->condition == refaddr $k->if_false
                                    ? MXCL::Term::Kontinue::Return->new( value => $condition, env => $k->env )
                                    : $self->evaluate_term( $k->if_false, $k->env );
                        }
                    }
                    when ('Throw') {
                        my @leave_konts;
                        while (@$queue) {
                            if ($queue->[-1] isa MXCL::Term::Kontinue::Context::Leave) {
                                push @leave_konts => pop @$queue;
                            }
                            elsif ($queue->[-1] isa MXCL::Term::Kontinue::Catch) {
                                if (@leave_konts) {
                                    push @$queue => $k, @leave_konts;
                                } else {
                                    $self->return_values( $k->exception );
                                }
                                break;
                            } else {
                                pop @$queue;
                            }
                        }

                        # bubble up to the HOST if no catch is found
                        if (scalar @$queue == 0) {
                            $on_error->stack->push( $k->exception );
                            return $on_error
                        }
                    }
                    when ('Catch') {
                        my $results = $k->stack->pop();
                        if ($results isa MXCL::Term::Runtime::Exception) {
                            push @$queue => MXCL::Term::Kontinue::Apply::Applicative->new(
                                env  => $k->env,
                                call => $k->handler,
                            )->with_stack(
                                $results
                            );
                        } else {
                            push @$queue => MXCL::Term::Kontinue::Return->new(
                                env   => $k->env,
                                value => $results,
                            );
                        }
                    }
                    when ('Eval::Expr') {
                        push @$queue => $self->evaluate_term( $k->expr, $k->env );
                    }
                    when ('Eval::TOS') {
                        my $to_eval = $k->stack->pop();
                        push @$queue => $self->evaluate_term( $to_eval, $k->env )
                    }
                    when ('Eval::Cons') {
                        my $list  = $k->cons;
                        push @$queue => (
                            MXCL::Term::Kontinue::Apply::Expr->new(
                                env  => $k->env,
                                args => $list->rest
                            ),
                            $self->evaluate_term( $list->first, $k->env )
                        );
                    }
                    when ('Eval::Cons::Rest') {
                        my $list = $k->rest;
                        my $rest = $list->rest;
                        unless ($rest isa MXCL::Term::Nil) {
                            push @$queue => MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                                env  => $k->env,
                                rest => $rest
                            );
                        }

                        $self->return_values( $k->stack->splice(0) );
                        push @$queue => $self->evaluate_term( $list->first, $k->env );
                    }
                    when ('Apply::Expr') {
                        my $call = $k->stack->pop();

                        if ($call isa MXCL::Term::Operative) {
                            push @$queue => MXCL::Term::Kontinue::Apply::Operative->new(
                                env  => $k->env,
                                call => $call,
                                args => $k->args,
                            );
                        }
                        elsif ($call isa MXCL::Term::Applicative) {
                            push @$queue => MXCL::Term::Kontinue::Apply::Applicative->new(
                                env  => $k->env,
                                call => $call,
                            );

                            unless ($k->args isa MXCL::Term::Nil) {
                                push @$queue => MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                                    env  => $k->env,
                                    rest => $k->args
                                );
                            }
                        }
                        else {
                            MXCL::Term::Runtime::Exception->throw("WTF, what is $call in Apply::Expr");
                        }
                    }
                    when ('Apply::Operative') {
                        my $call = $k->call;
                        if ($call isa MXCL::Term::Operative::Native) {
                            push @$queue => $call->body->( $k->env, $k->args->uncons )->@*;
                        }
                        elsif ($call isa MXCL::Term::FExpr) {
                            MXCL::Term::Runtime::Exception->throw('TODO - user-defined FExpr');
                        }
                        else {
                            MXCL::Term::Runtime::Exception->throw("WTF, what is $call in Apply::Applicative");
                        }
                    }
                    when ('Apply::Applicative') {
                        my $call = $k->call;
                        if ($call isa MXCL::Term::Applicative::Native) {
                            push @$queue => MXCL::Term::Kontinue::Return->new(
                                env   => $k->env,
                                value => $call->body->( $k->env, $k->stack->splice(0) ),
                            );
                        }
                        elsif ($call isa MXCL::Term::Lambda) {
                            my $lambda = $k->call;

                            my @params = $lambda->params->uncons;
                            my @args   = $k->stack->splice(0);

                            my %bindings;
                            for (my $i = 0; $i < scalar @params; $i++) {
                                $bindings{ $params[$i]->ident } = $args[$i];
                            }

                            my $local = $lambda->env->derive(%bindings);
                            push @$queue => MXCL::Term::Kontinue::Eval::Expr->new(
                                env  => $local,
                                expr => $lambda->body
                            );
                        }
                        else {
                            MXCL::Term::Runtime::Exception->throw("WTF, what is $call in Apply::Applicative");
                        }
                    }
                    default {
                        MXCL::Term::Runtime::Exception->throw("UNKNOWN CONTINUATION $k");
                    }
                }
            } catch ($e) {
                unless ($e isa MXCL::Term::Runtime::Exception) {
                    $e = MXCL::Term::Runtime::Exception->new(
                        msg => MXCL::Term::Str->new( value => "$e" )
                    );
                }

                push @$queue => MXCL::Term::Kontinue::Throw->new(
                    env       => $k->env,
                    exception => $e
                );
            }
        }

        MXCL::Term::Runtime::Exception->throw("This should never happen, we should always return via HOST");
    }

}
