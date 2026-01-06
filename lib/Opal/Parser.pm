
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

use IO::Scalar;

use Opal::Parser::Location;
use Opal::Parser::Token;
use Opal::Parser::Compound;
use Opal::Parser::Tools::CharBuffer;

class Opal::Parser {

    method parse ($source) {
        # coerce the input ...
        $source = IO::Scalar->new( \(my $src = "${source}") )
            unless blessed $source;

        $source = Opal::Parser::Tools::CharBuffer->new( handle => $source )
            if $source isa IO::Handle;

        confess "Expected either a string, an IO::Handler or a Opal::Parser::Tools::Charbuffer, not $source"
            unless $source isa Opal::Parser::Tools::CharBuffer;

        my @exprs;
        until ( $source->is_done ) {
            my ($expr, $rest) = $self->parse_tokens( $source );
            push @exprs => $expr;
            $source = $rest;
        }

        return @exprs;
    }

    method parse_tokens ( $buffer ) {
        if ( $buffer->discard_whitespace_and_peek eq '(' ) {
            my $start = $buffer->current_position;
            $buffer->skip(1);
            return $self->parse_list(
                $buffer,
                Opal::Parser::Compound->start( Opal::Parser::Location->at( $start ) )
            );
        } else {
            my $token = $self->collect_token( $buffer );
            return $token, $buffer;
        }
    }

    method parse_list ( $buffer, $acc ) {
        my $next = $buffer->discard_whitespace_and_peek;
        if ( !$next || $next eq ')' ) {
            my $end = $buffer->current_position;
            $buffer->skip(1);
            $acc->finish( Opal::Parser::Location->at( $end ) );
            return $acc, $buffer;
        } else {
            my ( $expr, $rest ) = $self->parse_tokens( $buffer );
            $acc->add_element( $expr );
            return $self->parse_list( $rest, $acc )
        }
    }

    method collect_token ( $buffer ) {
        my $start = $buffer->current_position;

        my $string;
        until ( $buffer->is_done ) {
            last if $buffer->peek =~ /^\s|\)|\($/;
            $string .= $buffer->get;
        }

        return Opal::Parser::Token->new(
            src => $string,
            loc => Opal::Parser::Location->new(
                start  => $start,
                end    => $buffer->current_position
            )
        );
    }

}
