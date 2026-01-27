
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::Fork :isa(MXCL::Effect) {

    method handles ($k, $strand) {
        given ($k->config->{operation}) {
            when ('fork') {
                my $expr = $k->stack->pop();
                my $pid  = $strand->fork_machine( $expr, $k->env );
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => $pid
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
            MXCL::Builtins::lift_operative('fork', [qw[ expr ]], sub ($env, $expr) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'fork' }
                    )->with_stack( $expr ),
                ]
            }),
        ]
    }
}



