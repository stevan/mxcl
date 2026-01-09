
use v5.42;
use experimental qw[ class ];

use Opal::Term;

# ------------------------------------------------------------------------------
# Runtime Objects
# ------------------------------------------------------------------------------

class Opal::Term::Unit :isa(Opal::Term::Nil) {
    method to_string { '(unit)' }
    method to_bool   { false    }
}

class Opal::Term::Exception :isa(Opal::Term) {
    field $msg :param :reader;

    sub throw ($class, $msg) {
        die $class->new( msg => blessed $msg ? $msg : Opal::Term::Str->new( value => $msg ) )
    }

    method to_string {
        sprintf '(exception %s)' => $msg->to_string;
    }
}

class Opal::Term::Environment :isa(Opal::Term::Hash) {
    field $parent :param :reader = undef;

    method is_root    { not defined $parent }
    method has_parent {     defined $parent }

    method define ($key, $value) {
        return $self->set($key, $value);
    }

    method lookup ($key) {
        return $self->get($key) if $self->has($key);
        return $self->parent->lookup($key) if $self->has_parent;
        return;
    }

    method update ($key, $value) {
        return $self->set($key, $value) if $self->has($key);
        return $self->parent->update($key, $value) if $self->has_parent;
        return;
    }

    method derive (%bindings) {
        __CLASS__->new( parent => $self, entries => \%bindings )
    }
}

# ------------------------------------------------------------------------------

