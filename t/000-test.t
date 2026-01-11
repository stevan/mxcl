#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Term;


class Capability :isa(Opal::Term::Hash) {

    method add_operations (@ops) {
        $self->set( $_->name, $_ ) foreach @ops;
        $self;
    }

    method lift_literal_binop ($name, $params, $f, $returns) {
        # TODO - check that params is just two
        Opal::Term::Applicative::Native->new(
            name   => Opal::Term::Key->new( ident => $name ),
            params => Opal::Term::Tuple->new(
                elements => [ map Opal::Term::Key->new( ident => $_ ), $params->@[ 0, 1 ] ]
            ),
            body   => sub ($env, $n, $m) {
                $returns->new( value => $f->( $n->value, $m->value ) )
            }
        )
    }

    method lift_literal_unop ($name, $params, $f, $returns) {
        # TODO - check that params is just one
        Opal::Term::Applicative::Native->new(
            name   => Opal::Term::Key->new( ident => $name ),
            params => Opal::Term::Tuple->new(
                elements => [ Opal::Term::Key->new( ident => $params->[0] ) ]
            ),
            body   => sub ($env, $n) {
                $returns->new( value => $f->( $n->value ) )
            }
        )
    }
}

my $cap = Capability->new;

$cap->add_operations(
    $cap->lift_literal_binop('==', [qw[ n m ]], sub ($n, $m) { $n + $m }, 'Opal::Term::Bool'),
    $cap->lift_literal_binop('+', [qw[ n m ]], sub ($n, $m) { $n + $m }, 'Opal::Term::Num'),
);

say $cap->stringify;
