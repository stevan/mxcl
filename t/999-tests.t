#!perl

use v5.42;
use experimental qw[ class switch ];

use Test::More;
use Data::Dumper qw[ Dumper ];
use Carp         qw[ confess ];

use Opal::Strand;

my $source = q[

    (list/new
        [ 10 20 [ 30 40 ] ]
        @[ 10 [ 20 30 ] 200 @[1 2 3] ]
        %{
            :foo 10
            :bar [ 20 30 ]
            :gorch @[ 0 0 0 0 ]
        }
    )

];

my $kont = Opal::Strand->new->load($source)->run;
isa_ok($kont, 'Opal::Term::Kontinue::Host');

is($kont->effect, 'SYS.exit', '... expected normal exit');

my ($result) = $kont->spill_stack();

say sprintf '%s : <%s>' => $_->stringify, blessed $_ foreach $result isa Opal::Term::List ? $result->uncons : $result;

done_testing;
