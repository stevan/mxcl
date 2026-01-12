
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Builtins;
use Opal::Effect;

class Opal::Effect::REPL :isa(Opal::Effect) {
    field $input  :param :reader = undef;
    field $output :param :reader = undef;
    field $error  :param :reader = undef;

    ADJUST {
        $input  = \*STDIN,
        $output = \*STDOUT,
        $error  = \*STDERR,
    }

    method handles ($k) {
        given ($k->config->{operation}) {
            when ('repl') {
                # print the old result if we have it
                if (defined(my $result = $k->stack_pop())) {
                    $output->print( '> ', $result->stringify, "\n" ) ;
                    $k->env->define( Opal::Term::Sym->CREATE('_') => $result );
                }

                # get new source
                $output->print('? ');
                my $source = $input->getline;

                # compile
                my $exprs = Opal::Expander->new(
                    exprs => Opal::Parser->new(
                        tokens => Opal::Tokenizer->new(
                            source => $source
                        )->tokenize
                    )->parse
                )->expand;

                # return the same continuation
                # TODO - add history to this continuation
                return +[
                    $k,
                    Opal::Term::Kontinue::Catch->new(
                        env     => $k->env,
                        handler => Opal::Builtins::lift_applicative('repl-catch', [qw[ exception ]], sub ($env, $exception) {
                            return $exception;
                        })
                    ),
                    reverse map {
                        Opal::Term::Kontinue::Eval::Expr->new( env => $k->env, expr => $_ )
                    } @$exprs
                ]
            }
            default {
                die "Unknown Operation: ".$k->config->{operation};
            }
        }
    }

    method provides {
        return +[
            Opal::Builtins::lift_operative('repl', [], sub ($env, @) {
                return [
                    Opal::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'repl' }
                    )
                ]
            }),
        ]
    }
}



