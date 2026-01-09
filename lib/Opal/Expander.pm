
use v5.42;
use experimental qw[ class ];

use importer 'Scalar::Util' => qw[ looks_like_number ];

use Opal::Term;
use Opal::Term::Parser;

class Opal::Expander {
    field $exprs :param :reader;

    method expand {
        map $self->expand_expression($_), @$exprs
    }

    method expand_expression ($expr) {
        if ($expr isa Opal::Term::Parser::Compound) {
            return $self->expand_compound( $expr );
        } else {
            return $self->expand_token( $expr );
        }
    }

    method expand_token ($token) {
        my $src = $token->source;
        return Opal::Term::Bool->new( value => true  ) if $src eq 'true';
        return Opal::Term::Bool->new( value => false ) if $src eq 'false';
        return Opal::Term::Str->new(
            value => substr($src, 1, length($src) - 2)
        ) if $src =~ /^\".*\"$/;
        return Opal::Term::Num->new(
            value => 0+$src
        ) if looks_like_number($src);
        return Opal::Term::Key->new( ident => substr($src, 1) ) if $src =~ /^\:/;
        return Opal::Term::Sym->new( ident => $src );
    }

    method expand_compound ($compound) {
        my @items = $compound->uncons;
        # expand empty lists
        return Opal::Term::Nil->new if scalar @items == 0;

        # expand pairs at compile time,
        # as they are constructive
        if (scalar @items == 3 && $items[1] isa Opal::Term::Parser::Token && $items[1]->source eq '.') {
            my ($fst, $dot, $snd) = @items;
            return Opal::Term::Pair->new(
                fst => $self->expand_expression($fst),
                snd => $self->expand_expression($snd),
            );
        }

        # ...
        my @list = map $self->expand_expression( $_ ), @items;

        # expand quoted lists ...
        unshift @list => Opal::Term::Sym->new( ident => 'quote' )
            if $compound->open->source eq "'";

        # expand hashes ...
        unshift @list => Opal::Term::Sym->new( ident => 'make-hash' )
            if $compound->open->source eq "%{";

        # otherwise it is a list ...
        return Opal::Term::List->new( items => \@list );
    }
}
