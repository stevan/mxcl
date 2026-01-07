
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
        $queue = [
            Opal::Term::Kontinue::Host->new( effect => 'SYS::exit', env => $env ),
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
                my $value = $env->get( $expr ) // confess "Could not find ".($expr->ident)." in Environment";
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
            given ($k->kind) {
                when ('Host') {
                    return $k
                }
                when ('Return') {
                    $self->return_values( $k->value )
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
                            args => Opal::Term::List->new(items => [ $list->rest ])
                        ),
                        $self->evaluate_term( $list->first, $k->env )
                    );
                }
                when ('Eval::Cons::Rest') {
                    my $list = $k->rest;
                    my @rest = $list->rest;
                    if (scalar @rest > 0) {
                        push @$queue => Opal::Term::Kontinue::Eval::Cons::Rest->new(
                            env  => $k->env,
                            rest => Opal::Term::List->new(items => \@rest )
                        );
                    }

                    $self->return_values( $k->spill_stack() );
                    push @$queue => $self->evaluate_term( $list->first, $k->env );
                }
                when ('Apply::Expr') {
                    my $call = $k->stack_pop();

                    if ($call isa Opal::Term::Operative) {
                        die 'TODO - Apply Expr to Operative';
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
                    die 'TODO - Apply Operative';
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
                        die 'TODO - handle Lambda'
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
