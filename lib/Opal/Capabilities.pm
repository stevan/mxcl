
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Builtins;
use Opal::Effect;

class Opal::Capabilities {
    field $effects  :param :reader = +[];
    field $base_env :reader;

    ADJUST {
        $base_env = Opal::Term::Environment->CREATE(
            (map { $_->name, $_ }
                (Opal::Builtins::get_core_set->@*,
                    map { $_->provides->@* } @$effects))
        )
    }

    method new_environment { $base_env->derive }
}
