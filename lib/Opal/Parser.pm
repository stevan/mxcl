
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

use IO::Scalar;

use Opal::Term;

class Opal::Parser {
    field $include_whitespace :param :reader = false;

    field @tokens;

    method parse ($input) {
        my $source = $self->coerce_input($input);

        while (defined(my $line = $source->getline)) {
            my @chunks = $self->tokenize( $line );
            push @tokens => map Opal::Term::Token->new( value => $_ ), @chunks;
        }

        return $self->parse_statements;
    }

    method parse_statements {
        my @exprs;
        while (@tokens) {
            my $expr = $self->parse_expression;
            push @exprs => $expr;
        }
        return @exprs;
    }

    method parse_expression {
        my $token = shift @tokens;
        #say "parse_expression ".$token->to_string;
        return $self->parse_compound(Opal::Term::Compound->new( from => $token ))
            if $token->value eq '('
            || $token->value eq '%(';
        return $token;
    }

    method parse_compound ( $compound ) {
        #say "parse_compound ".$compound->to_string;
        if ($tokens[0]->value eq ')') {
            shift @tokens;
            return $compound;
        }
        #say "... parse_expression ";
        my $expr = $self->parse_expression;
        #say "... parse_compound EXPR:".$expr->to_string;
        return $self->parse_compound( $compound->append( $expr ) );
    }

    method coerce_input ($source) {
        $source = IO::Scalar->new( \(my $src = "${source}") )
            unless blessed $source;

        confess "Expected either a string, or an IO::Handle, not $source"
            unless $source isa IO::Handle;

        return $source;
    }

    method tokenize ($source) {
        my @chunked = grep defined && $_, split /(\'|\%\(|\(|\)|\s+)/ => $source;
        my @assembled;
        while (@chunked) {
            my $chunk = shift @chunked;
            if ($chunk =~ /^\"/) {
                my $string = $chunk;

                while (@chunked) {
                    $string .= shift @chunked;
                    last if $string =~ /\"$/;
                }

                die "Unterminated string"
                    if scalar @chunked == 0 && $string =~ /\"$/;

                $chunk = $string;
            }
            push @assembled => $chunk
                unless $chunk =~ /^\s*$/ && !$include_whitespace;
        }
        return @assembled;
    }
}
