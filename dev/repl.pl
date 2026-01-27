#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q|


(let (x 10)
    (while (x > 0) (do
        (say ("x: " ~ x))
        (set! x (- x 1))
    ))
    (say ("x! " ~ x))
)



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

(defun fmt-pid ($pid) ("PID: " ~ $pid))

(say ("one ... " ~ (fmt-pid $PID)))
(fork (do
    (say (">> one ... " ~ (fmt-pid $PID)))
    (say (">> two ... " ~ (fmt-pid $PID)))
    (say (">> three ! " ~ (fmt-pid $PID)))
))
(say ("two ... " ~ (fmt-pid $PID)))
(say ("three ! " ~ (fmt-pid $PID)))

# when run does this ...

one ... PID: 1
>> one ... PID: 2
two ... PID: 1
>> two ... PID: 2
three ! PID: 1
>> three ! PID: 2
