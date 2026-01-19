

use v5.42;
use experimental qw[ class ];

use MXCL::Term;

# ------------------------------------------------------------------------------
# Parser Terms
# ------------------------------------------------------------------------------

class MXCL::Term::Parser::Exception :isa(MXCL::Term::Exception) {}

class MXCL::Term::Parser::Token :isa(MXCL::Term::Str) {
    field $start :param :reader = -1;
    field $end   :param :reader = -1;
    field $line  :param :reader = -1;
    field $pos   :param :reader = -1;

    method source { $self->value }

    method stringify {
        sprintf '<token %s>' => $self->value
    }
    method pprint {
        sprintf '<token %s>' => $self->value
    }
}

class MXCL::Term::Parser::Compound :isa(MXCL::Term::Array) {
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
    method pprint {
        sprintf '<compound %s:[%s]:%s>'
            => $open->pprint,
               (join ' ' => map $_->pprint, $self->uncons),
               $close->pprint;
    }
}

# ------------------------------------------------------------------------------
