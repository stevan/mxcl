#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q[

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

my $kont = MXCL::Strand->new->load($source)->run;

if ($kont->effect isa 'MXCL::Effect::Halt') {
    my ($result) = $kont->stack->splice(0);
    say join "\n" => sprintf '%s : <%s>' => $_->stringify, blessed $_
        foreach $result isa MXCL::Term::List
            ? $result->uncons
            : $result;
} else {
    say 'ERROR: ', $kont;
}

