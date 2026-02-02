
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Effect::TTY :isa(MXCL::Effect) {
    use Term::ReadKey qw[ ReadMode ReadKey ];

    field $input  :param :reader = undef;
    field $output :param :reader = undef;
    field $error  :param :reader = undef;

    ADJUST {
        $input  //= \*STDIN;
        $output //= \*STDOUT;
        $error  //= \*STDERR;
    }

    method handles ($k, $machine, $pid) {
        given ($k->config->{operation}) {
            when ('print') {
                $output->print(map $_->pprint, $k->stack->splice(0));
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Unit->new
                    )
                ]
            }
            when ('say') {
                $output->print((map $_->pprint, $k->stack->splice(0)), "\n");
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Unit->new
                    )
                ]
            }
            when ('warn') {
                $error->print((map $_->pprint, $k->stack->splice(0)), "\n");
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
            when ('getc') {
                ReadMode('cbreak', $input);
                my $char;
                1 until defined($char = ReadKey(-1, $input));
                ReadMode('restore', $input);
                return +[
                    MXCL::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => MXCL::Term::Str->CREATE( $char )
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
            }),
            MXCL::Builtins::lift_operative('getc', [], sub ($env, @) {
                return [
                    MXCL::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'getc' }
                    )
                ]
            })
        ]
    }
}



