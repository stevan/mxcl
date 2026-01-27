#!perl

use v5.42;
use experimental qw[ class switch ];

use Data::Dumper qw[ Dumper ];

use MXCL::Strand;

my $source = q|

    (say ("Waiting in " ~ $PID))
    (wait (fork
        (do
            (say ("sleeping in " ~ $PID))
            (sleep 3000)
            (say ("AWAKE! in" ~ $PID))
    )))
    (say ("done waiting" ~ $PID))

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

(say ("Waiting in " ~ $PID))
(wait (fork
    (do
        (say ("sleeping in " ~ $PID))
        (sleep 3000)
        (say ("AWAKE! in" ~ $PID))
)))
(say ("done waiting" ~ $PID))

;; Waiting in ^:001
;; sleeping in ^:001:002
;; AWAKE! in^:001:002
;; done waiting^:001


(let ($pid (fork
        (do
            (say ("sleeping in " ~ $PID))
            (sleep 3000)
            (say ("AWAKE! in" ~ $PID))
    )))

    (say ("Waiting on " ~ $pid))
    (wait $pid)
    (say ("PID finished" ~ $pid))
)

;; sleeping in ^:001:002
;; Waiting on ^:001:002
;; AWAKE! in^:001:002
;; PID finished^:001:002


(defun fork-tree ($n)
    (if ($n > 0)
        (fork
            (do
                (say $PID)
                (fork-tree ($n - 1))
            ))
        ()))

(fork-tree 5)

;; <PID ^:001:002>
;; <PID ^:001:002:003>
;; <PID ^:001:002:003:004>
;; <PID ^:001:002:003:004:005>
;; <PID ^:001:002:003:004:005:006>


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
