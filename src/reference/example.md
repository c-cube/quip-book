# Full example

We're going to explore a bigger example: the proof of unsatisfiability
of the SMTLIB problem `QF_UF/eq_diamond/eq_diamond2.smt2`.

It starts normally:

```smt2
{{#include ./proof_diamond2.quip:1:2}}
```

followed by a bundle of term definitions for better sharing
(note that the `_tseitin_xxx` symbols are actually introduced by Sidekick
during clausification; they're not just proof printing artefacts):

```smt2
{{#include ./proof_diamond2.quip:3:16}}
```

and then the actual proof:

```smt2
{{#include ./proof_diamond2.quip:17:}}
```

Note that the last step returns the empty clause, which means we did prove
the problem to be unsatisfiable:

```smt2
{{#include ./proof_diamond2.quip:54:}}
```

Let's examine a few steps.

- `c0`:
  ```
  (stepc c0 (cl (- $t1) (- $t2) (+ $t8))
    (cc-lemma (cl (- $t1) (- $t2) (+ $t8))))
  ```
  which means that \\( x0 = y0, y0 = x1 \vdash x0 = x1 \\) is a tautology
  of the theory of equality. Indeed it is, it's the transitivity axiom.

- `c3`:
  ```
  (stepc c3 (cl (- $t8)) (hres (init (ref c1)) (r1 (ref c2))))
  ```

  Here, we have:
  * `c1` is `(cl (- _tseitin_and_3) (- (= x0 x1))`
  * `c2` is `(cl (+ _tseitin_and_3))`
  * so, by resolution of `c1` and `c2`
    (note the use of "r1" since `c2` is unit: we do
    not need to specify a pivot) we obtain `(cl (- (= x0 x1)))`.

- `c4`:
  ```
  (stepc c4 (cl (- _tseitin_and_0) (+ $t2))
   (bool-c (cl (+ $t2) (- _tseitin_and_0))))
  ```
  where `_tseitin_and_0` is actually a name for `(and $t1 $t2)`.

  The `bool-c` rule is valid since `(cl (+ $t2) (- (and $t1 $t2)))`
  is one of the basic tautology on the `and` boolean connective.

- `c10`:
  ```
  (stepc c10 (cl (- _tseitin_and_1))
   (hres (init (ref c7)) (r (pivot $t5) (ref c9))
     (r (pivot $t4) (ref c8))))
  ```
  
  We have:
  - `c7` is `(cl (- $t5) (- $t4))`
  - `c9` is `(cl (- _tseitin_and_1) (+ $t5))`
  - `c8` is `(cl (- _tseitin_and_1) (+ $t4))`

  And the hyper-resolution steps therefore go:

  | clause | step |
  |----|------|
  | `(cl (- $t5) (- $t4))` | start with `c7` |
  | `(cl (- $t4) (- _tseitin_and_1))` | resolve with `c9` on `$t5` |
  | `(cl (- _tseitin_and_1))` | resolve with `c8` on `$t4` |

- `c17`:
  ```
  (stepc c17 (cl)
   (hres (init (ref c0)) (r1 (ref c16))
    (r1 (ref c14)) (r1 (ref c3)))))))
  ```

  We prove the empty clause! Here we have:
  - `c0` is `(cl (- $t1) (- $t2) (+ $t8))`
  - `c16` is `(cl (+ $t1))`
  - `c14` is `(cl (+ $t2))`
  - `c3` is `(cl (- $t8))`

  So by starting with `c0` and performing unit resolution steps we get:

  | clause | step |
  |-----|----|
  | `(cl (- $t1) (- $t2) (+ $t8))` | start with `c0` |
  | `(cl (- $t2) (+ $t8))` | unit-resolve with `c16` |
  | `(cl (+ $t8))` | unit-resolve with `c14` |
  | `(cl )` | unit-resolve with `c3` |

  
