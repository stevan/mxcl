
use v5.42;
use experimental qw[ class ];

# ------------------------------------------------------------------------------

class Opal::Term {

    method kind { __CLASS__ =~ s/^Opal\:\:Term\:\://r }

    method to_string { ... }
}

# ------------------------------------------------------------------------------

class Opal::Term::Unit :isa(Opal::Term) {
    method to_string { '(unit)' }
}

class Opal::Term::Atom :isa(Opal::Term) {}

# ------------------------------------------------------------------------------
# Literals
# ------------------------------------------------------------------------------

class Opal::Term::Literal :isa(Opal::Term::Atom) {
    field $value :param :reader;
}

class Opal::Term::Num :isa(Opal::Term::Literal) {
    method to_string { sprintf '%d' => $self->value }
}

class Opal::Term::Str :isa(Opal::Term::Literal) {
    method to_string { sprintf '"%s"' => $self->value }
}

class Opal::Term::Bool :isa(Opal::Term::Literal) {
    method to_string { $self->value ? 'true' : 'false' }
}

# ------------------------------------------------------------------------------
# Words
# ------------------------------------------------------------------------------

class Opal::Term::Word :isa(Opal::Term::Atom) {
    field $ident :param :reader;

    method to_string { $ident }
}

class Opal::Term::Sym :isa(Opal::Term::Word) {}
class Opal::Term::Key :isa(Opal::Term::Word) {}

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
}

class Opal::Term::List :isa(Opal::Term) {
    field $items :param :reader = +[];

    method length { scalar @$items }

    method at ($idx) { $items->[ $idx->value ] }

    method first { $items->[0] }
    method rest  { $items->@[ 1 .. $#{$items} ] }

    method to_string {
        sprintf '(%s)' => join ' ' => map $_->to_string, @$items;
    }
}

# ------------------------------------------------------------------------------
# Hashes
# ------------------------------------------------------------------------------

class Opal::Term::Hash :isa(Opal::Term) {
    field $entries :param :reader = +{};

    method has    ($key)         { exists $entries->{ $key->ident } }
    method get    ($key)         { $entries->{ $key->ident } }
    method set    ($key, $value) { $entries->{ $key->ident } = $value }
    method delete ($key)         { delete $entries->{ $key->ident } }

    method keys   { map { Key->new( ident => $_ ) } keys %$entries }
    method values { values %$entries }

    method to_string {
        sprintf '%%(%s)' => join ' ' => map {
            sprintf '%s %s' => $_, $entries->{$_}->to_string
        } keys %$entries;
    }
}

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

class Opal::Term::Callable    :isa(Opal::Term) {}
class Opal::Term::Applicative :isa(Opal::Term::Callable) {}
class Opal::Term::Operative   :isa(Opal::Term::Callable) {}

class Opal::Term::Applicative::Native :isa(Opal::Term::Applicative) {
    field $params :param :reader;
    field $body   :param :reader;

    method to_string {
        sprintf '(native:[%s]:applicative)' => $params->to_string;
    }
}

class Opal::Term::Operative::Native :isa(Opal::Term::Operative) {
    field $params :param :reader;
    field $body   :param :reader;

    method to_string {
        sprintf '(native:[%s]:operative)' => $params->to_string;
    }
}

class Opal::Term::Lambda :isa(Opal::Term::Applicative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method to_string {
        sprintf '(lambda (%s) %s)' => $params->to_string, $body->to_string;
    }
}

class Opal::Term::FExpr :isa(Opal::Term::Operative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    method to_string {
        sprintf '(fexpr (%s) %s)' => $params->to_string, $body->to_string;
    }
}

# ------------------------------------------------------------------------------
# Reader Objects
# ------------------------------------------------------------------------------

class Opal::Term::Token :isa(Opal::Term) {
    field $source :param :reader;
    field $start  :param :reader = -1;
    field $end    :param :reader = -1;

    method is_synthetic { $start == -1 && $end == -1 }

    method to_string {
        sprintf '(token:[\'%s\']:loc[%d;%d])' => $source, $start, $end
    }
}

class Opal::Term::Compound :isa(Opal::Term) {
    field $items  :param :reader = +[];
    field $open   :param :reader = undef;
    field $close  :param :reader = undef;

    method is_synthetic  { not(defined $open) && not(defined $close) }
    method is_unfinished { not(defined $close) }

    method add_items (@e) { push @$items => @e; $self }

    method begin  ($token) { $open  = $token; $self }
    method finish ($token) { $close = $token; $self }

    method to_string {
        sprintf '(compound:[%s])' => (join ' ' => map $_->to_string, @$items);
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

    method to_string {
        sprintf '(kontinue %s:[%s] %s)' => $self->kind, (join ', ' => map $_->to_string, @$stack), $env->to_string;
    }
}

class Opal::Term::Kontinue::Host :isa(Opal::Term::Kontinue) {
    field $effect  :param :reader;
    field $options :param :reader = +{};
}

class Opal::Term::Kontinue::Throw :isa(Opal::Term::Kontinue) {
    field $exception :param :reader;
}

class Opal::Term::Kontinue::Catch :isa(Opal::Term::Kontinue) {
    field $handler :param :reader;
}

class Opal::Term::Kontinue::IfElse :isa(Opal::Term::Kontinue) {
    field $condition :param :reader;
    field $if_true   :param :reader;
    field $if_false  :param :reader;
}

class Opal::Term::Kontinue::Define :isa(Opal::Term::Kontinue) {
    field $name :param :reader;
}

class Opal::Term::Kontinue::Return :isa(Opal::Term::Kontinue) {
    field $value :param :reader;
}

class Opal::Term::Kontinue::Eval::Expr :isa(Opal::Term::Kontinue) {
    field $expr :param :reader;
}

class Opal::Term::Kontinue::Eval::TOS :isa(Opal::Term::Kontinue) {}

class Opal::Term::Kontinue::Eval::Cons :isa(Opal::Term::Kontinue) {
    field $cons :param :reader;
}

class Opal::Term::Kontinue::Eval::Cons::Rest :isa(Opal::Term::Kontinue) {
    field $rest :param :reader;
}

class Opal::Term::Kontinue::Apply::Expr :isa(Opal::Term::Kontinue) {
    field $args :param :reader;
}

class Opal::Term::Kontinue::Apply::Operative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;
}

class Opal::Term::Kontinue::Apply::Applicative :isa(Opal::Term::Kontinue) {
    field $call :param :reader;
}

# ------------------------------------------------------------------------------
# Runtime Objects
# ------------------------------------------------------------------------------

class Opal::Term::Exception :isa(Opal::Term) {
    field $msg :param :reader;
}

class Opal::Term::Environment :isa(Opal::Term::Hash) {
    field $parent :param :reader = undef;

    method is_root    { not defined $parent }
    method has_parent {     defined $parent }

    method derive (%bindings) {
        __CLASS__->new( parent => $self, entries => \%bindings )
    }
}

# ------------------------------------------------------------------------------























