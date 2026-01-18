
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::TTY :isa(MXCL::Effect) {
    field $input  :param :reader = undef;
    field $output :param :reader = undef;
    field $error  :param :reader = undef;

    ADJUST {
        $input  = \*STDIN,
        $output = \*STDOUT,
        $error  = \*STDERR,
    }

    method handles ($k, $strand) {
        given ($k->config->{operation}) {
            when ('print') {
                $output->print(map $_->stringify, $k->stack->splice(0));
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Unit->new
                    )
                ]
            }
            when ('say') {
                $output->print((map $_->stringify, $k->stack->splice(0)), "\n");
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Unit->new
                    )
                ]
            }
            when ('warn') {
                $error->print((map $_->stringify, $k->stack->splice(0)), "\n");
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Unit->new
                    )
                ]
            }
            when ('readline') {
                my $line = $input->getline;
                chomp($line);
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Str->CREATE( $line )
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
            MXCL::Builtins::lift_operative('print', [qw[ ...args ]], sub ($env, @args) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'print' }
                    ),
                    MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => MXCL::Term::List->CREATE( @args ),
                        env  => $env
                    )
                ]
            }),
            MXCL::Builtins::lift_operative('say', [qw[ ...args ]], sub ($env, @args) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'say' }
                    ),
                    MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => MXCL::Term::List->CREATE( @args ),
                        env  => $env
                    )
                ]
            }),
            MXCL::Builtins::lift_operative('warn', [qw[ ...args ]], sub ($env, @args) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'warn' }
                    ),
                    MXCL::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => MXCL::Term::List->CREATE( @args ),
                        env  => $env
                    )
                ]
            }),
            MXCL::Builtins::lift_operative('readline', [], sub ($env, @) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'readline' }
                    )
                ]
            })
        ]
    }
}



