
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

use IO::Scalar;

use Opal::Term;
use Opal::Term::Parser;

class Opal::Parser {
    field $tokens :param :reader;

    method parse {
        my @exprs;
        while (@$tokens) {
            my $expr = $self->parse_expression;
            push @exprs => $expr;
        }
        return @exprs;
    }

    method parse_expression {
        my $token = shift @$tokens;
        #say "parse_expression ".$token->to_string;
        return $self->parse_compound(Opal::Term::Parser::Compound->new( open => $token ))
            if $token->value eq '('
            || $token->value eq '%{'
            || $token->value eq '{'
            || $token->value eq '@['
            || $token->value eq '[';

        if ($token->value eq "'") {
            return Opal::Term::Parser::Compound->new(
                open  => $token,
                items => [ $self->parse_expression ]
            );
        }

        return $token;
    }

    method parse_compound ( $compound ) {
        #say "parse_compound ".$compound->to_string;
        if ($tokens->[0]->value eq ')'
        ||  $tokens->[0]->value eq ']'
        ||  $tokens->[0]->value eq '}') {
            # TODO - ensure that the ending token
            # is of the same type as the starting
            # token, to make sure they are balanced
            my $close = shift @$tokens;
            $compound->close = $close;
            return $compound;
        }
        #say "... parse_expression ";
        my $expr = $self->parse_expression;
        #say "... parse_compound EXPR:".$expr->to_string;
        return $self->parse_compound( $compound->append( $expr ) );
    }
}
