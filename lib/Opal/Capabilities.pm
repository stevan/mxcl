
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Machine;
use Opal::Builtins;

class Opal::Capabilities {
    field $env :param = undef;

    ADJUST {
        $env //= Opal::Term::Environment->CREATE( Opal::Builtins::get_core_set->%* );
    }

    method new_environment { $env->derive }
}


