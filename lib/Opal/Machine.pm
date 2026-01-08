
use v5.42;
use experimental qw[ class switch ];

use importer 'Carp' => qw[ confess ];

use Opal::Term;

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

    method run {
        return $self->run_until_host;
    }

    method return_values (@values) {
        $queue->[-1]->stack_push( @values )
    }

    method evaluate_term ($expr, $env) {
        given ($expr->kind) {
            when ('Sym') {
                my $value = $env->lookup( $expr ) // confess "Could not find ".($expr->ident)." in Environment";
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
            warn sprintf "-- TICKS[%03d] %s\n" => $ticks, ('-' x 85);
            my $k = pop @$queue;
            warn sprintf "KONT :=> %s\n" => $k->to_string;
            warn join "\n  " => "QUEUE:", (map $_->to_string, reverse @$queue), "\n";
            given ($k->kind) {
                when ('Host') {
                    return $k
                }
                when ('Return') {
                    $self->return_values( $k->value )
                }
                when ('Define') {
                    my $value = $k->stack_pop();
                    $k->env->set( $k->name, $value );
                    $self->return_values( $value );
                }
                when ('IfElse') {
                    die 'TODO - If/Else'
                }
                when ('Throw') {
                    die 'TODO - Throw'
                }
                when ('Catch') {
                    die 'TODO - Catch'
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
                        die "WTF, what is $call in Apply::Expr";
                    }
                }
                when ('Apply::Operative') {
                    my $call = $k->call;
                    if ($call isa Opal::Term::Operative::Native) {
                        push @$queue => $call->body->( $k->env, $k->args->uncons )->@*;
                    }
                    elsif ($call isa Opal::Term::FExpr) {
                        die 'TODO - user-defined FExpr';
                    }
                    else {
                        die "WTF, what is $call in Apply::Applicative";
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
                        die "WTF, what is $call in Apply::Applicative";
                    }
                }
                default {
                    die "UNKNOWN CONTINUATION $k";
                }
            }
        }

        die "This should never happen, we should always return via HOST";
    }

}
