
use v5.42;
use experimental qw[ class ];

use Opal::Term;

# ------------------------------------------------------------------------------
# Kontinuations
# ------------------------------------------------------------------------------

class Opal::Term::Kontinue :isa(Opal::Term) {
    field $stack :param :reader = +[];
    field $env   :param :reader;

    method kind { __CLASS__ =~ s/^Opal\:\:Term\:\:Kontinue\:\://r }

    method stack_pop       { pop  @$stack }
    method stack_push (@e) { push @$stack => @e }
    method spill_stack {
        my @s = @$stack;
        @$stack = ();
        return @s;
    }

    method format ($msg) {
        sprintf '(K %s {%s} @[%s] %s)' => $self->kind, $msg, (join ', ' => map $_->to_string, @$stack), $env->to_string;
    }

    method to_string { $self->format('') }
}

class Opal::Term::Kontinue::Host :isa(Opal::Term::Kontinue) {
    field $effect  :param :reader;
    field $options :param :reader = +{};

    method to_string {
        $self->format( sprintf ':effect %s' => $effect )
    }
}

class Opal::Term::Kontinue::Throw :isa(Opal::Term::Kontinue) {
    field $exception :param :reader;

    method to_string {
        $self->format( sprintf ':exception %s' => $exception->to_string )
    }
}

class Opal::Term::Kontinue::Catch :isa(Opal::Term::Kontinue) {
    field $handler :param :reader;

    method to_string {
        $self->format( sprintf ':handler %s' => $handler->to_string )
    }
}

class Opal::Term::Kontinue::IfElse :isa(Opal::Term::Kontinue) {
    field $condition :param :reader;
    field $if_true   :param :reader;
    field $if_false  :param :reader;

    method to_string {
        $self->format(
            sprintf ':condition %s :if-true %s :if-false %s'
                => $condition->to_string,
                   $if_true->to_string,
                   $if_false->to_string,
        )
    }
}

class Opal::Term::Kontinue::Define :isa(Opal::Term::Kontinue) {
    field $name :param :reader;

    method to_string {
        $self->format( sprintf ':name %s' => $name->to_string )
    }
}

class Opal::Term::Kontinue::Mutate :isa(Opal::Term::Kontinue) {
    field $name :param :reader;

    method to_string {
        $self->format( sprintf ':name %s' => $name->to_string )
    }
}

class Opal::Term::Kontinue::Return :isa(Opal::Term::Kontinue) {
    field $value :param :reader;

    method to_string {
        $self->format( sprintf ':value %s' => $value->to_string )
    }
}

class Opal::Term::Kontinue::Eval::Expr :isa(Opal::Term::Kontinue) {
    field $expr :param :reader;

    method to_string {
        $self->format( sprintf ':expr %s' => $expr->to_string )
    }
}

class Opal::Term::Kontinue::Eval::TOS :isa(Opal::Term::Kontinue) {}

class Opal::Term::Kontinue::Eval::Cons :isa(Opal::Term::Kontinue) {
    field $cons :param :reader;

    method to_string {
        $self->format( sprintf ':cons %s' => $cons->to_string )
    }
}

class Opal::Term::Kontinue::Eval::Cons::Rest :isa(Opal::Term::Kontinue) {
    field $rest :param :reader;

    method to_string {
        $self->format( sprintf ':rest %s' => $rest->to_string )
    }
}

class Opal::Term::Kontinue::Apply::Expr :isa(Opal::Term::Kontinue) {
    field $args :param :reader;

    method to_string {
        $self->format( sprintf ':args %s' => $args->to_string )
    }
}

class Opal::Term::Kontinue::Apply::Operative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;
    field $args :param :reader;

    method to_string {
        $self->format( sprintf ':call %s :args %s' => $call->to_string, $args->to_string )
    }
}

class Opal::Term::Kontinue::Apply::Applicative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;

    method to_string {
        $self->format( sprintf ':call %s' => $call->to_string )
    }
}


# ------------------------------------------------------------------------------
