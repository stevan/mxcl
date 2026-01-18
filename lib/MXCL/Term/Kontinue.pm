
use v5.42;
use experimental qw[ class ];

use MXCL::Term;

# ------------------------------------------------------------------------------
# Kontinuations
# ------------------------------------------------------------------------------

class MXCL::Term::Kontinue :isa(MXCL::Term) {
    field $stack :param :reader = MXCL::Term::Array->new;
    field $env   :param :reader;

    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\:Kontinue\:\://r }

    method with_stack (@values) {
        $stack->push(@values);
        $self;
    }

    method format ($msg) {
        sprintf '(K %s {%s} @[%s] %s)' => $self->type, $msg, $stack->stringify, $env->stringify;
    }

    method stringify { $self->format('') }
}

class MXCL::Term::Kontinue::Host :isa(MXCL::Term::Kontinue) {
    field $effect :param :reader;
    field $config :param :reader = +{};

    method stringify {
        $self->format( sprintf ':effect %s' => $effect )
    }
}

class MXCL::Term::Kontinue::Throw :isa(MXCL::Term::Kontinue) {
    field $exception :param :reader;

    method stringify {
        $self->format( sprintf ':exception %s' => $exception->stringify )
    }
}

class MXCL::Term::Kontinue::Catch :isa(MXCL::Term::Kontinue) {
    field $handler :param :reader;

    method stringify {
        $self->format( sprintf ':handler %s' => $handler->stringify )
    }
}

class MXCL::Term::Kontinue::IfElse :isa(MXCL::Term::Kontinue) {
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

class MXCL::Term::Kontinue::Define :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;

    method stringify {
        $self->format( sprintf ':name %s' => $name->stringify )
    }
}

class MXCL::Term::Kontinue::Mutate :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;

    method stringify {
        $self->format( sprintf ':name %s' => $name->stringify )
    }
}

class MXCL::Term::Kontinue::Context::Enter :isa(MXCL::Term::Kontinue) {
    field $leave :reader;

    ADJUST {
        $leave = MXCL::Term::Kontinue::Context::Leave->new(
            env => $self->env
        );
    }

    method wrap (@kontinuations) {
        return ($leave, @kontinuations, $self)
    }

    method stringify {
        $self->format( sprintf ':leave %s' => $leave->stringify )
    }
}

class MXCL::Term::Kontinue::Context::Leave :isa(MXCL::Term::Kontinue) {
    field $deferred :reader = MXCL::Term::Array->new;

    method has_deferred { $deferred->length > 0 }

    method defer ($callback) {
        $deferred->push($callback);
        return;
    }

    method stringify {
        $self->format( sprintf ':deferred %s' => $deferred->stringify )
    }
}

class MXCL::Term::Kontinue::Return :isa(MXCL::Term::Kontinue) {
    field $value :param :reader;

    method stringify {
        $self->format( sprintf ':value %s' => $value->stringify )
    }
}

class MXCL::Term::Kontinue::Eval::Expr :isa(MXCL::Term::Kontinue) {
    field $expr :param :reader;

    method stringify {
        $self->format( sprintf ':expr %s' => $expr->stringify )
    }
}

class MXCL::Term::Kontinue::Eval::TOS :isa(MXCL::Term::Kontinue) {}

class MXCL::Term::Kontinue::Eval::Cons :isa(MXCL::Term::Kontinue) {
    field $cons :param :reader;

    method stringify {
        $self->format( sprintf ':cons %s' => $cons->stringify )
    }
}

class MXCL::Term::Kontinue::Eval::Cons::Rest :isa(MXCL::Term::Kontinue) {
    field $rest :param :reader;

    method stringify {
        $self->format( sprintf ':rest %s' => $rest->stringify )
    }
}

class MXCL::Term::Kontinue::Apply::Expr :isa(MXCL::Term::Kontinue) {
    field $args :param :reader;

    method stringify {
        $self->format( sprintf ':args %s' => $args->stringify )
    }
}

class MXCL::Term::Kontinue::Apply::Operative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;
    field $args :param :reader;

    method stringify {
        $self->format( sprintf ':call %s :args %s' => $call->stringify, $args->stringify )
    }
}

class MXCL::Term::Kontinue::Apply::Applicative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;

    method stringify {
        $self->format( sprintf ':call %s' => $call->stringify )
    }
}


# ------------------------------------------------------------------------------
