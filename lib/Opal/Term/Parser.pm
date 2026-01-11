

use v5.42;
use experimental qw[ class ];

use Opal::Term;

# ------------------------------------------------------------------------------
# Parser Terms
# ------------------------------------------------------------------------------

class Opal::Term::Parser::Exception :isa(Opal::Term::Exception) {}

class Opal::Term::Parser::Token :isa(Opal::Term::Str) {
    field $start :param :reader = -1;
    field $end   :param :reader = -1;
    field $line  :param :reader = -1;
    field $pos   :param :reader = -1;

    sub build ($class, $source, $start, $end, $line, $pos) {
        $class->new(
            value => $source,
            start => $start,
            end   => $end,
            line  => $line,
            pos   => $pos,
        )
    }

    method source { $self->value }

    method stringify {
        sprintf '<token %s>' => $self->value
    }
}

class Opal::Term::Parser::Compound :isa(Opal::Term::Array) {
    field $open  :param = undef;
    field $close :param = undef;

    method open  :lvalue { $open  }
    method close :lvalue { $close }

    method stringify {
        sprintf '<compound %s:[%s]:%s>'
            => $open->stringify,
               (join ' ' => map $_->stringify, $self->uncons),
               $close->stringify;
    }
}

# ------------------------------------------------------------------------------
