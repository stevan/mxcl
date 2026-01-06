
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

class Opal::Reader::Compound {
    field $begin_at :param :reader;
    field $end_at          :reader;
    field @elements;

    method add_element ($e) {
        confess "Cannot add elements after a Compound is closed"
            if defined $end_at;
        push @elements => $e;
        $self;
    }

    sub start ($class, $loc) { $class->new( begin_at => $loc ) }

    method finish ($loc) {
        $end_at = $loc;
        $self;
    }

    method DUMP {
        return +{
            elements => [ map $_->DUMP, @elements ],
            begin_at => $begin_at->DUMP,
            end_at   => $end_at->DUMP,
        }
    }
}
