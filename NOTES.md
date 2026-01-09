<!----------------------------------------------------------------------------->
# NOTES
<!----------------------------------------------------------------------------->

## Opal

- need top-level interpreter
- HOST handling

## Environment 

- make it composable, with capabilities

## Datatypes

- Add Arrays
    - `@[ 10 20 30 ]`
    - indexable, mutable
    - push, pop, shift, unshift, etc. 
    - converted into `(array ...)`
    
- Add Tuples
    - `[ 10 20 30 ]`
    - indexable, immutable
    - can only access one thing at a time, no `rest` methods
    - converted into `(tuple ...)`

- Add Blocks
    - `{ ... }`
    - converted into `(do ...)`
    - no new objects, just syntactic sugar

































<!----------------------------------------------------------------------------->
