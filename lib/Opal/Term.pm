
use v5.42;
use experimental qw[ class ];

# ------------------------------------------------------------------------------

class Opal::Term {
    use overload '""' => 'to_string';

    method kind { __CLASS__ =~ s/^Opal\:\:Term\:\://r }

    method to_string { ... }
    method to_bool   { true }
}

# ==============================================================================
# ... these are built at compile time
# ==============================================================================

class Opal::Term::Atom :isa(Opal::Term) {}

# ------------------------------------------------------------------------------
# Literals
# ------------------------------------------------------------------------------

class Opal::Term::Literal :isa(Opal::Term::Atom) {
    field $value :param :reader;
}

class Opal::Term::Num :isa(Opal::Term::Literal) {
    method to_string { sprintf '%d' => $self->value }
    method to_bool   { $self->value != 0 }
}

class Opal::Term::Str :isa(Opal::Term::Literal) {
    method to_string { sprintf '"%s"' => $self->value }
    method to_bool   { $self->value ne '' }
}

class Opal::Term::Bool :isa(Opal::Term::Literal) {
    method to_string { $self->value ? 'true' : 'false' }
    method to_bool   { $self->value }
}

# ------------------------------------------------------------------------------
# Words
# ------------------------------------------------------------------------------

class Opal::Term::Word :isa(Opal::Term::Atom) {
    field $ident :param :reader;

    method to_string { $ident }
}

class Opal::Term::Sym :isa(Opal::Term::Word) {}
class Opal::Term::Key :isa(Opal::Term::Word) {
    method to_string { ':'.$self->ident }
}

# ------------------------------------------------------------------------------
# Pairs
# ------------------------------------------------------------------------------

class Opal::Term::Pair :isa(Opal::Term) {
    field $fst :param :reader;
    field $snd :param :reader;

    method to_string {
        sprintf '(%s . %s)' => $fst->to_string, $snd->to_string;
    }
}

# ------------------------------------------------------------------------------
# Lists
# ------------------------------------------------------------------------------

class Opal::Term::Nil  :isa(Opal::Term::Atom) {
    method to_string { '()' }
    method to_bool   { false }
}

class Opal::Term::List :isa(Opal::Term) {
    field $items :param :reader = +[];

    method uncons { @$items }

    method length { scalar @$items }

    method at ($idx) { $items->[ $idx->value ] }

    method first { $items->[0] }
    method rest  {
        return Opal::Term::Nil->new if scalar @$items == 1;
        return __CLASS__->new( items => [ $items->@[ 1 .. $#{$items} ] ] );
    }

    method append ($other) {
        push @$items, $other;
        $self;
    }

    method to_string {
        sprintf '(%s)' => join ' ' => map $_->to_string, @$items;
    }
}

# ------------------------------------------------------------------------------
# Hashes
# ------------------------------------------------------------------------------

class Opal::Term::Hash :isa(Opal::Term) {
    field $entries :param :reader = +{};

    method size { scalar keys %$entries }

    method has    ($key)         { exists $entries->{ $key->ident } }
    method get    ($key)         { $entries->{ $key->ident } }
    method set    ($key, $value) { $entries->{ $key->ident } = $value }
    method delete ($key)         { delete $entries->{ $key->ident } }

    method keys   { map { Key->new( ident => $_ ) } keys %$entries }
    method values { values %$entries }

    method to_string {
        sprintf '%%(%s)' => join ' ' => map {
            sprintf ':%s %s' => $_, $entries->{$_}->to_string
        } keys %$entries;
    }
}

# ------------------------------------------------------------------------------
# Functions (Callable)
# ------------------------------------------------------------------------------

class Opal::Term::Callable    :isa(Opal::Term) {}
class Opal::Term::Applicative :isa(Opal::Term::Callable) {}
class Opal::Term::Operative   :isa(Opal::Term::Callable) {}

class Opal::Term::Applicative::Native :isa(Opal::Term::Applicative) {
    field $name :param :reader;
    field $body :param :reader;

    method to_string {
        sprintf '(native:[%s]:applicative)' => $name;
    }
}

class Opal::Term::Operative::Native :isa(Opal::Term::Operative) {
    field $name :param :reader;
    field $body :param :reader;

    method to_string {
        sprintf '(native:[%s]:operative)' => $name;
    }
}

class Opal::Term::Lambda :isa(Opal::Term::Applicative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method to_string {
        sprintf '(lambda %s %s)' => $params->to_string, $body->to_string;
    }
}

class Opal::Term::FExpr :isa(Opal::Term::Operative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method to_string {
        sprintf '(fexpr %s %s)' => $params->to_string, $body->to_string;
    }
}

# ------------------------------------------------------------------------------
