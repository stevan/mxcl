
use v5.42;
use experimental qw[ class ];

use Opal::Term;

# ------------------------------------------------------------------------------
# Kontinuations
# ------------------------------------------------------------------------------

class Opal::Term::Kontinue :isa(Opal::Term) {
    field $stack :param :reader = +[];
    field $env   :param :reader;

    sub build ($class, %args) { $class->new( %args ) }

    method kind { __CLASS__ =~ s/^Opal\:\:Term\:\:Kontinue\:\://r }

    method stack_pop       { pop  @$stack }
    method stack_push (@e) { push @$stack => @e }
    method spill_stack {
        my @s = @$stack;
        @$stack = ();
        return @s;
    }

    method format ($msg) {
        sprintf '(K %s {%s} @[%s] %s)' => $self->kind, $msg, (join ', ' => map $_->stringify, @$stack), $env->stringify;
    }

    method stringify { $self->format('') }
}

class Opal::Term::Kontinue::Host :isa(Opal::Term::Kontinue) {
    field $effect  :param :reader;
    field $options :param :reader = +{};

    method stringify {
        $self->format( sprintf ':effect %s' => $effect )
    }
}

class Opal::Term::Kontinue::Throw :isa(Opal::Term::Kontinue) {
    field $exception :param :reader;

    method stringify {
        $self->format( sprintf ':exception %s' => $exception->stringify )
    }
}

class Opal::Term::Kontinue::Catch :isa(Opal::Term::Kontinue) {
    field $handler :param :reader;

    method stringify {
        $self->format( sprintf ':handler %s' => $handler->stringify )
    }
}

class Opal::Term::Kontinue::IfElse :isa(Opal::Term::Kontinue) {
    field $condition :param :reader;
    field $if_true   :param :reader;
    field $if_false  :param :reader;

    method stringify {
        $self->format(
            sprintf ':condition %s :if-true %s :if-false %s'
                => $condition->stringify,
                   $if_true->stringify,
                   $if_false->stringify,
        )
    }
}

class Opal::Term::Kontinue::Define :isa(Opal::Term::Kontinue) {
    field $name :param :reader;

    method stringify {
        $self->format( sprintf ':name %s' => $name->stringify )
    }
}

class Opal::Term::Kontinue::Mutate :isa(Opal::Term::Kontinue) {
    field $name :param :reader;

    method stringify {
        $self->format( sprintf ':name %s' => $name->stringify )
    }
}

class Opal::Term::Kontinue::Return :isa(Opal::Term::Kontinue) {
    field $value :param :reader;

    method stringify {
        $self->format( sprintf ':value %s' => $value->stringify )
    }
}

class Opal::Term::Kontinue::Eval::Expr :isa(Opal::Term::Kontinue) {
    field $expr :param :reader;

    method stringify {
        $self->format( sprintf ':expr %s' => $expr->stringify )
    }
}

class Opal::Term::Kontinue::Eval::TOS :isa(Opal::Term::Kontinue) {}

class Opal::Term::Kontinue::Eval::Cons :isa(Opal::Term::Kontinue) {
    field $cons :param :reader;

    method stringify {
        $self->format( sprintf ':cons %s' => $cons->stringify )
    }
}

class Opal::Term::Kontinue::Eval::Cons::Rest :isa(Opal::Term::Kontinue) {
    field $rest :param :reader;

    method stringify {
        $self->format( sprintf ':rest %s' => $rest->stringify )
    }
}

class Opal::Term::Kontinue::Apply::Expr :isa(Opal::Term::Kontinue) {
    field $args :param :reader;

    method stringify {
        $self->format( sprintf ':args %s' => $args->stringify )
    }
}

class Opal::Term::Kontinue::Apply::Operative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;
    field $args :param :reader;

    method stringify {
        $self->format( sprintf ':call %s :args %s' => $call->stringify, $args->stringify )
    }
}

class Opal::Term::Kontinue::Apply::Applicative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;

    method stringify {
        $self->format( sprintf ':call %s' => $call->stringify )
    }
}


# ------------------------------------------------------------------------------
