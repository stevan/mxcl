
use v5.42;
use experimental qw[ class ];

use importer 'Scalar::Util' => qw[ looks_like_number ];

use MXCL::Term;
use MXCL::Term::Parser;

class MXCL::Expander {
    field $exprs :param :reader;

    method expand {
        return +[ map $self->expand_expression($_), @$exprs ]
    }

    method expand_expression ($expr) {
        if ($expr isa MXCL::Term::Parser::Compound) {
            return $self->expand_compound( $expr );
        } else {
            return $self->expand_token( $expr );
        }
    }

    method expand_token ($token) {
        my $src = $token->source;
        return MXCL::Term::Bool->new( value => true  ) if $src eq 'true';
        return MXCL::Term::Bool->new( value => false ) if $src eq 'false';
        return MXCL::Term::Str->new(
            value => substr($src, 1, length($src) - 2)
        ) if $src =~ /^\".*\"$/;
        return MXCL::Term::Num->new(
            value => 0+$src
        ) if looks_like_number($src);
        return MXCL::Term::Key->new( ident => substr($src, 1) ) if $src =~ /^\:/;
        return MXCL::Term::Sym->new( ident => $src );
    }

    method expand_compound ($compound) {
        my @elements = $compound->elements->@*;
        # expand empty lists
        return MXCL::Term::Nil->new if scalar @elements == 0;

        # expand pairs at compile time,
        # as they are constructive
        if (scalar @elements == 3 && $elements[1] isa MXCL::Term::Parser::Token && $elements[1]->source eq '.') {
            my ($fst, $dot, $snd) = @elements;
            return MXCL::Term::Pair->new(
                fst => $self->expand_expression($fst),
                snd => $self->expand_expression($snd),
            );
        }

        # ...
        my @list = map $self->expand_expression( $_ ), @elements;

        # expand quoted lists ...
        unshift @list => MXCL::Term::Sym->new( ident => 'quote' )
            if $compound->open->source eq "'";

        # expand blocks ...
        unshift @list => MXCL::Term::Sym->new( ident => 'do' )
            if $compound->open->source eq "{";

        # expand hashes ...
        unshift @list => MXCL::Term::Sym->new( ident => 'hash/new' )
            if $compound->open->source eq "%{";

        # expand tuples ...
        unshift @list => MXCL::Term::Sym->new( ident => 'tuple/new' )
            if $compound->open->source eq "[";

        # expand arrays ...
        unshift @list => MXCL::Term::Sym->new( ident => 'array/new' )
            if $compound->open->source eq "@[";

        # otherwise it is a list ...
        return MXCL::Term::List->new( items => \@list );
    }
}
