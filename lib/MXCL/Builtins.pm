
package MXCL::Builtins;
use v5.42;

use MXCL::Term;
use MXCL::Term::Kontinue;
use MXCL::Strand;

our $BIFS;

sub get_Bool_ops {
    return (
        lift_literal_sub('==', [qw[ n m ]], sub ($n, $m) { $n == $m }, 'boolify', 'MXCL::Term::Bool'),
        lift_literal_sub('!=', [qw[ n m ]], sub ($n, $m) { $n != $m }, 'boolify', 'MXCL::Term::Bool'),

        # XXX - these are pure bool opreators, but they coerce the input
        # not sure if this is right way, or if short-circuit is better
        # and then the return type is any Term, perhaps this needs to be
        # hoisted up to a Literal class of some kind, or just duplicated
        # across the different Literal types (to avoid complexities from
        # subclassing and other randomness)
        lift_literal_sub('&&', [qw[ n m ]], sub ($n, $m) { $n && $m }, 'boolify', 'MXCL::Term::Bool'),
        lift_literal_sub('||', [qw[ n m ]], sub ($n, $m) { $n || $m }, 'boolify', 'MXCL::Term::Bool'),
        lift_literal_sub('not',[qw[ n ]], sub ($n) { !$n }, 'boolify', 'MXCL::Term::Bool'),
    )
}

sub get_Str_ops {
    return (
        lift_literal_sub('~', [qw[ n m ]], sub ($n, $m) { $n . $m }, 'stringify', 'MXCL::Term::Str'),

        lift_literal_sub('eq', [qw[ n m ]], sub ($n, $m) { $n eq $m }, 'stringify', 'MXCL::Term::Bool'),
        lift_literal_sub('ne', [qw[ n m ]], sub ($n, $m) { $n ne $m }, 'stringify', 'MXCL::Term::Bool'),
        lift_literal_sub('gt', [qw[ n m ]], sub ($n, $m) { $n gt $m }, 'stringify', 'MXCL::Term::Bool'),
        lift_literal_sub('ge', [qw[ n m ]], sub ($n, $m) { $n ge $m }, 'stringify', 'MXCL::Term::Bool'),
        lift_literal_sub('lt', [qw[ n m ]], sub ($n, $m) { $n lt $m }, 'stringify', 'MXCL::Term::Bool'),
        lift_literal_sub('le', [qw[ n m ]], sub ($n, $m) { $n le $m }, 'stringify', 'MXCL::Term::Bool'),

        lift_literal_sub('cmp', [qw[ n m ]], sub ($n, $m) { $n cmp $m }, 'stringify', 'MXCL::Term::Num'),
    )
}

sub get_Num_ops {
    return (
        lift_literal_sub('+', [qw[ n m ]], sub ($n, $m) { $n + $m }, 'numify', 'MXCL::Term::Num'),
        lift_literal_sub('-', [qw[ n m ]], sub ($n, $m) { $n - $m }, 'numify', 'MXCL::Term::Num'),
        lift_literal_sub('*', [qw[ n m ]], sub ($n, $m) { $n * $m }, 'numify', 'MXCL::Term::Num'),
        lift_literal_sub('/', [qw[ n m ]], sub ($n, $m) { $n / $m }, 'numify', 'MXCL::Term::Num'),
        lift_literal_sub('%', [qw[ n m ]], sub ($n, $m) { $n % $m }, 'numify', 'MXCL::Term::Num'),


        lift_literal_sub('==', [qw[ n m ]], sub ($n, $m) { $n == $m }, 'numify', 'MXCL::Term::Bool'),
        lift_literal_sub('!=', [qw[ n m ]], sub ($n, $m) { $n != $m }, 'numify', 'MXCL::Term::Bool'),
        lift_literal_sub('>',  [qw[ n m ]], sub ($n, $m) { $n >  $m }, 'numify', 'MXCL::Term::Bool'),
        lift_literal_sub('>=', [qw[ n m ]], sub ($n, $m) { $n >= $m }, 'numify', 'MXCL::Term::Bool'),
        lift_literal_sub('<',  [qw[ n m ]], sub ($n, $m) { $n <  $m }, 'numify', 'MXCL::Term::Bool'),
        lift_literal_sub('<=', [qw[ n m ]], sub ($n, $m) { $n <= $m }, 'numify', 'MXCL::Term::Bool'),

        lift_literal_sub('<=>', [qw[ n m ]], sub ($n, $m) { $n <=> $m }, 'numify', 'MXCL::Term::Num'),
    )
}

sub get_core_set {
    # --------------------------------------------------------------------------
    # builder
    # --------------------------------------------------------------------------
    $BIFS //= +[
        # ----------------------------------------------------------------------
        # Predicates
        # ----------------------------------------------------------------------

        # TOOD - add to Object
        lift_applicative('eq?', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
            return MXCL::Term::Bool->CREATE( $lhs->equals($rhs) )
        }),

        # TOOD - add to Object
        lift_applicative('isa?', [qw[ value type ]], sub ($env, $value, $type) {
            return MXCL::Term::Bool->CREATE( $value->type eq $type )
        }),

        lift_type_predicate('atom?',        sub ($x) { $x->is_atom        }),
        lift_type_predicate('literal?',     sub ($x) { $x->is_literal     }),
        lift_type_predicate('callable?',    sub ($x) { $x->is_callable    }),
        lift_type_predicate('applicative?', sub ($x) { $x->is_applicative }),
        lift_type_predicate('operative?',   sub ($x) { $x->is_operative   }),
        lift_type_predicate('opaque?',      sub ($x) { $x->is_opaque      }),

        lift_type_predicate('bool?', 'MXCL::Term::Bool'),
        lift_type_predicate('num?',  'MXCL::Term::Num'),
        lift_type_predicate('str?',  'MXCL::Term::Str'),

        lift_type_predicate('word?', 'MXCL::Term::Word'),
        lift_type_predicate('sym?',  'MXCL::Term::Sym'),
        lift_type_predicate('tag?',  'MXCL::Term::Tag'),

        lift_type_predicate('pair?',  'MXCL::Term::Pair'),
        lift_type_predicate('list?',  'MXCL::Term::List'),
        lift_type_predicate('nil?',   'MXCL::Term::Nil'),
        lift_type_predicate('tuple?', 'MXCL::Term::Tuple'),
        lift_type_predicate('array?', 'MXCL::Term::Array'),
        lift_type_predicate('hash?',  'MXCL::Term::Hash'),

        lift_type_predicate('environment?', 'MXCL::Term::Environment'),
        lift_type_predicate('exception?',   'MXCL::Term::Exception'),
        lift_type_predicate('unit?',        'MXCL::Term::Unit'),

        lift_type_predicate('applicative-native?', 'MXCL::Term::Applicative::Native'),
        lift_type_predicate('operative-native?',   'MXCL::Term::Operative::Native'),

        lift_type_predicate('lambda?', 'MXCL::Term::Lambda'),
        lift_type_predicate('fexpr?',  'MXCL::Term::FExpr'),

        # ----------------------------------------------------------------------
        # Coercing
        # ----------------------------------------------------------------------

        # TOOD - add to Object
        lift_applicative('numify',    [qw[ value ]], sub ($env, $value) { MXCL::Term::Num->CREATE( $value->numify ) }),
        lift_applicative('stringify', [qw[ value ]], sub ($env, $value) { MXCL::Term::Str->CREATE( $value->stringify ) }),
        lift_applicative('boolify',   [qw[ value ]], sub ($env, $value) { MXCL::Term::Bool->CREATE( $value->boolify ) }),

        # ----------------------------------------------------------------------
        # String Operations
        # ----------------------------------------------------------------------

        # TOOD - add to Str with args reversed
        lift_literal_sub('split', [qw[ sep string ]], sub ($sep, $string) {
            map { MXCL::Term::Str->CREATE($_) } split( $sep =~ s/\./\\\./gr, $string );
        }, 'stringify', 'MXCL::Term::List'),

        # TOOD - add to List,Array,Tuple and Hash(maybe)
        lift_applicative('join', [qw[ sep list ]], sub ($env, $sep, $list) {
            MXCL::Term::Str->CREATE(
                join $sep->value,
                    map $_->stringify,
                        ($list isa MXCL::Term::List)
                            ? $list->uncons
                            : $list->elements
            )
        }),

        # ----------------------------------------------------------------------
        # Comparisons
        # ----------------------------------------------------------------------

        get_Num_ops(),
        get_Str_ops(),

        # ----------------------------------------------------------------------
        # Logical
        # ----------------------------------------------------------------------

        lift_applicative('not', [qw[ value ]], sub ($env, $value) {
            return MXCL::Term::Bool->CREATE( not( $value->boolify ) )
        }),

        lift_operative('and', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
            return [
                MXCL::Term::Kontinue::IfElse->new(
                    env       => $env,
                    condition => $lhs,
                    if_true   => $rhs,
                    if_false  => $lhs,
                ),
                MXCL::Term::Kontinue::Eval::Expr->new(
                    env  => $env,
                    expr => $lhs
                )
            ]
        }),

        lift_operative('or', [qw[ lhs rhs ]], sub ($env, $lhs, $rhs) {
            return [
                MXCL::Term::Kontinue::IfElse->new(
                    env       => $env,
                    condition => $lhs,
                    if_true   => $lhs,
                    if_false  => $rhs,
                ),
                MXCL::Term::Kontinue::Eval::Expr->new(
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
                MXCL::Term::Kontinue::Return->new(
                    env   => $env,
                    value => MXCL::Term::Lambda->CREATE( $params, $body, $env )
                )
            ]
        }),

        # ----------------------------------------------------------------------
        # Datatype Operations
        # ----------------------------------------------------------------------

        # pairs
        # ----------------------------------------------------------------------
        lift_datatype_constructor('pair/new',  [qw[ fst snd     ]], 'MXCL::Term::Pair'),

        lift_applicative('fst',  [qw[ pair ]], sub ($env, $pair) { $pair->fst }),
        lift_applicative('snd',  [qw[ pair ]], sub ($env, $pair) { $pair->snd }),

        # lists
        # ----------------------------------------------------------------------
        lift_datatype_constructor('list/new',  [qw[ ...items    ]], 'MXCL::Term::List'),

        lift_applicative('first', [qw[ list ]], sub ($env, $list) { $list->first }),
        lift_applicative('rest',  [qw[ list ]], sub ($env, $list) { $list->rest }),

        lift_applicative('list/length', [qw[ list ]], sub ($env, $list) { MXCL::Term::Num->CREATE( $list->length ) }),

        # tuples
        # ----------------------------------------------------------------------
        lift_datatype_constructor('tuple/new', [qw[ ...elements ]], 'MXCL::Term::Tuple'),

        lift_applicative('tuple/size', [qw[ tuple ]], sub ($env, $tuple) { MXCL::Term::Num->CREATE( $tuple->size ) }),
        lift_applicative('tuple/at',   [qw[ tuple idx ]], sub ($env, $tuple, $idx) { $tuple->at( $idx ) }),

        # arrays
        # ----------------------------------------------------------------------
        lift_datatype_constructor('array/new', [qw[ ...items    ]], 'MXCL::Term::Array'),

        lift_applicative('array/length', [qw[ array ]], sub ($env, $array) { MXCL::Term::Num->CREATE( $array->length ) }),

        lift_applicative('array/get',  [qw[ array idx ]],       sub ($env, $array, $idx) { $array->get( $idx ) }),
        lift_applicative('array/set!', [qw[ array idx value ]], sub ($env, $array, $idx, $value) {
            $array->set( $idx, $value )
        }),

        lift_applicative('array/pop',  [qw[ array ]],       sub ($env, $array) { $array->pop() }),
        lift_applicative('array/push', [qw[ array value ]], sub ($env, $array, $value) {
            $array->push( $value )
        }),

        lift_applicative('array/shift',   [qw[ array ]],       sub ($env, $array) { $array->shift() }),
        lift_applicative('array/unshift', [qw[ array value ]], sub ($env, $array, $value) {
            $array->unshift( $value )
        }),

        lift_applicative('array/splice', [qw[ array offset length ]], sub ($env, $array, $offset, $length=undef) {
            MXCL::Term::Array->CREATE( $array->splice( $offset->value, $length ? $length->value : () ) );
        }),

        # hashes
        # ----------------------------------------------------------------------
        lift_datatype_constructor('hash/new',  [qw[ ...entries  ]], 'MXCL::Term::Hash'),

        lift_applicative('hash/size', [qw[ hash ]], sub ($env, $hash) { MXCL::Term::Num->CREATE( $hash->size ) }),

        lift_applicative('hash/exists?', [qw[ hash key ]], sub ($env, $hash, $key) { MXCL::Term::Bool->CREATE( $hash->has($key) ) }),
        lift_applicative('hash/get',     [qw[ hash key ]], sub ($env, $hash, $key) { $hash->get($key) }),
        lift_applicative('hash/set!',    [qw[ hash key value ]], sub ($env, $hash, $key, $value) { $hash->set($key, $value) }),
        lift_applicative('hash/delete!', [qw[ hash key ]], sub ($env, $hash, $key) { $hash->delete($key) }),

        lift_applicative('hash/keys',   [qw[ hash ]], sub ($env, $hash) { MXCL::Term::List->CREATE( $hash->keys ) }),
        lift_applicative('hash/values', [qw[ hash ]], sub ($env, $hash) { MXCL::Term::List->CREATE( $hash->values ) }),

        # ----------------------------------------------------------------------
        # Keywords
        # ----------------------------------------------------------------------

        lift_operative('quote', [qw[ quoted ]], sub ($env, $quoted) {
            return [
                MXCL::Term::Kontinue::Return->new( value => $quoted, env => $env )
            ]
        }),
        lift_operative('do', [qw[ ...block ]], sub ($env, @exprs) {
            my $local = $env->derive;
            return [
                MXCL::Term::Kontinue::Context::Enter
                ->new( env => $local )
                ->wrap(
                    reverse map {
                        MXCL::Term::Kontinue::Eval::Expr->new(
                            env  => $local,
                            expr => $_
                        )
                    } @exprs
                )
            ]
        }),
        # ----------------------------------------------------------------------
        # Defintions & Scopes
        # ----------------------------------------------------------------------
        lift_operative('defvar', [qw[ name value ]], sub ($env, $name, $value) {
            return [
                MXCL::Term::Kontinue::Define->new( name => $name, env => $env ),
                MXCL::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
            ]
        }),
        lift_operative('defun', [qw[ name params body ]], sub ($env, $name, $params, $body) {
            return [
                MXCL::Term::Kontinue::Define->new( name => $name, env => $env ),
                MXCL::Term::Kontinue::Return->new(
                    env   => $env,
                    value => MXCL::Term::Lambda->new(
                        params => $params,
                        body   => $body,
                        env    => $env
                    )
                )
            ]
        }),
        lift_operative('set!', [qw[ name value ]], sub ($env, $name, $value) {
            return [
                MXCL::Term::Kontinue::Mutate->new( name => $name, env => $env ),
                MXCL::Term::Kontinue::Eval::Expr->new( expr => $value, env => $env ),
            ]
        }),
        # ----------------------------------------------------------------------
        # Scope
        # ----------------------------------------------------------------------
        lift_operative('let', [qw[ binding ...body ]], sub ($env, $binding, @body) {
            my ($name, $value) = $binding->uncons;
            my $local = $env->derive;
            return [
                MXCL::Term::Kontinue::Context::Enter
                ->new( env => $local )
                ->wrap(
                    (reverse map {
                        MXCL::Term::Kontinue::Eval::Expr->new(
                            env  => $local,
                            expr => $_
                        )
                    } @body),
                    MXCL::Term::Kontinue::Define->new( name => $name, env => $local ),
                    MXCL::Term::Kontinue::Eval::Expr->new( expr => $value, env => $local ),
                )
            ]
        }),
        # ----------------------------------------------------------------------
        # conditonals
        # ----------------------------------------------------------------------
        lift_operative('if', [qw[ cond if-true if-false ]],
        sub ($env, $cond, $if_true, $if_false) {
            my $local = $env->derive;
            return [
                MXCL::Term::Kontinue::Context::Enter
                ->new( env => $local )
                ->wrap(
                    MXCL::Term::Kontinue::IfElse->new(
                        env       => $local,
                        condition => $cond,
                        if_true   => $if_true,
                        if_false  => $if_false,
                    ),
                    MXCL::Term::Kontinue::Eval::Expr->new(
                        env  => $local,
                        expr => $cond
                    )
                )
            ]
        }),
        # ----------------------------------------------------------------------
        # loops
        # ----------------------------------------------------------------------
        lift_operative('while', [qw[ cond body ]],
        sub ($env, $cond, $body) {
            my $local = $env->derive;
            return [
                MXCL::Term::Kontinue::Context::Enter
                ->new( env => $local )
                ->wrap(
                    MXCL::Term::Kontinue::DoWhile->new(
                        env       => $local,
                        condition => $cond,
                        body      => $body,
                    ),
                    MXCL::Term::Kontinue::Eval::Expr->new(
                        env  => $local,
                        expr => $cond
                    )
                )
            ]
        }),
        # ----------------------------------------------------------------------
        # exceptions
        # ----------------------------------------------------------------------
        lift_operative('throw', [qw[ msg ]], sub ($env, $msg) {
            return [
                MXCL::Term::Kontinue::Throw->new(
                    env       => $env,
                    exception => MXCL::Term::Runtime::Exception->new( msg => $msg ),
                )
            ]
        }),
        lift_operative('try', [qw[ body catch-handler ]], sub ($env, $expr, $handler) {
            my ($params, $body) = $handler->rest->uncons;
            my $local = $env->derive;
            return [
                MXCL::Term::Kontinue::Context::Enter
                ->new( env => $local )
                ->wrap(
                    MXCL::Term::Kontinue::Catch->new(
                        env     => $local,
                        handler => MXCL::Term::Lambda->new(
                            params => $params,
                            body   => $body,
                            env    => $local
                        ),
                    ),
                    MXCL::Term::Kontinue::Eval::Expr->new(
                        env  => $local,
                        expr => $expr
                    )
                )
            ]
        }),

        # ----------------------------------------------------------------------
        # OO
        # ----------------------------------------------------------------------

        lift_operative('object', [qw[ ...body ]], sub ($env, @body) {
            my $instance = $env->derive;
            return [
                MXCL::Term::Kontinue::Return->new(
                    env   => $env,
                    value => MXCL::Term::Opaque->new(
                        env => $instance->capture
                    )
                ),
                reverse map {
                    MXCL::Term::Kontinue::Eval::Expr->new(
                        env  => $instance,
                        expr => $_
                    )
                } @body
            ]
        }),

        lift_operative('defclass', [qw[ name params ...body ]], sub ($env, $name, $params, @body) {
            return +[
                MXCL::Term::Kontinue::Define->new( name => $name, env => $env ),
                MXCL::Term::Kontinue::Return->new(
                    env => $env,
                    value => MXCL::Term::Operative::Native->new(
                        name   => $name,
                        params => $params,
                        body   => sub ($env, @args) {

                            my @params = $params->uncons;
                            my %bindings;
                            for (my $i = 0; $i < scalar @params; $i++) {
                                $bindings{ $params[$i]->ident } = $args[$i];
                            }

                            my $instance = $env->derive(%bindings);

                            return [
                                MXCL::Term::Kontinue::Return->new(
                                    env   => $env,
                                    value => MXCL::Term::Opaque->new(
                                        env => $instance->capture
                                    )
                                ),
                                reverse map {
                                    MXCL::Term::Kontinue::Eval::Expr->new(
                                        env  => $instance,
                                        expr => $_
                                    )
                                } @body
                            ]
                        }
                    )
                )
            ]
        }),

        # ----------------------------------------------------------------------
        # ...
        # ----------------------------------------------------------------------
    ];
}

# utils ...

sub lift_literal_sub ($name, $params, $f, $accepts, $returns) {
    my $arity = scalar @$params;
    return MXCL::Term::Applicative::Native->CREATE(
        MXCL::Term::Key->CREATE( $name ),
        MXCL::Term::List->CREATE( map MXCL::Term::Key->CREATE( $_ ), @$params ),
        sub ($env, @args) {
            MXCL::Term::Runtime::Exception->throw(
                "Arity Mismatch, expected ${arity} got ".(scalar @args)." in ${name}"
            ) if scalar @args != $arity;
            $returns->CREATE( $f->( map $_->$accepts, @args ) )
        }
    )
}

sub lift_datatype_constructor ($name, $params, $datatype) {
    return MXCL::Term::Applicative::Native->CREATE(
        MXCL::Term::Sym->CREATE( $name ),
        MXCL::Term::List->CREATE( map MXCL::Term::Key->CREATE( $_ ), @$params ),
        sub ($env, @args) { $datatype->CREATE( @args ) }
    )
}

sub lift_type_predicate ($name, $type_or_f) {
    return MXCL::Term::Applicative::Native->CREATE(
        MXCL::Term::Sym->CREATE( $name ),
        MXCL::Term::List->CREATE( MXCL::Term::Key->CREATE( 'x' ) ),
        (ref $type_or_f eq 'CODE'
            ? sub ($env, $arg) { MXCL::Term::Bool->CREATE( $type_or_f->($arg) ) }
            : sub ($env, $arg) { MXCL::Term::Bool->CREATE( blessed $arg && $arg->isa($type_or_f) ) })
    )
}

sub lift_operative ($name, $params, $fexpr) {
    return MXCL::Term::Operative::Native->CREATE(
        MXCL::Term::Sym->CREATE( $name ),
        MXCL::Term::List->CREATE( map MXCL::Term::Key->CREATE( $_ ), @$params ),
        $fexpr
    )
}

sub lift_applicative ($name, $params, $native) {
    return MXCL::Term::Applicative::Native->CREATE(
        MXCL::Term::Sym->CREATE( $name ),
        MXCL::Term::List->CREATE( map MXCL::Term::Key->CREATE( $_ ), @$params ),
        $native
    )
}




