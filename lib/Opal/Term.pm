
use v5.42;
use experimental qw[ class ];

# ------------------------------------------------------------------------------

class Opal::Term {

}

# ------------------------------------------------------------------------------

class Opal::Term::Unit :isa(Opal::Term) {}
class Opal::Term::Atom :isa(Opal::Term) {}

# ------------------------------------------------------------------------------
# Literals
# ------------------------------------------------------------------------------

class Opal::Term::Literal :isa(Opal::Term::Atom) {
    field $value :param :reader;
}

class Opal::Term::Num  :isa(Opal::Term::Literal) {}
class Opal::Term::Str  :isa(Opal::Term::Literal) {}
class Opal::Term::Bool :isa(Opal::Term::Literal) {}

# ------------------------------------------------------------------------------
# Words
# ------------------------------------------------------------------------------

class Opal::Term::Word :isa(Opal::Term::Atom) {
    field $ident :param :reader;
}

class Opal::Term::Sym :isa(Opal::Term::Word) {}
class Opal::Term::Key :isa(Opal::Term::Word) {}

# ------------------------------------------------------------------------------
# Pairs
# ------------------------------------------------------------------------------

class Opal::Term::Pair :isa(Opal::Term) {
    field $fst :param :reader;
    field $snd :param :reader;
}

# ------------------------------------------------------------------------------
# Lists
# ------------------------------------------------------------------------------

class Opal::Term::Nil  :isa(Opal::Term::Atom) {}
class Opal::Term::List :isa(Opal::Term) {
    field $items :param :reader = +[];

    method length { Opal::Term::Num->new( value => scalar @$items ) }

    method at ($idx) { $items->[ $idx->value ] // Opal::Term::Nil->new }

    method first { $items->[0] }
    method rest {
        return Opal::Term::Nil->new if scalar @$items == 1;
        return Opal::Term::List->new( items => $items->@[ 1 .. $#{$items} ] );
    }
}

# ------------------------------------------------------------------------------
# Hashes
# ------------------------------------------------------------------------------

class Opal::Term::Hash :isa(Opal::Term) {
    field $entries :param :reader = +{};

    method has    ($key)         { Opal::Term::Bool->new( value => exists $entries->{ $key->ident } ) }
    method get    ($key)         { $entries->{ $key->ident } }
    method set    ($key, $value) { $entries->{ $key->ident } = $value }
    method delete ($key)         { delete $entries->{ $key->ident } }

    method keys   { Opal::Term::List->new( items => [ map { Key->new( ident => $_ ) } keys   %$entries ] ) }
    method values { Opal::Term::List->new( items => [ values %$entries ] ) }
}

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

class Opal::Term::Callable    :isa(Opal::Term) {}
class Opal::Term::Applicative :isa(Opal::Term::Callable) {}
class Opal::Term::Operative   :isa(Opal::Term::Callable) {}

class Opal::Term::Applicative::Native :isa(Opal::Term::Applicative) {
    field $body :param :reader;
}

class Opal::Term::Operative::Native :isa(Opal::Term::Operative) {
    field $body :param :reader;
}

class Opal::Term::Lambda :isa(Opal::Term::Applicative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;
}

class Opal::Term::FExpr :isa(Opal::Term::Operative) {
    field $params :param :reader;
    field $body   :param :reader;
    field $env    :param :reader;
}

# ------------------------------------------------------------------------------
# Reader Objects
# ------------------------------------------------------------------------------

class Opal::Term::Token :isa(Opal::Term) {
    field $source :param :reader;
    field $start  :param :reader;
    field $end    :param :reader;

    method is_synthetic { $start == -1 && $end == -1 }

    method to_string {
        return sprintf 'Token["%s"]' => $source if $self->is_synthetic;
        return sprintf 'Token["%s":%d,%d]' => $source, $start, $end;
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
        return sprintf 'Compound[-](%s)[-]' => (join ';' => map { $_->to_string } @$items)
            if $self->is_synthetic;
        return sprintf 'Compound[%s](%s)[-]' => $open->to_string, (join ';' => map { $_->to_string } @$items)
            if $self->is_unfinished;
        return sprintf 'Compound[%s](%s)[%s]' => $open->to_string, (join ';' => map { $_->to_string } @$items), $close->to_string;
    }
}

# ------------------------------------------------------------------------------
# Runtime Objects
# ------------------------------------------------------------------------------

class Opal::Term::Exception :isa(Opal::Term) {
    field $msg :param :reader;
}

class Opal::Term::Environment :isa(Opal::Term::Hash) {
    field $parent :param :reader = undef;

    method is_root    { Opal::Term::Bool->new( value => not defined $parent ) }
    method has_parent { Opal::Term::Bool->new( value =>     defined $parent ) }

    method derive { __CLASS__->new( parent => $self ) }
}











