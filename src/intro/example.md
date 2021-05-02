# Example

This is a very simple SMT problem in the category `QF_UF`, representing
the problem \\( a=b \land f~a = c \vdash f~b = c \\) by trying to contradict it:

```smtlib2
{{#include ./example-pb.smt2}}
```

With [Sidekick](https://github.com/c-cube/sidekick)'s experimental
proof producing mode, we solve this problem (it replies "UNSAT"):

```sh
$ sidekick example-pb.smt2 -o example-proof.quip
Unsat (0.003/0.000/0.000)
```

And we get the following proof:

```sexp
{{#include ./example-proof.quip}}
```
**NOTE**: the proof uses the S-expression format, but I do hope to have a
more efficient binary format relatively early on.

## Detailed explanation

- proof start with `(quip <version> <proof>)`. For now `version` is 1.

- `(steps (<assumptions>) (<steps>))` is the main composite proof rule.
  Let's ignore the assumptions for now. Each step in this rule
  is either a symbol definition (see below) or a `(stepc <name> <clause> <proof>)`,
  which introduce a name for an intermediate lemma (the clause)
  as proved by the sub-proof.

  A side-effect of this is that you can have partially correct[^1] proofs
  if a step is used correctly in the remainder of the proof, but its proof is
  invalid.

- `(deft $t1 (f a))` is a term definition.
  It defines the new symbol `$t1` as a syntactic shortcut for
  the term `(f a)`, to be expanded as early as possible by the proof checker.

  Similarly, `$t5` is short for `(= c (f b))`.

  This kind of definition becomes important in larger proofs, where re-printing
  a whole term every time it is used would be wasteful and would bloat proof
  files. Using definitions we can preserve a lot of sharing in the proofs.

- `(stepc c0 …)` is the first real step of the proof.
  Here, `c0` is the clause `{ - $t2, - $t3, + $t5`,
  and is proved by the proof `(cc-lemma …)` (a congruence closure lemma,
  i.e. a tautology of equality). It is, in essence, the proof we seek;
  the rest of the steps are used to derive a contradiction by
  deducing "false" from `c0` and our
  initial assumptions.

- the steps deducing `c1`, `c2`, and `c3` do so by using `assert`
  (meaning that the clause is actually an assumption of the initial problem),
  and then "preprocessing" them.

  For `(stepc c1 (cl (- $t5))
    (hres (init (assert (not $t5))) (p1 (refl $t5))))` we get the following
    tree:

  \\[
    \cfrac{
      \cfrac{}{$t5 ~\tiny{(assume)}} \qquad
      \cfrac{}{$t5 = $t5  ~\tiny{(refl)}}
      }{$t5  ~\tiny{(para1)}}
  \\]

  In this tree we can see the general shape of preprocessing terms: assume the
  initial term `± t`, prove `+ (t = u)` (where `u` is the simplified version),
  and then use boolean paramodulation to obtain `± u`.

  It just so happens
  that no meaningful simplification occurred and so `t` and `u` are the same,
  and sidekick did not shorten the proof accordingly into
  `(stepc c1 (cl (- $t5)) (assert (not $t5)))`


[^1]: or partially incorrect, depending on your point of view. Glass half-full
  and all that.
