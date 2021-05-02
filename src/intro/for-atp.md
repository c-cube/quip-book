
## Quip for the Automatic Theorem Prover

Quip is biased towards being easy to _produce_ from theorem provers and SMT
solvers, while remaining reasonably efficient to check.

The easiness comes from several aspects:

- redundancy in rules: many rules will have a general form (e.g. a congruence
  closure lemma, or hyper-resolution with \\( n \\) steps),
  and some shorter forms for the common case (e.g. unary resolution
  or the reflexivity rule).

- rules can be quite high-level, requiring the proof checkers to reimplement
  congruence closure, resolution, etc.

- the proof rules do not need to always specify their result, only enough
  information that the conclusion can be reconstructed.

- proofs are based on a _proof language_ ("proof terms") that allow for easy
  composition of several steps. This way it's not necessary to name each single
  clause occurring in the proof.

