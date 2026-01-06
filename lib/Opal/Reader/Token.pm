
use v5.42;
use experimental qw[ class ];

class Opal::Reader::Token {
    field $source :param :reader;
    field $start  :param :reader = -1;
    field $end    :param :reader = -1;

    method DUMP {
        return +{
            source => $source,
            start  => $start,
            end    => $end,
        }
    }
}
