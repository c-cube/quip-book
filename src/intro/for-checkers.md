
## Quip for the Proof Checker

Quip's design favors the production of proofs, not their checking. However,
proof checking should still be implementable in an efficient way.

A proof checker must implement a few core algorithms to be able to verify proofs
(not to mention the particular set of theories it might support).
These are:

- **Congruence Closure**: equality is central to Quip, and most equality proofs
  will be of the shape \\( t_1=u_1, \ldots, t_n = u_n \vdash t=u \\).
  These can be checked in \\( O(n ~ log(n)) \\) time using Congruence Closure
  (See for example the [EGG paper]).
- **Resolution**: 




[EGG]: https://arxiv.org/abs/2004.03082
