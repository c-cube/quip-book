# Terms

Terms belong to higher-order logic, with prenex polymorphism. In general
we denote terms as \\( t \\) or \\( u \\) (with indices if needed).

(TODO: provide some citations)

(TODO: specify types)

The term can be constructed in the following ways:

- **Variables**, denoted \\( x, y, z \\). They can be free, or bound. Variables
  are typed.
- **Applications**, denoted `(f t1 t2 t3)`. Partial applications are transparent,
  meaning that `(f t1 t2 t3)` is short for `(((f t1) t2) t3)`.

- **Constants**, denoted \\( a, b, c, f, g, h \\)
  (where \\(a,b,c\\) are of atomic type and \\(f, g, h\\)
   are functions by convention).

  Polymorphic constants are applied to type arguments. Quip does not accept
  a term made of a partially applied constant: polymorphism constants must always
  be applied to enough type arguments.

  **NOTE**:
  This does _not_ include constants introduced by the prover using `(deft <name> <term>)` steps.
  In that construct, say `(deft c (f a b))`, `c` and `(f a b)` are considered syntactically
  equal; the proof checker can just expand `c` into `(f a b)` at parse time
  and then forget entirely about `c`.

- **Binders**, such as \\( \lambda (x:ty). t \\), or \\( \forall (x:ty). t \\).
  The latter is a shortcut for the application
  \\( \text{forall}~ (\lambda (x:ty). term) \\)
  (where \\( \text{forall} \\) is a constant of type \\( \Pi a. (a \to \text{bool}) \to \text{bool} \\) ).

With lambda-abstraction comes a handful of axioms:
\\( \beta\\)-reduction, and \\( \eta \\)-expansion
(more details in [the rules section](./rules.md)).
