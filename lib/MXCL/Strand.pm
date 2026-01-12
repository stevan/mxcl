
use v5.42;
use experimental qw[ class ];

use MXCL::Tokenizer;
use MXCL::Parser;
use MXCL::Expander;
use MXCL::Machine;
use MXCL::Capabilities;

use MXCL::Effect;
use MXCL::Effect::TTY;
use MXCL::Effect::REPL;
use MXCL::Effect::Require;

class MXCL::Strand {
    field $capabilities :reader :param = undef;
    field $tokenizer    :reader;
    field $parser       :reader;
    field $expander     :reader;
    field $machine      :reader;

    ADJUST {
        $capabilities //= MXCL::Capabilities->new(
            effects => [
                MXCL::Effect::TTY->new,
                MXCL::Effect::REPL->new,
                MXCL::Effect::Require->new,
            ]
        );
    }

    method load ($source) {
        $tokenizer = MXCL::Tokenizer->new( source => $source );
        $parser    = MXCL::Parser->new( tokens => $tokenizer->tokenize );
        $expander  = MXCL::Expander->new( exprs => $parser->parse );

        my $env  = $capabilities->new_environment;
        $machine = MXCL::Machine->new(
            program => $expander->expand,
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
        while (defined( my $kont = $host->effect->handles( $host ) )) {
            $host = $machine->resume( @$kont );
        }
        return $host;
    }
}

