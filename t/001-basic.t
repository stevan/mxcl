#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use MXCL::Strand;

my $source = q[

    (def thirty 30)

    (defun adder (x y) (+ x y))

    (list/new
        30
        thirty
        (+ 10 20)
        (+ 10 (* 4 5))
        (+ (* 2 5) 20)
        (+ (* 2 5) (* 4 (+ 3 2)))
        ((lambda (x y) (+ x y)) 10 20)
        (adder 10 20)
        (first (list/new 30 20 10))
        (first (rest (list/new 40 30 20 10)))
        (try (+ 10 20) (catch (e) e))
        (+ 10 (or false 20))
        (+ 10 (and true 20))
        (if true 30 false)
        (if (+ 0 0) false (+ 10 20))
        (if "test" (+ 10 20) false)
        (if "" false (+ 10 20))
        (if () false (+ 10 20))
        (let (x 10) (+ x 20))
    )

];

my $kont = MXCL::Strand->new->load($source)->run;
isa_ok($kont, 'MXCL::Term::Kontinue::Host');

isa_ok($kont->effect, 'MXCL::Effect::Halt', '... expected normal exit');

my ($list) = $kont->spill_stack();

is_deeply(
    [ map $_->value, $list->uncons ],
    [ (30) x $list->length ],
    '... expected everything to be 30'
);

done_testing;
