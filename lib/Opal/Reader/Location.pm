
use v5.42;
use experimental qw[ class ];

class Opal::Reader::Location {
    field $start  :param :reader;
    field $end    :param :reader;

    sub at ($class, $start) {
        $class->new( start => $start, end => $start + 1 )
    }

    method DUMP { sprintf 'loc(%d:%d)' => $start, $end }
}
