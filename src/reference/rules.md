# Proof Rules

## Atomic rules

- **ref** (`(ref <name>)`): returns a proof previously defined using `stepc`
  (see [composite proofs](#composite-proofs) below).
  There is no need to re-prove anything, we assume the step was valid and
  just reuse its conclusion.

  In other words, `(ref c5)` coming after `(defc c5 (cl (+ p) (+ q)) <proof>)`
  is a trivial proof of the clause `(cl (+ p) (+ q))`.

- **refl** (`(refl <term>)`): `(refl t)` is a proof of the
  clause `(cl (+ (= t t)))`.

- **assert** (`(assert <clause>)`): proves a clause, but only if it matches exactly
  an assertion/hypothesis of the original problem.

  (TODO: be able to refer to the original formula by file+name if it was provided)

- **hres** (`(hres (init <proof>) <hstep>+)`): a fold-like operation on the
  initial proof's result. It can represent a resolution step, or hyper-resolution,
  or some boolean paramodulation steps. As opposed to the other rules which
  are mostly useful for preprocessing/simplification of the original problem,
  this is expected to be one of the main inference rules
  for resolution/superposition provers.

  The proof step `(hres (init p0) h1 h2 … hn)` starts with the clause
  `C0` obtained by validating `p0`. It then applies each "h-step" in the order
  they are presented. Assuming the current clause is `C == (cl l1 … lm)`,
  each h-step can be one of the following:

  * **resolution** (`(r (pivot <term>) <proof>)`): `(r (pivot t) proof)`
    resolves `proof` into a clause `D` which must contain a literal
    `(+ t)` or `(- t)`. Then it performs boolean resolution between
    the current clause `C` and the clause `D` with pivot literal `(+ t)`.

    Without loss of generality let's assume the proof returns `D`
    where \\( D \triangleq D' \lor (+ t) \\), and \\( C \triangleq C' \lor (- t) \\).
    Then the new clause is \\( C' \lor D' \\).

  * **unit resolution** (`(r1 <proof>)`): `(r1 proof)` resolves `proof` into a clause `D`
    which _must_ be a unit-clause (i.e. exactly one literal).
    Since there is not ambiguity on the pivot, it performs unit resolution
    between `C` and `D` on the unique literal of `D`.

   TODO: p and p1

- **cc-lemma** (`(cc-lemma <clause>)`): proves a clause `c` if it's a
  tautology of the theory of equality. There should generally be
  n negative literals and one positive literal, all of them equations.

  An example:

  ```
  (cc-lemma
    (cl
      (- (= a b))
      (- (= (f b) c))
      (- (= c c2))
      (- (= (f c2) d))
      (+ (= (f (f a)) d))))
  ```

- **cc-imply** (`(cc-imply (<proof>*) <term> <term>)`): a shortcut step
  that combines `cc-lemma` and `hres` for more convenient proof production.
  Internally the checker should be able to reuse most of the implementation
  logic of `cc-lemma`.

  `(cc-imply (p1 … pn) t u)` takes `n` proofs, all of which must have
  unit equations as their conclusions (say, `p_i` proves `(cl (+ (= t_i u_i)))`);
  and two terms `t` and `u`;
  and it returns a proof of `(cl (+ (= t u)))` if
  the clause `(cl (- (= t_1 u_1)) (- (= t_2 u_2)) … (- (= t_n u_n)) (+ (= t u)))`
  is a valid equality lemma (one that `cc-lemma` would validate).

  In other words, `(cc-lemma (p1…pn) t u)`
  could be expanded (using fresh names for steps) to:

  ```
  (steps ()
    ((stepc c_1 (cl (+ (= t_1 u_1))) p_1)
     (stepc c_2 (cl (+ (= t_2 u_2))) p_2)
     …
     (stepc c_n (cl (+ (= t_n u_n))) p_n)
     (stepc the_lemma
      (cl (- (= t_1 u_1)) (- (= t_2 u_2)) … (- (= t_n u_n)) (+ (= t u)))
      (cc-lemma
        (cl (- (= t_1 u_1)) (- (= t_2 u_2)) … (- (= t_n u_n)) (+ (= t u)))))
     (stepc res (cl (+ (= t u)))
      (hres
        (init (ref the_lemma))
        (r1 (ref c_1))
        (r1 (ref c_2))
        …
        (r1 (ref c_n))))))
  ```

- **bool-c** (`(bool-c <clause>)`): `(bool-c c)` proves the clause `C` if
  it is a boolean tautology of depth 1. In other words, it corresponds to one
  construction or destruction axioms for the boolean connective
  `and`, `or`, `=>`, boolean `=`, `xor`, `not`.

  The possible axioms, in their binary version, are:

  | connective | n-ary | axiom |
  |--------|-----|--|
  |  `and` |  yes | `(cl (- A) (- B) (+ (and A B)))` |
  |  `and` |  yes | `(cl (- (and A B)) (+ A))` |
  |  `and` |  yes | `(cl (- (and A B)) (+ B))` |
  |  `or` |  yes | `(cl (- (or A B)) (+ A) (+ B))` |
  |  `or` |  yes | `(cl (- A) (+ (or A B)))` |
  |  `or` |  yes | `(cl (- B) (+ (or A B)))` |
  |  `=>` |  yes | `(cl (- (=> A B)) (- A) (+ B))` |
  |  `=>` |  yes | `(cl (+ A) (+ (=> A B)))` |
  |  `=>` |  yes | `(cl (- B) (+ (=> A B)))` |
  | `not` | no | `(cl (- (not A)) (+ A))` |
  | `not` | no | `(cl (- A) (+ (not A))` |
  |  `=` |  no | `(cl (- (= A B)) (- A) (+ B))` |
  |  `=` |  no | `(cl (- (= A B)) (- B) (+ A))` |
  |  `=` |  no | `(cl (+ A) (+ B) (+ (= A B)))` |
  |  `=` |  no | `(cl (- A) (- B) (+ (= A B)))` |
  |  `xor` |  no | `(cl (- (xor A B)) (- A) (- B))` |
  |  `xor` |  no | `(cl (- (xor A B)) (+ A) (+ B))` |
  |  `xor` |  no | `(cl (+ A) (- B) (+ (xor A B)))` |
  |  `xor` |  no | `(cl (- A) (+ B) (+ (xor A B)))` |

  And an example of a n-ary axiom could be:

  ```
  (cl (- A1) (- A2) … (- An) (+ (and A1 A2 … An)))
  ```

- **bool-eq** (`(bool-eq <term> <term>)`): `(bool-eq t u)` proves
  the clause `(cl (+ (= t u)))` (where `t` and `u` are both boolean terms)
  if `t` simplifies to `u` via a basic simplification step.

  This rule corresponds to the axioms:

  | axiom |
  |-----|
  | `(= (not true) false)` |
  | `(= (not false) true)` |
  | `(= (not (not t)) t)` |
  | `(= (= true A) A)` |
  | `(= (= false A) (not A))` |
  | `(= (xor true A) (not A))` |
  | `(= (xor false A) A)` |
  | `(= (= t t) true)` |
  | `(= (or t1…tn true u1…um) true)` |
  | `(= (or false false) false)` |
  | `(= (=> true A) A)` |
  | `(= (=> false A) true)` |
  | `(= (=> A true) true)` |
  | `(= (=> A false) (not A))` |
  | `(= (or false false) false)` |
  | `(= (and t1…tn false u1…um) false)` |
  | `(= (and true true) true)` |

- **\\( \beta \\)-reduction** (`(beta-red <term> <term>)`):
  Given `(lambda (x:τ) body)` and `u`, returns the clause
  `(cl (+ (= ((lambda (x:τ) body) u) body[x := u])))`
  where `body[x := u]` denotes the term obtained by substituting `x` with `u`
  in `body` in a capture avoiding way.

  Mathematically:
  \\[
    \vdash (\lambda x:\tau. t)~ u = t[x := u]
  \\]

<!-- TODO? or unecessary?
- **\\( \eta \\)-expansion** (`(eta-exp <term>)`):
  Given a term `t` of arrow type `a → b`, returns the lemma
  `(cl (+ (= t ((lambda (x:a) t) x))))` for a variable `x` of type `a`.

  Mathematically:
  \\[
    (\lambda x:\tau. t)~ x = t
  \\]
  -->


TODO: instantiation

TODO: reasoning under quantifiers

## Composite proofs

The main structuring construct for proofs is `steps`. Its structure is
`(steps (<assumption>*) (<step>+))`.

- Each **assumption** is a pair `(<name> <literal>)`.
  As a reminder, literals are of the shape `(+ t)` or `(- t)`.

  These assumptions can be used in the steps by using `(ref <name>)` (see below),
  which is a trivial proof of the unit clause `(cl <literal>)`.
  
- Each **step** is one of:

  * **Term definition** (`(deft <name> <term>)`), which introduces an
    alias for a term. `<name>` must not be in the signature of the original problem.

    Logically speaking, after `(deft c t)`, `c` and `t` are syntactically the
    same. `c` has no real existence, it is only a shortcut, so a proof
    of `(cl (+ (= c t)))` can be simply `(refl t)` (or `(refl c)`).

  * **Reasoning step** (`(stepc <name> <clause> <proof>)`):
    `(stepc name clause proof)` (where `name` must be fresh: be defined nowhere else)
    introduces `name` as a shortcut for `proof` in the following steps.

    The result of `proof` must be exactly `clause`, otherwise the step fails.
    This means we can start _using_ `(ref name)` in the following steps
    before we validate `proof`, since we know the result ahead. In a
    high-performance proof checker this is a good opportunity for parallelisation,
    where `proof` can be checked in parallel with other steps that make use of its
    result.

- The result of `(steps (A1 … Am) (S1 … Sn))`, where the last step
  `Sn` has as conclusion a clause `C` with literals `(cl l1 … ln)`,
  is the clause `(cl l1 … ln ¬A1 … ¬Am)`.

  In particular, if `Sn` proves the empty clause, then `(steps …)` proves
  that at least one assumption must be false. If both `Sn`'s conclusion
  and the list of assumptions are empty, then
  the result is the empty clause.

- The list of assumptions can be useful either for subproofs,
  or to produce a proof of unsatisfiability for
  the SMTLIB v2.6 statement `(check-sat-assuming (<lit>+))`.


## Box

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
  whose conclusion is `(box C)`. Semantically it does nothing.

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
obtain `(cl l1 … ln)`, ie. was the original goal `A`.

Another possibility is to box a full clause, and use it as an assumption
in a sub-proof `steps`. Then `box-assume` is required to make use of the assumption.



[AVATAR]: https://link.springer.com/chapter/10.1007/978-3-319-08867-9_46
