
use v5.42;
use experimental qw[ class ];

use Opal::Tokenizer;
use Opal::Parser;
use Opal::Expander;
use Opal::Machine;
use Opal::Environment;

class Opal::Strand {
    field $tokenizer :reader;
    field $parser    :reader;
    field $expander  :reader;
    field $machine   :reader;

    method load ($source) {
        $tokenizer = Opal::Tokenizer->new( source => $source );
        $parser    = Opal::Parser->new( tokens => $tokenizer->tokenize );
        $expander  = Opal::Expander->new( exprs => $parser->parse );
        $machine   = Opal::Machine->new(
            program => $expander->expand,
            env     => Opal::Environment->initialize
        );
        $self;
    }

    method run {
        my $kont = $machine->run_until_host;
        return $kont;
    }
}

