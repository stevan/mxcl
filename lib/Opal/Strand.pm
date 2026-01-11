
use v5.42;
use experimental qw[ class ];

use Opal::Tokenizer;
use Opal::Parser;
use Opal::Expander;
use Opal::Machine;
use Opal::Capabilities;

class Opal::Strand {
    field $capabilities :reader :param = undef;
    field $tokenizer    :reader;
    field $parser       :reader;
    field $expander     :reader;
    field $machine      :reader;

    ADJUST {
        $capabilities //= Opal::Capabilities->new;
    }

    method load ($source) {
        $tokenizer = Opal::Tokenizer->new( source => $source );
        $parser    = Opal::Parser->new( tokens => $tokenizer->tokenize );
        $expander  = Opal::Expander->new( exprs => $parser->parse );
        $machine   = Opal::Machine->new(
            program => $expander->expand,
            env     => $capabilities->new_environment
        );
        $self;
    }

    method run {
        my $kont = $machine->run_until_host;
        return $kont;
    }
}

__END__

my @TTY = qw[
    print say warn readline
];

my @IO = qw[
    -e -f -d -s -x
    open close read readline slurp write spew
    opendir closedir readdir
];
