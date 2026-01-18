#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q[
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

my $kont = MXCL::Strand->new->load($source)->run;

if ($kont->effect isa 'MXCL::Effect::Halt') {
    my ($result) = $kont->stack->splice(0);
    say "RESULT:";
    say join "\n" => sprintf '%s : <%s>' => $_->stringify, blessed $_
        foreach $result isa MXCL::Term::List
            ? $result->uncons
            : $result;
} else {
    say 'ERROR: ', $kont;
}

