
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;

use MXCL::Tokenizer;
use MXCL::Parser;
use MXCL::Expander;

class MXCL::Compiler {
    field $tokenizer    :reader;
    field $parser       :reader;
    field $expander     :reader;

    ADJUST {
        $tokenizer = MXCL::Tokenizer->new;
        $parser    = MXCL::Parser->new;
        $expander  = MXCL::Expander->new;
    }

    method compile ($source, $env) {
        my $tokens = $tokenizer->tokenize($source);
        my $trees  = $parser->parse($tokens);
        my $expr   = $expander->expand($trees);
        return [
            reverse map {
                MXCL::Term::Kontinue::Eval::Expr->new(
                    expr => $_,
                    env  => $env,
                )
            } @$expr
        ]
    }
}
