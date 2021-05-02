# Example

This is a very simple SMT problem in the category `QF_UF`, representing
the problem \\( a=b \land f~a = c \vdash f~b = c \\) by trying to contradict it:

```smtlib2
{{#include ./example-pb.smt2}}
```

With [Sidekick](https://github.com/c-cube/sidekick)'s experimental
proof producing mode, we solve this problem (it replies "UNSAT"):

```sh
$ sidekick example-pb.smt2 -o example-proof.quip
Unsat (0.003/0.000/0.000)
```

And we get the following proof:

```sexp
{{#include ./example-proof.quip}}
```

