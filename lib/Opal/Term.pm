
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

# ... these are built at runtime (or are part of the runtime)

# ------------------------------------------------------------------------------
# Functions
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
# Reader Objects
# ------------------------------------------------------------------------------

class Opal::Term::Token :isa(Opal::Term::Str) {

    method source { $self->value }

    method to_string {
        sprintf '<token %s>' => $self->value
    }
}

class Opal::Term::Compound :isa(Opal::Term::List) {
    field $from :param :reader;

    method to_string {
        sprintf '<compound %s:[%s]>'
            => $from->to_string,
               (join ' ' => map $_->to_string, $self->uncons);
    }
}

# ------------------------------------------------------------------------------
# Kontinuations
# ------------------------------------------------------------------------------

class Opal::Term::Kontinue :isa(Opal::Term) {
    field $stack :param :reader = +[];
    field $env   :param :reader;

    method kind { __CLASS__ =~ s/^Opal\:\:Term\:\:Kontinue\:\://r }

    method stack_pop       { pop  @$stack }
    method stack_push (@e) { push @$stack => @e }
    method spill_stack {
        my @s = @$stack;
        @$stack = ();
        return @s;
    }

    method format ($msg) {
        sprintf '(K %s {%s} @[%s] %s)' => $self->kind, $msg, (join ', ' => map $_->to_string, @$stack), $env->to_string;
    }

    method to_string { $self->format('') }
}

class Opal::Term::Kontinue::Host :isa(Opal::Term::Kontinue) {
    field $effect  :param :reader;
    field $options :param :reader = +{};

    method to_string {
        $self->format( sprintf ':effect %s' => $effect )
    }
}

class Opal::Term::Kontinue::Throw :isa(Opal::Term::Kontinue) {
    field $exception :param :reader;

    method to_string {
        $self->format( sprintf ':exception %s' => $exception->to_string )
    }
}

class Opal::Term::Kontinue::Catch :isa(Opal::Term::Kontinue) {
    field $handler :param :reader;

    method to_string {
        $self->format( sprintf ':handler %s' => $handler->to_string )
    }
}

class Opal::Term::Kontinue::IfElse :isa(Opal::Term::Kontinue) {
    field $condition :param :reader;
    field $if_true   :param :reader;
    field $if_false  :param :reader;

    method to_string {
        $self->format(
            sprintf ':condition %s :if-true %s :if-false %s'
                => $condition->to_string,
                   $if_true->to_string,
                   $if_false->to_string,
        )
    }
}

class Opal::Term::Kontinue::Define :isa(Opal::Term::Kontinue) {
    field $name :param :reader;

    method to_string {
        $self->format( sprintf ':name %s' => $name->to_string )
    }
}

class Opal::Term::Kontinue::Mutate :isa(Opal::Term::Kontinue) {
    field $name :param :reader;

    method to_string {
        $self->format( sprintf ':name %s' => $name->to_string )
    }
}

class Opal::Term::Kontinue::Return :isa(Opal::Term::Kontinue) {
    field $value :param :reader;

    method to_string {
        $self->format( sprintf ':value %s' => $value->to_string )
    }
}

class Opal::Term::Kontinue::Eval::Expr :isa(Opal::Term::Kontinue) {
    field $expr :param :reader;

    method to_string {
        $self->format( sprintf ':expr %s' => $expr->to_string )
    }
}

class Opal::Term::Kontinue::Eval::TOS :isa(Opal::Term::Kontinue) {}

class Opal::Term::Kontinue::Eval::Cons :isa(Opal::Term::Kontinue) {
    field $cons :param :reader;

    method to_string {
        $self->format( sprintf ':cons %s' => $cons->to_string )
    }
}

class Opal::Term::Kontinue::Eval::Cons::Rest :isa(Opal::Term::Kontinue) {
    field $rest :param :reader;

    method to_string {
        $self->format( sprintf ':rest %s' => $rest->to_string )
    }
}

class Opal::Term::Kontinue::Apply::Expr :isa(Opal::Term::Kontinue) {
    field $args :param :reader;

    method to_string {
        $self->format( sprintf ':args %s' => $args->to_string )
    }
}

class Opal::Term::Kontinue::Apply::Operative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;
    field $args :param :reader;

    method to_string {
        $self->format( sprintf ':call %s :args %s' => $call->to_string, $args->to_string )
    }
}

class Opal::Term::Kontinue::Apply::Applicative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;

    method to_string {
        $self->format( sprintf ':call %s' => $call->to_string )
    }
}

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























