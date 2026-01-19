
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;

class MXCL::Effect {
    # handles ($host-kontinue, $strand)
    #   - returning undef tells the machine to halt
    #   - otherwise return an array of Kontinue objects to resume with
    #
    # provides ()
    #   - returns an array of Callable objects to be added to the env

    method handles  ($, $) { ... }
    method provides { ... }
}

class MXCL::Effect::Halt :isa(MXCL::Effect) {
    method handles  ($, $) { undef }
    # XXX - should this provide an exit() function?
    method provides { +[] }
}

class MXCL::Effect::Error :isa(MXCL::Effect) {
    method handles  ($k, $strand) { die "ERROR!!!!", (join ', ' => map { $_->pprint } $k->stack->splice(0)),"\n" }
    # XXX - should this provide anything?
    method provides { +[] }
}






