
use v5.42;
use experimental qw[ class ];

use importer 'Carp' => qw[ confess ];

class Opal::Reader::Compound {
    field $items :param :reader = [];
    field $start :param :reader = -1;
    field $end   :param :reader = -1;

    method add_items (@e) { push @$items => @e; $self }

    method finish ($pos) { $end = $pos; $self }

    method DUMP {
        return +{
            items => [ map $_->DUMP, @$items ],
            start => $start,
            end   => $end,
        }
    }
}
