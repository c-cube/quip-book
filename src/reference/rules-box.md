# Box rules

Box is a term constructor that allows abstracting a clause into an opaque
constant term. This way, a whole clause can become a literal in another clause
without having to deal with true nested clauses;
see [the section on terms](./terms.md) for more details.

First, a few remarks.

- `(box C)` and `(box D)` are syntactically the same term if and only if (iff)
  `C` and `D` are the same clause, modulo renaming of free variables
  and reordering of literals.
- `(box C)` is opaque and will not be traversed by congruence closure.

That said, we have a few rules to deal with boxes:

- **box-assume** (`(box-assume <clause>)`):
  `(box-assume c)`, where `c` is `(cl l1 l2 … ln)`,
  proves the tautology `(cl (- (box c)) l1 l2 … ln)`.

  If one erases box (which is, semantically, transparent), this corresponds to
  the tautology \\( \lnot (\forall \vec{x} C) \lor \forall \vec{x} C \\)
  where \\( \vec{x} \\) is the set of free variables in \\( C \\).

  The use-case for this rule is that we can assume `C` freely and use it
  in the rest of the proof, _provided_ we keep an assumption `(box C)` around
  in a negative literal. Once we actually prove `C` we can discharge `(box C)`.

- **box-proof** (`(box-proof <proof>)`):
  given a proof `p` with conclusion `C`, this returns a proof
  whose conclusion is `(cl (+ (box C)))`. Semantically it is merely the identity.

An interesting possibility offered by `box` is simplifications in a tactic framework.
A simplification rule might take a _goal_ clause `A`, and simplify it
into a goal clause `B`. To justify this, the theorem prover might produce
a proof `(cl (- (box B)) l1 … ln)` (assuming `A` is `(cl l1 … ln)`)
which means \\( B \Rightarrow A \\). 
It might do that by starting with `(box-assume B)` and applying the rewrite
steps backward to get back to the literals of `A`.

Once the goal `B` is proved, we obtain a proof of `B` which we can lift
to a proof of `(cl (+ (box B)))` using `box-lift`; then we only have to do unit-resolution
on `(cl (+ (box B)))` and `(cl (- (box B)) l1 … ln)` to
obtain `(cl l1 … ln)`, ie. the original goal `A`.

Another possibility is to box a full clause, and use it as an assumption
in a sub-proof using [`steps`](./rules-composite.md).
Then, `box-assume` can be used to make use of the assumption by resolving
it with the `(- (box C))` literal from `box-assume`.



[AVATAR]: https://link.springer.com/chapter/10.1007/978-3-319-08867-9_46
