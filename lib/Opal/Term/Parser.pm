

use v5.42;
use experimental qw[ class ];

use Opal::Term;

# ------------------------------------------------------------------------------
# Parser Terms
# ------------------------------------------------------------------------------

class Opal::Term::Parser::Location :isa(Opal::Term) {
    field $start :param = -1;
    field $end   :param = -1;
    field $line  :param = -1;
    field $pos   :param = -1;

    method start :lvalue { $start }
    method end   :lvalue { $end   }
    method line  :lvalue { $line  }
    method pos   :lvalue { $pos   }
}

class Opal::Term::Parser::Token :isa(Opal::Term::Str) {
    field $location :param :reader = undef;

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
