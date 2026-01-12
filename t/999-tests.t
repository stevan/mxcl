#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use MXCL::Strand;

my $source = q[

    (def *count* 1)
    (def *fails* 0)

    (defun diag (msg) (say "# " msg))

    (defun todo (msg)
        (diag (~ "TODO:" msg)))

    (defun pass (msg)
        (do
            (say "ok " (stringify *count*) " - " msg)
            (set! *count* (+ *count* 1))))

    (defun fail (msg)
        (do
            (say "not ok " *count* " - " msg)
            (set! *count* (+ *count* 1))
            (set! *fails* (+ *fails* 1))))

    (defun ok (test msg)
        (if (boolify test) (pass msg) (fail msg)))

    (defun is (got expected msg)
        (let (result (eq? got expected))
            (do (ok result msg)
                (or result
                    (do
                        (diag (~ "Failed test " msg))
                        (diag (~ "       got: " got))
                        (diag (~ "  expected: " expected)))))))

    (defun done ()
        (do (say (~ "1.." *count*))
            (and (> *fails* 0)
                (diag (~ (~ "looks like you failed " *fails*)
                         (~ " test(s) of " *count*))))))

    (diag "Equality tests")

    (ok true "... true is")

    (ok  (== true  true ) "... true is true")
    (ok  (== false false) "... false is false")
    (ok  (!= true  false) "... true is not false")
    (ok  (!= false true ) "... false is not true")

    (ok  (== 1 1     )  "... one is one")
    (ok  (!= 1 2     )  "... one is not two")
    (ok  (== 1 1.0   )  "... one is one.0")
    (ok  (== 1.0 1   )  "... one.0 is one")
    (ok  (== 1.5 1.5 )  "... one.5 is one.5")
    (ok  (!= 1.5 2.5 )  "... one.5 is not two.5")
    (ok  (== 1 true  )  "... one is true")
    (ok  (== 0 false )  "... zero is false")
    (ok  (!= 2 true  )  "... two is not true")

    (ok  (eq "hello" "hello")     "... string is string")
    (ok  (ne "hello" "goodbye")   "... string is not other string")

    (diag "Comparison tests")

    (ok (<  1    2 ) "... one is less than two")
    (ok (<= 1    2 ) "... one is less than or equal two")
    (ok (<= 1    1 ) "... one is less than or equal one")
    (ok (>  10   2 ) "... ten is greater than two")
    (ok (>= 10   2 ) "... ten is greater than or equal two")
    (ok (>= 10   10) "... ten is greater than or equal ten")

    (ok (lt "a" "b") "... a is less than b")
    (ok (le "a" "b") "... a is less than or equal b")
    (ok (le "a" "a") "... a is less than or equal a")
    (ok (gt "b" "a") "... b is greater than a")
    (ok (ge "b" "a") "... b is greater than  or equal a")
    (ok (ge "b" "b") "... b is greater than  or equal b")

    (diag "Basic Math tests")

    (is (+ 1 1) 2 "... 1 + 1 == 2")
    (is (* 2 2) 4 "... 2 * 2 == 4")
    (is (- 4 2) 2 "... 4 - 2 == 2")
    (is (/ 4 2) 2 "... 4 / 2 == 2")
    (is (% 4 2) 0 "... 4 % 2 == 0")

    (is (+ 1.5 1.5) 3   "... 1.5 + 1.5 == 3")
    (is (+ 1.5 1.7) 3.2 "... 1.5 + 1.7 == 3.2")
    (is (* 2.5   2) 5   "... 2.5 * 2 == 5")
    (is (* 2.5 0.2) 0.5 "... 2.5 * 0.2 == 0.5")
    (is (- 4.5   2) 2.5 "... 4.5 - 2 == 2.5")
    (is (/ 4   0.5) 8   "... 4 / 0.5 == 8")

    (is (* 2 (- 20 5))                 30 "... * 2 (20 - 5) == 30")
    (is (* 2 (- (* 10 2) 5))           30 "... * 2 ((10 * 2) - 5) == 30")
    (is (* (- 3.2 1.2) (- (* 10 2) 5)) 30 "... (3.2 - 1.2) * ((10 * 2) - 5) == 30")

    (done)

];

my $kont = MXCL::Strand->new->load($source)->run;
#isa_ok($kont, 'MXCL::Term::Kontinue::Host');
#isa_ok($kont->effect, 'MXCL::Effect::Halt', '... expected normal exit');
my ($result) = $kont->spill_stack();
say sprintf '%s : <%s>' => $_->stringify, blessed $_ foreach $result isa MXCL::Term::List ? $result->uncons : $result;
#done_testing;
