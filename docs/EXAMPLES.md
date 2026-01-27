<!----------------------------------------------------------------------------->
# Random Examples
<!----------------------------------------------------------------------------->

If you want to know what MXCL looks like, you can look at the `ext/Test.mxcl`
file, it is our MXCL test framework. It is used by test files matching this
pattern `t/100-self-test/**/*.t`. Those files will give you a good idea of the 
basic syntax of MXCL, this file serves a different purpose. 

As I develop the language, I am often experimenting and testing out ideas. 
Not all of those things deserve to be turned into a test, and that is what 
you will find here. Small snippets of code, some serious, some silly, but 
all of them representative of explorations of the language. Don't judge too 
harshly ;)

## Serious

### Basic anon object expample

Objects are basically captured environments.

```lisp
(defvar $foo (object
    (defvar x 0)
    (defun add ($self m) (set! x (x + m)))))

($foo add 20)
(say ($foo x))
($foo add 220)
(say ($foo x))

```

### Basic OO expample

`defclass` creates constructor functions that can build instances. 

```lisp
(defclass Point ($x $y)
    (defvar x $x)
    (defvar y $y)

    (defun x! ($self $x) (set! x $x))
    (defun y! ($self $y) (set! y $y))
)

(let ($p (Point 10 20))
    (do
        (say ($p x))
        ($p x! 100)
        (say ($p x))
    )
)
```

## Silly

### We have `libreadline` at home!

This is just a test of `getc` which is handled by the `TTY` effect, I wanted 
to see if I could capture keypresses in a loop threading back and forth through 
the effect. 

```lisp
(defun read-line (buffer)
    (let (c (getc))
        (do
            (print c)
            (if (c eq "\n")
                buffer
                (read-line (buffer ~ c))))))

(do
    (print "Guess a number? ")
    (let (guess (read-line ""))
        (say ("You guessed: " ~ (numify guess)))
    )
)
```

## Simple/Stupid HTML generation

This is mostly to see if I can use HTML as syntax. Of course it breaks when 
you want to have attributes, but meh, its something. 

> This would be more interesting if we could write language level FExprs, 
> we should revist this when that happens.

```lisp

(defvar <html>   "<html>")
(defvar </html> "</html>")

(defvar <body>   "<body>")
(defvar </body> "</body>")

(defvar <h1>   "<h1>")
(defvar </h1> "</h1>")

(defvar <p>   "<p>")
(defvar </p> "</p>")

(defvar <hr/> "<hr/>")

(defun cdata (str) str)

(defun print-page (title summary)
    (say
        <html>
            <body>
                <h1>(cdata title)</h1>
                <hr/>
                <p>(cdata summary)</p>
            </body>
        </html>))

(page "Greetings" "Hello world!")

```
