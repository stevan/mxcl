
use v5.42;
use experimental qw[ class ];

use MXCL::Compiler;
use MXCL::Machine;
use MXCL::Capabilities;

use MXCL::Effect;
use MXCL::Effect::TTY;
use MXCL::Effect::REPL;
use MXCL::Effect::Require;

class MXCL::Strand {
    field $capabilities :reader :param = undef;
    field $compiler     :reader;
    field $machine      :reader;

    ADJUST {
        $compiler = MXCL::Compiler->new;

        $capabilities //= MXCL::Capabilities->new(
            effects => [
                MXCL::Effect::TTY->new,
                MXCL::Effect::REPL->new,
                MXCL::Effect::Require->new,
            ]
        );
    }

    method load ($source) {
        my $env     = $capabilities->new_environment;
        my $program = $compiler->compile($source, $env);
        $machine = MXCL::Machine->new(
            program => $program,
            env     => $env,
            on_exit => MXCL::Term::Kontinue::Host->new(
                effect => MXCL::Effect::Halt->new,
                env => $env
            ),
            on_error => MXCL::Term::Kontinue::Host->new(
                effect => MXCL::Effect::Error->new,
                env => $env
            ),
        );

        $self;
    }

    method run {
        my $host = $machine->run_until_host;
        while (defined( my $kont = $host->effect->handles( $host, $self ) )) {
            $host = $machine->resume( @$kont );
        }
        return $host;
    }
}

