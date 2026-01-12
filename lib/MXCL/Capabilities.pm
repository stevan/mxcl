
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Builtins;
use MXCL::Effect;

class MXCL::Capabilities {
    field $effects  :param :reader = +[];
    field $base_env :reader;

    ADJUST {
        $base_env = MXCL::Term::Environment->CREATE(
            (map { $_->name, $_ }
                (MXCL::Builtins::get_core_set->@*,
                    map { $_->provides->@* } @$effects))
        )
    }

    method new_environment { $base_env->derive }
}
