
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Compiler;
use MXCL::Builtins;

use MXCL::Effect;
use MXCL::Effect::TTY;
use MXCL::Effect::REPL;
use MXCL::Effect::Require;
use MXCL::Effect::Fork;

class MXCL::Capabilities {
    field $compiler :reader;
    field $base_env :reader;
    field $effects  :reader :param = undef;

    ADJUST {
        $effects //= +[
            MXCL::Effect::TTY->new,
            MXCL::Effect::REPL->new,
            MXCL::Effect::Require->new,
            MXCL::Effect::Fork->new,
        ];

        $compiler = MXCL::Compiler->new;
        $base_env = MXCL::Term::Environment->CREATE(
            (map { $_->name, $_ }
                (MXCL::Builtins::get_core_set->@*,
                    map { $_->provides->@* } @$effects))
        );
    }

    method new_environment {
        $base_env->derive
    }

    method compile ($source, $env) {
        $compiler->compile($source, $env);
    }

    method cleanup {
        foreach my $effect (@$effects) {
            try {
                $effect->cleanup
            } catch ($e) {
                warn "Effect cleanup failed: $e";
            }
        }
    }
}
