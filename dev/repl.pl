#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q|


(say ("NOW: " ~ (time)))

(fork
    (do
        (sleep 1000)
        (say ("CHILD AFTER 1000: " ~ (time)))
    )
)

(sleep 300)
(say ("AFTER 300: " ~ (time)))


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
    say 'ERROR: ', $kont->pprint;
}

__END__


(say ("NOW: " ~ (time)))
(fork
    (do
        (sleep 1000)
        (say ("CHILD AFTER 1000: " ~ (time)))
    )
)
(sleep 300)
(say ("AFTER 300: " ~ (time)))

;; output:
;; NOW: 963814.324482
;; AFTER 300: 963814.632044
;; CHILD AFTER 1000: 963815.333371



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
