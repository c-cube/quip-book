# Atomic rules

- **ref** (`(ref <name>)`): returns a proof previously defined using `stepc`
  (see [composite proofs](#composite-proofs) below) or a unit clause
  corresponding to a local assumption of `steps`.
  There is no need to re-prove anything, we assume the step was valid and
  just reuse its conclusion.

  In other words, `(ref c5)` coming after `(defc c5 (cl (+ p) (+ q)) <proof>)`
  is a trivial proof of the clause `(cl (+ p) (+ q))`.

  The serialization might use "@" instead of "ref".

- **refl** (`(refl <term>)`): `(refl t)` is a proof of the
  clause `(cl (+ (= t t)))`.

- **assert** (`(assert <term>)`): proves a unit clause `(cl (+ t))` (if
  the term is `t`), but only if it matches exactly
  an assertion/hypothesis of the original problem.

  (TODO: be able to refer to the original formula by file+name if it was provided)

- **hres** (`(hres <proof> <hstep>+)`): a fold-like operation on the
  initial proof's result. It can represent a resolution step, or hyper-resolution,
  or some boolean paramodulation steps. As opposed to the other rules which
  are mostly useful for preprocessing/simplification of the original problem,
  this is expected to be one of the main inference rules
  for resolution/superposition provers.

  The proof step `(hres (init p0) h1 h2 … hn)` starts with the clause
  `C0` obtained by validating `p0`. It then applies each "h-step" in the order
  they are presented. Assuming the current clause is `C == (cl l1 … lm)`,
  each h-step can be one of the following:

  * **resolution** (`(r <term> <proof>)`): `(r t proof)`
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

- **r** (`(r <term> <proof> <proof>)`): resolution on the given pivot
  between the two clauses.

  The proof term `(r pivot p1 p2)` corresponds to `(hres p1 (r pivot p2))`.

- **r1** (`(r1 <proof> <proof>)`): unit resolution.
  The shortcut `(r1 p1 p2)` allows the user to omit the
  pivot **if** one the the two proofs is unit (ie. has exactly one literal).
  It is the same as `(hres p1 (r1 p2))`.

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

- **nn** (`(nn <proof>)`): not-normalization: a normalization step that
  transforms some literals in a clause. It turns `(- (not a))` into `(+ a)`,
  and `(+ (not a))` into `(- a)`.

- **bool-c** (`(bool-c <name> <term>+)`): `(bool-c <name> <terms>)`
  proves a boolean tautology of depth 1 using the
  particular sub-rule named `<name>` with some term argument(s).
  In other words, it corresponds to one construction or destruction axioms for
  the boolean connective `and`, `or`, `=>`, boolean `=`, `xor`, `not`.

  The possible axioms are:

  | rule | axiom |
  |------| --|
  | `(and-i (and A1…An))` | `(cl (- A1) … (- An) (+ (and A1…An)))` |
  | `(and-e (and A1…An) Ai)` | `(cl (- (and A1…An)) (+ Ai))` |
  | `(or-e (or A1…An))` | `(cl (- (or A1…An)) (+ A1) … (+ An))` |
  | `(or-i (or A1…An) Ai)` | `(cl (- Ai) (+ (or A1…An)))` |
  | `(imp-e (=> A1…An B))` | `(cl (- (=> A1…An B)) (- A1)…(- An) (+ B))` |
  | `(imp-i (=> A1…An B) Ai)` | `(cl (+ Ai) (+ (=> A1…An B)))` |
  | `(imp-i (=> A1…An B) B)` | `(cl (- B) (+ (=> A1…An B)))` |
  | `(not-e (not A))` | `(cl (- (not A)) (+ A))` |
  | `(not-i (not A))` | `(cl (- A) (+ (not A))` |
  | `(eq-e (= A B) A)` | `(cl (- (= A B)) (- A) (+ B))` |
  | `(eq-e (= A B) B)` | `(cl (- (= A B)) (- B) (+ A))` |
  | `(eq-i+ (= A B))` | `(cl (+ A) (+ B) (+ (= A B)))` |
  | `(eq-i- (= A B))` | `(cl (- A) (- B) (+ (= A B)))` |
  | `(xor-e- (xor A B))` | `(cl (- (xor A B)) (- A) (- B))` |
  | `(xor-e+ (xor A B))` | `(cl (- (xor A B)) (+ A) (+ B))` |
  | `(xor-i (xor A B) B)` | `(cl (+ A) (- B) (+ (xor A B)))` |
  | `(xor-i (xor A B) A)` | `(cl (- A) (+ B) (+ (xor A B)))` |

- **bool-eq** (`(bool-eq <term> <term>)`): `(bool-eq t u)` proves
  the clause `(cl (+ (= t u)))` (where `t` and `u` are both boolean terms)
  if `t` simplifies to `u` via a basic simplification step.

  This rule corresponds to the axioms:

  **TODO**: also give names to sub-rules here

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

