
use v5.42;
use experimental qw[ class switch try ];

use Opal::Term;
use Opal::Term::Kontinue;

class Opal::Term::Runtime::Exception :isa(Opal::Term::Exception) {}

class Opal::Machine {
    field $program :param :reader;
    field $env     :param :reader;

    field $queue :reader;
    field $ticks :reader;

    ADJUST {
        $ticks = 0;
        $env   = $env->derive;
        $queue = [
            Opal::Term::Kontinue::Host->new( effect => 'SYS.exit', env => $env ),
            reverse map {
                Opal::Term::Kontinue::Eval::Expr->new(
                    expr => $_,
                    env  => $env,
                )
            } @$program
        ];
    }

    method return_values (@values) {
        $queue->[-1]->stack_push( @values )
    }

    method evaluate_term ($expr, $env) {
        given ($expr->type) {
            when ('Sym') {
                my $value = $env->lookup( $expr );

                if ( not defined $value ) {
                    return Opal::Term::Kontinue::Throw->new(
                        env       => $env,
                        exception => Opal::Term::Runtime::Exception->new(
                            msg => Opal::Term::Str->new(
                                value => "Could not find ".($expr->ident)." in Environment"
                            )
                        )
                    );
                }

                return Opal::Term::Kontinue::Return->new( value => $value, env => $env )
            }
            when ('List') {
                return Opal::Term::Kontinue::Eval::Cons->new( cons => $expr, env => $env )
            }
            default {
                return Opal::Term::Kontinue::Return->new( value => $expr, env => $env )
            }
        }
    }

    method run_until_host {
        while (@$queue) {
            $ticks++;
            my $k = pop @$queue;
            warn sprintf "-- TICKS[%03d] %s\n" => $ticks, ('-' x 85);
            warn "KONT :=> $k\n";
            warn join "\n  " => "QUEUE:", (reverse @$queue), "\n";
            try {
                given ($k->type) {
                    when ('Host') {
                        return $k
                    }
                    when ('Return') {
                        $self->return_values( $k->value )
                    }
                    when ('Mutate') {
                        my $value = $k->stack_pop();
                        my $name  = $k->name;

                        if (!$k->env->update( $k->name, $value )) {
                            push @$queue => Opal::Term::Kontinue::Throw->new(
                                env       => $env,
                                exception => Opal::Term::Runtime::Exception->new(
                                    msg => Opal::Term::Str->new(
                                        value => "Could not find ".($k->name->ident)." in Environment"
                                    )
                                )
                            );
                        }

                        $self->return_values( $value );
                    }
                    when ('Define') {
                        my $value = $k->stack_pop();
                        $k->env->define( $k->name, $value );
                        $self->return_values( $value );
                    }
                    when ('IfElse') {
                        my $condition = $k->stack_pop();
                        if ($condition->boolify) {
                            push @$queue =>
                                # AND short/circuit
                                refaddr $k->condition == refaddr $k->if_true
                                    ? Opal::Term::Kontinue::Return->new( value => $condition, env => $k->env )
                                    : $self->evaluate_term( $k->if_true, $k->env );
                        } else {
                            push @$queue =>
                                # OR short/circuit
                                refaddr $k->condition == refaddr $k->if_false
                                    ? Opal::Term::Kontinue::Return->new( value => $condition, env => $k->env )
                                    : $self->evaluate_term( $k->if_false, $k->env );
                        }
                    }
                    when ('Throw') {
                        while (@$queue) {
                            if ($queue->[-1] isa Opal::Term::Kontinue::Catch) {
                                $self->return_values( $k->exception );
                                break;
                            } else {
                                pop @$queue;
                            }
                        }
                        # bubble up to the HOST if no catch is found
                        return Opal::Term::Kontinue::Host->new(
                            env    => $k->env,
                            effect => 'SYS.error'
                        ) if scalar @$queue == 0;
                    }
                    when ('Catch') {
                        my $results = $k->stack_pop();
                        if ($results isa Opal::Term::Runtime::Exception) {
                            my $catcher = Opal::Term::Kontinue::Apply::Applicative->new(
                                env  => $k->env,
                                call => $k->handler,
                            );
                            $catcher->stack_push( $results );
                            push @$queue => $catcher;
                        } else {
                            push @$queue => Opal::Term::Kontinue::Return->new(
                                env   => $k->env,
                                value => $results,
                            );
                        }
                    }
                    when ('Eval::Expr') {
                        push @$queue => $self->evaluate_term( $k->expr, $k->env );
                    }
                    when ('Eval::TOS') {
                        my $to_eval = $k->stack_pop();
                        push @$queue => $self->evaluate_term( $to_eval, $k->env )
                    }
                    when ('Eval::Cons') {
                        my $list  = $k->cons;
                        push @$queue => (
                            Opal::Term::Kontinue::Apply::Expr->new(
                                env  => $k->env,
                                args => $list->rest
                            ),
                            $self->evaluate_term( $list->first, $k->env )
                        );
                    }
                    when ('Eval::Cons::Rest') {
                        my $list = $k->rest;
                        my $rest = $list->rest;
                        unless ($rest isa Opal::Term::Nil) {
                            push @$queue => Opal::Term::Kontinue::Eval::Cons::Rest->new(
                                env  => $k->env,
                                rest => $rest
                            );
                        }

                        $self->return_values( $k->spill_stack() );
                        push @$queue => $self->evaluate_term( $list->first, $k->env );
                    }
                    when ('Apply::Expr') {
                        my $call = $k->stack_pop();

                        if ($call isa Opal::Term::Operative) {
                            push @$queue => Opal::Term::Kontinue::Apply::Operative->new(
                                env  => $k->env,
                                call => $call,
                                args => $k->args,
                            );
                        }
                        elsif ($call isa Opal::Term::Applicative) {
                            push @$queue => Opal::Term::Kontinue::Apply::Applicative->new(
                                env  => $k->env,
                                call => $call,
                            );

                            unless ($k->args isa Opal::Term::Nil) {
                                push @$queue => Opal::Term::Kontinue::Eval::Cons::Rest->new(
                                    env  => $k->env,
                                    rest => $k->args
                                );
                            }
                        }
                        else {
                            Opal::Term::Runtime::Exception->throw("WTF, what is $call in Apply::Expr");
                        }
                    }
                    when ('Apply::Operative') {
                        my $call = $k->call;
                        if ($call isa Opal::Term::Operative::Native) {
                            push @$queue => $call->body->( $k->env, $k->args->uncons )->@*;
                        }
                        elsif ($call isa Opal::Term::FExpr) {
                            Opal::Term::Runtime::Exception->throw('TODO - user-defined FExpr');
                        }
                        else {
                            Opal::Term::Runtime::Exception->throw("WTF, what is $call in Apply::Applicative");
                        }
                    }
                    when ('Apply::Applicative') {
                        my $call = $k->call;
                        if ($call isa Opal::Term::Applicative::Native) {
                            push @$queue => Opal::Term::Kontinue::Return->new(
                                env   => $k->env,
                                value => $call->body->( $k->env, $k->spill_stack() ),
                            );
                        }
                        elsif ($call isa Opal::Term::Lambda) {
                            my $lambda = $k->call;

                            my @params = $lambda->params->uncons;
                            my @args   = $k->spill_stack;

                            my %bindings;
                            for (my $i = 0; $i < scalar @params; $i++) {
                                $bindings{ $params[$i]->ident } = $args[$i];
                            }

                            my $local = $lambda->env->derive(%bindings);
                            push @$queue => Opal::Term::Kontinue::Eval::Expr->new(
                                env  => $local,
                                expr => $lambda->body
                            );
                        }
                        else {
                            Opal::Term::Runtime::Exception->throw("WTF, what is $call in Apply::Applicative");
                        }
                    }
                    default {
                        Opal::Term::Runtime::Exception->throw("UNKNOWN CONTINUATION $k");
                    }
                }
            } catch ($e) {
                unless ($e isa Opal::Term::Runtime::Exception) {
                    $e = Opal::Term::Runtime::Exception->new(
                        msg => Opal::Term::Str->new( value => "$e" )
                    );
                }

                push @$queue => Opal::Term::Kontinue::Throw->new(
                    env       => $k->env,
                    exception => $e
                );
            }
        }

        Opal::Term::Runtime::Exception->throw("This should never happen, we should always return via HOST");
    }

}
