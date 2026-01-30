

use v5.42;
use experimental qw[ class ];

use MXCL::Term;

# ------------------------------------------------------------------------------
# Parser Terms
# ------------------------------------------------------------------------------

class MXCL::Term::Parser::Exception :isa(MXCL::Term::Exception) {}

class MXCL::Term::Parser::Token :isa(MXCL::Term) {
    field $value :param :reader;
    field $start :param :reader = -1;
    field $end   :param :reader = -1;
    field $line  :param :reader = -1;
    field $pos   :param :reader = -1;

    method source { $self->value }

    method stringify {
        $self->pprint;
    }

    method pprint {
        sprintf '%s' => $self->value
    }
}

class MXCL::Term::Parser::Compound :isa(MXCL::Term::Array) {
    field $open  :param = MXCL::Term::Parser::Token->new(value => '(');
    field $close :param = MXCL::Term::Parser::Token->new(value => ')');

    method open  :lvalue { $open  }
    method close :lvalue { $close }

    method stringify {
        $self->pprint
    }

    method pprint {
        sprintf '%s %s %s'
            => $open->pprint,
               (join ' ' => map $_->pprint, $self->all_elements),
               $close->pprint;
    }
}

# ------------------------------------------------------------------------------
