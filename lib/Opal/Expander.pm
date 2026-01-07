
use v5.42;
use experimental qw[ class ];

use importer 'Carp'         => qw[ confess ];
use importer 'Scalar::Util' => qw[ looks_like_number ];

use Opal::Term;

class Opal::Expander {
    field $exprs :param :reader;

    method expand {
        map $self->expand_expression($_), @$exprs
    }

    method expand_expression ($expr) {
        if ($expr isa Opal::Term::Compound) {
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
        return Opal::Term::Tag->new( ident => $src ) if $src =~ /^\:/;
        return Opal::Term::Sym->new( ident => $src );
    }

    method expand_compound ($compound) {
        my @items = $compound->items->@*;
        return Opal::Term::Nil->new if scalar @items == 0;

        my @list;
        while (@items) {
            my $item     = shift @items;
            my $expanded = $self->expand_expression( $item );
            push @list => $expanded;
        }

        if ($list[0] isa Opal::Term::Sym && $list[0]->ident eq 'hash') {
            pop @list;
            return Opal::Term::Hash->new(entries => +{
                map { $_ isa Opal::Term::Key ? $_->ident : $_ } @list
            });
        }

        return Opal::Term::List->new( items => \@list );
    }
}
