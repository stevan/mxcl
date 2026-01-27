> NOTE:
> This document is a stream of conciousness first draft word salad full of 
> all sorts of mistakes, misstatements and misunderstandings, all of which 
> are my fault. (Don't blame Matt or Claude) 

<!----------------------------------------------------------------------------->
# What is MXCL?
<!----------------------------------------------------------------------------->

MXCL stands for "Matt's eXtensible {Config,Control,Command} Language" and is 
the latest version of the XCL language which Matt Trout created. 

> More on the history in another document. 

The https://github.com/mst-ripples github organization contains a set of forks 
of relevant projects from Matt's personal account. In particular it contains
XCL, the initial version and NXCL, the second version, which was a radical 
re-write of XCL. Within the NXCL repo is a Javascript implementation, the 
thrid version, which builds further on the ideas of the Perl version. All three
versions contain a folder called `sketches/` in which some of Matt's thought 
process can be seen. 

The MXCL project is a synthesis of the best parts of all three versions as well 
as some ideas that were only in sketches. 

Keen observers of the source code will notice it looks absolutely nothing like
MST code at all. And keen observers of the MXCL code will noticed it also looks
different from XCL and NXCL code. And frankly, it shoudn't matter, those are 
both cosmetic, the real genius of Matt's design is the combination of language
features he assembled and the way they interact. 

<!----------------------------------------------------------------------------->
## The Language Foundations
<!----------------------------------------------------------------------------->

MXCL is built on a Lambda Calculus fondation and just about the entire system 
could be described using pure lambda calculus, building up everything from just 
functions and arguments, etc. 

> Pure LC only has functions and variables, not literal values like numbers, 
> they are build with Church numerals or some similar encoding of functions
> and variables. Powerful but very low level. 

But since that is very tedious, we borrow from the LISP/Scheme family of 
languages and build our language using S-Expressions. The entire language 
can be described using S-Expressions in a head-normal form. 

> "head-normal form" basically means s-expressions where the `head` item
> or `first` item, is a function to be applied with the `tail` or `rest`
> of the list as arguments. This form is key to the eval/apply dance that 
> a LISP style interpreter does. 

But honestly, even this is a bit tedious, so we do what most practical 
implementations do and we also include a set of native `Term`s to handle
values like numbers, strings, booleans. We also include list, nil and pair terms 
to construct the S-Expression tree from. This gives us our core set of terms 
needed to be self describing. 

From here we can build more sophisticated `Term`s to represent things like 
lambda expression, conditionals, array, tuples, hashmaps etc. Suffice to say, 
while these are implmented natively, it is possible to implement them as 
constructions of the core terms. 

> This is common in production LISP and Scheme systems, as long as the 
> language level semantics are maintained, the underlying representation is 
> largely irrelevant. In OO terms, this is a seperation of behavior from 
> representation, basically encapsulation. 

The next step would usually be to add in special forms like `lambda`, `if` 
and `quote`, etc. But here is where we take a detour, with a one stop along the 
way. 

First, we borrow from the Kernel language and the Vau Calculus it uses, and 
we introduce a distinction between `Applicative` functions (arguments are 
evaluted and then passed to the function), and `Operative` functions 
(arguments are not evaluated before being passed to the function). In addition 
to getting unevaluted arguments, the operative functions also get the 
current environment as a parameter. The Kernel language and accompanying phd
lay this all out in formal terms, we do not go that far, we simply steal the
idea of the applicative/operative distinction.

> Kernel Language - https://klisp.org/ if you want to know more. 

Next, we add `Term`s to allow us to bind native functions as applicative and 
operative functions in the language. This allows us to write all our special
forms (`lambda`, `if`, `quote`, etc) as native operative functions. For 
instance, the `lambda` operative just constructs a `Lambda` term and returns it;
the `if` operative evalutes the conditional, and then chooses which branch to 
evaluate. 

The result of this detour being that we do not need any special forms in the 
language at all. We retain a pure S-Expression representation with head-normal
form, and all control structures are actually just functions. 

> See some examples of operatives in the `Bridge` section. 

### What does this give us?

We have a language which ...
- can be distilled down to pure lambda calculus
- can be represented entirely with s-expressions
- has no special parser forms, all pure evaluation
- head normal form is always maintained

<!----------------------------------------------------------------------------->
## The Machine Foundations
<!----------------------------------------------------------------------------->

The MXCL virtual machine is a continuation based interpreter, but with a few 
twists. Unlike most CPS style systems, where the compiler will transform the 
entire program to continuation passing style, we take a different approach. 

To start with, continuations are just `Term` objects, and so are just data. 
Each continuation term has a "current" environment and a "stack" for return 
values, along with any neccessary data specific to the type of operation 
it represents.

Our compiler is much simpler, it simply wraps the root expression in 
an `Eval::Expr` continuation and places it into a LIFO queue.

Each step of the machine removes a continuation from the queue and processes
it accordingly. For `Eval::Expr`, it evaluates the expression, which then 
results in more continuations being pushed onto the queue, and so on. 

When returning values from expressions, instead of using a global temporary 
stack, we use the stack inside the continuation object (see above). Values 
are returned by pushing onto the stack of the continuation object at the front
of the queue. 

This incremental CPS transformation allows us to get delimited continuations
almost entirely for free. An expression could be delimited by simply wrapping
it in an `Eval::Expr` continuation, there is no need to mark the end of it. 
When placed on a VM queue it will be evaluated in it's local environment and 
return it's results to the continution behind it in the queue. 

With it being possible to splice delimited continuations at literally any 
expression boundary, concurrency forms like green threads, generators, etc. 
all become fairly simple to implement. But since continuations are just `Term`s, 
and therefore representable as simple s-expresssions, distributed computation 
also gets easier (or at least turns into mostly a network problem). 

### What does this give us?

- execution/evaluation is pausable, resumeable, delimitable and transportable
- everything is tail recursive, no C stack

<!----------------------------------------------------------------------------->
## The Bridge 
<!----------------------------------------------------------------------------->

The main bridge between the language and the machine is the Operative functions. 

The Operatives get called with unevaluated args, and the current env, then 
return a list of continuations to be pushed onto the queue. The result of this
is that unlike operatives in the Kernel language which selectively evaluate 
arguments inside of the operative function application, we instead essentially 
"schedule" the evaluation of arguments and their subsequent use through a set 
of continuations. 

This "scheduling" approach allows the Machine to have a very small set of 
continuations (currently 16) which handle a core set of VM operations. These
core operations can then be composed together (by putting several in to the 
queue at a time) to provide richer semantics and functionality. 

The continuations provides the following feature set:

- looking up variables in environments
- applying functions (both operative and applicative)
    - evaluating arguments accordingly
- conditional execution
- definitions and mutations in the environment
- scope enter/leave context management
- exception handle (throw, try/catch)
- trigger a "host" effect 

Here are some examples, the syntax is still a WIP. 

```lisp
; define the `lambda` keyword as an operative
; so this AST `(lambda (x y) (+ x y))` can be
; read as calling the lambda functions with
; two un-evaluated arguments, the parameter
; list and the body. The operative calling 
; convention also adds the current environment
; at the head of args list, which gives us
; all that we need to construct a Lambda 
; term with and return that by returning 
; a tagged continuation (kontinue) term 
; (:Return) to handle returning the value
; to the caller, and threading the $env 
; through as well.
(defun lambda ($env params body) :operative
    (kontinue $env
        :Return (construct :Lambda ($env derive) params body)))

; here is a simple `if` keyword as an operative
; it works the same as `lambda` in how it is 
; called but here returns a list of kontinue 
; terms, they should be read in bottom-up order.
; The first (`EvalExpr`) evalutes the condition 
; placing its return value onto a stack, the 
; second `IfElse` pops the value from the stack
; and executes if-true or if-false accordingly.
; This is an example of the 'scheduling' idea
; in small form. 
(defun if ($env cond if-true if-false) :operative
    (list
        (kontinue $env :IfElse if-true if-false)
        (kontinue $env :EvalExpr cond)))
```

### What does this give us?

- this greatly amplifies the power of the Operatives
- ???

<!----------------------------------------------------------------------------->
## The Host Effect System
<!----------------------------------------------------------------------------->

The MXCL virtual machine runs inside of a "host", which is called a `Strand`
in the codebase. The "host" manages the execution of code on a machine, in 
particular it manages the capabilities available to the machine through the 
root environment it constructs for the machine. 

In addition to the set of language builtins, a host/strand can also enable a 
set of "effects" through the environment. The Effect system provides functions 
for the environment to allow access to it capabilities, and a handler function  
that actually provide the access. The effect system is triggered by a special 
"host" continuation, which pauses the VM and hands control back to the host, 
which invokes the appropriate Effect handler. 

Through this mechanism we do things such as provide terminal access via the 
`TTY` effect, which provides `print`, `say`, `warn` and `readline` functions, 
along with a handler that has file handles for STD{IN,OUT,ERR}. We also handle 
loading code from a file via a `Require` effect, and the repl is implemented
as a recursive `REPL` Effect handler. 

This is built on the foundations of Algebraic Effects, which in turn are built
on Monads. The key idea being that we are able to isolate any "side effects" 
that occur outside of the machine's execution context, and handle these things 
independent of the machine. 


```lisp

; `fetch` would be a function provided by an effect
; which might yield and be handled asyncronously, 
; allowing other running strands to run. Once the 
; async fetch is resolved, execution resumes from 
; that point and the `header` and `body` variables
; are bound.
(defun get-url (url) 
    (let ((headers body) (fetch url))
        ; is-cached? and fetch-from-cache can both be async calls to 
        ; REDIS or something, or just local sync calls to in-memory
        ; objects, it does not matter, the code doesn't change. 
        (if (is-cached? headers)
            (fetch-from-cache headers)
            (if (is-redirect? header)
                ; if it is a redirect, then recurse and 
                ; for the redirect. This is automatically 
                ; tail-recursive through the machine's queue
                ; mechanism and all state is contained in the
                ; continuation queue.
                (get-url (parse-redirect-url header))
                ; return the response
                (response headers (parse-html body))
            )
        )
    )
)

```

### What does this give us?

- colorless functions
- async friendly runtime
- FFI like capabilities

<!----------------------------------------------------------------------------->
# What else needs explaining
<!----------------------------------------------------------------------------->

## Object System 

- Opague object system
- standard objects as Opaque
- meta-circular Object System via Opaques
- unified method dispatch
- head-normal form 

## Kontinue stuff

- Context enter/leave 
    - provides defer mechanics
    - uses paired continuations
- Throw/Catch
    - unwinding, with defer working

## Expander

- provides simple syntax sugar expansion
- possibly where a weaver/precedence parser might go?

## Homonicity

- This is implied, but should be stressed more

<!----------------------------------------------------------------------------->
# What Ideas need more exploring
<!----------------------------------------------------------------------------->

### Actor System in an Effect

If strands were capable of managing multiple machine instances, we could build
an actor system as an Effect. The actor effect would manage the spawning of 
new machines (by calling the strand object), and the sending/recieveing of 
messages would be done via a mailbox managed inside the effect. 

It would also be possible to have a basic fork/join threading model as an 
Effect as well, building on the same ideas as the Actor, but with a different
interface/API. 


<!----------------------------------------------------------------------------->
 
