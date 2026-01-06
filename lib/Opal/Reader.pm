
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

use IO::Scalar;

use Opal::Reader::Token;
use Opal::Reader::Compound;
use Opal::Reader::Tools::CharBuffer;

class Opal::Reader {
    field $source :param :reader;

    ADJUST {
        # coerce the input ...
        $source = IO::Scalar->new( \(my $src = "${source}") )
            unless blessed $source;

        $source = Opal::Reader::Tools::CharBuffer->new( handle => $source )
            if $source isa IO::Handle;

        confess "Expected either a string, an IO::Handler or a Opal::Reader::Tools::Charbuffer, not $source"
            unless $source isa Opal::Reader::Tools::CharBuffer;
    }

    method parse {
        my @exprs;
        while ( defined $source->discard_whitespace_and_peek ) {
            my $expr = $self->parse_expression;
            push @exprs => $expr;
        }
        return Opal::Reader::Compound->new(
            items => \@exprs,
            start => 0,
            end   => $source->current_position
        );
    }

    method parse_expression {
        if ( $source->discard_whitespace_and_peek eq '(' ) {
            my $start = $source->current_position;
            $source->skip(1);
            return $self->parse_list( Opal::Reader::Compound->new( start => $start ) );
        } else {
            my $token = $self->parse_token;
            return $token;
        }
    }

    method parse_list ( $list ) {
        my $next = $source->discard_whitespace_and_peek;
        if ( !$next || $next eq ')' ) {
            my $end = $source->current_position;
            $source->skip(1);
            return $list->finish( $end );
        } else {
            my $expr = $self->parse_expression( $source );
            return $self->parse_list( $list->add_items( $expr ) );
        }
    }

    method parse_token {
        my $start = $source->current_position;

        my $string;
        until ( $source->is_done ) {
            last if $source->peek =~ /^\s|\)|\($/;
            $string .= $source->get;
        }

        return Opal::Reader::Token->new(
            source => $string,
            start  => $start,
            end    => $source->current_position
        );
    }
}
