#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Parser;
use Opal::Expander;
use Opal::Machine;

my $parser = Opal::Parser->new(
    buffer => q[

    (hash :foo ( 10 . 20 ) :bar "FOOOOO" )

]);

my $env = Opal::Term::Environment->new(entries => {
    '+' => Opal::Term::Applicative::Native->new(
        params => Opal::Term::Nil->new,
        body   => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value + $m->value)) }
    ),
    '-' => Opal::Term::Applicative::Native->new(
        params => Opal::Term::Nil->new,
        body   => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value - $m->value)) }
    ),
    '*' => Opal::Term::Applicative::Native->new(
        params => Opal::Term::Nil->new,
        body   => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value * $m->value)) }
    ),
    '/' => Opal::Term::Applicative::Native->new(
        params => Opal::Term::Nil->new,
        body   => sub ($env, $n, $m) { Opal::Term::Num->new(value => ($n->value / $m->value)) }
    ),
});

my @exprs = $parser->parse;

my $expander = Opal::Expander->new( exprs => \@exprs );

my @terms = $expander->expand;

say join "\n" => map { $_->to_string } @exprs;
say join "\n" => map { $_->to_string } @terms;

my $machine = Opal::Machine->new(
    program => \@terms,
    env     => $env
);

my $result = $machine->run;

say "RESULT is ", $result->to_string;

