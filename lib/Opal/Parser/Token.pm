
use v5.42;
use experimental qw[ class ];

class Opal::Parser::Token {
    field $src :param :reader;
    field $loc :param :reader;

    method DUMP {
        return +{
            src => $src,
            loc => $loc->DUMP
        }
    }
}
