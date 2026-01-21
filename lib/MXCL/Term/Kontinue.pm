
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
        sprintf '(K %s {%s} %s %s)' => $self->type, $msg, $stack->stringify, $env->stringify;
    }
    method pformat ($msg) {
        sprintf '(K %s {%s} %s %s)' => $self->type, $msg, $stack->pprint, $env->pprint;
    }

    method stringify { $self->format('') }
    method pprint    { $self->pformat('') }
}

class MXCL::Term::Kontinue::Host :isa(MXCL::Term::Kontinue) {
    field $effect :param :reader;
    field $config :param :reader = +{};

    method stringify {
        $self->format( sprintf ':effect %s' => $effect )
    }
    method pprint {
        $self->pformat( sprintf ':effect %s' => $effect )
    }
}

class MXCL::Term::Kontinue::Throw :isa(MXCL::Term::Kontinue) {
    field $exception :param :reader;

    method stringify {
        $self->format( sprintf ':exception %s' => $exception->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':exception %s' => $exception->pprint )
    }
}

class MXCL::Term::Kontinue::Catch :isa(MXCL::Term::Kontinue) {
    field $handler :param :reader;

    method stringify {
        $self->format( sprintf ':handler %s' => $handler->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':handler %s' => $handler->pprint )
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
    method pprint {
        $self->pformat(
            sprintf ':condition %s :if-true %s :if-false %s'
                => $condition->pprint,
                   $if_true->pprint,
                   $if_false->pprint,
        )
    }
}

class MXCL::Term::Kontinue::Define :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;

    method stringify {
        $self->format( sprintf ':name %s' => $name->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':name %s' => $name->pprint )
    }
}

class MXCL::Term::Kontinue::Mutate :isa(MXCL::Term::Kontinue) {
    field $name :param :reader;

    method stringify {
        $self->format( sprintf ':name %s' => $name->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':name %s' => $name->pprint )
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
    method pprint {
        $self->pformat( sprintf ':leave %s' => $leave->pprint )
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
    method pprint {
        $self->pformat( sprintf ':deferred %s' => $deferred->pprint )
    }
}

class MXCL::Term::Kontinue::Return :isa(MXCL::Term::Kontinue) {
    field $value :param :reader;

    method stringify {
        $self->format( sprintf ':value %s' => $value->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':value %s' => $value->pprint )
    }
}

class MXCL::Term::Kontinue::Eval::Expr :isa(MXCL::Term::Kontinue) {
    field $expr :param :reader;

    method stringify {
        $self->format( sprintf ':expr %s' => $expr->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':expr %s' => $expr->pprint )
    }
}

class MXCL::Term::Kontinue::Eval::TOS :isa(MXCL::Term::Kontinue) {}

class MXCL::Term::Kontinue::Eval::Cons :isa(MXCL::Term::Kontinue) {
    field $cons :param :reader;

    method stringify {
        $self->format( sprintf ':cons %s' => $cons->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':cons %s' => $cons->pprint )
    }
}

class MXCL::Term::Kontinue::Eval::Cons::Rest :isa(MXCL::Term::Kontinue) {
    field $rest :param :reader;

    method stringify {
        $self->format( sprintf ':rest %s' => $rest->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':rest %s' => $rest->pprint )
    }
}

class MXCL::Term::Kontinue::Apply::Expr :isa(MXCL::Term::Kontinue) {
    field $args :param :reader;

    method stringify {
        $self->format( sprintf ':args %s' => $args->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':args %s' => $args->pprint )
    }
}

class MXCL::Term::Kontinue::Apply::Operative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;
    field $args :param :reader;

    method stringify {
        $self->format( sprintf ':call %s :args %s' => $call->stringify, $args->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':call %s :args %s' => $call->pprint, $args->pprint )
    }
}

class MXCL::Term::Kontinue::Apply::Applicative :isa(MXCL::Term::Kontinue) {
    field $call :param :reader;

    method stringify {
        $self->format( sprintf ':call %s' => $call->stringify )
    }
    method pprint {
        $self->pformat( sprintf ':call %s' => $call->pprint )
    }
}


# ------------------------------------------------------------------------------
