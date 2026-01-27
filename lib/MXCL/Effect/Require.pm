
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::Require :isa(MXCL::Effect) {

    method handles ($k, $strand, $pid) {
        given ($k->config->{operation}) {
            when ('require') {
                my $file   = $k->stack->pop();
                my $path   = './ext/'.$file->stringify;
                my $fh     = IO::File->new;
                $fh->open($path, '<') or die "Cannot open file($path) because $!";
                my $source = join '' => $fh->getlines;
                # compile it ...
                return $strand->compiler->compile($source, $k->env);
            }
            default {
                die "Unknown Operation: ".$k->config->{operation};
            }
        }
    }

    method provides {
        return +[
            MXCL::Builtins::lift_operative('require', [qw[ file ]], sub ($env, $file) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'require' }
                    ),
                    MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => MXCL::Term::List->CREATE( $file ),
                        env  => $env
                    )
                ]
            }),
        ]
    }
}



