# Full example

We're going to explore a bigger example: the proof of unsatisfiability
of the SMTLIB problem `QF_UF/eq_diamond/eq_diamond2.smt2`.

It starts normally:

```smt2
{{#include ./proof_diamond2.quip:1:2}}
```

followed by a bundle of term definitions for better sharing:

```smt2
{{#include ./proof_diamond2.quip:3:17}}
```

and then the actual proof:

```smt2
{{#include ./proof_diamond2.quip:17:}}
```

Note that the last step returns the empty clause:

```smt2
{{#include ./proof_diamond2.quip:54:}}
```

