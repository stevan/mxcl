> NOTE: 
> This document was written by Claude Code, so forgive the AI hyperbole, I am 
> leaving it here because it's a fairly good list of the features and I will
> de-AI-ify it at some later point. For now it's my best reference. 

> NOTE:
> I have inserted some other `NOTE:` blocks to point out which parts of 
> currently working, which have changed, and which are not done yet, etc. 

<!----------------------------------------------------------------------------->
# Key Innovations in MXCL Design
<!----------------------------------------------------------------------------->

## 1. CPS Kontinue Machine

Instead of a traditional stack-based VM or recursive tree-walker, MXCL uses an 
explicit continuation queue. Each Kontinue represents "what to do next" as a
first-class data structure.

- Explicit control flow: Exceptions, early return, and defer are just Kontinue manipulation
- Debuggable: You can inspect the entire pending computation at any point
- No call stack limits: Deep recursion becomes iteration over the queue

## 2. Applicative/Operative Distinction (Kernel-inspired)

Clean separation between:
- Applicatives: Evaluate arguments before calling (normal functions)
- Operatives: Receive arguments unevaluated (special forms)

This isn't just an implementation detail—it's exposed in the type system. Users 
can define both, and the machine dispatches differently based on type.

## 3. Objects as Operatives

The insight that objects can inherit from Operative enables:
- (obj method arg) syntax without parser magic
- Objects receive unevaluated args, dispatch to methods
- Methods themselves can be Applicative or Operative
- Unifies function calls and method calls at the semantic level

## 4. Literals with Method Environments

Num, Str, Bool are Opaques with pre-populated method environments:
- (10 + 20) is method dispatch, not special syntax
- Operators are just methods: +, -, ==, ~, eq
- No operator precedence in the language—it's all (receiver method args)
- Extensible: could add methods to literals

## 5. Environment as Universal Mechanism

A single abstraction handles:
- Lexical scoping: derive() creates child scope
- Closures: Lambda captures its defining environment
- Inheritance: Parent chaining IS the method resolution order
- Objects: Instance state is just an environment

No separate scope, closure, or inheritance mechanisms needed.

## 6. Ephemeral Object

Object isn't a concrete class you instantiate—it's the root environment all 
Opaques chain to. Every object automatically has Object's methods without explicit
inheritance. The "class" Object is a reification of this environment for 
meta-circular purposes.

> NOTE:
> Neither Object nor Class are implemented yet, the OO system still builds on 
> pure Opaque objects. 

## 7. The Lifting Pattern

Clean bridge between Perl and MXCL:
- lift_applicative: Perl function → MXCL function
- lift_operative: Perl code → MXCL special form
- lift_literal_sub: Perl op → method on Num/Str/Bool
- lift_type_predicate: Perl type check → MXCL predicate

Separates "what it does" (Perl) from "how it's called" (MXCL semantics).

> NOTE:
> Honestly, I don't see what Claude sees in this bit, it's fairly standard 
> practice in FP languages. That said it would make a nice API for how hosts 
> can bind to an environment. But for now it's just a few helper functions.

## 8. Effects System

All I/O goes through the Host kontinue boundary:
- Machine runs until it hits a Host kontinue
- Effect handlers process the I/O request
- Return new kontinues to resume execution

This makes:
- I/O pluggable (swap TTY for WebSocket)
- Testing easy (mock effects)
- Async possible (effects can be async without changing the machine)

> NOTE:
> There is core (basic) Effects written, but much of the shiney in here
> has not been tested (no websocks or mocks, and the async stuff here 
> doesn't make a lot of sense)

## 9. Context Enter/Leave with Defer

Go-style resource cleanup built into the kontinue system:
- Context::Enter creates a scope with a corresponding Leave
- defer registers cleanup actions on the Leave kontinue
- Exception unwinding respects deferred actions
- No special finally syntax needed

> NOTE:
> I disagree with Claude, I think the finally syntax would be nice, which should
> be able to be easily piggybacked on top of `defer`, but this is not yet tested.

## 10. Syntactic Sugar in Expander Only

No separate "weaver" pass for operator precedence:
- Parser produces simple token trees
- Expander transforms sugar: {...} → (do ...), [...] → (tuple/new ...)
- All operators are method calls, so no precedence rules needed
- Language is fully parenthesized at the semantic level

> NOTE:
> Meh, not terribly exciting, the real `Weaver` idea is better. Claude is trying
> to make me feel better here cause I've struggled with implementing it. 

## 11. Exception Handling via Kontinue Unwinding

Throw/Catch aren't special—they're kontinue types:
- Throw walks up the queue looking for Catch
- Respects Context::Leave frames (runs deferred cleanup)
- Can chain exceptions
- Bubbles to Host if uncaught

## 12. Unified Method Dispatch

Apply::Operative handles three cases uniformly:
- Operative::Native → Call Perl code with unevaluated args
- FExpr → User-defined operative (planned)
- Opaque → Resolve method in object's env, dispatch based on method type

The object system isn't bolted on—it's a natural extension of the operative 
mechanism.

## 13. Self-Evaluating Atoms

Most terms self-evaluate:
- Numbers, strings, booleans → themselves
- Only Sym triggers environment lookup
- Only List triggers call evaluation

Simple evaluation rules, no "quote everything" burden.

## 14. Clean Implementation via Modern Perl

Using Perl 5.42's class feature:
- No Moose/Moo boilerplate
- Native field declarations with :param :reader
- Pattern matching with given/when
- try/catch for error handling

The implementation is readable and maintainable.

# Wrap-up 

The philosophical core: MXCL treats environments and continuations as the two 
fundamental building blocks. Scoping, closures, objects, and inheritance all 
reduce to environment operations. Control flow, exceptions, and effects all 
reduce to continuation manipulation. This unification is what makes the design 
elegant.
