
use v5.42;
use experimental qw[ class ];

use Opal::Tokenizer;
use Opal::Parser;
use Opal::Expander;
use Opal::Machine;
use Opal::Capabilities;

use Opal::Effect;
use Opal::Effect::TTY;

class Opal::Strand {
    field $capabilities :reader :param = undef;
    field $tokenizer    :reader;
    field $parser       :reader;
    field $expander     :reader;
    field $machine      :reader;

    ADJUST {
        $capabilities //= Opal::Capabilities->new(
            effects => [
                Opal::Effect::TTY->new
            ]
        );
    }

    method load ($source) {
        $tokenizer = Opal::Tokenizer->new( source => $source );
        $parser    = Opal::Parser->new( tokens => $tokenizer->tokenize );
        $expander  = Opal::Expander->new( exprs => $parser->parse );

        my $env  = $capabilities->new_environment;
        $machine = Opal::Machine->new(
            program => $expander->expand,
            env     => $env,
            on_exit => Opal::Term::Kontinue::Host->new(
                effect => Opal::Effect::Halt->new,
                env => $env
            )
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

