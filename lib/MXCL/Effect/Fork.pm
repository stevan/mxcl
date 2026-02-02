
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::Fork :isa(MXCL::Effect) {

    method handles ($k, $machine, $pid) {
        given ($k->config->{operation}) {
            when ('fork') {
                my $expr = $k->stack->pop();
                my ($forked, $new_pid)  = $machine->fork_strand( $pid, $expr, $k->env );
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $forked,
                        value => $new_pid
                    )
                ]
            }
            when ('wait') {
                my $wait_on = $k->stack->pop();
                $machine->schedule_watcher( $wait_on, $pid );
                return undef;
            }
            when ('sleep') {
                my $ms = $k->stack->pop();
                $machine->schedule_alarm( $k->env->lookup('$PID'), $ms->value );
                return undef;
            }
            when ('time') {
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Num->CREATE( $machine->now )
                    )
                ]
            }
            default {
                die "Unknown Operation: ".$k->config->{operation};
            }
        }
    }

    method provides {
        return +[
            MXCL::Builtins::lift_operative('wait', [qw[ pid ]], sub ($env, $pid) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'wait' }
                    ),
                    MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => MXCL::Term::List->CREATE( $pid ),
                        env  => $env
                    )
                ]
            }),
            MXCL::Builtins::lift_operative('fork', [qw[ expr ]], sub ($env, $expr) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'fork' }
                    )->with_stack( $expr ),
                ]
            }),
            MXCL::Builtins::lift_operative('time', [qw[]], sub ($env) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'time' }
                    )
                ]
            }),
            MXCL::Builtins::lift_operative('sleep', [qw[ ms ]], sub ($env, $ms) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'sleep' }
                    ),
                    MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => MXCL::Term::List->CREATE( $ms ),
                        env  => $env
                    )
                ]
            }),
        ]
    }
}



