# Atomic rules

- **ref** (`(ref <name>)`): returns a proof previously defined using `stepc`
  (see [composite proofs](#composite-proofs) below) or a unit clause
  corresponding to a local assumption of `steps`.
  There is no need to re-prove anything, we assume the step was valid and
  just reuse its conclusion.

  In other words, `(ref c5)` coming after `(defc c5 (cl (+ p) (+ q)) <proof>)`
  is a trivial proof of the clause `(cl (+ p) (+ q))`.

- **refl** (`(refl <term>)`): `(refl t)` is a proof of the
  clause `(cl (+ (= t t)))`.

- **assert** (`(assert <term>)`): proves a unit clause `(cl (+ t))` (if
  the term is `t`), but only if it matches exactly
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

  * **boolean-paramodulation** (`(p <term> <term> <proof>)`):
    `(p lhs rhs proof)` resolves `proof` into a clause
    `D` which must contain a literal `(+ (= lhs rhs))`, where both
    `lhs` and `rhs` are boolean terms.
    In other words, \\( D \triangleq lhs = rhs \lor D' \\).

    The current clause `C` must contain a literal `(± lhs)`;
    ie. \\( C \triangleq C' \lor ± lhs \\).

    the result is obtained by replacing `lhs` with `rhs` in `C` and
    adding `D'` back. Mathematically:

    \\[
      \cfrac{
        lhs = rhs \lor D'
        \qquad
        lhs \lor C'
        }{
          C' \lor D' \lor rhs
        }
    \\]

  * **unit-boolean-paramodulation** (`(p1 <proof>)`):
    Same as `p` but the proof must return a unit clause `(+ (= lhs rhs))`.

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

- **bool-c** (`(bool-c <name> <clause>)`): `(bool-c <name> c)`
  proves the clause `C` if it is a boolean tautology of depth 1 using the
  particular sub-rule named `<name>`.
  In other words, it corresponds to one construction or destruction axioms for
  the boolean connective `and`, `or`, `=>`, boolean `=`, `xor`, `not`.

  Note that a rule name can still cover several possible axioms. For example
  `and-e` (for "and elim") covers all the `(cl (- (and t1 … tn)) (+ t_i))`
  for `i ∈ {1…n}`.

  The possible axioms, in their binary version, are:

  | name | connective | n-ary | axiom |
  |------|--------|-----|--|
  | and-i | `and` |  yes | `(cl (- A) (- B) (+ (and A B)))` |
  | and-e | `and` |  yes | `(cl (- (and A B)) (+ A))` |
  | and-e | `and` |  yes | `(cl (- (and A B)) (+ B))` |
  | or-e | `or` |  yes | `(cl (- (or A B)) (+ A) (+ B))` |
  | or-i | `or` |  yes | `(cl (- A) (+ (or A B)))` |
  | or-i | `or` |  yes | `(cl (- B) (+ (or A B)))` |
  | imp-e | `=>` |  yes | `(cl (- (=> A B)) (- A) (+ B))` |
  | imp-i | `=>` |  yes | `(cl (+ A) (+ (=> A B)))` |
  | imp-i | `=>` |  yes | `(cl (- B) (+ (=> A B)))` |
  | not-e | `not` | no | `(cl (- (not A)) (+ A))` |
  | not-i | `not` | no | `(cl (- A) (+ (not A))` |
  | eq-e | `=` |  no | `(cl (- (= A B)) (- A) (+ B))` |
  | eq-e | `=` |  no | `(cl (- (= A B)) (- B) (+ A))` |
  | eq-i | `=` |  no | `(cl (+ A) (+ B) (+ (= A B)))` |
  | eq-i | `=` |  no | `(cl (- A) (- B) (+ (= A B)))` |
  | xor-e | `xor` |  no | `(cl (- (xor A B)) (- A) (- B))` |
  | xor-e | `xor` |  no | `(cl (- (xor A B)) (+ A) (+ B))` |
  | xor-i | `xor` |  no | `(cl (+ A) (- B) (+ (xor A B)))` |
  | xor-i | `xor` |  no | `(cl (- A) (+ B) (+ (xor A B)))` |

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

