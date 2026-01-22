
use v5.42;
use experimental qw[ class ];

use Sub::Util ();

# ------------------------------------------------------------------------------

class MXCL::Term {
    method identity { $self }

    method type { __CLASS__ =~ s/^MXCL\:\:Term\:\://r }

    sub CREATE ($class, @args) { ... }

    method equals ($other) { ... }

    method stringify { die "Cannot stringify a ".__CLASS__ }
    method pprint    { die "Cannot pprint a ".__CLASS__ }
    method numify    { die "Cannot numify a ".__CLASS__ }
    method boolify   { true }
}

# ==============================================================================
# ... these are built at compile time
# ==============================================================================

class MXCL::Term::Atom :isa(MXCL::Term) {}

class MXCL::Term::Unit :isa(MXCL::Term) {
    sub CREATE ($class) { $class->new }

    method equals ($other) { $other isa __CLASS__ }

    method stringify { '(unit)' }
    method pprint    { '(unit)' }
    method boolify   { false    }
}

# ------------------------------------------------------------------------------
# Words
# ------------------------------------------------------------------------------

class MXCL::Term::Word :isa(MXCL::Term::Atom) {
    field $ident :param :reader;

    sub CREATE ($class, $ident) { $class->new( ident => $ident ) }

    method equals ($other) { $other isa MXCL::Term::Word && $other->ident eq $self->ident }
    method stringify { $ident }
    method pprint    { $ident }
}

class MXCL::Term::Sym :isa(MXCL::Term::Word) {}
class MXCL::Term::Key :isa(MXCL::Term::Word) {
    method stringify { ':'.$self->ident }
    method pprint    { ':'.$self->ident }
}

# ------------------------------------------------------------------------------
# Pairs
# ------------------------------------------------------------------------------

class MXCL::Term::Pair :isa(MXCL::Term) {
    field $fst :param :reader;
    field $snd :param :reader;

    sub CREATE ($class, $first, $second) { $class->new( fst => $first, snd => $second ) }

    method equals ($other) {
        $other isa MXCL::Term::Word
            && $fst->equals($other->fst)
                %% && $snd->equals($other->snd)
    }

    method stringify {
        sprintf '(%s . %s)' => $fst->stringify, $snd->stringify;
    }
    method pprint {
        sprintf '(%s . %s)' => $fst->pprint, $snd->pprint;
    }
}

# ------------------------------------------------------------------------------
# Lists
# ------------------------------------------------------------------------------

class MXCL::Term::Nil  :isa(MXCL::Term::Atom) {

    sub CREATE ($class) { $class->new }

    method uncons { () }

    method equals ($other) { $other isa __CLASS__ }
    method stringify { '()' }
    method pprint    { '()' }
    method boolify   { false }
}

class MXCL::Term::List :isa(MXCL::Term) {
    field $items :param :reader = +[];

    sub CREATE ($class, @items) { $class->new( items => [ @items ] ) }

    method uncons { @$items }

    method length { scalar @$items }

    method first { $items->[0] }
    method rest  {
        return MXCL::Term::Nil->new if scalar @$items == 1;
        return __CLASS__->new( items => [ $items->@[ 1 .. $#{$items} ] ] );
    }

    method equals ($other) {
        return false unless $other isa __CLASS__;
        return false unless $self->length == $other->length;
        for (my $i = 0; $i < scalar @$items; $i++) {
            return false
                unless $items->[$i]->equals( $other->items->[$i] );
        }
        return true;
    }

    method stringify {
        sprintf '(%s)' => join ' ' => map $_->stringify, @$items;
    }
    method pprint {
        sprintf '(%s)' => join ' ' => map $_->pprint, @$items;
    }
}

# ------------------------------------------------------------------------------
# Tuple
# ------------------------------------------------------------------------------

class MXCL::Term::Tuple :isa(MXCL::Term) {
    field $elements :param :reader;

    sub CREATE ($class, @elements) { $class->new( elements => [ @elements ] ) }

    method size { scalar @$elements }

    method all_elements { @$elements }

    method at ($idx) { $elements->[ $idx->value ] }

    method equals ($other) {
        return false unless $other isa __CLASS__;
        return false unless $self->size == $other->size;
        for (my $i = 0; $i < scalar @$elements; $i++) {
            return false
                unless $elements->[$i]->equals( $other->elements->[$i] );
        }
        return true;
    }

    method stringify {
        sprintf '[%s]' => join ' ' => map $_->stringify, @$elements;
    }
    method pprint {
        sprintf '[%s]' => join ' ' => map $_->pprint, @$elements;
    }
}

# ------------------------------------------------------------------------------
# Arrays
# ------------------------------------------------------------------------------

class MXCL::Term::Array :isa(MXCL::Term) {
    field $elements :param :reader = +[];

    sub CREATE ($class, @elements) { $class->new( elements => [ @elements ] ) }

    method length { scalar @$elements }

    method all_elements { @$elements }

    method get ($idx)         { $elements->[ $idx->value ] }
    method set ($idx, $value) { $elements->[ $idx->value ] = $value }

    method push    (@others) {    push @$elements, @others; $self; }
    method unshift (@others) { unshift @$elements, @others; $self; }

    method pop   { pop   @$elements }
    method shift { shift @$elements }

    method splice ($offset, $length=undef) {
        return splice @$elements, $offset unless defined $length;
        return splice @$elements, $offset, $length;
    }

    method equals ($other) {
        return false unless $other isa __CLASS__;
        return false unless $self->length == $other->length;
        for (my $i = 0; $i < scalar @$elements; $i++) {
            return false
                unless $elements->[$i]->equals( $other->elements->[$i] );
        }
        return true;
    }

    method stringify {
        sprintf '@[%s]' => join ' ' => map $_->stringify, @$elements;
    }
    method pprint {
        sprintf '@[%s]' => join ' ' => map $_->pprint, @$elements;
    }
}

# ------------------------------------------------------------------------------
# Hashes
# ------------------------------------------------------------------------------

class MXCL::Term::Hash :isa(MXCL::Term) {
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

    method keys   { map { MXCL::Term::Key->new( ident => $_ ) } keys %$entries }
    method values { values %$entries }

    method equals ($other) {
        return false unless $other isa __CLASS__;
        return false unless $self->size == $other->size;
        foreach my $key (keys %$entries) {
            return false
                unless $entries->{$key}->equals( $other->entries->{$key} );
        }
        return true;
    }

    method stringify {
        sprintf '%%(%s)' => join ' ' => map {
            sprintf ':%s %s' => $_, $entries->{$_}->stringify
        } keys %$entries;
    }

    method pprint {
        sprintf '%%(%s)' => join ' ' => map {
            sprintf ':%s %s' => $_, $entries->{$_}->pprint
        } keys %$entries;
    }
}

# ------------------------------------------------------------------------------

class MXCL::Term::Environment :isa(MXCL::Term::Hash) {
    field $parent   :param :reader = undef;

    method is_root    { not defined $parent }
    method has_parent {     defined $parent }

    # ...

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

    # ...

    method capture {
        __CLASS__->new( entries => $self->entries )
    }

    method derive (%bindings) {
        __CLASS__->new( parent => $self, entries => \%bindings )
    }

    method equals ($other) {
        return true if $self->SUPER::equals($other);
        return refaddr $parent == refaddr $other->parent
            if $parent->has_parent && $other->has_parent;
        return false;
    }

    method pprint ($indent='') {
        sprintf "%%E(\n${indent}%s%s\n${indent})" =>
            (join "\n${indent}" => map { sprintf '%s %s' => $_->pprint, ($self->get($_) ? $self->get($_)->type : 'WTF!') } $self->keys),
            (defined $parent
                ? ($parent->is_root
                    ? "\n${indent}:parent %BIFS(...)"
                    : "\n${indent}:parent ".$parent->pprint($indent . '    '))
                : '');
    }
}

# ------------------------------------------------------------------------------
# Exceptions
# ------------------------------------------------------------------------------

class MXCL::Term::Exception :isa(MXCL::Term) {
    field $msg :param :reader;
    field @chained;

    sub CREATE ($class, $msg) { $class->new( msg => $msg ) }

    sub throw ($class, $msg) {
        die $class->new( msg => blessed $msg ? $msg : MXCL::Term::Str->CREATE( $msg ) )
    }

    method chain (@exceptions) { push @chained => @exceptions }

    method equals ($other) { $other isa __CLASS__ && $msg->equals( $other->msg ) }
    method stringify {
        return sprintf '(exception %s :chained(%s))' =>
            $msg->stringify, join ', ' => map $_->stringify, @chained
            if @chained;
        return sprintf '(exception %s)' => $msg->stringify;
    }
    method pprint {
        return sprintf '(exception %s :chained(%s))' =>
            $msg->pprint, join ', ' => map $_->pprint, @chained
            if @chained;
        return sprintf '(exception %s)' => $msg->pprint;
    }
}

# ------------------------------------------------------------------------------
# Functions (Callable)
# ------------------------------------------------------------------------------

class MXCL::Term::Callable    :isa(MXCL::Term) {}
class MXCL::Term::Applicative :isa(MXCL::Term::Callable) {}
class MXCL::Term::Operative   :isa(MXCL::Term::Callable) {}

class MXCL::Term::Applicative::Native :isa(MXCL::Term::Applicative) {
    field $name   :param :reader;
    field $params :param :reader;
    field $body   :param :reader;

    sub CREATE ($class, $name, $params, $body) {
        Sub::Util::set_subname( $name->ident, $body );
        $class->new( name => $name, params => $params, body => $body )
    }

    method equals ($other) {
        $other isa __CLASS__
            && $name->equals( $other->name )
                && $params->equals( $other->params )
                    && refaddr $body == refaddr $other->body;
    }

    method stringify {
        sprintf '(native[%s]applicative)' => $name->stringify
    }
    method pprint {
        sprintf '(native[%s]applicative)' => $name->pprint
    }
}

class MXCL::Term::Operative::Native :isa(MXCL::Term::Operative) {
    field $name   :param :reader;
    field $params :param :reader;
    field $body   :param :reader;

    sub CREATE ($class, $name, $params, $body) {
        Sub::Util::set_subname( $name->ident, $body );
        $class->new( name => $name, params => $params, body => $body )
    }

    method equals ($other) {
        $other isa __CLASS__
            && $name->equals( $other->name )
                && $params->equals( $other->params )
                    && refaddr $body == refaddr $other->body;
    }

    method stringify {
        sprintf '(native[%s]operative)' => $name->stringify;
    }
    method pprint {
        sprintf '(native[%s]operative)' => $name->pprint;
    }
}

class MXCL::Term::Lambda :isa(MXCL::Term::Applicative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    sub CREATE ($class, $params, $body, $env) {
        $class->new( params => $params, body => $body, env => $env )
    }

    method equals ($other) {
        $other isa __CLASS__
            && $params->equals( $other->params )
                && $body->equals( $other->body );
    }

    method stringify {
        sprintf '(lambda %s %s)' => $params->stringify, $body->stringify;
    }
    method pprint {
        sprintf '(lambda %s %s)' => $params->pprint, $body->pprint;
    }
}

class MXCL::Term::FExpr :isa(MXCL::Term::Operative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;

    sub CREATE ($class, $params, $body, $env) {
        $class->new( params => $params, body => $body, env => $env )
    }

    method equals ($other) {
        $other isa __CLASS__
            && $params->equals( $other->params )
                && $body->equals( $other->body );
    }

    method stringify {
        sprintf '(fexpr %s %s)' => $params->stringify, $body->stringify;
    }
    method pprint {
        sprintf '(fexpr %s %s)' => $params->pprint, $body->pprint;
    }
}

class MXCL::Term::Opaque :isa(MXCL::Term::Operative) {
    field $env :param :reader;

    method resolve ($method) { $env->lookup($method) }

    method equals ($other) {
        $other isa __CLASS__
            && $env->equals( $other->env );
    }

    method stringify {
        sprintf '(opaque %s)' => ($env // MXCL::Term::Nil->new)->stringify;
    }
    method pprint {
        sprintf '(opaque %s)' => ($env // MXCL::Term::Nil->new)->pprint;
    }
}

# ------------------------------------------------------------------------------
# Literals
# ------------------------------------------------------------------------------

class MXCL::Term::Literal :isa(MXCL::Term::Opaque) {}

class MXCL::Term::Num :isa(MXCL::Term::Literal) {
    field $value :param :reader;

    sub CREATE ($class, $value) {
        $class->new(
            value => $value,
            env   => MXCL::Term::Environment->new(
                entries => +{
                    map { $_->name->ident, $_ } MXCL::Builtins::get_Num_ops()
                }
            )
        )
    }

    method equals ($other) { $other isa __CLASS__ && $other->value == $self->value }
    method stringify { ''.$self->value }
    method pprint    { ''.$self->value }
    method numify    { $self->value }
    method boolify   { $self->value != 0 }
}

class MXCL::Term::Str :isa(MXCL::Term::Literal) {
    field $value :param :reader;

    sub CREATE ($class, $value) {
        $class->new(
            value => $value,
            env   => MXCL::Term::Environment->new(
                entries => +{
                    map { $_->name->ident, $_ } MXCL::Builtins::get_Str_ops()
                }
            )
        )
    }

    method equals ($other) { $other isa __CLASS__ && $other->value eq $self->value }
    method stringify { $self->value }
    method pprint    { $self->value }
    method numify    { 0+$self->value }
    method boolify   { $self->value ne '' }
}

class MXCL::Term::Bool :isa(MXCL::Term::Literal) {
    field $value :param :reader;

    sub CREATE ($class, $value) {
        $class->new(
            value => $value,
            env   => MXCL::Term::Environment->new(
                entries => +{
                    map { $_->name->ident, $_ } MXCL::Builtins::get_Bool_ops()
                }
            )
        )
    }

    method equals ($other) { $other isa __CLASS__ && $other->value == $self->value }
    method stringify { $self->value ? 'true' : 'false' }
    method pprint    { $self->value ? 'true' : 'false' }
    method numify    { $self->value ? 1 : 0 }
    method boolify   { $self->value }
}

# ------------------------------------------------------------------------------
