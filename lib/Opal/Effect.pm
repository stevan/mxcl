
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Term::Kontinue;

class Opal::Effect {
    # handles ($host-kontinue)
    #   - returning undef tells the machine to halt
    #   - otherwise return an array of Kontinue objects to resume with
    #
    # provides ()
    #   - returns an array of Callable objects to be added to the env

    method handles  ($k) { ... }
    method provides { ... }
}

class Opal::Effect::Halt :isa(Opal::Effect) {
    method handles  { undef }
    # XXX - should this provide an exit() function?
    method provides { +[] }
}

class Opal::Effect::Error :isa(Opal::Effect) {
    method handles  ($k) { die "ERROR!!!!", (join ', ' => map { $_->stringify } $k->spill_stack()),"\n" }
    # XXX - should this provide anything?
    method provides { +[] }
}






