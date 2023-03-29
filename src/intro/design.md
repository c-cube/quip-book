
## Overall design

A Quip proof is organized around a few main notions: _terms_, _substitutions_,
_clauses_, and _proof steps_.

- **Terms** are expressions in a simple higher-order logic similar to the ones
  of HOL light, HOL, Isabelle/HOL, etc. It features prenex polymorphism,
  applications, equality, variables, and lambda abstractions.

  An example term might be \\(  p~ x = (\lambda y. f~ x~ y = y) \\)
  where \\( p \\) is a predicate symbol and \\( f \\) a function symbol.
  We use here a ML-like syntax with currying.

- **Substitutions** are finite mappings from variables to terms,
  noted as such: \\( \\{ x_1 \mapsto t_1, \ldots, x_n \mapsto t_n \\} \\).

  _Applying_ a substitution to a term yields a new term, where the variables
  have been replaced by their image in the substitution (or kept if they're
  not bound in the substitution)

- **Clauses** are sets of literals[^1], where each literal is a tuple
  \\( sign, term \\). The _sign_ of a literal is a boolean
  that indicates whether the term is positive (`true`) or negative (`false`).
  A negative literal `(false, t)` fundamentally _represents_ \\( \lnot t \\)
  but is distinct from the term \\( \lnot t \\) because the polarity (the sign)
  is only relevant in the context of a clause.

  We will denote a negative literal as \\( - t \\) and a positive
  literal as \\( + t \\).

  An example clause might be: \\[ \\{ - (a=b), - (c=d), + ((f~ a~ c) = (f~ b~ d)) \\} \\]
  It represents the basic congruence lemma:
  \\[ a=b, c=d \vdash f~ a~ c = f~ b~ d    \\]

- **Proof steps** are the basic building blocks of proofs. A proof step
  is composed of:

  * a **rule**, which indicates how to process this step;
  * a **conclusion**, which is the clause that this proof step produces;
  * a set of **premises**, which are inputs to the proof step.
  * optionally, some additional arguments such as terms, substitutions, etc.

  A proof step asserts (via its particular rule) that the set of premises
  implies its conclusion. In practice not all the elements of a step might be
  explicitly written down! For example \\( \text{refl}~ t \\) (with \\( t \\) a term)
  is a basic proof step with rule "refl", no premises,
  and conclusion  \\( \\{ + (t = t) \\} \\).


A distinguishing feature of Quip compared to some other proof formats such as
the one in VeriT is that the rules are high-level and require proof checkers
to do more work in order to verify them. In exchange, the hope is that
we get more concise proofs that are also easier to produce from theorem provers.

**TODO**: citations for VeriT

[^1]: Clauses can alternatively be seen as classical sequents, with negative elements
  on the left of \\( \vdash \\), and positive elements on the right of it.
