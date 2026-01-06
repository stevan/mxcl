
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

use IO::Scalar;

use Opal::Term;
use Opal::Reader::Tools::CharBuffer;

class Opal::Reader {
    field $buffer :param :reader;

    ADJUST {
        # coerce the input ...
        $buffer = IO::Scalar->new( \(my $src = "${buffer}") )
            unless blessed $buffer;

        $buffer = Opal::Reader::Tools::CharBuffer->new( handle => $buffer )
            if $buffer isa IO::Handle;

        confess "Expected either a string, an IO::Handler or a Opal::Reader::Tools::Charbuffer, not $buffer"
            unless $buffer isa Opal::Reader::Tools::CharBuffer;
    }

    method parse {
        my @exprs;
        while ( defined $buffer->discard_whitespace_and_peek ) {
            my $expr = $self->parse_expression;
            push @exprs => $expr;
        }

        return \@exprs;
    }

    method parse_expression {
        if ( $buffer->discard_whitespace_and_peek eq '(' ) {
            my $start = $buffer->current_position;
            $buffer->skip(1);
            return $self->parse_list( $self->create_compound( $start ) );
        } else {
            my $token = $self->parse_token;
            return $token;
        }
    }

    method parse_list ( $list ) {
        my $next = $buffer->discard_whitespace_and_peek;
        if ( !$next || $next eq ')' ) {
            my $end = $buffer->current_position;
            $buffer->skip(1);
            return $list->finish( $self->create_token( ')', $end ) );
        } else {
            my $expr = $self->parse_expression( $buffer );
            return $self->parse_list( $list->add_items( $expr ) );
        }
    }

    method parse_token {
        my $at = $buffer->current_position;
        my $string;
        until ( $buffer->is_done ) {
            last if $buffer->peek =~ /^\s|\)|\($/;
            $string .= $buffer->get;
        }
        return $self->create_token( $string, $at );
    }

    method create_compound ( $at ) {
        return Opal::Term::Compound->new->begin(
            $self->create_token( '(', $at )
        )
    }

    method create_token ( $string, $at ) {
        return Opal::Term::Token->new(
            source => $string,
            start  => $at,
            end    => $buffer->current_position
        );
    }
}
