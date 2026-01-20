#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q/

(defvar $point (object
    (defvar x 0)
    (defvar y 0)

    (defun set-x! (_x) (set! x _x))
    (defun set-y! (_y) (set! y _y))
))

(say ($point :x))

($point :set-x! 10)

(say ($point :x))

/;

my $kont = MXCL::Strand->new->load($source)->run;

if ($kont->effect isa 'MXCL::Effect::Halt') {
    my ($result) = $kont->stack->splice(0);
    say "RESULT:";
    say sprintf '%s : <%s>' => $_->stringify, blessed $_
        foreach $result isa MXCL::Term::List
            ? $result->uncons
            : $result;
} else {
    say 'ERROR: ', $kont;
}

