#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q|


(defvar Point (object
    (defun new ($class x y)
        (object
            (defun set-x! ($self _x) (set! x _x))
            (defun set-y! ($self _y) (set! y _y))))

    (defun xy ($self)
        [ ($self :x) ($self :y) ])

    (defun clear ($self)
        (do
            ($self :set-x! 0)
            ($self :set-y! 0)))

))

(defvar $point (Point :new 20 30))

(say ($point :xy))
($point :clear)
(say ($point :xy))


|;

my $kont = MXCL::Strand->new->load($source)->run;

if ($kont->effect isa 'MXCL::Effect::Halt') {
    my ($result) = $kont->stack->splice(0);
    say "RESULT:";
    say sprintf '%s : <%s>' => $_->pprint, blessed $_
        foreach $result isa MXCL::Term::List
            ? $result->uncons
            : $result;
} else {
    say 'ERROR: ', $kont;
}

