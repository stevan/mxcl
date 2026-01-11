
use v5.42;
use experimental qw[ class ];

# ------------------------------------------------------------------------------

class Opal::Term {
    use overload '""' => 'stringify';

    method identity { $self }

    method kind { __CLASS__ =~ s/^Opal\:\:Term\:\://r }

    sub CREATE ($class, @args) { ... }

    method stringify { die "Cannot stringify a ".__CLASS__ }
    method numify    { die "Cannot numify a ".__CLASS__ }
    method boolify   { true }
}

# ==============================================================================
# ... these are built at compile time
# ==============================================================================

class Opal::Term::Atom :isa(Opal::Term) {}

class Opal::Term::Unit :isa(Opal::Term) {
    sub CREATE ($class) { $class->new }

    method stringify { '(unit)' }
    method boolify   { false    }
}

# ------------------------------------------------------------------------------
# Literals
# ------------------------------------------------------------------------------

class Opal::Term::Literal :isa(Opal::Term::Atom) {
    field $value :param :reader;

    sub CREATE ($class, $value) { $class->new( value => $value ) }
}

class Opal::Term::Num :isa(Opal::Term::Literal) {
    method stringify { sprintf '%d' => $self->value }
    method numify    { $self->value }
    method boolify   { $self->value != 0 }
}

class Opal::Term::Str :isa(Opal::Term::Literal) {
    method stringify { sprintf '"%s"' => $self->value }
    method boolify   { $self->value ne '' }
}

class Opal::Term::Bool :isa(Opal::Term::Literal) {
    method stringify { $self->value ? 'true' : 'false' }
    method boolify   { $self->value }
}

# ------------------------------------------------------------------------------
# Words
# ------------------------------------------------------------------------------

class Opal::Term::Word :isa(Opal::Term::Atom) {
    field $ident :param :reader;

    sub CREATE ($class, $ident) { $class->new( ident => $ident ) }

    method stringify { $ident }
}

class Opal::Term::Sym :isa(Opal::Term::Word) {}
class Opal::Term::Key :isa(Opal::Term::Word) {
    method stringify { ':'.$self->ident }
}

# ------------------------------------------------------------------------------
# Pairs
# ------------------------------------------------------------------------------

class Opal::Term::Pair :isa(Opal::Term) {
    field $fst :param :reader;
    field $snd :param :reader;

    sub CREATE ($class, $first, $second) { $class->new( fst => $first, snd => $second ) }

    method stringify {
        sprintf '(%s . %s)' => $fst->stringify, $snd->stringify;
    }
}

# ------------------------------------------------------------------------------
# Lists
# ------------------------------------------------------------------------------

class Opal::Term::Nil  :isa(Opal::Term::Atom) {

    sub CREATE ($class) { $class->new }

    method stringify { '()' }
    method boolify   { false }
}

class Opal::Term::List :isa(Opal::Term) {
    field $items :param :reader = +[];

    sub CREATE ($class, @items) { $class->new( items => [ @items ] ) }

    method uncons { @$items }

    method length { scalar @$items }

    method first { $items->[0] }
    method rest  {
        return Opal::Term::Nil->new if scalar @$items == 1;
        return __CLASS__->new( items => [ $items->@[ 1 .. $#{$items} ] ] );
    }

    method stringify {
        sprintf '(%s)' => join ' ' => map $_->stringify, @$items;
    }
}

# ------------------------------------------------------------------------------
# Tuple
# ------------------------------------------------------------------------------

class Opal::Term::Tuple :isa(Opal::Term) {
    field $elements :param :reader;

    sub CREATE ($class, @elements) { $class->new( elements => [ @elements ] ) }

    method size { scalar @$elements }

    method at ($idx) { $elements->[ $idx->value ] }

    method stringify {
        sprintf '[%s]' => join ' ' => map $_->stringify, @$elements;
    }
}

# ------------------------------------------------------------------------------
# Arrays
# ------------------------------------------------------------------------------

class Opal::Term::Array :isa(Opal::Term) {
    field $elements :param :reader = +[];

    sub CREATE ($class, @elements) { $class->new( elements => [ @elements ] ) }

    method length { scalar @$elements }

    method get ($idx)         { $elements->[ $idx->value ] }
    method set ($idx, $value) { $elements->[ $idx->value ] = $value }

    method push    (@others) {    push @$elements, @others; $self; }
    method unshift (@others) { unshift @$elements, @others; $self; }

    method pop   { pop   @$elements }
    method shift { shift @$elements }

    method stringify {
        sprintf '@[%s]' => join ' ' => map $_->stringify, @$elements;
    }
}

# ------------------------------------------------------------------------------
# Hashes
# ------------------------------------------------------------------------------

class Opal::Term::Hash :isa(Opal::Term) {
    field $entries :param :reader = +{};

    sub CREATE ($class, @args) {
        my %entries;
        foreach my ($key, $value) (@args) {
            $entries{ blessed $key ? $key->ident : $key } = $value;
        }
        $class->new( entries => \%entries )
    }

    method size { scalar keys %$entries }

    method has    ($key)         { exists $entries->{ $key->ident } }
    method get    ($key)         { $entries->{ $key->ident } }
    method set    ($key, $value) { $entries->{ $key->ident } = $value }
    method delete ($key)         { delete $entries->{ $key->ident } }

    method keys   { map { Key->new( ident => $_ ) } keys %$entries }
    method values { values %$entries }

    method stringify {
        sprintf '%%(%s)' => join ' ' => map {
            sprintf ':%s %s' => $_, $entries->{$_}->stringify
        } keys %$entries;
    }
}

# ------------------------------------------------------------------------------

class Opal::Term::Environment :isa(Opal::Term::Hash) {
    field $parent :param :reader = undef;

    method is_root    { not defined $parent }
    method has_parent {     defined $parent }

    method define ($key, $value) {
        return $self->set($key, $value);
    }

    method lookup ($key) {
        return $self->get($key) if $self->has($key);
        return $self->parent->lookup($key) if defined $parent;
        return;
    }

    method update ($key, $value) {
        return $self->set($key, $value) if $self->has($key);
        return $self->parent->update($key, $value) if defined $parent;
        return;
    }

    method derive (%bindings) {
        __CLASS__->new( parent => $self, entries => \%bindings )
    }
}

# ------------------------------------------------------------------------------
# Exceptions
# ------------------------------------------------------------------------------

class Opal::Term::Exception :isa(Opal::Term) {
    field $msg :param :reader;

    sub CREATE ($class, $msg) { $class->new( msg => $msg ) }

    sub throw ($class, $msg) {
        die $class->new( msg => blessed $msg ? $msg : Opal::Term::Str->new( value => $msg ) )
    }

    method stringify {
        sprintf '(exception %s)' => $msg->stringify;
    }
}

# ------------------------------------------------------------------------------
# Functions (Callable)
# ------------------------------------------------------------------------------

class Opal::Term::Callable    :isa(Opal::Term) {}
class Opal::Term::Applicative :isa(Opal::Term::Callable) {}
class Opal::Term::Operative   :isa(Opal::Term::Callable) {}

class Opal::Term::Applicative::Native :isa(Opal::Term::Applicative) {
    field $name   :param :reader;
    field $params :param :reader = [];
    field $body   :param :reader;

    sub CREATE ($class, $name, $params, $body) {
        $class->new( name => $name, params => $params, body => $body )
    }

    method stringify {
        sprintf '(native[%s]applicative)' => $name->stringify
    }
}

class Opal::Term::Operative::Native :isa(Opal::Term::Operative) {
    field $name   :param :reader;
    field $params :param :reader = [];
    field $body   :param :reader;

    sub CREATE ($class, $name, $params, $body) {
        $class->new( name => $name, params => $params, body => $body )
    }

    method stringify {
        sprintf '(native[%s]operative)' => $name->stringify;
    }
}

class Opal::Term::Lambda :isa(Opal::Term::Applicative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    sub CREATE ($class, $params, $body, $env) {
        $class->new( params => $params, body => $body, env => $env )
    }

    method stringify {
        sprintf '(lambda %s %s)' => $params->stringify, $body->stringify;
    }
}

class Opal::Term::FExpr :isa(Opal::Term::Operative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    sub CREATE ($class, $params, $body, $env) {
        $class->new( params => $params, body => $body, env => $env )
    }

    method stringify {
        sprintf '(fexpr %s %s)' => $params->stringify, $body->stringify;
    }
}

# ------------------------------------------------------------------------------
