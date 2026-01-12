
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Builtins;
use Opal::Effect;

class Opal::Capabilities {
    field $root_env :param :reader = undef;
    field $effects  :param :reader = +[];

    ADJUST {
        $root_env //= Opal::Term::Environment->CREATE(
            Opal::Builtins::get_core_set->%*
        );
    }

    method new_environment {
        my $env = $root_env->derive;
        foreach my $effect (@$effects) {
            $env->define( $_->name, $_ ) foreach $effect->provides->@*;
        }
        return $env;
    }
}
