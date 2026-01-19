#!perl

use v5.42;
use Test::More;
use MXCL::Strand;

my $source = q[
    (require "Test.mxcl")

    (diag "hash/new constructor tests")
    (defvar h (hash/new :a 1 :b 2))
    (ok (hash? h)               "... hash/new creates a hash")
    (is (hash/size h)           2       "... hash has 2 entries")

    (diag "%{} literal syntax")
    (defvar literal %{:x 10 :y 20})
    (ok (hash? literal)         "... %{...} creates a hash")
    (is (hash/size literal)     2       "... literal hash has 2 entries")

    (diag "Empty hash tests")
    (defvar empty (hash/new))
    (ok (hash? empty)           "... empty hash/new creates a hash")
    (is (hash/size empty)       0       "... empty hash has 0 entries")

    (defvar empty-literal %{})
    (ok (hash? empty-literal)   "... %{} creates empty hash")
    (is (hash/size empty-literal) 0     "... empty literal hash has 0 entries")

    (diag "hash/get tests")
    (defvar data %{:name "Alice" :age 30})
    (is (hash/get data :name)   "Alice" "... hash/get :name")
    (is (hash/get data :age)    30      "... hash/get :age")

    (diag "hash/set! mutation tests")
    (defvar mutable %{:a 1})
    (hash/set! mutable :a 99)
    (is (hash/get mutable :a)   99      "... hash/set! modifies existing key")

    (hash/set! mutable :b 2)
    (is (hash/get mutable :b)   2       "... hash/set! adds new key")
    (is (hash/size mutable)     2       "... size increased after adding key")

    (diag "hash/exists? tests")
    (defvar exists-test %{:foo 1 :bar 2})
    (ok (hash/exists? exists-test :foo) "... existing key exists")
    (ok (hash/exists? exists-test :bar) "... another existing key exists")
    (ok (not (hash/exists? exists-test :baz)) "... non-existing key does not exist")

    (diag "hash/delete! tests")
    (defvar deletable %{:a 1 :b 2 :c 3})
    (defvar deleted (hash/delete! deletable :b))
    (is deleted                 2       "... delete returns deleted value")
    (is (hash/size deletable)   2       "... size decreased after delete")
    (ok (not (hash/exists? deletable :b)) "... deleted key no longer exists")

    (diag "hash/keys tests")
    (defvar keyed %{:x 1 :y 2 :z 3})
    (defvar keys (hash/keys keyed))
    (ok (list? keys)            "... hash/keys returns a list")
    (is (list/length keys)      3       "... keys list has 3 elements")

    (diag "hash/values tests")
    (defvar valued %{:a 10 :b 20})
    (defvar vals (hash/values valued))
    (ok (list? vals)            "... hash/values returns a list")
    (is (list/length vals)      2       "... values list has 2 elements")

    (diag "Hash with computed values")
    (defvar computed %{:sum (+ 1 2) :product (* 3 4)})
    (is (hash/get computed :sum)     3      "... computed sum value")
    (is (hash/get computed :product) 12     "... computed product value")

    (diag "Hash with lambda values")
    (defvar with-fn %{:adder (lambda (x y) (+ x y))})
    (is ((hash/get with-fn :adder) 10 20) 30 "... lambda stored and called from hash")

    (done)
];

my $kont = MXCL::Strand->new->load($source)->run;
unless ($kont->effect isa MXCL::Effect::Halt) {
    die "EXPECTED HALT, GOT! ", $kont->stringify;
}
