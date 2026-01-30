
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Parser;

class MXCL::Parser {

    method parse ($tokens) {
        my @exprs;
        while (@$tokens) {
            my $expr = $self->parse_expression($tokens);
            push @exprs => $expr;
        }
        return \@exprs;
    }

    method parse_expression ($tokens) {
        my $token = shift @$tokens;
        #say "parse_expression ".$token->pprint;
        return $self->parse_compound(MXCL::Term::Parser::Compound->new( open => $token ), $tokens)
            if $self->is_opening_bracket($token);

        if ($token->value eq "'") {
            return MXCL::Term::Parser::Compound->new(
                open     => $token,
                elements => [ $self->parse_expression($tokens) ]
            );
        }

        return $token;
    }

    method parse_compound ( $compound, $tokens ) {
        #say "parse_compound ".$compound->pprint;
        if ($self->is_closing_bracket($tokens->[0])) {
            my $close = shift @$tokens;
            $compound->close = $self->do_brackets_match($compound, $close);
            #say '-' x 80;
            #say "... ending compound";
            #say "COMPOUND:\n", $compound->pprint;
            #say "REMAINING:\n", join ", " => map $_->pprint, @$tokens;
            #say '-' x 80;
            return $compound;
        }
        #say "... parse_expression ";
        my $expr = $self->parse_expression($tokens);
        #say "... parse_compound EXPR:".$expr->pprint;
        return $self->parse_compound( $compound->push( $expr ), $tokens );
    }

    method is_opening_bracket ($token) {
        return $token->value eq '('
            || $token->value eq '%{'
            || $token->value eq '{'
            || $token->value eq '@['
            || $token->value eq '['
    }

    method is_closing_bracket ($token) {
        return $token->value eq ')'
            || $token->value eq ']'
            || $token->value eq '}'
    }

    method do_brackets_match ($compound, $close) {
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

        return $close;
    }
}
