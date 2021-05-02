# Quip for the Proof Checker

Quip's design favors the production of proofs, not their checking. However,
proof checking should still be implementable in an efficient way.

A proof checker must implement a few core algorithms to be able to verify proofs
(not to mention the particular set of theories it might support).
These are:

- **Congruence Closure**:
  equality is central to Quip, and most equality proofs
  will be of the shape \\( t_1=u_1, \ldots, t_n = u_n \vdash t=u \\).
  These can be checked in \\( O(n ~ log(n)) \\) time using Congruence Closure
  (See for example the [EGG paper]).

- **Resolution**: 
  clause-level reasoning is done via multiple steps of resolution.

  The core rule is:
  \\[
    \cfrac{C1 \lor l  \qquad         C2 \lor \lnot l}{ C1 \lor C2 }
  \\]

- **Instantiation**:
  A clause \\( C \\) contains free variables \\( \\{ x_1, \ldots, x_n \\} \\).
  Given a substitution \\( \sigma \triangleq \\{ x_1 \mapsto t_1, \ldots, x_n \mapsto t_n \\} \\), we
  can deduce \\( C\sigma \\).




[EGG]: https://arxiv.org/abs/2004.03082
