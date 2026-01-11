
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Machine;

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

class Opal::Environment {


    my sub lift_literal_sub ($name, $params, $f, $accepts, $returns) {
        my $param_count = scalar @$params;

        my $body = sub ($env, @args) {
            Opal::Term::Runtime::Exception->throw(
                "Arity Mismatch, expected ${param_count} got ".(scalar @args)." in ${name}"
            ) if scalar @args != $param_count;
            $returns->CREATE( $f->( map $_->$accepts, @args ) )
        };

        return Opal::Term::Applicative::Native->CREATE(
            Opal::Term::Key->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            $body,
        )
    }

    my sub lift_datatype_constructor ($name, $params, $datatype) {
        return Opal::Term::Applicative::Native->CREATE(
            Opal::Term::Sym->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            sub ($env, @args) { $datatype->CREATE( @args ) }
        )
    }

    my sub lift_operative ($name, $params, $fexpr) {
        return Opal::Term::Operative::Native->CREATE(
            Opal::Term::Sym->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            $fexpr
        )
    }


    sub initialize ($class) {

        Opal::Term::Environment->CREATE(
            # ----------------------------------------------------------------------
            # Datatype construction
            # ----------------------------------------------------------------------
            'array' => lift_datatype_constructor('array', [qw[ ...items    ]], 'Opal::Term::Array'),
            'tuple' => lift_datatype_constructor('tuple', [qw[ ...elements ]], 'Opal::Term::Tuple'),
            'hash'  => lift_datatype_constructor('hash',  [qw[ ...entries  ]], 'Opal::Term::Hash'),
            # ----------------------------------------------------------------------
            # Lambda construction
            # ----------------------------------------------------------------------
            # NOTE: this is operative to avoid evaluating the params and body
            'lambda' => lift_operative('lambda', [qw[ params body ]], sub ($env, $params, $body) {
                return [
                    Opal::Term::Kontinue::Return->new(
                        env   => $env,
                        value => Opal::Term::Lambda->CREATE( $params, $body, $env )
                    )
                ]
            }),
            # ----------------------------------------------------------------------
            # Quotes & Blocks
            # ----------------------------------------------------------------------
            'quote' => Opal::Term::Applicative::Native->new(
                name => Opal::Term::Sym->CREATE('quote'),
                body => sub ($env, $quoted) { $quoted }
            ),
            'do' => lift_operative('do', [qw[ ...block ]], sub ($env, @exprs) {
                my $local = $env->derive;
                return [
                    reverse map {
                        Opal::Term::Kontinue::Eval::Expr->new(
                            env  => $local,
                            expr => $_
                        )
                    } @exprs
                ]
            }),
            # ----------------------------------------------------------------------
            # Defintions & Scopes
            # ----------------------------------------------------------------------
            'def' => lift_operative('def', [qw[ name value ]], sub ($env, $name, $value) {
                return [
                    Opal::Term::Kontinue::Define->new( name => $name, env => $env ),
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
                ]
            }),
            'defun' => lift_operative('defun', [qw[ name params body ]], sub ($env, $name, $params, $body) {
                return [
                    Opal::Term::Kontinue::Define->new( name => $name, env => $env ),
                    Opal::Term::Kontinue::Return->new(
                        env   => $env,
                        value => Opal::Term::Lambda->new(
                            params => $params,
                            body   => $body,
                            env    => $env
                        )
                    )
                ]
            }),
            'set!' => lift_operative('set!', [qw[ name value ]], sub ($env, $name, $value) {
                return [
                    Opal::Term::Kontinue::Mutate->new( name => $name, env => $env ),
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
                ]
            }),
            'let' => lift_operative('let', [qw[ binding body ]], sub ($env, $binding, $body) {
                my ($name, $value) = $binding->uncons;
                my $local = $env->derive;
                return [
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $body, env => $local ),
                    Opal::Term::Kontinue::Define->new( name => $name, env => $local ),
                    Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $local ),
                ]
            }),
            # ----------------------------------------------------------------------
            # conditonals
            # ----------------------------------------------------------------------
            'and' => Opal::Term::Operative::Native->new(
                name => Opal::Term::Sym->CREATE('and'),
                body => sub ($env, $lhs, $rhs) {
                    return [
                        Opal::Term::Kontinue::IfElse->new(
                            env       => $env,
                            condition => $lhs,
                            if_true   => $rhs,
                            if_false  => $lhs,
                        ),
                        Opal::Term::Kontinue::Eval::Expr->new(
                            env  => $env,
                            expr => $lhs
                        )
                    ]
                }
            ),
            'or' => Opal::Term::Operative::Native->new(
                name => Opal::Term::Sym->CREATE('or'),
                body => sub ($env, $lhs, $rhs) {
                    return [
                        Opal::Term::Kontinue::IfElse->new(
                            env       => $env,
                            condition => $lhs,
                            if_true   => $lhs,
                            if_false  => $rhs,
                        ),
                        Opal::Term::Kontinue::Eval::Expr->new(
                            env  => $env,
                            expr => $lhs
                        )
                    ]
                }
            ),
            'if' => Opal::Term::Operative::Native->new(
                name => Opal::Term::Sym->CREATE('if'),
                body => sub ($env, $cond, $if_true, $if_false) {
                    my $local = $env->derive;
                    return [
                        Opal::Term::Kontinue::IfElse->new(
                            env       => $local,
                            condition => $cond,
                            if_true   => $if_true,
                            if_false  => $if_false,
                        ),
                        Opal::Term::Kontinue::Eval::Expr->new(
                            env  => $local,
                            expr => $cond
                        )
                    ]
                }
            ),
            # ----------------------------------------------------------------------
            # exceptions
            # ----------------------------------------------------------------------
            'throw' => Opal::Term::Operative::Native->new(
                name => Opal::Term::Sym->CREATE('throw'),
                body => sub ($env, $msg) {
                    return [
                        Opal::Term::Kontinue::Throw->new(
                            env       => $env,
                            exception => Opal::Term::Runtime::Exception->new( msg => $msg ),
                        )
                    ]
                }
            ),
            'try' => Opal::Term::Operative::Native->new(
                name => Opal::Term::Sym->CREATE('try'),
                body => sub ($env, $expr, $handler) {
                    my ($params, $body) = $handler->rest->uncons;
                    return [
                        Opal::Term::Kontinue::Catch->new(
                            env     => $env,
                            handler => Opal::Term::Lambda->new(
                                params => $params,
                                body   => $body,
                                env    => $env
                            ),
                        ),
                        Opal::Term::Kontinue::Eval::Expr->new(
                            env  => $env,
                            expr => $expr
                        )
                    ]
                }
            ),
            # ----------------------------------------------------------------------
            # Lists
            # ----------------------------------------------------------------------
            'list' => Opal::Term::Applicative::Native->new(
                name => Opal::Term::Sym->CREATE('list'),
                body => sub ($env, @items) {
                    return Opal::Term::Nil->new if scalar @items == 0;
                    return Opal::Term::List->new( items => \@items );
                }
            ),
            'first' => Opal::Term::Applicative::Native->new(
                name => Opal::Term::Sym->CREATE('first'),
                body => sub ($env, $list) { $list->first }
            ),
            'rest' => Opal::Term::Applicative::Native->new(
                name => Opal::Term::Sym->CREATE('rest'),
                body => sub ($env, $list) { $list->rest }
            ),
            # ----------------------------------------------------------------------
            # Numbers
            # ----------------------------------------------------------------------
            '+' => lift_literal_sub('+', [qw[ n m ]], sub ($n, $m) { $n + $m }, 'numify', 'Opal::Term::Num'),
            '-' => lift_literal_sub('-', [qw[ n m ]], sub ($n, $m) { $n - $m }, 'numify', 'Opal::Term::Num'),
            '*' => lift_literal_sub('*', [qw[ n m ]], sub ($n, $m) { $n * $m }, 'numify', 'Opal::Term::Num'),
            '/' => lift_literal_sub('/', [qw[ n m ]], sub ($n, $m) { $n / $m }, 'numify', 'Opal::Term::Num'),
            '%' => lift_literal_sub('%', [qw[ n m ]], sub ($n, $m) { $n % $m }, 'numify', 'Opal::Term::Num'),

            '==' => lift_literal_sub('==', [qw[ n m ]], sub ($n, $m) { $n == $m }, 'numify', 'Opal::Term::Bool'),
            '!=' => lift_literal_sub('!=', [qw[ n m ]], sub ($n, $m) { $n != $m }, 'numify', 'Opal::Term::Bool'),
            '>'  => lift_literal_sub('>',  [qw[ n m ]], sub ($n, $m) { $n >  $m }, 'numify', 'Opal::Term::Bool'),
            '>=' => lift_literal_sub('>=', [qw[ n m ]], sub ($n, $m) { $n >= $m }, 'numify', 'Opal::Term::Bool'),
            '<'  => lift_literal_sub('<',  [qw[ n m ]], sub ($n, $m) { $n <  $m }, 'numify', 'Opal::Term::Bool'),
            '<=' => lift_literal_sub('<=', [qw[ n m ]], sub ($n, $m) { $n <= $m }, 'numify', 'Opal::Term::Bool'),

            '~' => lift_literal_sub('~', [qw[ n m ]], sub ($n, $m) { $n . $m }, 'stringify', 'Opal::Term::Str'),

            'eq' => lift_literal_sub('eq', [qw[ n m ]], sub ($n, $m) { $n eq $m }, 'stringify', 'Opal::Term::Bool'),
            'ne' => lift_literal_sub('ne', [qw[ n m ]], sub ($n, $m) { $n ne $m }, 'stringify', 'Opal::Term::Bool'),
            'gt' => lift_literal_sub('gt', [qw[ n m ]], sub ($n, $m) { $n gt $m }, 'stringify', 'Opal::Term::Bool'),
            'ge' => lift_literal_sub('ge', [qw[ n m ]], sub ($n, $m) { $n ge $m }, 'stringify', 'Opal::Term::Bool'),
            'lt' => lift_literal_sub('lt', [qw[ n m ]], sub ($n, $m) { $n lt $m }, 'stringify', 'Opal::Term::Bool'),
            'le' => lift_literal_sub('le', [qw[ n m ]], sub ($n, $m) { $n le $m }, 'stringify', 'Opal::Term::Bool'),

        );
    }
}


