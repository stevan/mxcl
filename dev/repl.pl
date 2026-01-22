#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q|


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

__END__

