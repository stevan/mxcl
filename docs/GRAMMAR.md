


```
sub length ($list) {
    if (is_nil($list)) {
        return 0;
    } else {
        return 1 + length(rest($list));
    }
}
```

```
(sub length ($list) (
    if (is_nil $list)
        (return 0)
    else
        (return (+ 1 (length (rest $list))))))
```

```
(defun length (f list) 
    (if (nil? list)
        0
        (+ 1 (length (rest list)))))
```

```
program    = expression* 
expression = primary

primary = 
    | atom
    | pair
    | list
    | hash
    | quoted

atom = BOOL | NIL | NUMBER | STRING | SYMBOL | KEY

quoted = QUOTE expression

pair   = LPAREN expression DOT expression RPAREN
list   = LPAREN expression RPAREN
hash   = HSIGIL PAREN expression RPAREN

LPAREN  = "(" ;
RPAREN  = ")" ;
LSQUARE = "[" ;
RSQUARE = "]" ;
LBLOCK  = "{" ;
RBLOCK  = "}" ;

QUOTE  = "'" ;
DOT    = "." ;
BOOL   = 'true' | 'false'
NIL    = "nil"
STRING = C-style string literal
NUMBER = integer or float literal
SYMBOL = sequence of non-whitespace, non-delimiter chars 
KEY    = keyword starting with ':'

```
