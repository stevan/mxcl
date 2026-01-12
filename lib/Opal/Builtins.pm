
package Opal::Builtins;
use v5.42;

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Machine;

our $BIFS;

sub get_core_set {
    # --------------------------------------------------------------------------
    # builder
    # --------------------------------------------------------------------------
    # TODO:
    #   - str/length
    #   - tuple/size tuple/at
    #   - array/get array/set! array/length
    #       - array/push array/pop array/shift array/unshift
    #   - hash/get hash/set!
    #       - hash/exists hash/keys hash/values
    # --------------------------------------------------------------------------
    $BIFS //= +[
        # ----------------------------------------------------------------------
        # Type Predicates
        # ----------------------------------------------------------------------

        lift_applicative('isa?', [qw[ value type ]], sub ($env, $value, $type) {
            return Opal::Term::Str->CREATE( $value->type eq $type )
        }),

        lift_type_predicate('atom?', 'Opal::Term::Atom'),
        lift_type_predicate('literal?', 'Opal::Term::Literal'),
        lift_type_predicate('bool?', 'Opal::Term::Bool'),
        lift_type_predicate('num?',  'Opal::Term::Num'),
        lift_type_predicate('str?',  'Opal::Term::Str'),
        lift_type_predicate('word?', 'Opal::Term::Word'),
        lift_type_predicate('sym?', 'Opal::Term::Sym'),
        lift_type_predicate('tag?', 'Opal::Term::Tag'),

        lift_type_predicate('pair?',  'Opal::Term::Pair'),
        lift_type_predicate('list?',  'Opal::Term::List'),
        lift_type_predicate('nil?',   'Opal::Term::Nil'),
        lift_type_predicate('tuple?', 'Opal::Term::Tuple'),
        lift_type_predicate('array?', 'Opal::Term::Array'),
        lift_type_predicate('hash?',  'Opal::Term::Hash'),

        lift_type_predicate('environment?', 'Opal::Term::Environment'),
        lift_type_predicate('exception?', 'Opal::Term::Exception'),
        lift_type_predicate('unit?', 'Opal::Term::Unit'),

        lift_type_predicate('callable?', 'Opal::Term::Callable'),
        lift_type_predicate('applicative?', 'Opal::Term::Applicative'),
        lift_type_predicate('applicative-native?', 'Opal::Term::Applicative::Native'),
        lift_type_predicate('lambda?', 'Opal::Term::Lambda'),
        lift_type_predicate('operative?', 'Opal::Term::Operative'),
        lift_type_predicate('applicative-native?', 'Opal::Term::Operative::Native'),
        lift_type_predicate('fexpr?',  'Opal::Term::FExpr'),


        # ----------------------------------------------------------------------
        # Coercing
        # ----------------------------------------------------------------------

        lift_applicative('numify',    [qw[ value ]], sub ($env, $value) { Opal::Term::Num->CREATE( $value->numify ) }),
        lift_applicative('stringify', [qw[ value ]], sub ($env, $value) { Opal::Term::Str->CREATE( $value->stringify ) }),
        lift_applicative('boolify',   [qw[ value ]], sub ($env, $value) { Opal::Term::Bool->CREATE( $value->boolify ) }),

        # ----------------------------------------------------------------------
        # Artithmetic
        # ----------------------------------------------------------------------

        lift_literal_sub('+', [qw[ n m ]], sub ($n, $m) { $n + $m }, 'numify', 'Opal::Term::Num'),
        lift_literal_sub('-', [qw[ n m ]], sub ($n, $m) { $n - $m }, 'numify', 'Opal::Term::Num'),
        lift_literal_sub('*', [qw[ n m ]], sub ($n, $m) { $n * $m }, 'numify', 'Opal::Term::Num'),
        lift_literal_sub('/', [qw[ n m ]], sub ($n, $m) { $n / $m }, 'numify', 'Opal::Term::Num'),
        lift_literal_sub('%', [qw[ n m ]], sub ($n, $m) { $n % $m }, 'numify', 'Opal::Term::Num'),

        # ----------------------------------------------------------------------
        # String Operations
        # ----------------------------------------------------------------------

        lift_literal_sub('~', [qw[ n m ]], sub ($n, $m) { $n . $m }, 'stringify', 'Opal::Term::Str'),

        # ----------------------------------------------------------------------
        # Comparisons
        # ----------------------------------------------------------------------

        lift_literal_sub('==', [qw[ n m ]], sub ($n, $m) { $n == $m }, 'numify', 'Opal::Term::Bool'),
        lift_literal_sub('!=', [qw[ n m ]], sub ($n, $m) { $n != $m }, 'numify', 'Opal::Term::Bool'),
        lift_literal_sub('>',  [qw[ n m ]], sub ($n, $m) { $n >  $m }, 'numify', 'Opal::Term::Bool'),
        lift_literal_sub('>=', [qw[ n m ]], sub ($n, $m) { $n >= $m }, 'numify', 'Opal::Term::Bool'),
        lift_literal_sub('<',  [qw[ n m ]], sub ($n, $m) { $n <  $m }, 'numify', 'Opal::Term::Bool'),
        lift_literal_sub('<=', [qw[ n m ]], sub ($n, $m) { $n <= $m }, 'numify', 'Opal::Term::Bool'),


        lift_literal_sub('eq', [qw[ n m ]], sub ($n, $m) { $n eq $m }, 'stringify', 'Opal::Term::Bool'),
        lift_literal_sub('ne', [qw[ n m ]], sub ($n, $m) { $n ne $m }, 'stringify', 'Opal::Term::Bool'),
        lift_literal_sub('gt', [qw[ n m ]], sub ($n, $m) { $n gt $m }, 'stringify', 'Opal::Term::Bool'),
        lift_literal_sub('ge', [qw[ n m ]], sub ($n, $m) { $n ge $m }, 'stringify', 'Opal::Term::Bool'),
        lift_literal_sub('lt', [qw[ n m ]], sub ($n, $m) { $n lt $m }, 'stringify', 'Opal::Term::Bool'),
        lift_literal_sub('le', [qw[ n m ]], sub ($n, $m) { $n le $m }, 'stringify', 'Opal::Term::Bool'),

        lift_literal_sub('<=>', [qw[ n m ]], sub ($n, $m) { $n <=> $m }, 'numify', 'Opal::Term::Num'),
        lift_literal_sub('cmp', [qw[ n m ]], sub ($n, $m) { $n cmp $m }, 'stringify', 'Opal::Term::Num'),

        # ----------------------------------------------------------------------
        # Logical
        # ----------------------------------------------------------------------

        lift_applicative('not', [qw[ value ]], sub ($env, $value) {
            return Opal::Term::Bool->CREATE( not( $value->boolify ) )
        }),
        lift_operative('and', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
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
        }),
        lift_operative('or', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
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
        }),

        # ----------------------------------------------------------------------
        # Datatype construction
        # ----------------------------------------------------------------------

        # lambdas are different, they are operatives so that
        # we do not evaluate the params and body
        lift_operative('lambda', [qw[ params body ]], sub ($env, $params, $body) {
            return [
                Opal::Term::Kontinue::Return->new(
                    env   => $env,
                    value => Opal::Term::Lambda->CREATE( $params, $body, $env )
                )
            ]
        }),

        # ... constructors
        lift_datatype_constructor('pair/new',  [qw[ fst snd     ]], 'Opal::Term::Pair'),
        lift_datatype_constructor('list/new',  [qw[ ...items    ]], 'Opal::Term::List'),
        lift_datatype_constructor('array/new', [qw[ ...items    ]], 'Opal::Term::Array'),
        lift_datatype_constructor('tuple/new', [qw[ ...elements ]], 'Opal::Term::Tuple'),
        lift_datatype_constructor('hash/new',  [qw[ ...entries  ]], 'Opal::Term::Hash'),

        # ----------------------------------------------------------------------
        # Datatype Operations
        # ----------------------------------------------------------------------

        # pairs
        lift_applicative('fst',  [qw[ pair ]], sub ($env, $pair) { $pair->fst }),
        lift_applicative('snd',  [qw[ pair ]], sub ($env, $pair) { $pair->snd }),

        lift_applicative('first', [qw[ list ]], sub ($env, $list) { $list->first }),
        lift_applicative('rest',  [qw[ list ]], sub ($env, $list) { $list->rest }),

        # ----------------------------------------------------------------------
        # Keywords
        # ----------------------------------------------------------------------
        lift_applicative('quote', [qw[ quoted ]], sub ($env, $quoted) { $quoted }),
        lift_operative('do', [qw[ ...block ]], sub ($env, @exprs) {
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
        lift_operative('def', [qw[ name value ]], sub ($env, $name, $value) {
            return [
                Opal::Term::Kontinue::Define->new( name => $name, env => $env ),
                Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
            ]
        }),
        lift_operative('defun', [qw[ name params body ]], sub ($env, $name, $params, $body) {
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
        lift_operative('set!', [qw[ name value ]], sub ($env, $name, $value) {
            return [
                Opal::Term::Kontinue::Mutate->new( name => $name, env => $env ),
                Opal::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
            ]
        }),
        # ----------------------------------------------------------------------
        # Scope
        # ----------------------------------------------------------------------
        lift_operative('let', [qw[ binding body ]], sub ($env, $binding, $body) {
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
        lift_operative('and', [qw[ cond if-true if-false ]],
        sub ($env, $cond, $if_true, $if_false) {
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
        }),
        # ----------------------------------------------------------------------
        # exceptions
        # ----------------------------------------------------------------------
        lift_operative('throw', [qw[ msg ]], sub ($env, $msg) {
            return [
                Opal::Term::Kontinue::Throw->new(
                    env       => $env,
                    exception => Opal::Term::Runtime::Exception->new( msg => $msg ),
                )
            ]
        }),
        lift_operative('try', [qw[ body catch-handler ]], sub ($env, $expr, $handler) {
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
        }),

    ];
}

# utils ...

sub lift_literal_sub ($name, $params, $f, $accepts, $returns) {
    my $arity = scalar @$params;
    return Opal::Term::Applicative::Native->CREATE(
        Opal::Term::Key->CREATE( $name ),
        Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
        sub ($env, @args) {
            Opal::Term::Runtime::Exception->throw(
                "Arity Mismatch, expected ${arity} got ".(scalar @args)." in ${name}"
            ) if scalar @args != $arity;
            $returns->CREATE( $f->( map $_->$accepts, @args ) )
        }
    )
}

sub lift_datatype_constructor ($name, $params, $datatype) {
    return Opal::Term::Applicative::Native->CREATE(
        Opal::Term::Sym->CREATE( $name ),
        Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
        sub ($env, @args) { $datatype->CREATE( @args ) }
    )
}

sub lift_type_predicate ($name, $type) {
    return Opal::Term::Applicative::Native->CREATE(
        Opal::Term::Sym->CREATE( $name ),
        Opal::Term::List->CREATE( Opal::Term::Key->CREATE( $type ) ),
        sub ($env, $arg) {
            Opal::Term::Bool->CREATE( blessed $arg && $arg->isa($type) )
        }
    )
}

sub lift_operative ($name, $params, $fexpr) {
    return Opal::Term::Operative::Native->CREATE(
        Opal::Term::Sym->CREATE( $name ),
        Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
        $fexpr
    )
}

sub lift_applicative ($name, $params, $native) {
    return Opal::Term::Applicative::Native->CREATE(
        Opal::Term::Sym->CREATE( $name ),
        Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
        $native
    )
}




