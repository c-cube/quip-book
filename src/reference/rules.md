# Proof Rules

Rules form an expression language designed to only return valid clause
(i.e. theorems, or assumptions of the problem). Most rules are of the atomic kind
(they take arguments but look like a function application);
the main [structuring rule](./rules-composite.md) permits the definition
of named intermediate steps. This is also necessary to introduce sharing in a proof,
where some clause might be proved once but used many times.
