
use v5.42;
use experimental qw[ class switch ];

use MXCL::Term;
use MXCL::Term::Kontinue;

class MXCL::Effect {
    # handles ($host-kontinue, $machine, $pid)
    #   - returning undef tells the machine to halt
    #   - otherwise return an array of Kontinue objects to resume with
    #
    # provides ()
    #   - returns an array of Callable objects to be added to the env
    #
    # cleanup ()
    #   - optional cleanup hook called by Strand on exit/error/signal
    #   - default is no-op, subclasses can override to release resources

    method handles  ($, $, $) { ... }
    method provides { ... }
    method cleanup  () { } # Default: no-op
}

class MXCL::Effect::Halt :isa(MXCL::Effect) {
    method handles  ($, $, $) { undef }
    # XXX - should this provide an exit() function?
    method provides { +[] }
}

class MXCL::Effect::Error :isa(MXCL::Effect) {
    method handles  ($k, $machine, $pid) {
        die sprintf "%s ERROR! %s\n",
            $pid->pprint,
            (join ', ' => map { $_->pprint } $k->stack->splice(0))
    }

    # XXX - should this provide anything?
    method provides { +[] }
}






