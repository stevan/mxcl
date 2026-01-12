
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::Require :isa(MXCL::Effect) {

    method handles ($k) {
        given ($k->config->{operation}) {
            when ('require') {
                my $file   = $k->stack_pop();
                my $path   = './ext/'.$file->stringify;
                my $fh     = IO::File->new;
                $fh->open($path, '<') or die "Cannot open file($path) because $!";
                my $source = join '' => $fh->getlines;

                # compile it ...
                my $exprs = MXCL::Expander->new(
                    exprs => MXCL::Parser->new(
                        tokens => MXCL::Tokenizer->new(
                            source => $source
                        )->tokenize
                    )->parse
                )->expand;

                return +[
                    reverse map {
                        MXCL::Term::Kontinue::Eval::Expr->new( env => $k->env, expr => $_ )
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



