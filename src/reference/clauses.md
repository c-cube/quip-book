# Clauses


We denote clauses as `(cl <lit>*)`. The empty clause is therefore `(cl)`.
Each literal is `(<sign> <term>)` with the sign being either `+` or `-`
(for a clause-level negation).

For example, `(cl (- true) (+ (= b b)))` represents the clause
\\( \lnot \top \lor b=b \\), or the sequent \\( \top \vdash b=b \\).
