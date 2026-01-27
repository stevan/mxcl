

use v5.42;
use experimental qw[ class ];

use MXCL::Term;
use MXCL::Term::Parser;

use MXCL::Tokenizer;
use MXCL::Parser;

=pod

Input: Flat structure with operators

WHILE structure has operators:
  1. Find all operators in middle positions
  2. Pick operator with LOWEST precedence (highest index)
  3. Split structure at that operator
  4. Recursively weave left and right sides
  5. Build tree with operator at root

Output: Nested tree with correct precedence

=cut


class MXCL::Weaver {
    use Data::Dumper qw[ Dumper ];

    field $precedence :param :reader = +{
      '*'  => 1,
      '/'  => 1,
      '+'  => 2,
      '-'  => 2,
      '<=' => 3,
      '>=' => 3,
      '<'  => 3,
      '>=' => 3,
      '==' => 4,
      '!=' => 4,
      '~'  => 5,
    };


    method weave ($exprs) {
        return map $self->weave_expression($_), @$exprs
    }

    method weave_expression ($expr) {
        if ($expr isa MXCL::Term::Parser::Compound) {
            return $self->weave_compound([ $expr->tokens ]);
        } else {
            return $expr;
        }
    }

    method weave_compound ($tokens) {
        say "WEAVING: ", join '  ' => map $_->stringify, @$tokens;

        return unless @$tokens;

        return $tokens->[0] if scalar @$tokens == 1;

        return MXCL::Term::Parser::Compound->CREATE(@$tokens)
            unless scalar @$tokens > 2;

        my ($split_on) = sort {
            $b->[0] <=> $a->[0]
        } map {
            exists $precedence->{ $tokens->[$_]->source }
                ? [ $precedence->{ $tokens->[$_]->source }, $_ ]
                : ()
        } 1 .. ($#{$tokens} - 1);

        my ($prec, $idx) = @$split_on;

        my @pre  = $tokens->@[ 0 .. ($idx-1) ];
        my $op   = $tokens->@[ $idx ];
        my @post = $tokens->@[ ($idx+1) .. $#{$tokens} ];

        say "     PRE: ", join ' ' => map { $_->stringify } @pre;
        say "OPERATOR: ", $op->stringify;
        say "    POST: ", join ' ' => map { $_->stringify } @post;

        return MXCL::Term::Parser::Compound->CREATE(
            $op,
            $self->weave_compound(\@pre),
            $self->weave_compound(\@post),
        );
    }

}

my $tokenizer = MXCL::Tokenizer->new;
my $parser    = MXCL::Parser->new;
my $weaver    = MXCL::Weaver->new;


my $source = q[

    (x + (10 * 20) - 2)

];

my $tokens = $tokenizer->tokenize($source);
my $parsed = $parser->parse($tokens);

say $_ foreach @$parsed;

my @weaved = $weaver->weave($parsed);

say $_ foreach @weaved;










