#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use MXCL::Strand;

# NOTE - these should all be converted in proper tests,
# only the $source one runs for now, but the others
# are known to work.

my $early_oo = q{


(defclass Point ($x $y)
    (defvar x $x)
    (defvar y $y)

    (defun x! ($self $x) (set! x $x))
    (defun y! ($self $y) (set! y $y))
)

(let ($p (Point 10 20))
    (do
        (say ($p x))
        ($p x! 100)
        (say ($p x))
    )
)

(defvar $foo (object
    (defvar x 0)
    (defun add ($self m) (set! x (x + m)))))

($foo add 20)
(say ($foo x))
($foo add 220)
(say ($foo x))

};

my $defer = q[
    (defer (lambda () (say "9. hoop!")))
    {
        (defer (lambda () (say "5. ho")))
        {
            (defer (lambda () (say "2. ho")))
            (say "1. hey")
            (defer (lambda () (say "3. ho")))
        }
        (defer (lambda () (say "6. ho")))
        (say "4. hey")
        (defer (lambda () (say "7. ho")))
    }
    (defer (lambda () (say "10. END!")))
    (say "8. hi")
];

my $defer_w_expections = q[
    (try
        (do
            (defer (lambda () (say "1. hello")))
            {
                (defer (lambda () (say "2. hello")))
                (throw "ho!")
            }
        )
        (catch (e)
            (say e)
        )
    )
];

my $defer_w_expections_inside_defer = q[
    (try
        (do
            (defer (lambda () (say "2. hey")))
            (defer (lambda () (throw "4. goodbye!!!")))
            {
                (defer (lambda () (say "1. hello")))
                (defer (lambda () (throw "3. goodbye")))
                (throw "5. ho!")
            }
        )
        (catch (e)
            (do
                (say (~ "ERROR: " e))
                e)

        )
    )
];

my $source = q[

    (defvar thirty 30)

    (defun adder (x y) (+ x y))

    (defvar my-hash %{ :foo 10 :bar 20 :gorch (lambda (x y) (+ x y)) })

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
        ((hash/get my-hash :gorch) (hash/get my-hash :foo) (hash/get my-hash :bar))
    )

];

my $kont = MXCL::Strand->new->load($source)->run;
isa_ok($kont, 'MXCL::Term::Kontinue::Host');

isa_ok($kont->effect, 'MXCL::Effect::Halt', '... expected normal exit');

my ($list) = $kont->stack->splice(0);

is_deeply(
    [ map $_->value, $list->uncons ],
    [ (30) x $list->length ],
    '... expected everything to be 30'
);

done_testing;
