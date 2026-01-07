<!----------------------------------------------------------------------------->
# Core Types
<!----------------------------------------------------------------------------->

These are created by the Parser.

- Token 
- Compound 

These are all created in the Expander based on basic syntax patterns 
found in the Compound returned from the Parser. 

- Num 
- Str 
- Bool
- Sym 
- Key 
- Pair 
- Nil  
- List 
- Hash

These are native implementations of builtin functions (Applicative) 
and keywords (Operative).
 
- Applicative::Native 
- Operative::Native 

These require an `env` so they are created via `Operative::Native` fexpr.

- Lambda 
- FExpr 

These are the continuations that power the Machine.

- Kontinue::Host 
- Kontinue::Throw 
- Kontinue::Catch 
- Kontinue::IfElse 
- Kontinue::Define 
- Kontinue::Return 
- Kontinue::Eval::Expr 
- Kontinue::Eval::TOS 
- Kontinue::Eval::Cons 
- Kontinue::Eval::Cons::Rest 
- Kontinue::Apply::Expr 
- Kontinue::Apply::Operative 
- Kontinue::Apply::Applicative 

These are runtime values

- Unit 
- Exception 
- Environment 

<!----------------------------------------------------------------------------->
