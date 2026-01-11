
use v5.42;
use experimental qw[ class switch ];

use Opal::Term;
use Opal::Term::Kontinue;
use Opal::Machine;

class Opal::Environment {

    # --------------------------------------------------------------------------
    # helpers ...
    # --------------------------------------------------------------------------

    my sub lift_literal_sub ($name, $params, $f, $accepts, $returns) {
        my $arity = scalar @$params;
        return Opal::Term::Applicative::Native->CREATE(
            Opal::Term::Key->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            sub ($env, @args) {
                Opal::Term::Runtime::Exception->throw(
                    "Arity Mismatch, expected ${arity} got ".(scalar @args)." in ${name}"
                ) if scalar @args != $arity;
                $returns->CREATE( $f->( map $_->$accepts, @args ) )
            },
        )
    }

    my sub lift_datatype_constructor ($name, $params, $datatype) {
        return Opal::Term::Applicative::Native->CREATE(
            Opal::Term::Sym->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            sub ($env, @args) { $datatype->CREATE( @args ) }
        )
    }

    my sub lift_type_predicate ($name, $type) {
        return Opal::Term::Applicative::Native->CREATE(
            Opal::Term::Sym->CREATE( $name ),
            Opal::Term::List->CREATE( Opal::Term::Key->CREATE( $type ) ),
            sub ($env, $arg) {
                Opal::Term::Bool->CREATE( blessed $arg && $arg->isa($type) )
            }
        )
    }

    my sub lift_operative ($name, $params, $fexpr) {
        return Opal::Term::Operative::Native->CREATE(
            Opal::Term::Sym->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            $fexpr
        )
    }

    my sub lift_applicative ($name, $params, $native) {
        return Opal::Term::Applicative::Native->CREATE(
            Opal::Term::Sym->CREATE( $name ),
            Opal::Term::List->CREATE( map Opal::Term::Key->CREATE( $_ ), @$params ),
            $native
        )
    }

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

    sub initialize ($class) {
        Opal::Term::Environment->CREATE(
            # ----------------------------------------------------------------------
            # Type Predicates
            # ----------------------------------------------------------------------

            'isa?' => lift_applicative('isa?', [qw[ value type ]], sub ($env, $value, $type) {
                return Opal::Term::Str->CREATE( $value->type eq $type )
            }),

            'atom?' => lift_type_predicate('atom?', 'Opal::Term::Atom'),
                'literal?' => lift_type_predicate('literal?', 'Opal::Term::Literal'),
                    'bool?' => lift_type_predicate('bool?', 'Opal::Term::Bool'),
                    'num?'  => lift_type_predicate('num?',  'Opal::Term::Num'),
                    'str?'  => lift_type_predicate('str?',  'Opal::Term::Str'),
                'word?' => lift_type_predicate('word?', 'Opal::Term::Word'),
                    'sym?' => lift_type_predicate('sym?', 'Opal::Term::Sym'),
                    'tag?' => lift_type_predicate('tag?', 'Opal::Term::Tag'),

            'pair?'   => lift_type_predicate('pair?',  'Opal::Term::Pair'),
            'list?'   => lift_type_predicate('list?',  'Opal::Term::List'),
            'nil?'    => lift_type_predicate('nil?',   'Opal::Term::Nil'),
            'tuple?'  => lift_type_predicate('tuple?', 'Opal::Term::Tuple'),
            'array?'  => lift_type_predicate('array?', 'Opal::Term::Array'),
            'hash?'   => lift_type_predicate('hash?',  'Opal::Term::Hash'),

            'environment?' => lift_type_predicate('environment?', 'Opal::Term::Environment'),
            'exception?'   => lift_type_predicate('exception?', 'Opal::Term::Exception'),
            'unit?'        => lift_type_predicate('unit?', 'Opal::Term::Unit'),

            'callable?' => lift_type_predicate('callable?', 'Opal::Term::Callable'),
                'applicative?' => lift_type_predicate('applicative?', 'Opal::Term::Applicative'),
                    'applicative-native?' => lift_type_predicate('applicative-native?', 'Opal::Term::Applicative::Native'),
                    'lambda?' => lift_type_predicate('lambda?', 'Opal::Term::Lambda'),
                'operative?'   => lift_type_predicate('operative?', 'Opal::Term::Operative'),
                    'operative-native?' => lift_type_predicate('applicative-native?', 'Opal::Term::Operative::Native'),
                    'fexpr?'  => lift_type_predicate('fexpr?',  'Opal::Term::FExpr'),


            # ----------------------------------------------------------------------
            # Artithmetic
            # ----------------------------------------------------------------------

            '+' => lift_literal_sub('+', [qw[ n m ]], sub ($n, $m) { $n + $m }, 'numify', 'Opal::Term::Num'),
            '-' => lift_literal_sub('-', [qw[ n m ]], sub ($n, $m) { $n - $m }, 'numify', 'Opal::Term::Num'),
            '*' => lift_literal_sub('*', [qw[ n m ]], sub ($n, $m) { $n * $m }, 'numify', 'Opal::Term::Num'),
            '/' => lift_literal_sub('/', [qw[ n m ]], sub ($n, $m) { $n / $m }, 'numify', 'Opal::Term::Num'),
            '%' => lift_literal_sub('%', [qw[ n m ]], sub ($n, $m) { $n % $m }, 'numify', 'Opal::Term::Num'),

            # ----------------------------------------------------------------------
            # String Operations
            # ----------------------------------------------------------------------

            '~' => lift_literal_sub('~', [qw[ n m ]], sub ($n, $m) { $n . $m }, 'stringify', 'Opal::Term::Str'),

            # ----------------------------------------------------------------------
            # Comparisons
            # ----------------------------------------------------------------------

            '==' => lift_literal_sub('==', [qw[ n m ]], sub ($n, $m) { $n == $m }, 'numify', 'Opal::Term::Bool'),
            '!=' => lift_literal_sub('!=', [qw[ n m ]], sub ($n, $m) { $n != $m }, 'numify', 'Opal::Term::Bool'),
            '>'  => lift_literal_sub('>',  [qw[ n m ]], sub ($n, $m) { $n >  $m }, 'numify', 'Opal::Term::Bool'),
            '>=' => lift_literal_sub('>=', [qw[ n m ]], sub ($n, $m) { $n >= $m }, 'numify', 'Opal::Term::Bool'),
            '<'  => lift_literal_sub('<',  [qw[ n m ]], sub ($n, $m) { $n <  $m }, 'numify', 'Opal::Term::Bool'),
            '<=' => lift_literal_sub('<=', [qw[ n m ]], sub ($n, $m) { $n <= $m }, 'numify', 'Opal::Term::Bool'),


            'eq' => lift_literal_sub('eq', [qw[ n m ]], sub ($n, $m) { $n eq $m }, 'stringify', 'Opal::Term::Bool'),
            'ne' => lift_literal_sub('ne', [qw[ n m ]], sub ($n, $m) { $n ne $m }, 'stringify', 'Opal::Term::Bool'),
            'gt' => lift_literal_sub('gt', [qw[ n m ]], sub ($n, $m) { $n gt $m }, 'stringify', 'Opal::Term::Bool'),
            'ge' => lift_literal_sub('ge', [qw[ n m ]], sub ($n, $m) { $n ge $m }, 'stringify', 'Opal::Term::Bool'),
            'lt' => lift_literal_sub('lt', [qw[ n m ]], sub ($n, $m) { $n lt $m }, 'stringify', 'Opal::Term::Bool'),
            'le' => lift_literal_sub('le', [qw[ n m ]], sub ($n, $m) { $n le $m }, 'stringify', 'Opal::Term::Bool'),

            '<=>' => lift_literal_sub('<=>', [qw[ n m ]], sub ($n, $m) { $n <=> $m }, 'numify', 'Opal::Term::Num'),
            'cmp' => lift_literal_sub('cmp', [qw[ n m ]], sub ($n, $m) { $n cmp $m }, 'stringify', 'Opal::Term::Num'),

            # ----------------------------------------------------------------------
            # Logical
            # ----------------------------------------------------------------------

            'not' =>lift_applicative('not', [qw[ value ]], sub ($env, $value) {
                return Opal::Term::Bool->CREATE( not( $value->boolify ) )
            }),
            'and' => lift_operative('and', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
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
            'or' => lift_operative('or', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
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
            'lambda' => lift_operative('lambda', [qw[ params body ]], sub ($env, $params, $body) {
                return [
                    Opal::Term::Kontinue::Return->new(
                        env   => $env,
                        value => Opal::Term::Lambda->CREATE( $params, $body, $env )
                    )
                ]
            }),

            # ... constructors
            'pair/new'  => lift_datatype_constructor('pair',  [qw[ fst snd     ]], 'Opal::Term::Pair'),
            'list/new'  => lift_datatype_constructor('list',  [qw[ ...items    ]], 'Opal::Term::List'),
            'array/new' => lift_datatype_constructor('array', [qw[ ...items    ]], 'Opal::Term::Array'),
            'tuple/new' => lift_datatype_constructor('tuple', [qw[ ...elements ]], 'Opal::Term::Tuple'),
            'hash/new'  => lift_datatype_constructor('hash',  [qw[ ...entries  ]], 'Opal::Term::Hash'),

            # ----------------------------------------------------------------------
            # Datatype Operations
            # ----------------------------------------------------------------------

            # pairs
            'fst' => lift_applicative('fst',  [qw[ pair ]], sub ($env, $pair) { $pair->fst }),
            'snd' => lift_applicative('snd',  [qw[ pair ]], sub ($env, $pair) { $pair->snd }),

            'first' => lift_applicative('first', [qw[ list ]], sub ($env, $list) { $list->first }),
            'rest'  => lift_applicative('rest',  [qw[ list ]], sub ($env, $list) { $list->rest }),

            # ----------------------------------------------------------------------
            # Keywords
            # ----------------------------------------------------------------------
            'quote' => lift_applicative('quote', [qw[ quoted ]], sub ($env, $quoted) { $quoted }),
            'do'    => lift_operative('do', [qw[ ...block ]], sub ($env, @exprs) {
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
            # ----------------------------------------------------------------------
            # Scope
            # ----------------------------------------------------------------------
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
            'if' => lift_operative('and', [qw[ cond if-true if-false ]],
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
            'throw' => lift_operative('throw', [qw[ msg ]], sub ($env, $msg) {
                return [
                    Opal::Term::Kontinue::Throw->new(
                        env       => $env,
                        exception => Opal::Term::Runtime::Exception->new( msg => $msg ),
                    )
                ]
            }),
            'try' => lift_operative('try', [qw[ body catch-handler ]], sub ($env, $expr, $handler) {
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

        );
    }
}


