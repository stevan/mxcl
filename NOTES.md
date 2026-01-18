<!----------------------------------------------------------------------------->
# NOTES
<!----------------------------------------------------------------------------->

## Effect::IO

-e -f -d -s -x
open close read readline slurp write spew
opendir closedir readdir

<!----------------------------------------------------------------------------->
## Terms
<!----------------------------------------------------------------------------->

### Parser Terms
```
(Token    :isa(Str)   location-data?)
(Compound :isa(Array) open? close?)
```

### Runtime Terms
```
(Unit)

(Bool \$native-bool)
(Num  \$native-num)
(Str  \$native-str)
(Sym  \$native-str)
(Tag  \$native-str)

(Pair fst . snd)
(Nil)
(List first rest)

(Tuple ...)
(Array ...)
(Hash  (k v) ...)

(Environment :isa(Hash) parent?)

(Exception msg)

(Lambda (params) body captured-env)
(FExpr (params env) body captured-env)

(Native::Operative   name params \&native-code)
(Native::Applicative name params \&native-code)
```

### Kontinues
```
(Host effect config)            [value]

(Throw exception)               []
(Catch handler)                 [exception]

(IfElse cond if-true if-false)  [evaled-cond]

(Define name)                   [value]
(Mutate name)                   [value]

(Return value)                  []

(Eval::TOS)                     [expr]
(Eval::Expr expr)               []
(Eval::Cons list)               []
(Eval::Cons::Rest rest)         [evaled-rest]

(Apply::Expr args)              [call]
(Apply::Operative call args)    []
(Apply::Applicative call)       [args]
```











