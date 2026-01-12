
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Builtins;
use Opal::Effect;

class Opal::Effect::TTY :isa(Opal::Effect) {
    field $input  :param :reader = undef;
    field $output :param :reader = undef;
    field $error  :param :reader = undef;

    ADJUST {
        $input  = \*STDIN,
        $output = \*STDOUT,
        $error  = \*STDERR,
    }

    method handles ($k) {
        my sub prepare_output () {
            map {
                # YUCK
                $_ isa Opal::Term::Str ? $_->value : $_->stringify
            } $k->spill_stack()
        }

        given ($k->config->{operation}) {
            when ('print') {
                $output->print(prepare_output());
                return +[
                    Opal::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => Opal::Term::Unit->new
                    )
                ]
            }
            when ('say') {
                $output->print(prepare_output(), "\n");
                return +[
                    Opal::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => Opal::Term::Unit->new
                    )
                ]
            }
            when ('warn') {
                $error->print(prepare_output(), "\n");
                return +[
                    Opal::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => Opal::Term::Unit->new
                    )
                ]
            }
            when ('readline') {
                my $line = $input->getline;
                chomp($line);
                return +[
                    Opal::Term::Kontinue::Return->new(
                        env   => $k->env,
                        value => Opal::Term::Str->CREATE( $line )
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
            Opal::Builtins::lift_operative('print', [qw[ ...args ]], sub ($env, @args) {
                return [
                    Opal::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'print' }
                    ),
                    Opal::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => Opal::Term::List->CREATE( @args ),
                        env  => $env
                    )
                ]
            }),
            Opal::Builtins::lift_operative('say', [qw[ ...args ]], sub ($env, @args) {
                return [
                    Opal::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'say' }
                    ),
                    Opal::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => Opal::Term::List->CREATE( @args ),
                        env  => $env
                    )
                ]
            }),
            Opal::Builtins::lift_operative('warn', [qw[ ...args ]], sub ($env, @args) {
                return [
                    Opal::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'warn' }
                    ),
                    Opal::Term::Kontinue::Eval::Cons::Rest->new(
                        rest => Opal::Term::List->CREATE( @args ),
                        env  => $env
                    )
                ]
            }),
            Opal::Builtins::lift_operative('readline', [], sub ($env, @) {
                return [
                    Opal::Term::Kontinue::Host->new(
                        env    => $env,
                        effect => $self,
                        config => { operation => 'readline' }
                    )
                ]
            })
        ]
    }
}



