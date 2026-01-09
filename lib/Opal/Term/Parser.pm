

use v5.42;
use experimental qw[ class ];

use Opal::Term;

# ------------------------------------------------------------------------------
# Parser Terms
# ------------------------------------------------------------------------------

class Opal::Term::Parser::Token :isa(Opal::Term::Str) {
    field $start :param :reader = -1;
    field $end   :param :reader = -1;
    field $line  :param :reader = -1;
    field $pos   :param :reader = -1;

    method source { $self->value }

    method to_string {
        sprintf '<token %s>' => $self->value
    }
}

class Opal::Term::Parser::Compound :isa(Opal::Term::List) {
    field $open  :param = undef;
    field $close :param = undef;

    method open  :lvalue { $open  }
    method close :lvalue { $close }

    method to_string {
        sprintf '<compound %s:[%s]:%s>'
            => $open->to_string,
               (join ' ' => map $_->to_string, $self->uncons),
               $close->to_string;
    }
}

# ------------------------------------------------------------------------------
