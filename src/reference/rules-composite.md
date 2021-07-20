# Composite rule

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

## Toplevel composite rule

The syntax allows the toplevel composite rule
(i.e. the main proof, as opposed to a subproof)
to be _flattened_ into a list of S-expressions.

It's probably not very useful to have assumptions here[^1].

For example, a proof could look like:

```
(quip 1)

(step1)
(step2)
(step3)
…
```


[^1]: famous last words.
