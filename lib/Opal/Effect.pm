

my @core = qw[
    bool? true false
        and or not

    num?
        + - * / mod == != < <= > >= <=>
        sin cos abs trunc

    str?
        ~ eq ne gt ge lt le cmp
        substr char-at

    list? list
    pair? pair
    nil?  nil
        cons first second rest

    tuple? tuple
        size at

    array? array
        array-get
        length push pop shift unshift

    hash? hash
        hash-get
        exists keys values

    callable?
    native?
    fexpr?

    lambda? lambda

    quote let do if throw try
];

my @mutable = qw[
    def defun

    set! array-set! hash-set!
];

my @console = qw[
    print say warn readline repl
];

my @file_io = qw[
    open close
    read readline slurp
    write spew

    opendir closedir
    read

    -e -f -d -s
];

my @actor_ipc = qw[
    send recv
    signal timeout
    sleep
];




class Opal::Term::Effect::Exception :isa(Opal::Term::Exception) {}

class Opal::Effect {
    method throws  ($msg)  { ... }
    method handles ($kont) { ... }
    method provides { return +{} }
}

class Opal::Effect::TTY :isa(Opal::Effect) {
    method throws ($msg) { Opal::Term::Effect::Exception->new( msg => $msg ) }

    method handles ($kont) {
        given ($kont->effect) {
            when ('TTY::print') {

            }
            when ('TTY::say') {

            }
            when ('TTY::warn') {

            }
            default {
                die "Not handled by TTY, what is ".$kont->effect;
            }
        }
    }

    method provides {
        return +{
            'print'  => undef,
            'say'    => undef,
            'warn'   => undef,
        }
    }
}

