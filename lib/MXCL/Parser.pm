
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Parser;

class MXCL::Parser {
    field $tokens :param :reader;

    method parse {
        my @exprs;
        while (@$tokens) {
            my $expr = $self->parse_expression;
            push @exprs => $expr;
        }
        return \@exprs;
    }

    method parse_expression {
        my $token = shift @$tokens;
        #say "parse_expression ".$token->stringify;
        return $self->parse_compound(MXCL::Term::Parser::Compound->new( open => $token ))
            if $token->value eq '('
            || $token->value eq '%{'
            || $token->value eq '{'
            || $token->value eq '@['
            || $token->value eq '[';

        if ($token->value eq "'") {
            return MXCL::Term::Parser::Compound->new(
                open     => $token,
                elements => [ $self->parse_expression ]
            );
        }

        return $token;
    }

    method parse_compound ( $compound ) {
        #say "parse_compound ".$compound->stringify;
        if ($tokens->[0]->value eq ')'
        ||  $tokens->[0]->value eq ']'
        ||  $tokens->[0]->value eq '}') {
            my $close = shift @$tokens;
            given ($close->value) {
                when (')') {
                    $compound->open->value eq '('
                        || MXCL::Term::Parser::Exception->throw
                            ("Unbalanced Brackets: Expected ) and got "
                                .$compound->open->value)
                }
                when (']') {
                    $compound->open->value eq '[' || $compound->open->value eq '@['
                        || MXCL::Term::Parser::Exception->throw
                            ("Unbalanced Brackets: Expected ] and got "
                                .$compound->open->value)
                }
                when ('}') {
                    $compound->open->value eq '{' || $compound->open->value eq '%{'
                        || MXCL::Term::Parser::Exception->throw
                            ("Unbalanced Brackets: Expected } and got "
                                .$compound->open->value)
                }
            }
            $compound->close = $close;
            return $compound;
        }
        #say "... parse_expression ";
        my $expr = $self->parse_expression;
        #say "... parse_compound EXPR:".$expr->stringify;
        return $self->parse_compound( $compound->push( $expr ) );
    }
}
