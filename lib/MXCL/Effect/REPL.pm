
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::REPL :isa(MXCL::Effect) {
    field $input  :param :reader = undef;
    field $output :param :reader = undef;
    field $error  :param :reader = undef;

    ADJUST {
        $input  = \*STDIN,
        $output = \*STDOUT,
        $error  = \*STDERR,
    }

    method handles ($k, $machine, $pid) {
        given ($k->config->{operation}) {
            when ('repl') {
                # print the old result if we have it
                if (defined(my $result = $k->stack->pop())) {
                    $output->print( '> ', $result->pprint, "\n" ) ;
                    $k->env->define( MXCL::Term::Sym->CREATE('_') => $result );
                }

                # get new source
                $output->print('? ');
                my $source = $input->getline;

                # compile it ...
                my $kont = $machine->capabilities->compile($source, $k->env);

                # return the same continuation
                # TODO - add history to this continuation
                return +[
                    $k,
                    MXCL::Term::Kontinue::Catch->new(
                        env     => $k->env,
                        handler => MXCL::Builtins::lift_applicative('repl-catch', [qw[ exception ]], sub ($env, $exception) {
                            return $exception;
                        })
                    ),
                    @$kont
                ]
            }
            default {
                die "Unknown Operation: ".$k->config->{operation};
            }
        }
    }

    method provides {
        return +[
            MXCL::Builtins::lift_operative('repl', [], sub ($env, @) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'repl' }
                    )
                ]
            }),
        ]
    }
}



